//
//  TMDBServices.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// MARK: - TMDB Service
final class TMDBServices {
    private let baseURL = Constants.Services.TMDB.baseURL
    private let imageBaseURL = Constants.Services.TMDB.imageURL

    enum ImageSize: String {
        case w92, w154, w185, w342, w500, w780, original
    }

    // MARK: - Caches
    let searchCache: LRUCache<SearchCacheKey, [TMDBMediaItem]>
    let imageMetadataCache: LRUCache<ImageMetadataCacheKey, TMDBImagesResponse>
    let thumbnailCache: LRUCache<ThumbnailCacheKey, Data>

    init(cacheCapacity: Int = Constants.Configure.Preferences.Cache.size,
         thumbnailMultiplier: Int = Constants.Configure.Preferences.Cache.multiplier) {
        searchCache = LRUCache(capacity: cacheCapacity)
        imageMetadataCache = LRUCache(capacity: cacheCapacity)
        thumbnailCache = LRUCache(capacity: cacheCapacity * thumbnailMultiplier)
    }

    func updateCacheCapacity(_ capacity: Int, thumbnailMultiplier: Int) async {
        await searchCache.resize(to: capacity)
        await imageMetadataCache.resize(to: capacity)
        await thumbnailCache.resize(to: capacity * thumbnailMultiplier)
    }

    func searchMedia(query: String, mediaType: MediaType, apiKey: String,
                     forceRefresh: Bool = false) async throws -> [TMDBMediaItem] {
        let cacheKey = SearchCacheKey(query: query.lowercased(), mediaType: mediaType)

        if !forceRefresh, let cached = await searchCache.get(cacheKey) {
            return cached
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/search/\(mediaType.rawValue)?api_key=\(apiKey)&query=\(encodedQuery)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)

        await searchCache.set(cacheKey, value: response.results)
        return response.results
    }

    func getImages(itemId: Int,
                   mediaType: MediaType,
                   languages: [String],
                   apiKey: String) async throws -> TMDBImagesResponse {
        let cacheKey = ImageMetadataCacheKey(itemId: itemId, mediaType: mediaType, languages: languages)

        if let cached = await imageMetadataCache.get(cacheKey) {
            return cached
        }

        let includeLanguages = (languages.isEmpty ? "" : languages.joined(separator: ",") + ",") + "null"
        let urlString = "\(baseURL)/" +
                        "\(mediaType.rawValue)/" +
                        "\(itemId)/" +
                        "images?api_key=\(apiKey)" +
                        "&include_image_language=\(includeLanguages)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        var response = try JSONDecoder().decode(TMDBImagesResponse.self, from: data)
        
        // Sort by area (width x height) in descending order
        response = TMDBImagesResponse(
            id: response.id,
            posters: response.posters.sorted { ($0.width * $0.height) > ($1.width * $1.height) },
            backdrops: response.backdrops.sorted { ($0.width * $0.height) > ($1.width * $1.height) },
            logos: response.logos.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
        )

        await imageMetadataCache.set(cacheKey, value: response)
        return response
    }
    
