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
        // Append the folder name to the destination path
        let path = URL(fileURLWithPath: settingsManager.downloadPath).appendingPathComponent(destPath).path
        
        guard await tmdbService.downloadImage(path: sourcePath, to: path, filename: filename, flip: flip)
            else { return false }

        return true
    }
}
