//
//  AssetUploadTask.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import Foundation

// MARK: - Asset Type

enum AssetType: String {
    case showPoster = "Show Poster"
    case showBackdrop = "Show Backdrop"
    case moviePoster = "Movie Poster"
    case movieBackdrop = "Movie Backdrop"
    case seasonPoster = "Season Poster"
    case episodeTitleCard = "Episode Title Card"
}

// MARK: - Asset Upload Task

struct AssetUploadTask: Identifiable {
    let id = UUID()
    let type: AssetType
    let filePath: String
    let ratingKey: String
    let displayName: String
    var status: UploadStatus = .pending
    var error: String?
    
    enum UploadStatus {
        case pending
        case uploading
        case completed
        case failed
    }
}

// MARK: - Asset Scanner

struct AssetScanner {
    let metadataPath: String
    
    /// Scan directory for all asset files
    func scanAssets() -> [String: String] {
        var assets: [String: String] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: metadataPath) else {
            return assets
        }
        
        while let file = enumerator.nextObject() as? String {
            let fullPath = "\(metadataPath)/\(file)"
            
            // Skip directories
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory),
                  !isDirectory.boolValue else {
                continue
            }
            
            // Check if it's an image file
            let fileExtension = (file as NSString).pathExtension.lowercased()
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                continue
            }
            
            // Store with relative path as key
            assets[file] = fullPath
        }
        
        return assets
    }
    
    /// Find best poster file (prefer .png over .jpg)
    func findPoster(in assets: [String: String], prefix: String = "poster") -> String? {
        // Try PNG first
        if let pngPath = assets.first(where: { $0.key.hasPrefix(prefix) && $0.key.hasSuffix(".png") })?.value {
            return pngPath
        }
        
        // Fall back to JPG
        if let jpgPath = assets.first(where: { 
            $0.key.hasPrefix(prefix) && ($0.key.hasSuffix(".jpg") || $0.key.hasSuffix(".jpeg"))
        })?.value {
            return jpgPath
        }
        
        return nil
    }
    
    /// Find best backdrop file (prefer .png over .jpg)
    func findBackdrop(in assets: [String: String]) -> String? {
        let backdropPrefixes = ["background", "backdrop", "fanart"]
        
        // Try PNG first for all prefixes
        for prefix in backdropPrefixes {
            if let pngPath = assets.first(where: { $0.key.hasPrefix(prefix) && $0.key.hasSuffix(".png") })?.value {
                return pngPath
            }
        }
        
        // Fall back to JPG
        for prefix in backdropPrefixes {
            if let jpgPath = assets.first(where: {
                $0.key.hasPrefix(prefix) && ($0.key.hasSuffix(".jpg") || $0.key.hasSuffix(".jpeg"))
            })?.value {
                return jpgPath
            }
        }
        
        return nil
    }
    
    /// Find season poster files (Season01.png, Season02.jpg, etc.)
    func findSeasonPosters(in assets: [String: String]) -> [(seasonNumber: Int, filePath: String)] {
        var seasonPosters: [(Int, String)] = []
        
        for (file, fullPath) in assets {
            // Check if file matches Season## pattern
            if file.hasPrefix("Season") && !file.contains("/") {
                // Extract season number (Season01 -> 1, Season02 -> 2)
                let afterSeason = file.dropFirst(6)
                if let seasonNum = Int(String(afterSeason.prefix(2))) {
                    // Prefer PNG
                    if file.hasSuffix(".png") {
                        // Remove any existing JPG for this season
                        seasonPosters.removeAll { $0.0 == seasonNum }
                        seasonPosters.append((seasonNum, fullPath))
                    } else if (file.hasSuffix(".jpg") || file.hasSuffix(".jpeg")) &&
                              !seasonPosters.contains(where: { $0.0 == seasonNum }) {
                        seasonPosters.append((seasonNum, fullPath))
                    }
                }
            }
        }
        
        return seasonPosters.sorted(by: { $0.0 < $1.0 })
    }
    
    /// Find episode title card files (S01E01.png, S02E05.jpg, etc.)
    func findEpisodeTitleCards(in assets: [String: String]) -> [(season: Int, episode: Int, filePath: String)] {
        var episodeCards: [(Int, Int, String)] = []
        var episodeMap: [String: String] = [:] // "S01E01" -> filePath
        
        for (file, fullPath) in assets {
            // Match S##E## pattern
            let fileName = (file as NSString).lastPathComponent
            let pattern = "^S(\\d{2})E(\\d{2})\\.(png|jpg|jpeg)$"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) {
                
                guard let seasonRange = Range(match.range(at: 1), in: fileName),
                      let episodeRange = Range(match.range(at: 2), in: fileName),
                      let extensionRange = Range(match.range(at: 3), in: fileName) else {
                    continue
                }
                
                let seasonNum = Int(fileName[seasonRange]) ?? 0
                let episodeNum = Int(fileName[episodeRange]) ?? 0
                let ext = String(fileName[extensionRange]).lowercased()
                let key = "S\(String(format: "%02d", seasonNum))E\(String(format: "%02d", episodeNum))"
                
                // Prefer PNG over JPG
                if ext == "png" {
                    episodeMap[key] = fullPath
                } else if (ext == "jpg" || ext == "jpeg") && episodeMap[key] == nil {
                    episodeMap[key] = fullPath
                }
            }
        }
        
        // Convert map to array
        for (key, path) in episodeMap {
            let seasonNum = Int(key.dropFirst().prefix(2)) ?? 0
            let episodeNum = Int(key.dropFirst(4).prefix(2)) ?? 0
            episodeCards.append((seasonNum, episodeNum, path))
        }
        
        return episodeCards.sorted(by: { a, b in
            if a.0 == b.0 {
                return a.1 < b.1
            }
            return a.0 < b.0
        })
    }
}
