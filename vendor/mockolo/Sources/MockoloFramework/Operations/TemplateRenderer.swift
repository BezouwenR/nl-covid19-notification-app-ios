//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Renders models with temeplates for output

func renderTemplates(entities: [ResolvedEntity],
                     useTemplateFunc: Bool,
                     useMockObservable: Bool,
                     enableFuncArgsHistory: Bool,
                     completion: @escaping (String, Int64) -> ()) {
    scan(entities) { (resolvedEntity, lock) in
        let mockModel = resolvedEntity.model()
        if let mockString = mockModel.render(with: resolvedEntity.key, encloser: mockModel.name, useTemplateFunc: useTemplateFunc, useMockObservable: useMockObservable, enableFuncArgsHistory: enableFuncArgsHistory), !mockString.isEmpty {
            lock?.lock()
            completion(mockString, mockModel.offset)
            lock?.unlock()
        }
    }
}
