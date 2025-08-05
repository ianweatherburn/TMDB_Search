//
//  TMDBImage.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

struct TMDBImagesResponse: Codable {
    let id: Int
    let posters: [TMDBImage]
    let backdrops: [TMDBImage]
}

struct TMDBImage: Codable, Identifiable {
    let aspectRatio: Double
    let height: Int
    let width: Int
    let filePath: String
    let voteAverage: Double
    let voteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case height, width
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    var id: String { filePath }
}
