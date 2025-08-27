//
//  BinaryInteger.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/27.
//

import SwiftUI

extension BinaryInteger {
    func pluralize(_ word: String, inflect: Bool = true) -> LocalizedStringKey {
        return inflect ?
            "^[\(Int(self)) \(word)](inflect: true)" :
            "^[\(Int(self)) \(word)](inflect: false)"
    }
}
