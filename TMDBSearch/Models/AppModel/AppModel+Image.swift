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
        }

        guard let path else { return nil }
        guard let data = await tmdbService.loadImage(path: path, size: .w342) else { return nil }
        return NSImage(data: data)
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
