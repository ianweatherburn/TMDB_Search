//
//  TMDBSearchResponse.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

// Core TMDB API Response Models
struct TMDBSearchResponse: Codable {
    let page: Int
    let results: [TMDBMediaItem]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
