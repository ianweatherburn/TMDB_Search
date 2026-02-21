//
//  PlexLibrary.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import Foundation

// MARK: - Plex Library Models

struct PlexLibrary: Codable, Identifiable, Hashable {
    let key: String
    let title: String
    let type: String
    
    var id: String { key }
    
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case type
    }
}

// MARK: - Plex Season Models

struct PlexSeason: Codable, Identifiable {
    let ratingKey: String
    let index: Int
    let title: String
    
    var id: String { ratingKey }
    
    enum CodingKeys: String, CodingKey {
        case ratingKey
        case index
        case title
    }
}

// MARK: - Plex Episode Models

struct PlexEpisode: Codable, Identifiable {
    let ratingKey: String
    let index: Int
    let parentIndex: Int  // Season number
    let title: String
    
    var id: String { ratingKey }
    var seasonNumber: Int { parentIndex }
    var episodeNumber: Int { index }
    
    enum CodingKeys: String, CodingKey {
        case ratingKey
        case index
        case parentIndex
        case title
    }
}

// MARK: - Plex Children Response (Seasons/Episodes)

struct PlexChildrenResponse: Codable {
    let mediaContainer: MediaContainer
    
    struct MediaContainer: Codable {
        let metadata: [PlexMetadata]
        
        enum CodingKeys: String, CodingKey {
            case metadata = "Metadata"
        }
    }
    
    struct PlexMetadata: Codable {
        let ratingKey: String
        let index: Int
        let parentIndex: Int?
        let title: String
        
        enum CodingKeys: String, CodingKey {
            case ratingKey
            case index
            case parentIndex
            case title
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

// MARK: - Plex Libraries Response

struct PlexLibrariesResponse: Codable {
    let mediaContainer: MediaContainer
    
    struct MediaContainer: Codable {
        let directory: [PlexLibrary]
        
        enum CodingKeys: String, CodingKey {
            case directory = "Directory"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}
