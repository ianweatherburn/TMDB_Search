//
//  PlexServices.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import Foundation

// MARK: - Plex Services

final class PlexServices {
    private func debugPrint(_ message: @autoclosure () -> String) {
        DebugLogger.log(message())
    }
    
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
            debugPrint("Plex API decoding error: \(decodingError)")
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
        debugPrint("\n*** PlexService.uploadPoster ***")
        debugPrint("Input Parameters:")
        debugPrint("  Server: \(server)")
        debugPrint("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        debugPrint("  Rating Key: \(ratingKey)")
        debugPrint("  Poster Path: \(posterPath)")
        
        guard !server.isEmpty, !token.isEmpty, !ratingKey.isEmpty, !posterPath.isEmpty else {
            debugPrint("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            debugPrint("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        // Read poster file
        guard let posterData = try? Data(contentsOf: URL(fileURLWithPath: posterPath)) else {
            debugPrint("❌ ERROR: Failed to read poster file at \(posterPath)")
            throw URLError(.fileDoesNotExist)
        }
        
        debugPrint("Poster file size: \(posterData.count) bytes")
        
        // Upload endpoint
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/posters?X-Plex-Token=\(token)"
        
        debugPrint("\n🌐 Upload URL:")
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        debugPrint("  \(maskedURL)")
        
        guard let url = URL(string: urlString) else {
            debugPrint("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = posterData
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        debugPrint("\nUploading poster to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint("Response Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                debugPrint("Response Body: \(responseString.prefix(500))")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                debugPrint("❌ ERROR: Bad status code \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            debugPrint("✅ Poster upload successful")
        }
        debugPrint("*** End PlexService.uploadPoster ***\n")
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
        debugPrint("\n*** PlexService.searchMedia ***")
        debugPrint("Searching for: \(title) (\(year ?? "no year"))")
        
        guard !server.isEmpty, !token.isEmpty, !sectionId.isEmpty else {
            debugPrint("❌ ERROR: Required parameters missing")
            throw URLError(.badURL)
        }
        
        // Build list of title variants to try
        var titlesToTry: [(description: String, title: String)] = [
            ("Original", title)
        ]
        
        // Apostrophe variant: curly -> straight
        if title.contains("\u{2019}") {
            titlesToTry.append(("Straight apostrophe",
                                title.replacingOccurrences(of: "\u{2019}", with: "\u{0027}")))
        }
        
        // Apostrophe variant: straight -> curly
        if title.contains("\u{0027}") {
            titlesToTry.append(("Curly apostrophe",
                                title.replacingOccurrences(of: "\u{0027}", with: "\u{2019}")))
        }
        
        // Colon variant: if title has " - " it may be a colon in Plex
        if title.contains(" - ") {
            titlesToTry.append(("Colon from dash",
                                title.replacingOccurrences(of: " - ", with: ": ")))
        }
        
        // Slash variant: if title has "-" between words it may be a slash in Plex
        if title.contains("-") {
            titlesToTry.append(("Forward slash from dash",
                                title.replacingOccurrences(of: "-", with: "/")))
            titlesToTry.append(("Back slash from dash",
                                title.replacingOccurrences(of: "-", with: "\\")))
        }
        
        // Try each variant
        for (description, variantTitle) in titlesToTry {
            if variantTitle != title || description == "Original" {
                if description != "Original" {
                    debugPrint("⚠️ Retrying with \(description): \(variantTitle)")
                }
                
                if let result = try await performSearch(
                    server: server,
                    token: token,
                    sectionId: sectionId,
                    title: variantTitle,
                    year: year,
                    tmdbId: tmdbId
                ) {
                    return result
                }
            }
        }
        
        debugPrint("❌ No matching item found after all attempts")
        return nil
    }
    
    // MARK: - Search Helper
    
    private func performSearch(
        server: String,
        token: String,
        sectionId: String,
        title: String,
        year: String?,
        tmdbId: String?
    ) async throws -> String? {
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
        }
        
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            debugPrint("❌ ERROR: Failed to encode title")
            throw URLError(.badURL)
        }
        
        var urlString = "\(serverURL)/library/sections/\(sectionId)/all?title=\(encodedTitle)"
        if let year = year {
            urlString += "&year=\(year)"
        }
        urlString += "&X-Plex-Token=\(token)"
        
        debugPrint("Search URL: \(urlString.replacingOccurrences(of: token, with: "***TOKEN***"))")
        
        guard let url = URL(string: urlString) else {
            debugPrint("❌ ERROR: Failed to create URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse response to find matching item
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let mediaContainer = json["MediaContainer"] as? [String: Any],
           let metadata = mediaContainer["Metadata"] as? [[String: Any]] {
            
            debugPrint("Found \(metadata.count) results")
            
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
                                        debugPrint("✅ Found match by TMDB ID. Rating Key: \(ratingKey)")
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
                debugPrint("✅ Using first result. Rating Key: \(ratingKey)")
                return ratingKey
            }
        }
        
        return nil
    }
    
    // MARK: - Get Seasons
    
    func getSeasons(
        server: String,
        token: String,
        showRatingKey: String
    ) async throws -> [PlexSeason] {
        guard !server.isEmpty, !token.isEmpty, !showRatingKey.isEmpty else {
            throw URLError(.badURL)
        }
        
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
        }
        
        let urlString = "\(serverURL)/library/metadata/\(showRatingKey)/children?X-Plex-Token=\(token)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(PlexChildrenResponse.self, from: data)
        
        return response.mediaContainer.metadata.map { metadata in
            PlexSeason(
                ratingKey: metadata.ratingKey,
                index: metadata.index,
                title: metadata.title
            )
        }
    }
    
    // MARK: - Get Episodes
    
    func getEpisodes(
        server: String,
        token: String,
        seasonRatingKey: String
    ) async throws -> [PlexEpisode] {
        guard !server.isEmpty, !token.isEmpty, !seasonRatingKey.isEmpty else {
            throw URLError(.badURL)
        }
        
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
        }
        
        let urlString = "\(serverURL)/library/metadata/\(seasonRatingKey)/children?X-Plex-Token=\(token)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(PlexChildrenResponse.self, from: data)
        
        return response.mediaContainer.metadata.compactMap { metadata in
            guard let parentIndex = metadata.parentIndex else { return nil }
            return PlexEpisode(
                ratingKey: metadata.ratingKey,
                index: metadata.index,
                parentIndex: parentIndex,
                title: metadata.title
            )
        }
    }
    
    // MARK: - Upload Backdrop/Art
    
    func uploadBackdrop(
        server: String,
        token: String,
        ratingKey: String,
        backdropPath: String
    ) async throws {
        debugPrint("\n*** PlexService.uploadBackdrop ***")
        debugPrint("Input Parameters:")
        debugPrint("  Server: \(server)")
        debugPrint("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        debugPrint("  Rating Key: \(ratingKey)")
        debugPrint("  Backdrop Path: \(backdropPath)")

        guard !server.isEmpty, !token.isEmpty, !ratingKey.isEmpty, !backdropPath.isEmpty else {
            debugPrint("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            debugPrint("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        guard let backdropData = try? Data(contentsOf: URL(fileURLWithPath: backdropPath)) else {
            debugPrint("❌ ERROR: Failed to read backdrop file at \(backdropPath)")
            throw URLError(.fileDoesNotExist)
        }

        let fileName = (backdropPath as NSString).lastPathComponent
        let isPNG = fileName.lowercased().hasSuffix(".png")
        let mimeType = isPNG ? "image/png" : "image/jpeg"
        debugPrint("Backdrop file size: \(backdropData.count) bytes")
        debugPrint("Backdrop MIME type: \(mimeType)")
        
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/arts?X-Plex-Token=\(token)"
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        debugPrint("\n🌐 Backdrop Upload URL:")
        debugPrint("  \(maskedURL)")
        
        guard let url = URL(string: urlString) else {
            debugPrint("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = backdropData
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        
        debugPrint("\nUploading backdrop to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint("Response Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                debugPrint("Response Body: \(responseString.prefix(500))")
            } else {
                debugPrint("Response Body: <empty>")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                debugPrint("❌ ERROR: Backdrop upload failed with status \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            debugPrint("✅ Backdrop upload successful")
        }
        debugPrint("*** End PlexService.uploadBackdrop ***\n")
    }
    
    // MARK: - Upload Logo
    
    func uploadLogo(
        server: String,
        token: String,
        ratingKey: String,
        logoPath: String
    ) async throws {
        try await uploadBinaryArt(
            server: server,
            token: token,
            ratingKey: ratingKey,
            filePath: logoPath,
            element: "clearLogos",
            assetLabel: "Logo"
        )
    }
    
    // MARK: - Upload Square Art
    
    func uploadSquareArt(
        server: String,
        token: String,
        ratingKey: String,
        squareArtPath: String
    ) async throws {
        try await uploadBinaryArt(
            server: server,
            token: token,
            ratingKey: ratingKey,
            filePath: squareArtPath,
            element: "squareArts",
            assetLabel: "Square Art"
        )
    }
    
    // MARK: - Binary Art Upload Helper
    
    private func uploadBinaryArt(
        server: String,
        token: String,
        ratingKey: String,
        filePath: String,
        element: String,
        assetLabel: String
    ) async throws {
        debugPrint("\n*** PlexService.upload\(assetLabel.replacingOccurrences(of: " ", with: "")) ***")
        debugPrint("Input Parameters:")
        debugPrint("  Server: \(server)")
        debugPrint("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        debugPrint("  Rating Key: \(ratingKey)")
        debugPrint("  \(assetLabel) Path: \(filePath)")
        debugPrint("  Plex Element Endpoint: \(element)")

        guard !server.isEmpty, !token.isEmpty, !ratingKey.isEmpty, !filePath.isEmpty else {
            debugPrint("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            debugPrint("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            debugPrint("❌ ERROR: Failed to read file at \(filePath)")
            throw URLError(.fileDoesNotExist)
        }
        
        let urlString = "\(serverURL)/library/metadata/\(ratingKey)/\(element)?X-Plex-Token=\(token)"
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        debugPrint("\n🌐 \(assetLabel) Upload URL:")
        debugPrint("  \(maskedURL)")
        
        guard let url = URL(string: urlString) else {
            debugPrint("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        let fileName = (filePath as NSString).lastPathComponent
        let mimeType = fileName.lowercased().hasSuffix(".png") ? "image/png" : "image/jpeg"
        debugPrint("\(assetLabel) file size: \(fileData.count) bytes")
        debugPrint("\(assetLabel) MIME type: \(mimeType)")
        
        var body = Data()
        body.append(fileData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        
        debugPrint("\nUploading \(assetLabel.lowercased()) to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint("Response Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                debugPrint("Response Body: \(responseString.prefix(500))")
            } else {
                debugPrint("Response Body: <empty>")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                debugPrint("❌ ERROR: \(assetLabel) upload failed with status \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            debugPrint("✅ \(assetLabel) upload successful")
        }
        debugPrint("*** End PlexService.upload\(assetLabel.replacingOccurrences(of: " ", with: "")) ***\n")
    }
    
    // MARK: - Refresh Metadata (kept for backwards compatibility)
    
    func refreshMetadata(
        server: String,
        token: String,
        sectionId: String,
        metadataPath: String
    ) async throws {
        debugPrint("\n*** PlexService.refreshMetadata ***")
        debugPrint("Input Parameters:")
        debugPrint("  Server: \(server)")
        debugPrint("  Token: \(token.isEmpty ? "EMPTY" : "***\(token.suffix(4))") (length: \(token.count))")
        debugPrint("  Section ID: \(sectionId)")
        debugPrint("  Metadata Path: \(metadataPath)")
        
        guard !server.isEmpty, !token.isEmpty, !sectionId.isEmpty, !metadataPath.isEmpty else {
            debugPrint("❌ ERROR: One or more required parameters are empty")
            throw URLError(.badURL)
        }
        
        // Ensure server has protocol prefix
        var serverURL = server
        if !serverURL.hasPrefix("http://") && !serverURL.hasPrefix("https://") {
            serverURL = "http://\(serverURL)"
            debugPrint("Added http:// prefix. Server URL: \(serverURL)")
        }
        
        guard let encodedPath = metadataPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            debugPrint("❌ ERROR: Failed to encode metadata path")
            throw URLError(.badURL)
        }
        
        debugPrint("Encoded Path: \(encodedPath)")
        
        let urlString = """
        \(serverURL)\(Constants.Services.Plex.librarySection)/\(sectionId)/refresh?\
        path=\(encodedPath)&X-Plex-Token=\(token)
        """
        
        debugPrint("\n🌐 Full Plex Refresh URL:")
        // Print URL with token masked for security
        let maskedURL = urlString.replacingOccurrences(of: token, with: "***TOKEN***")
        debugPrint("  \(maskedURL)")
        debugPrint("\n🌐 Actual URL (with real token):")
        debugPrint("  \(urlString)")
        
        guard let url = URL(string: urlString) else {
            debugPrint("❌ ERROR: Failed to create URL from string")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        debugPrint("\nSending request to Plex...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint("Response Status Code: \(httpResponse.statusCode)")
            debugPrint("Response Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                debugPrint("Response Body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                debugPrint("❌ ERROR: Bad status code \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw URLError(.userAuthenticationRequired)
                }
                throw URLError(.badServerResponse)
            }
            
            debugPrint("✅ Plex refresh request successful")
        }
        debugPrint("*** End PlexService.refreshMetadata ***\n")
    }
}
