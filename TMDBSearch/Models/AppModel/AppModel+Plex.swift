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
    
    // MARK: - Asset Scan and Selection
    
    @MainActor
    private func performAssetUpload(
        for item: TMDBMediaItem,
        type: MediaType,
        uhd: Bool,
        sectionId: String
    ) async {
        // Construct metadata path - try apostrophe variants
        DebugLogger.log("\n--- Asset Folder Path Resolution ---")
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.plexTitle.toFileSystemSafe
        
        DebugLogger.log("Original folder name: \(folderName)")
        DebugLogger.log("  Unicode: \(folderName.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
        
        // Try multiple apostrophe variants
        let fileManager = FileManager.default
        let basePath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)"
        
        // List what's actually in the directory
        DebugLogger.log("\nListing folders in: \(basePath)")
        if let contents = try? fileManager.contentsOfDirectory(atPath: basePath) {
            let matchingFolders = contents.filter { $0.contains("Agatha") || $0.contains("Christie") }
            DebugLogger.log("Found \(matchingFolders.count) matching folders:")
            for folder in matchingFolders.prefix(5) {
                DebugLogger.log("  - \(folder)")
                DebugLogger.log("    Unicode: \(folder.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
            }
        } else {
            DebugLogger.log("  Could not list directory contents")
        }
        
        // Generate all possible variants
        let pathsToTry: [(description: String, path: String)] = [
            ("Original", "\(basePath)/\(folderName)"),
            ("Curly apostrophe", "\(basePath)/\(folderName.withCurlyApostrophes)"),
            ("Normalized apostrophe", "\(basePath)/\(folderName.normalizingApostrophes)")
        ]
        
        var metadataPath = pathsToTry[0].path
        var found = false
        
        for (description, path) in pathsToTry {
            let pathComponents = path.split(separator: "/")
            let folderComponent = pathComponents.last ?? ""
            DebugLogger.log("\nTrying \(description):")
            DebugLogger.log("  Folder: \(folderComponent)")
            DebugLogger.log("  Unicode: \(folderComponent.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
            DebugLogger.log("  Full path: \(path)")
            let exists = fileManager.fileExists(atPath: path)
            DebugLogger.log("  Exists: \(exists)")
            
            if exists {
                DebugLogger.log("✅ Found using \(description)")
                metadataPath = path
                found = true
                break
            }
        }
        
        if !found {
            DebugLogger.log("❌ No valid path found after trying all variants")
        }
        
        DebugLogger.log("\nFinal metadata path: \(metadataPath)")
        DebugLogger.log("--- End Asset Folder Path Resolution ---\n")
        
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
                tmdbId: tmdbId,
                searchType: type
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
            
            // Logo
            if let logoPath = scanner.findLogo(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .logo,
                    filePath: logoPath,
                    ratingKey: mainRatingKey,
                    displayName: "\(type == .movie ? "Movie" : "Show") Logo"
                ))
            }
            
            // Square Art
            if let squareArtPath = scanner.findSquareArt(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .squareArt,
                    filePath: squareArtPath,
                    ratingKey: mainRatingKey,
                    displayName: "\(type == .movie ? "Movie" : "Show") Square Art"
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
            
            // Show asset selection dialog
            showAssetSelectionDialog(tasks: tasks, item: item, type: type, sectionId: sectionId, ratingKey: mainRatingKey)
            
        } catch {
            errorMessage = "Plex update failed: \(error.localizedDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
    }
    
    // MARK: - Asset Selection Dialog
    
    @MainActor
    private func showAssetSelectionDialog(
        tasks: [AssetUploadTask],
        item: TMDBMediaItem,
        type: MediaType,
        sectionId: String,
        ratingKey: String
    ) {
        plexPendingTasks = tasks
        plexAssetSelections = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, true) })
        plexSelectionItem = item
        plexSelectionType = type
        plexSelectionSectionId = sectionId
        plexSelectionRatingKey = ratingKey
        showPlexAssetSelection = true
    }
    
    @MainActor
    func confirmPlexAssetSelection() async {
        showPlexAssetSelection = false
        
        // Filter to only selected tasks
        let selectedTasks = plexPendingTasks.filter { plexAssetSelections[$0.id] == true }
        
        guard !selectedTasks.isEmpty else {
            return
        }
        
        // Check if any selected task is a poster type (png or jpg) and remove overlay label if needed
        let hasPosterUpload = selectedTasks.contains { task in
            let isPosterType: Bool
            switch task.type {
            case .showPoster, .moviePoster, .seasonPoster:
                isPosterType = true
            default:
                isPosterType = false
            }
            guard isPosterType else { return false }
            let ext = (task.filePath as NSString).pathExtension.lowercased()
            return ext == "png" || ext == "jpg" || ext == "jpeg"
        }
        
        if hasPosterUpload {
            do {
                _ = try await plexService.removeOverlayLabelIfPresent(
                    server: settingsManager.plexServer,
                    token: settingsManager.plexToken,
                    sectionId: plexSelectionSectionId,
                    ratingKey: plexSelectionRatingKey
                )
            } catch {
                DebugLogger.log("⚠️ Failed to remove Overlay label for \(plexSelectionRatingKey): \(error.localizedDescription)")
            }
        }
        
        // Show progress window and start uploads
        plexUploadTasks = selectedTasks
        plexCurrentTaskIndex = 0
        plexUploadCancelled = false
        showPlexUploadProgress = true
        
        await startPlexUploads()
    }
    
    @MainActor
    func cancelPlexAssetSelection() {
        showPlexAssetSelection = false
        plexPendingTasks = []
        plexAssetSelections = [:]
        plexSelectionItem = nil
    }
    
    // MARK: - Upload Execution
    
    @MainActor
    private func performUploads() async {
        for index in 0..<plexUploadTasks.count {
            if plexUploadCancelled || Task.isCancelled {
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
                    
                case .logo:
                    try await plexService.uploadLogo(
                        server: settingsManager.plexServer,
                        token: settingsManager.plexToken,
                        ratingKey: task.ratingKey,
                        logoPath: task.filePath
                    )
                    
                case .squareArt:
                    try await plexService.uploadSquareArt(
                        server: settingsManager.plexServer,
                        token: settingsManager.plexToken,
                        ratingKey: task.ratingKey,
                        squareArtPath: task.filePath
                    )
                }
                
                plexUploadTasks[index].status = .completed
                
            } catch is CancellationError {
                plexUploadTasks[index].status = .failed
                plexUploadTasks[index].error = "Cancelled"
                break
            } catch {
                plexUploadTasks[index].status = .failed
                plexUploadTasks[index].error = error.localizedDescription
            }
        }

        if plexUploadCancelled || Task.isCancelled {
            return
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
        plexUploadTask?.cancel()
        showPlexUploadProgress = false
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
        DebugLogger.log("\n--- Collection Asset Folder Path Resolution ---")
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.displayTitle.toFileSystemSafe
        
        DebugLogger.log("Original folder name: \(folderName)")
        DebugLogger.log("  Unicode: \(folderName.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " "))")
        
        // Try multiple apostrophe variants
        let fileManager = FileManager.default
        let basePath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)"
        
        // Generate all possible variants
        let pathsToTry: [(description: String, path: String)] = [
            ("Original", "\(basePath)/\(folderName)"),
            ("Curly apostrophe", "\(basePath)/\(folderName.withCurlyApostrophes)"),
            ("Normalized apostrophe", "\(basePath)/\(folderName.normalizingApostrophes)")
        ]
        
        var metadataPath = pathsToTry[0].path
        var found = false
        
        for (description, path) in pathsToTry {
            DebugLogger.log("Trying \(description): \(path)")
            if fileManager.fileExists(atPath: path) {
                DebugLogger.log("✅ Found using \(description)")
                metadataPath = path
                found = true
                break
            }
        }
        
        if !found {
            DebugLogger.log("❌ No valid path found after trying all variants")
        }
        
        DebugLogger.log("Final metadata path: \(metadataPath)")
        DebugLogger.log("--- End Collection Asset Folder Path Resolution ---\n")
        
        do {
            // Search for the collection in Plex
            let title = item.displayTitle
            let year = item.displayYear.isEmpty ? nil : item.displayYear
            let tmdbId = String(item.id)
            
            guard let ratingKey = try await plexService.searchMedia(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                sectionId: sectionId,
                title: title,
                year: year,
                tmdbId: tmdbId,
                searchType: .collection
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
            
            // Logo
            if let logoPath = scanner.findLogo(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .logo,
                    filePath: logoPath,
                    ratingKey: ratingKey,
                    displayName: "Collection Logo"
                ))
            }
            
            // Square Art
            if let squareArtPath = scanner.findSquareArt(in: assets) {
                tasks.append(AssetUploadTask(
                    type: .squareArt,
                    filePath: squareArtPath,
                    ratingKey: ratingKey,
                    displayName: "Collection Square Art"
                ))
            }
            
            guard !tasks.isEmpty else {
                errorMessage = "No assets found for collection '\(item.formattedTitle)'"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Show asset selection dialog
            showAssetSelectionDialog(tasks: tasks, item: item, type: .collection, sectionId: sectionId, ratingKey: ratingKey)
            
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

    @MainActor
    private func startPlexUploads() async {
        plexUploadTask?.cancel()
        plexUploadCancelled = false

        let taskID = UUID()
        plexUploadTaskID = taskID

        let uploadTask = Task { [weak self] in
            guard let self else { return }
            await self.performUploads()
        }

        plexUploadTask = uploadTask
        await uploadTask.value

        if plexUploadTaskID == taskID {
            plexUploadTask = nil
            plexUploadTaskID = nil
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
