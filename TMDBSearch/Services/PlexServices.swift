//
//  PlexServices.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import Foundation

// MARK: - Plex Services

final class PlexServices {
    
    // MARK: - Fetch Libraries
    
    func fetchLibraries(server: String, token: String) async throws -> [PlexLibrary] {
        guard !server.isEmpty, !token.isEmpty else {
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
        }
        
        let urlString = "\(serverURL)\(Constants.Services.Plex.librarySection)?X-Plex-Token=\(token)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        do {
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Try to decode the response
            let response = try JSONDecoder().decode(PlexLibrariesResponse.self, from: data)
            return response.mediaContainer.directory
        } catch let decodingError as DecodingError {
            print("Plex API decoding error: \(decodingError)")
            throw decodingError
        }
    }
    
    // MARK: - Upload Poster
    
    func uploadPoster(
        server: String,
        token: String,
        ratingKey: String,
        posterPath: String
    ) async throws {
        print("\n*** PlexService.uploadPoster ***")
        print("Input Parameters:")
        print("  Server: \(server)")
        print("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        print("  Rating Key: \(ratingKey)")
        print("  Poster Path: \(posterPath)")
        
        guard !server.isEmpty, !token.isEmpty, !ratingKey.isEmpty, !posterPath.isEmpty else {
            print("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            print("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        // Read poster file
        guard let posterData = try? Data(contentsOf: URL(fileURLWithPath: posterPath)) else {
            print("❌ ERROR: Failed to read poster file at \(posterPath)")
            throw URLError(.fileDoesNotExist)
        }
        
        print("Poster file size: \(posterData.count) bytes")
        
        // Upload endpoint
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/posters?X-Plex-Token=\(token)"
        
        print("\n🌐 Upload URL:")
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        print("  \(maskedURL)")
        
        guard let url = URL(string: urlString) else {
            print("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = posterData
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        print("\nUploading poster to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString.prefix(500))")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ ERROR: Bad status code \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            print("✅ Poster upload successful")
        }
        print("*** End PlexService.uploadPoster ***\n")
    }
    
    // MARK: - Search for Media Item
    
    func searchMedia(
        server: String,
        token: String,
        sectionId: String,
        title: String,
        year: String?,
        tmdbId: String?
    ) async throws -> String? {
        print("\n*** PlexService.searchMedia ***")
        print("Searching for: \(title) (\(year ?? "no year"))")
        
        guard !server.isEmpty, !token.isEmpty, !sectionId.isEmpty else {
            print("❌ ERROR: Required parameters missing")
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
        }
        
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ ERROR: Failed to encode title")
            throw URLError(.badURL)
        }
        
        var urlString = "\(serverURL)/library/sections/\(sectionId)/all?title=\(encodedTitle)"
        if let year = year {
            urlString += "&year=\(year)"
        }
        urlString += "&X-Plex-Token=\(token)"
        
        print("Search URL: \(urlString.replacingOccurrences(of: token, with: "***TOKEN***"))")
        
        guard let url = URL(string: urlString) else {
            print("❌ ERROR: Failed to create URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse response to find matching item
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let mediaContainer = json["MediaContainer"] as? [String: Any],
           let metadata = mediaContainer["Metadata"] as? [[String: Any]] {
            
            print("Found \(metadata.count) results")
            
            // Try to match by TMDB ID first if provided
            if let tmdbId = tmdbId {
                for item in metadata {
                    if let media = item["Media"] as? [[String: Any]] {
                        for mediaItem in media {
                            if let parts = mediaItem["Part"] as? [[String: Any]] {
                                for part in parts {
                                    if let file = part["file"] as? String,
                                       file.contains("{tmdb-\(tmdbId)}") {
                                        let ratingKey = item["ratingKey"] as? String ?? ""
                                        print("✅ Found match by TMDB ID. Rating Key: \(ratingKey)")
                                        return ratingKey
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Fallback to first result
            if let firstItem = metadata.first,
               let ratingKey = firstItem["ratingKey"] as? String {
                print("✅ Using first result. Rating Key: \(ratingKey)")
                return ratingKey
            }
        }
        
        print("❌ No matching item found")
        return nil
    }
    
    // MARK: - Refresh Metadata (kept for backwards compatibility)
    
    func refreshMetadata(
        server: String,
        token: String,
        sectionId: String,
        metadataPath: String
    ) async throws {
        print("\n*** PlexService.refreshMetadata ***")
        print("Input Parameters:")
        print("  Server: \(server)")
        print("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        print("  Section ID: \(sectionId)")
        print("  Metadata Path: \(metadataPath)")
        
        guard !server.isEmpty, !token.isEmpty, !sectionId.isEmpty, !metadataPath.isEmpty else {
            print("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            print("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        guard let encodedPath = metadataPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ ERROR: Failed to encode metadata path")
            throw URLError(.badURL)
        }
        
        print("Encoded Path: \(encodedPath)")
        
        let urlString = """
        \(serverURL)\(Constants.Services.Plex.librarySection)/\(sectionId)/refresh?\
        path=\(encodedPath)&X-Plex-Token=\(token)
        """
        
        print("\n🌐 Full Plex Refresh URL:")
        // Print URL with token masked for security
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        print("  \(maskedURL)")
        print("\n🌐 Actual URL (with real token):")
        print("  \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("\nSending request to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
            print("Response Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ ERROR: Bad status code \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            print("✅ Plex refresh request successful")
        }
        print("*** End PlexService.refreshMetadata ***\n")
    }
}
