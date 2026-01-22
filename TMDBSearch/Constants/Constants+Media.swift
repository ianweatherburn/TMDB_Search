//
//  Constants+Media.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

// swiftlint:disable nesting

// Media Item Constants
extension Constants.Media {
    enum Types {
        static let shows = "shows"
        static let movies = "movies"
        static let collections = "collections"
    }
    
    enum UpdatePoster {
        static let script = "~/scripts/update_plex_posters.py"
        static let library = "-l"
        static let collection = "-c"
    }
    
    enum Actions {
        enum Tooltip {
            static let name = "Copy Title (⌘+Click)"
            static let folder = "Copy Asset Folder (Click)"
            static let id = "Copy TMDB-ID (⌥+Click)"
            static let updatePoster = "Copy Update Plex Poster Command (⌃+Click) (⌥⌃+Click for UHD)"
            static let updatePlex = "Update Plex Posters"
        }
    }
}

// swiftlint:enable nesting
