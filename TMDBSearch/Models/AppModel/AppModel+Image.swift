//
//  AppModel+Image.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import AppKit // Required for NSImage

// MARK: - Image Loading and Downloading
extension AppModel {
    @MainActor
    func loadImage(for item: TMDBMediaItem, as type: ImageType) async -> NSImage? {
        let path: String?

        switch type {
        case .poster:
            path = item.posterPath
        case .backdrop:
            path = item.backdropPath
        case .logo:
            return nil // Logos require fetching from the images endpoint; use loadLogoImage instead
        }

        guard let path else { return nil }
        guard let data = await tmdbService.loadImage(path: path, size: .w342) else { return nil }
        return NSImage(data: data)
    }
    
    /// Loads the first available logo for a media item from the images endpoint.
    /// Logos are not included in search results, so we must fetch them separately.
    @MainActor
    func loadLogoImage(for item: TMDBMediaItem, mediaType: MediaType) async -> (image: NSImage?, hasLogos: Bool) {
        guard let response = await loadImages(for: item.id, mediaType: mediaType) else {
            return (nil, false)
        }
        
        guard let firstLogo = response.logos.first else {
            return (nil, false)
        }
        
        guard let data = await tmdbService.loadImage(path: firstLogo.filePath, size: .w342) else {
            return (nil, true)
        }
        
        return (NSImage(data: data), true)
    }

    func loadImages(for itemId: Int, mediaType: MediaType) async -> TMDBImagesResponse? {
        do {
            return try await tmdbService.getImages(
                itemId: itemId,
                mediaType: mediaType,
                languages: selectedLanguages,
                apiKey: settingsManager.apiKey)
        } catch {
            print("Failed to load images: \(error)")
            return nil
        }
    }

    func downloadImage(sourcePath: String, destPath: String, filename: String, flip: Bool = false) async -> Bool {
        // Download the image data from TMDB (with optional flip)
        guard let imageData = await tmdbService.downloadImageData(path: sourcePath, flip: flip) else {
            print("❌ Failed to download image from TMDB")
            return false
        }
        
        // Save using UnifiedFileManager with security-scoped access
        return await fileManager.saveImageData(imageData, filename: filename, subdirectory: destPath)
    }
}
