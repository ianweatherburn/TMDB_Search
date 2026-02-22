//
//  TMDBImage.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

enum ImageType {
    case backdrop
    case logo
    case poster
}

struct TMDBImagesResponse: Codable {
    let id: Int
    let posters: [TMDBImage]
    let backdrops: [TMDBImage]
    let logos: [TMDBImage]

    enum CodingKeys: String, CodingKey {
        case id, posters, backdrops, logos
    }

    init(id: Int, posters: [TMDBImage], backdrops: [TMDBImage], logos: [TMDBImage]) {
        self.id = id
        self.posters = posters
        self.backdrops = backdrops
        self.logos = logos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        posters = try container.decodeIfPresent([TMDBImage].self, forKey: .posters) ?? []
        backdrops = try container.decodeIfPresent([TMDBImage].self, forKey: .backdrops) ?? []
        logos = try container.decodeIfPresent([TMDBImage].self, forKey: .logos) ?? []
    }
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
