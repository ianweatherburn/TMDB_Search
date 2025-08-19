//
//  Constants.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//
import Foundation

enum Constants {
    
    enum Image {
        enum Poster {
            static let width: CGFloat = 100
            static let height: CGFloat = 140
            static let ratio: CGFloat = 2.0/3.0 // Typical movie poster ratio
            static let spacing: CGFloat = 8
        }
        enum Backdrop {
            static let width: CGFloat = 140
            static let height: CGFloat = 100
            static let ratio: CGFloat = 16.0/9.0 // Widescreen ratio for backdrops
            static let spacing: CGFloat = 12
        }
        enum Gallery {
            static let width: CGFloat = 900
            static let height: CGFloat = 700
        }
        enum Types {
            static let poster = "poster.jpg"
            static let backdrop = "backdrop.jpg"
        }
    }
    
    enum Media {
        enum Types {
            static let shows = "shows"
            static let movies = "movies"
            static let collections = "collections"
        }
    }
    
    enum Configure {
        enum Window {
            static let multiplier: CGFloat = 0.80
        }
        enum API {
            static let tmdbSite = "themoviedb.org"
            static let tmdbURL = "https://www.themoviedb.org/settings/api)"
        }
        enum Preferences {
            enum History {
                static let size = 25
                static let minimum: CGFloat = 5
                static let maximum: CGFloat = 50
            }
            static let gridSize: GridSize = .medium
        }
    }
    
    enum App {
        enum Sounds {
            static let success = "Glass"
            static let failure = "Pop"
            static let idCopy = "Ping"
            static let nameCopy = "Glass"
        }
        enum Window {
            enum Main {
                static let width: CGFloat = 900
                static let height: CGFloat = 650
            }
            enum Help {
                static let width: CGFloat = 700
                static let height: CGFloat = 450
            }
        }
        static let image = "tmdb"
    }
}
