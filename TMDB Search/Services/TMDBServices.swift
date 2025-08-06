//
//  TMDBServices.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import Foundation
import SwiftUI


// MARK: - TMDB Service
final class TMDBService {
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    
    enum ImageSize: String {
        case w92, w154, w185, w342, w500, w780, original
    }
    
    func searchMedia(query: String, mediaType: MediaType, apiKey: String) async throws -> [TMDBMediaItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/\(mediaType.rawValue)?api_key=\(apiKey)&query=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
        return response.results
    }
    
    func getImages(itemId: Int, mediaType: MediaType, apiKey: String) async throws -> TMDBImagesResponse {
        let urlString = "\(baseURL)/\(mediaType.rawValue)/\(itemId)/images?api_key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TMDBImagesResponse.self, from: data)
    }
    
    func loadImage(path: String, size: ImageSize = .w342) async -> Data? {
        let urlString = "\(imageBaseURL)/\(size.rawValue)\(path)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
    
    func downloadImage(path: String, to directory: String, filename: String) async -> Bool {
        let urlString = "\(imageBaseURL)/original\(path)"
        
        guard let url = URL(string: urlString) else { return false }

        do {
            let directoryURL = URL(fileURLWithPath: directory)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Break the filename into base and extension
            let fileBase = (filename as NSString).deletingPathExtension
            let fileExtension = (filename as NSString).pathExtension
            
            var fileURL = directoryURL.appendingPathComponent(filename)
            var counter = 1
            
            // Check if the file exists or find a unique name
            while FileManager.default.fileExists(atPath: fileURL.path) {
                let newFilename = "\(fileBase)_\(counter).\(fileExtension)"
                fileURL = directoryURL.appendingPathComponent(newFilename)
                counter += 1
            }

            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to download image: \(error)")
            return false
        }
    }

}
