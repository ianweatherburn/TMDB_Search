//
//  Constants+App.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import Foundation

// swiftlint:disable nesting

// Application Constants
extension Constants.App {
    enum Sounds {
        static let success = "Glass"
        static let failure = "Pop"
        static let idCopy = "Morse"
        static let nameCopy = "Tink"
    }
    enum Window {
        enum Main {
            static let width: CGFloat = 1_366
            static let height: CGFloat = 768
        }
        enum Help {
            static let width: CGFloat = 800
            static let height: CGFloat = 600
        }
    }
    enum Menu {
        static let clearSearch = "Clear Search"
        static let showSearchHistory = "Show Search History"
        static let help = "\(name) Help"
    }
    enum Help {
        static let tapHelp = "Tap to copy the name or Opt+Tap to copy the ID"
    }
    
    static let name = "TMDB Search"
    static let image = "tmdb"
    static let defaultMediaType = MediaType.tv
}

// swiftlint:enable nesting
