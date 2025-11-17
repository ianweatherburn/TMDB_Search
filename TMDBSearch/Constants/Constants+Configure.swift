//
//  Constants+Configure.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import Foundation

// swiftlint:disable nesting

// App Configuration Constants
extension Constants.Configure {
    enum Window {
        static let multiplier: CGFloat = 0.80
    }
    enum API {
        static let tmdbSite = "themoviedb.org"
        static let tmdbURL = "https://www.themoviedb.org/settings/api)"
    }
    enum Preferences {
        enum History {
            static let size = 20
            static let minimum: Double = 5
            static let maximum: Double = 50
        }
        static let gridSize: GridSize = .small
        static let downloadPath = NSHomeDirectory() + "/Downloads/TMDB"
    }
}

// swiftlint:enable nesting
