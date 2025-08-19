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
            static let width: CGFloat = 140
            static let height: CGFloat = 100
            static let ratio: CGFloat = 16.0/9.0 // Widescreen ratio for backdrops
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
            static let width: CGFloat = 1366
            static let height: CGFloat = 768
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
            static let gridSize: GridSize = .small
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
                static let width: CGFloat = 1366
                static let height: CGFloat = 768
            }
            enum Help {
                static let width: CGFloat = 800
                static let height: CGFloat = 600
            }
        }
        static let image = "tmdb"
    }
}
