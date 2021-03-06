/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Lottie
import UIKit

protocol OnboardingStepViewControllable: ViewControllable {}

final class OnboardingStepViewController: ViewController, OnboardingStepViewControllable {

    // MARK: - Lifecycle

    init(onboardingManager: OnboardingManaging,
         onboardingStepBuilder: OnboardingStepBuildable,
         listener: OnboardingStepListener,
         theme: Theme,
         index: Int) {

        self.onboardingManager = onboardingManager
        self.onboardingStepBuilder = onboardingStepBuilder
        self.listener = listener
        self.index = index

        guard let step = self.onboardingManager.getStep(index) else { fatalError("OnboardingStep index out of range") }

        self.onboardingStep = step

        super.init(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.internalView.onboardingStep = self.onboardingStep

        setThemeNavigationBar()

        internalView.button.title = self.onboardingStep.buttonTitle
        internalView.button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if internalView.animationView.animation != nil, animationsEnabled() {
            self.internalView.animationView.play()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.internalView.animationView.stop()
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    // MARK: - Private

    private weak var listener: OnboardingStepListener?
    private lazy var internalView: OnboardingStepView = OnboardingStepView(theme: self.theme)
    private var index: Int
    private var onboardingStep: OnboardingStep
    private let onboardingManager: OnboardingManaging
    private let onboardingStepBuilder: OnboardingStepBuildable

    // MARK: - Setups

    private func setupViews() {
        setThemeNavigationBar()
    }

    // MARK: - Functions

    @objc func buttonPressed() {
        let nextIndex = self.index + 1
        if onboardingManager.onboardingSteps.count > nextIndex {
            listener?.nextStepAtIndex(nextIndex)
        } else {
            // build consent
            listener?.onboardingStepsDidComplete()
        }
    }
}

final class OnboardingStepView: View {

    private lazy var scrollView = UIScrollView()

    fileprivate lazy var button: Button = {
        return Button(theme: self.theme)
    }()

    lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.contentMode = .scaleToFill
        return animationView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var viewsInDisplayOrder = [imageView, animationView, titleLabel, contentLabel]

    var onboardingStep: OnboardingStep? {
        didSet {
            updateView()
        }
    }

    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }

    override func build() {
        super.build()

        addSubview(scrollView)
        addSubview(button)
        viewsInDisplayOrder.forEach { scrollView.addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalTo(button.snp.top).offset(-16)
        }

        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }

        titleLabel.snp.makeConstraints { maker in
            // no need for offset as the images include whitespace
            maker.top.greaterThanOrEqualTo(imageView.snp.bottom)
            maker.top.greaterThanOrEqualTo(animationView.snp.bottom)
            maker.leading.trailing.equalTo(self).inset(16)
        }

        contentLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(self).inset(16)
            maker.bottom.lessThanOrEqualTo(scrollView)
        }

        self.contentLabel.sizeToFit()
    }

    func updateView() {

        guard let step = self.onboardingStep else {
            return
        }

        self.titleLabel.attributedText = step.attributedTitle
        self.contentLabel.attributedText = step.attributedContent
        self.displayLink?.invalidate()
        self.displayLink = nil
        self.frameNumber = nil

        switch step.illustration {
        case let .image(named: name):
            imageView.image = Image.named(name)
            animationView.isHidden = true
            imageView.isHidden = false
        case let .animation(named: name, repeatFromFrame: repeatFromFrame):
            animationView.animation = LottieAnimation.named(name)
            animationView.isHidden = false
            imageView.isHidden = true

            if let repeatFromFrame = repeatFromFrame {
                loopAnimation(fromFrame: repeatFromFrame)
            } else {
                animationView.loopMode = .loop
            }
        }

        imageView.sizeToFit()

        if let width = imageView.image?.size.width,
            let height = imageView.image?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            imageView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalToSuperview()
                maker.width.equalTo(scrollView).inset(16)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio)
            }
        }

        animationView.sizeToFit()

        if let width = animationView.animation?.size.width,
            let height = animationView.animation?.size.height,
            width > 0, height > 0 {

            let aspectRatio = height / width

            animationView.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.centerX.equalToSuperview()
                maker.width.equalTo(scrollView).multipliedBy(1.5)
                maker.height.equalTo(scrollView.snp.width).multipliedBy(aspectRatio * 1.5)
            }
        }
    }

    // MARK: - Private

    var displayLink: CADisplayLink?
    var frameNumber: Int?

    private func loopAnimation(fromFrame frameNumber: Int) {
        self.frameNumber = frameNumber

        displayLink?.invalidate()

        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: RunLoop.current, forMode: .common)
    }

    @objc private func tick() {
        if animationView.currentProgress == 1.0,
            animationView.isAnimationPlaying == false,
            let frameNumber = frameNumber {
            animationView.play(fromFrame: CGFloat(frameNumber),
                               toFrame: animationView.animation?.endFrame ?? 0,
                               loopMode: nil,
                               completion: nil)
        }
    }
}
