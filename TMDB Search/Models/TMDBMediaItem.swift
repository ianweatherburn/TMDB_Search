//
//  TMDBMediaItem.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

struct TMDBMediaItem: Codable, Identifiable {
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
        return "\(displayTitle)\(year) [\(id)]"
    }
}


