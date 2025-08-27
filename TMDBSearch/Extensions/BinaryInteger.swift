//
//  BinaryInteger.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/27.
//

import SwiftUI

extension BinaryInteger {
    func inflect(_ word: String) -> LocalizedStringKey {
        let value = Int(self)           // <- concrete type for interpolation
        return "^[\(value) \(word)](inflect: true)"
    }
}
