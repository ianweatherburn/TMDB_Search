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
