//
//  TMDBMedia.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SFSymbol

/* // swiftlint:disable identifier_name */
enum MediaType: String, CaseIterable, Codable {
    case tv
    case movie
    case collection

    var displayInfo: (icon: String, title: String, default: Bool) {
        switch self {
        case .tv: return (SFSymbol6.Photo.photo.rawValue, "Shows", true)
        case .movie: return (SFSymbol6.Movieclapper.movieclapper.rawValue, "Movies", false)
        case .collection: return (SFSymbol6.Film.filmStack.rawValue, "Collections", false)
        }
    }

}
/* // swiftlint:enable identifier_name */

struct TMDBMediaItem: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let name: String? // TV shows use 'name' instead of 'title'
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String? // TV shows use 'first_air_date'

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
    }

    // Computed properties for unified access
    var displayTitle: String {
        return title ?? name ?? "Unknown Title"
    }

    var displayYear: String {
        let dateString = releaseDate ?? firstAirDate ?? ""
        if dateString.count >= 4 {
            return String(dateString.prefix(4))
        }
        return ""
    }

    var formattedTitle: String {
        let year = displayYear.isEmpty ? "" : " (\(displayYear))"
        return "\(displayTitle)\(year)"
    }

    var plexTitle: String {
        let year = displayYear.isEmpty ? "" : " (\(displayYear))"
        return "\(displayTitle)\(year) {tmdb-\(id)}"
    }
}
