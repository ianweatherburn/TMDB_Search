//
//  Constants.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//
import Foundation

enum Constants {
    enum App {}
    enum Configure {}
    enum Image {}
    enum Media {}
    enum Services {}
}

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
    static let image = "tmdb"
}

// Image Display Constants
extension Constants.Image {
    enum Poster {
        static let ratio: CGFloat = 2.0 / 3.0 // Typical movie poster ratio
        static let width: CGFloat = 100
        static let height: CGFloat = width / ratio
        static let spacing: CGFloat = 12
        enum Gallery {
            enum Count {
                static let small = 8
                static let medium = 6
                static let large = 5
                static let huge = 4
            }
        }
    }
    enum Backdrop {
        static let ratio: CGFloat = 16.0 / 9.0 // Widescreen ratio for backdrops
        static let height: CGFloat = 100
        static let width: CGFloat = height * ratio
        static let spacing: CGFloat = 12
        enum Gallery {
            enum Count {
                static let small = 5
                static let medium = 4
                static let large = 3
                static let huge = 2
            }
        }
    }
    enum Gallery {
        static let width: CGFloat = 1_366
        static let height: CGFloat = 768
        static let scaleEffect: CGFloat = 1.04
    }
    enum Types {
        static let poster = "poster.jpg"
        static let backdrop = "backdrop.jpg"
    }
}

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
    }
}

// Media Item Constants
extension Constants.Media {
    enum Types {
        static let shows = "shows"
        static let movies = "movies"
        static let collections = "collections"
    }
}

// Service & API Constants
extension Constants.Services {
    enum TMDB {
        static let baseURL = "https://api.themoviedb.org/3"
        static let imageURL = "https://image.tmdb.org/t/p"
        static let languages = ["en"]
    }
    enum Flip {
        static let quality = 0.6
    }
}

// swiftlint:enable nesting
