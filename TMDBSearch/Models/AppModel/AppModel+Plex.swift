//
//  AppModel+Plex.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import AppKit

// MARK: - Plex Functionality
extension AppModel {
    
    @MainActor
    func updatePlexMetadata(for item: TMDBMediaItem, type: MediaType, uhd: Bool) async {
        // For collections, show library selection menu
        if type == .collection {
            showCollectionLibrarySelection(for: item, uhd: uhd)
            return
        }
        
        // Validate Plex settings
        guard !settingsManager.plexServer.isEmpty else {
            errorMessage = "Plex server address not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexToken.isEmpty else {
            errorMessage = "Plex token not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexServerAssetPath.isEmpty else {
            errorMessage = "Plex server asset path not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        let sectionId = getSectionId(for: type, uhd: uhd)
        
        guard !sectionId.isEmpty else {
            let typeDescription = getLibraryTypeDescription(for: type, uhd: uhd)
            errorMessage = "Plex library not configured for \(typeDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        // Start upload process
        await performAssetUpload(for: item, type: type, uhd: uhd, sectionId: sectionId)
    }
    
    // MARK: - Asset Upload Orchestration
    
    @MainActor
    private func performAssetUpload(
        for item: TMDBMediaItem,
        type: MediaType,
        uhd: Bool,
        sectionId: String
    ) async {
        // Reset cancellation flag
        plexUploadCancelled = false
        
        // Construct metadata path - try both apostrophe variants
        print("\n--- Asset Folder Path Resolution ---")
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.plexTitle.replacingColonsWithDashes
        
        print("Original folder name: \(folderName)")
        print("  Unicode: \(folderName.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
        
        // Try multiple apostrophe variants
        let fileManager = FileManager.default
        let basePath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)"
        
        // List what's actually in the directory
        print("\nListing folders in: \(basePath)")
        if let contents = try? fileManager.contentsOfDirectory(atPath: basePath) {
            let matchingFolders = contents.filter { $0.contains("Agatha") || $0.contains("Christie") }
            print("Found \(matchingFolders.count) matching folders:")
            for folder in matchingFolders.prefix(5) {
                print("  - \(folder)")
                print("    Unicode: \(folder.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
            }
        } else {
            print("  Could not list directory contents")
        }
        
        // Generate all possible variants
        var pathsToTry: [(description: String, path: String)] = [
            ("Original", "\(basePath)/\(folderName)"),
            ("Curly apostrophe", "\(basePath)/\(folderName.withCurlyApostrophes)"),
            ("Normalized apostrophe", "\(basePath)/\(folderName.normalizingApostrophes)")
        ]
        
        var metadataPath = pathsToTry[0].path
        var found = false
        
        for (description, path) in pathsToTry {
            let pathComponents = path.split(separator: "/")
            let folderComponent = pathComponents.last ?? ""
            print("\nTrying \(description):")
            print("  Folder: \(folderComponent)")
            print("  Unicode: \(folderComponent.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
            print("  Full path: \(path)")
            let exists = fileManager.fileExists(atPath: path)
            print("  Exists: \(exists)")
            
            if exists {
                print("✅ Found using \(description)")
                metadataPath = path
                found = true
                break
            }
        }
        
        if !found {
            print("❌ No valid path found after trying all variants")
        }
        
        print("\nFinal metadata path: \(metadataPath)")
        print("--- End Asset Folder Path Resolution ---\n")
        
        do {
            // Search for item in Plex
            let title = item.displayTitle
            let year = item.displayYear
            let tmdbId = String(item.id)
            
            guard let mainRatingKey = try await plexService.searchMedia(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                sectionId: sectionId,
                title: title,
                year: year,
                tmdbId: tmdbId
            ) else {
                errorMessage = "'\(item.formattedTitle)' not found in Plex library"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Scan for all assets
            let scanner = AssetScanner(metadataPath: metadataPath)
            let assets = scanner.scanAssets()
            
            guard !assets.isEmpty else {
                errorMessage = "No assets found at \(metadataPath)"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Build task list
            var tasks: [AssetUploadTask] = []
            
            // Main poster
            if let posterPath = scanner.findPoster(in: assets) {
                tasks.append(AssetUploadTask(
                    type: type == .movie ? .moviePoster : .showPoster,
                    filePath: posterPath,
                    ratingKey: mainRatingKey,
                    displayName: "\(type == .movie ? "Movie" : "Show") Poster"
                ))
            }
            
            // Main backdrop
            if let backdropPath = scanner.findBackdrop(in: assets) {
                tasks.append(AssetUploadTask(
                    type: type == .movie ? .movieBackdrop : .showBackdrop,
                    filePath: backdropPath,
                    ratingKey: mainRatingKey,
                    displayName: "\(type == .movie ? "Movie" : "Show") Backdrop"
                ))
            }
            
            // For TV shows, add seasons and episodes
            if type == .tv {
                // Get seasons from Plex
                let seasons = try await plexService.getSeasons(
                    server: settingsManager.plexServer,
                    token: settingsManager.plexToken,
                    showRatingKey: mainRatingKey
                )
                
                // Season posters
                let seasonPosters = scanner.findSeasonPosters(in: assets)
                for (seasonNum, filePath) in seasonPosters {
                    if let season = seasons.first(where: { $0.index == seasonNum }) {
                        tasks.append(AssetUploadTask(
                            type: .seasonPoster,
                            filePath: filePath,
                            ratingKey: season.ratingKey,
                            displayName: "Season \(String(format: "%02d", seasonNum)) Poster"
                        ))
                    }
                }
                
                // Episode title cards
                let episodeCards = scanner.findEpisodeTitleCards(in: assets)
                
                // Group episodes by season to minimize API calls
                var episodesBySeason: [Int: [PlexEpisode]] = [:]
                for season in seasons {
                    if episodeCards.contains(where: { $0.season == season.index }) {
                        let episodes = try await plexService.getEpisodes(
                            server: settingsManager.plexServer,
                            token: settingsManager.plexToken,
                            seasonRatingKey: season.ratingKey
                        )
                        episodesBySeason[season.index] = episodes
                    }
                }
                
                // Create tasks for episode title cards
                for (seasonNum, episodeNum, filePath) in episodeCards {
                    if let episodes = episodesBySeason[seasonNum],
                       let episode = episodes.first(where: { $0.index == episodeNum }) {
                        tasks.append(AssetUploadTask(
                            type: .episodeTitleCard,
                            filePath: filePath,
                            ratingKey: episode.ratingKey,
                            displayName: "S\(String(format: "%02d", seasonNum))E\(String(format: "%02d", episodeNum))"
                        ))
                    }
                }
            }
            
            guard !tasks.isEmpty else {
                errorMessage = "No uploadable assets found"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Show progress window and start uploads
            plexUploadTasks = tasks
            plexCurrentTaskIndex = 0
            showPlexUploadProgress = true
            
            // Perform uploads
            await performUploads()
            
        } catch {
            errorMessage = "Plex update failed: \(error.localizedDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
    }
    
    // MARK: - Upload Execution
    
    @MainActor
    private func performUploads() async {
        for index in 0..<plexUploadTasks.count {
            if plexUploadCancelled {
                break
            }
            
            plexCurrentTaskIndex = index
            plexUploadTasks[index].status = .uploading
            
            let task = plexUploadTasks[index]
            
            do {
                switch task.type {
                case .showPoster, .moviePoster, .seasonPoster, .episodeTitleCard:
                    try await plexService.uploadPoster(
                        server: settingsManager.plexServer,
                        token: settingsManager.plexToken,
                        ratingKey: task.ratingKey,
                        posterPath: task.filePath
                    )
                    
                case .showBackdrop, .movieBackdrop:
                    try await plexService.uploadBackdrop(
                        server: settingsManager.plexServer,
                        token: settingsManager.plexToken,
                        ratingKey: task.ratingKey,
                        backdropPath: task.filePath
                    )
                }
                
                plexUploadTasks[index].status = .completed
                
            } catch {
                plexUploadTasks[index].status = .failed
                plexUploadTasks[index].error = error.localizedDescription
            }
        }
        
        // Show summary
        let completedCount = plexUploadTasks.filter { $0.status == .completed }.count
        let failedCount = plexUploadTasks.filter { $0.status == .failed }.count
        
        if failedCount == 0 {
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.success))?.play()
        } else if completedCount > 0 {
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
    }
    
    @MainActor
    func cancelPlexUpload() {
        plexUploadCancelled = true
    }
    
    // MARK: - Collection Handling
    
    @MainActor
    private func showCollectionLibrarySelection(for item: TMDBMediaItem, uhd: Bool) {
        let alert = NSAlert()
        alert.messageText = "Select Collection Library"
        alert.informativeText = "Which library contains this collection?"
        alert.alertStyle = .informational
        
        if uhd {
            alert.addButton(withTitle: "Movies 4K")
            alert.addButton(withTitle: "Shows 4K")
        } else {
            alert.addButton(withTitle: "Movies")
            alert.addButton(withTitle: "Shows")
        }
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            // Movies or Movies 4K
            Task {
                await performCollectionUpdate(for: item, type: .movie, uhd: uhd)
            }
        case .alertSecondButtonReturn:
            // Shows or Shows 4K
            Task {
                await performCollectionUpdate(for: item, type: .tv, uhd: uhd)
            }
        default:
            // Cancel
            break
        }
    }
    
    @MainActor
    private func performCollectionUpdate(for item: TMDBMediaItem, type: MediaType, uhd: Bool) async {
        // Validate Plex settings
        guard !settingsManager.plexServer.isEmpty else {
            errorMessage = "Plex server address not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexToken.isEmpty else {
            errorMessage = "Plex token not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexServerAssetPath.isEmpty else {
            errorMessage = "Plex server asset path not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        let sectionId = getSectionId(for: type, uhd: uhd)
        
        guard !sectionId.isEmpty else {
            let typeDescription = getLibraryTypeDescription(for: type, uhd: uhd)
            errorMessage = "Plex library not configured for \(typeDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        // Construct metadata path - collections use movies path, try both apostrophe variants
        print("\n--- Collection Asset Folder Path Resolution ---")
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.plexTitle.replacingColonsWithDashes
        
        print("Original folder name: \(folderName)")
        print("  Unicode: \(folderName.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
        
        // Try multiple apostrophe variants
        let fileManager = FileManager.default
        let basePath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)"
        
        // Generate all possible variants
        var pathsToTry: [(description: String, path: String)] = [
            ("Original", "\(basePath)/\(folderName)"),
            ("Curly apostrophe", "\(basePath)/\(folderName.withCurlyApostrophes)"),
            ("Normalized apostrophe", "\(basePath)/\(folderName.normalizingApostrophes)")
        ]
        
        var metadataPath = pathsToTry[0].path
        var found = false
        
        for (description, path) in pathsToTry {
            print("Trying \(description): \(path)")
            if fileManager.fileExists(atPath: path) {
                print("✅ Found using \(description)")
                metadataPath = path
                found = true
                break
            }
        }
        
        if !found {
            print("❌ No valid path found after trying all variants")
        }
        
        print("Final metadata path: \(metadataPath)")
        print("--- End Collection Asset Folder Path Resolution ---\n")
        
        do {
            // Search for the collection in Plex
            let title = item.displayTitle
            let year = item.displayYear
            let tmdbId = String(item.id)
            
            guard let ratingKey = try await plexService.searchMedia(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                sectionId: sectionId,
                title: title,
                year: year,
                tmdbId: tmdbId
            ) else {
                errorMessage = "Collection '\(item.formattedTitle)' not found in Plex library"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Scan for assets
            let scanner = AssetScanner(metadataPath: metadataPath)
            let assets = scanner.scanAssets()
            
            var tasks: [AssetUploadTask] = []
            
            // Poster
            if let posterPath = scanner.findPoster(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .moviePoster,
                    filePath: posterPath,
                    ratingKey: ratingKey,
                    displayName: "Collection Poster"
                ))
            }
            
            // Backdrop
            if let backdropPath = scanner.findBackdrop(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .movieBackdrop,
                    filePath: backdropPath,
                    ratingKey: ratingKey,
                    displayName: "Collection Backdrop"
                ))
            }
            
            guard !tasks.isEmpty else {
                errorMessage = "No assets found for collection '\(item.formattedTitle)'"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Show progress and upload
            plexUploadTasks = tasks
            plexCurrentTaskIndex = 0
            showPlexUploadProgress = true
            
            await performUploads()
            
        } catch {
            errorMessage = "Plex update failed: \(error.localizedDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSectionId(for type: MediaType, uhd: Bool) -> String {
        switch (type, uhd) {
        case (.tv, false):
            return settingsManager.plexShowsLibraryId
        case (.tv, true):
            return settingsManager.plexShows4KLibraryId
        case (.movie, false), (.collection, false):
            return settingsManager.plexMoviesLibraryId
        case (.movie, true), (.collection, true):
            return settingsManager.plexMovies4KLibraryId
        }
    }
    
    private func getLibraryPath(for type: MediaType) -> String {
        switch type {
        case .tv:
            return Constants.Media.Types.shows
        case .movie, .collection:
            return Constants.Media.Types.movies
        }
    }
    
    private func getLibraryTypeDescription(for type: MediaType, uhd: Bool) -> String {
        switch (type, uhd) {
        case (.tv, false):
            return "Shows"
        case (.tv, true):
            return "Shows 4K"
        case (.movie, false), (.collection, false):
            return "Movies"
        case (.movie, true), (.collection, true):
            return "Movies 4K"
        }
    }
}