    func loadImage(path: String, size: ImageSize = .w342) async -> Data? {
        let cacheKey = ThumbnailCacheKey(path: path, size: size.rawValue)

        if size == .w342, let cached = await thumbnailCache.get(cacheKey) {
            return cached
        }

        let urlString = "\(imageBaseURL)/\(size.rawValue)\(path)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if size == .w342 {
                await thumbnailCache.set(cacheKey, value: data)
            }
            return data
        } catch {
            DebugLogger.log("Failed to load image: \(error)")
            return nil
        }
    }
    
    /// Downloads image data from TMDB and optionally flips it
    /// - Parameters:
    ///   - path: The TMDB image path
    ///   - flip: Whether to flip the image horizontally
    /// - Returns: The processed image data, or nil if download fails
    func downloadImageData(path: String, flip: Bool = false) async -> Data? {
        let urlString = "\(imageBaseURL)/original\(path)"
        
        guard let url = URL(string: urlString) else { 
            DebugLogger.log("Invalid image URL: \(urlString)")
            return nil 
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Convert SVG/WebP to PNG (preserves transparency, no-op for JPEG/PNG)
            let convertedData = convertToPNG(data)
            
            // Process the image data and only flip horizontally if requested
            if flip {
                guard let flippedData = flipImageHorizontally(convertedData) else {
                    DebugLogger.log("Failed to flip image horizontally")
                    return nil
                }
                return flippedData
            } else {
                return convertedData
            }
        } catch {
            DebugLogger.log("Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Legacy method for backward compatibility - will be deprecated
    @available(*, deprecated, message: "Use downloadImageData with UnifiedFileManager instead")
    func downloadImage(path: String, to directory: String, filename: String, flip: Bool = false) async -> Bool {
        let urlString = "\(imageBaseURL)/original\(path)"
        
        guard let url = URL(string: urlString) else { return false }

        do {
            let directoryURL = URL(fileURLWithPath: directory)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Process the image data and only flip horizontally if requested
            let finalData: Data
            if flip {
                guard let flippedData = flipImageHorizontally(data) else {
                    DebugLogger.log("Failed to flip image horizontally")
                    return false
                }
                finalData = flippedData
            } else {
                finalData = data
            }
            
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
            
            try finalData.write(to: fileURL)
            return true
        } catch {
            DebugLogger.log("Failed to download image: \(error)")
            return false
        }
    }
   
    private func flipImageHorizontally(_ imageData: Data) -> Data? {
            guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            
            // Get original image format
            guard let imageTypeIdentifier = CGImageSourceGetType(source) else {
                return nil
            }
            
            // Convert to UTType for modern API
            guard let imageUTType = UTType(imageTypeIdentifier as String) else {
                return nil
            }
            
            let width = cgImage.width
            let height = cgImage.height
            
            // Create a bitmap context
            guard let colorSpace = cgImage.colorSpace,
                  let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: cgImage.bitsPerComponent,
                    bytesPerRow: 0,
                    space: colorSpace,
                    bitmapInfo: cgImage.bitmapInfo.rawValue
                  ) else {
                return nil
            }
            
            // Apply horizontal flip transformation
            context.translateBy(x: CGFloat(width), y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
            
            // Draw the image
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            // Get the flipped image
            guard let flippedCGImage = context.makeImage() else {
                return nil
            }
            
            // Convert back to data using original format
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(mutableData, imageTypeIdentifier, 1, nil) else {
                return nil
            }
            
            // Use lossless settings based on format
            let options: [CFString: Any]
            if imageUTType.conforms(to: UTType.jpeg) {
                // Maximum quality for JPEG (still lossy but minimal loss)
                options = [kCGImageDestinationLossyCompressionQuality: Constants.Services.Flip.quality]
            } else {
                // For PNG and other lossless formats, no compression options needed
                options = [:]
            }
            
            CGImageDestinationAddImage(destination, flippedCGImage, options.isEmpty ? nil : options as CFDictionary)
            
            guard CGImageDestinationFinalize(destination) else {
                return nil
            }
            
            return mutableData as Data
        }
    
    // MARK: - Image Format Conversion
    
    /// Converts image data from SVG or WebP to PNG, preserving transparency.
    /// Returns the original data unchanged for JPEG/PNG formats.
    private func convertToPNG(_ data: Data) -> Data {
        // Check for SVG: look for XML/SVG markers in the first bytes
        let headerSize = min(data.count, 1024)
        if let header = String(data: data.prefix(headerSize), encoding: .utf8),
           header.contains("<svg") || header.contains("<?xml") {
            return convertSVGToPNG(data) ?? data
        }
        
        // Check for WebP: starts with "RIFF" followed by "WEBP"
        if data.count >= 12,
           let riff = String(data: data.prefix(4), encoding: .ascii), riff == "RIFF",
           let webp = String(data: data[8..<12], encoding: .ascii), webp == "WEBP" {
            return convertWebPToPNG(data) ?? data
        }
        
        return data
    }
    
    /// Converts SVG data to PNG using NSImage rendering at native dimensions
    private func convertSVGToPNG(_ data: Data) -> Data? {
        guard let image = NSImage(data: data) else { return nil }
        
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        
        bitmapRep.size = size
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        
        return bitmapRep.representation(using: .png, properties: [:])
    }
    
    /// Converts WebP data to PNG using CGImageSource
    private func convertWebPToPNG(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }

}
