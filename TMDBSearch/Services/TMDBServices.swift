//
//  TMDBServices.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import Foundation
import SwiftUI
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - TMDB Service
final class TMDBService {
    private let baseURL = Constants.Services.TMDB.baseURL
    private let imageBaseURL = Constants.Services.TMDB.imageURL

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

    func getImages(itemId: Int,
                   mediaType: MediaType,
                   languages: [String],
                   apiKey: String) async throws -> TMDBImagesResponse {
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
        
        // Sort by area (width × height) in descending order
        response = TMDBImagesResponse(
            id: response.id,
            posters: response.posters.sorted { ($0.width * $0.height) > ($1.width * $1.height) },
            backdrops: response.backdrops.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
        )
        
        return response
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
                    print("Failed to flip image horizontally")
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
            print("Failed to download image: \(error)")
            return false
        }
    }
    
    func downloadImageWithShellHelper(path: String,
                                      to directory: String,
                                      filename: String,
                                      flip: Bool = false) async -> Bool {
        let urlString = "\(imageBaseURL)/original\(path)"
        
        guard let url = URL(string: urlString) else { return false }

        do {
            // Download the image data
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Process the image data
            let finalData: Data
            if flip {
                guard let flippedData = flipImageHorizontally(data) else {
                    print("Failed to flip image horizontally")
                    return false
                }
                finalData = flippedData
            } else {
                finalData = data
            }
            
            // Write using shell command
            return try await writeFileUsingShell(data: finalData, directory: directory, filename: filename)
            
        } catch {
            print("Failed to download image: \(error)")
            return false
        }
    }

    func writeFileUsingShell(data: Data, directory: String, filename: String) async throws -> Bool {
        // Write to temporary file first
        let tempDir = NSTemporaryDirectory()
        let tempFile = tempDir + UUID().uuidString + "_" + filename
        try data.write(to: URL(fileURLWithPath: tempFile))
        
        // Create destination directory first
        let mkdirSuccess = await runShellCommand("/bin/mkdir", arguments: ["-p", directory])
        guard mkdirSuccess else {
            try? FileManager.default.removeItem(atPath: tempFile)
            throw NSError(domain: "ShellError",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create directory"])
        }
        
        // Handle filename conflicts
        let fileBase = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension
        
        var finalFilename = filename
        var counter = 1
        var destinationPath = directory + "/" + finalFilename
        
        // Check for existing files and find unique name
        while FileManager.default.fileExists(atPath: destinationPath) {
            if fileExtension.isEmpty {
                finalFilename = "\(fileBase)_\(counter)"
            } else {
                finalFilename = "\(fileBase)_\(counter).\(fileExtension)"
            }
            destinationPath = directory + "/" + finalFilename
            counter += 1
        }
        
        // Copy file using shell command
        let copySuccess = await runShellCommand("/bin/cp", arguments: [tempFile, destinationPath])
        
        // Clean up temp file
        try? FileManager.default.removeItem(atPath: tempFile)
        
        if !copySuccess {
            throw NSError(domain: "ShellError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to copy file"])
        }
        
        return true
    }

    func runShellCommand(_ command: String, arguments: [String]) async -> Bool {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.launchPath = command
            task.arguments = arguments
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.terminationHandler = { process in
                if process.terminationStatus != 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    print("Command '\(command) \(arguments.joined(separator: " "))' failed: \(output)")
                }
                continuation.resume(returning: process.terminationStatus == 0)
            }
            
            task.launch()
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

}
