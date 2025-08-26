//
//  Binding.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

extension Binding {
    /// Create a binding to a property of an object
    init<Object: AnyObject>(_ object: Object, keyPath: ReferenceWritableKeyPath<Object, Value>) {
        self.init(
            get: { object[keyPath: keyPath] },
            set: { object[keyPath: keyPath] = $0 }
        )
    }
}
