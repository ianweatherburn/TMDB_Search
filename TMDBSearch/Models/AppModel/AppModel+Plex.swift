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
        print("\n=== UPDATE PLEX METADATA ===")
        print("Media Type: \(type)")
        print("UHD: \(uhd)")
        print("Item Title: \(item.formattedTitle)")
        
        // For collections, show library selection menu
        if type == .collection {
            print("Collection detected - showing library selection dialog")
            showCollectionLibrarySelection(for: item, uhd: uhd)
            return
        }
        
        // Validate Plex settings
        print("\n--- Validating Plex Settings ---")
        print("Plex Server: \(settingsManager.plexServer.isEmpty ? "EMPTY" : settingsManager.plexServer)")
        print("Plex Token: \(settingsManager.plexToken.isEmpty ? "EMPTY" : "***configured***")")
        print("Plex Asset Path: \(settingsManager.plexServerAssetPath.isEmpty ? "EMPTY" : settingsManager.plexServerAssetPath)")
        
        guard !settingsManager.plexServer.isEmpty else {
            print("ERROR: Plex server address not configured")
            errorMessage = "Plex server address not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexToken.isEmpty else {
            print("ERROR: Plex token not configured")
            errorMessage = "Plex token not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        guard !settingsManager.plexServerAssetPath.isEmpty else {
            print("ERROR: Plex server asset path not configured")
            errorMessage = "Plex server asset path not configured"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        // Get the appropriate section ID based on type and uhd
        print("\n--- Library Configuration ---")
        print("Shows Library: \(settingsManager.plexShowsLibrary) (ID: \(settingsManager.plexShowsLibraryId))")
        print("Shows 4K Library: \(settingsManager.plexShows4KLibrary) (ID: \(settingsManager.plexShows4KLibraryId))")
        print("Movies Library: \(settingsManager.plexMoviesLibrary) (ID: \(settingsManager.plexMoviesLibraryId))")
        print("Movies 4K Library: \(settingsManager.plexMovies4KLibrary) (ID: \(settingsManager.plexMovies4KLibraryId))")
        
        let sectionId = getSectionId(for: type, uhd: uhd)
        print("Selected Section ID: \(sectionId.isEmpty ? "EMPTY" : sectionId)")
        
        guard !sectionId.isEmpty else {
            let typeDescription = getLibraryTypeDescription(for: type, uhd: uhd)
            print("ERROR: Plex library not configured for \(typeDescription)")
            errorMessage = "Plex library not configured for \(typeDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
            return
        }
        
        // Construct metadata path
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.plexTitle.replacingColonsWithDashes
        let metadataPath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)/\(folderName)"
        
        print("\n--- Path Construction ---")
        print("Library Path: \(libraryPath)")
        print("Folder Name: \(folderName)")
        print("Full Metadata Path: \(metadataPath)")
        
        print("\n--- Searching for Plex Item ---")
        
        do {
            // First, search for the item in Plex to get its rating key
            let title = item.displayTitle
            let year = item.displayYear
            let tmdbId = String(item.id)
            
            let yearDisplay = year ?? "no year"
            print("Searching Plex for: \(title) (\(yearDisplay)) [tmdb-\(tmdbId)]")
            
            guard let ratingKey = try await plexService.searchMedia(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                sectionId: sectionId,
                title: title,
                year: year,
                tmdbId: tmdbId
            ) else {
                print("❌ ERROR: Could not find item in Plex library")
                errorMessage = "'\(item.formattedTitle)' not found in Plex library"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            print("Found Plex item with rating key: \(ratingKey)")
            
            // Now find and upload the poster
            print("\n--- Finding Poster File ---")
            let posterPath = "\(metadataPath)/poster"
            let posterExtensions = ["jpg", "jpeg", "png"]
            var foundPosterPath: String?
            
            for ext in posterExtensions {
                let testPath = "\(posterPath).\(ext)"
                print("Checking: \(testPath)")
                if FileManager.default.fileExists(atPath: testPath) {
                    foundPosterPath = testPath
                    print("✅ Found poster: \(testPath)")
                    break
                }
            }
            
            guard let posterFilePath = foundPosterPath else {
                print("❌ ERROR: No poster file found at \(posterPath)")
                errorMessage = "No poster file found for '\(item.formattedTitle)'"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            print("\n--- Uploading Poster to Plex ---")
            try await plexService.uploadPoster(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                ratingKey: ratingKey,
                posterPath: posterFilePath
            )
            
            print("✅ SUCCESS: Plex poster uploaded successfully")
            statusMessage = "Plex poster updated for '\(item.formattedTitle)'"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.success))?.play()
        } catch let error as URLError {
            print("❌ URLError occurred: \(error)")
            print("Error code: \(error.code.rawValue)")
            if error.code == .userAuthenticationRequired {
                errorMessage = "Plex token is invalid or expired"
            } else if error.code == .badURL {
                errorMessage = "Invalid Plex server URL or metadata path"
            } else if error.code == .fileDoesNotExist {
                errorMessage = "Poster file not found"
            } else {
                errorMessage = "Failed to connect to Plex server: \(error.localizedDescription)"
            }
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        } catch {
            print("❌ Generic error: \(error)")
            errorMessage = "Plex update failed: \(error.localizedDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
        print("=== END UPDATE PLEX METADATA ===\n")
    }
    
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
        
        // Construct metadata path - collections use movies path
        let libraryPath = getLibraryPath(for: type)
        let folderName = item.plexTitle.replacingColonsWithDashes
        let metadataPath = "\(settingsManager.plexServerAssetPath)/\(libraryPath)/\(folderName)"
        
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
            
            // Find poster file
            let posterPath = "\(metadataPath)/poster"
            let posterExtensions = ["jpg", "jpeg", "png"]
            var foundPosterPath: String?
            
            for ext in posterExtensions {
                let testPath = "\(posterPath).\(ext)"
                if FileManager.default.fileExists(atPath: testPath) {
                    foundPosterPath = testPath
                    break
                }
            }
            
            guard let posterFilePath = foundPosterPath else {
                errorMessage = "No poster file found for collection '\(item.formattedTitle)'"
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
                return
            }
            
            // Upload poster
            try await plexService.uploadPoster(
                server: settingsManager.plexServer,
                token: settingsManager.plexToken,
                ratingKey: ratingKey,
                posterPath: posterFilePath
            )
            
            statusMessage = "Plex collection poster updated for '\(item.formattedTitle)'"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.success))?.play()
        } catch let error as URLError {
            if error.code == .userAuthenticationRequired {
                errorMessage = "Plex token is invalid or expired"
            } else if error.code == .badURL {
                errorMessage = "Invalid Plex server URL or metadata path"
            } else if error.code == .fileDoesNotExist {
                errorMessage = "Poster file not found"
            } else {
                errorMessage = "Failed to connect to Plex server: \(error.localizedDescription)"
            }
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        } catch {
            errorMessage = "Plex update failed: \(error.localizedDescription)"
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
        }
    }
    
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
