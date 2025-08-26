//
//  UnifiedFieldManager.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/25.
//

import Foundation
import AppKit

class UnifiedFileManager: ObservableObject {
    @Published var selectedDirectory: URL?
    @Published var hasDirectoryAccess = false
    private let bookmarkKey = "SelectedDirectoryBookmark"
    
    init() {
        restoreDirectoryAccess()
    }
    
    // MARK: - Directory Selection
    func requestDirectoryAccess() -> Bool {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select Output Directory"
        openPanel.message = "Choose where to save your images (local folder or network share)"
        openPanel.prompt = "Select"
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            return setSelectedDirectory(selectedURL)
        }
        return false
    }
    
    private func setSelectedDirectory(_ url: URL) -> Bool {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // Save bookmark to UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            
            if url.startAccessingSecurityScopedResource() {
                self.selectedDirectory = url
                self.hasDirectoryAccess = true
                print("✅ Directory access granted: \(url.path)")
                return true
            } else {
                print("❌ Could not start accessing selected directory")
                return false
            }
            
        } catch {
            print("❌ Failed to create bookmark: \(error)")
            return false
        }
    }
    
    // MARK: - Restore bookmark at launch
    private func restoreDirectoryAccess() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("⚠️ Bookmark was stale, refreshing…")
                _ = setSelectedDirectory(url) // re-save fresh bookmark
                return
            }
            
            if url.startAccessingSecurityScopedResource() {
                self.selectedDirectory = url
                self.hasDirectoryAccess = true
                print("✅ Restored RW access to: \(url.path)")
            } else {
                print("❌ Failed to restore RW access to: \(url.path)")
            }
            
        } catch {
            print("❌ Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
    
    private func loadSavedDirectory() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("Bookmark is stale, re-requesting access...")
                return
            }
            
            self.selectedDirectory = url
            self.hasDirectoryAccess = true
            print("Restored directory access: \(url.path)")
            
        } catch {
            print("Failed to restore bookmark: \(error)")
            // Clear invalid bookmark
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
    
    // MARK: - File Operations
    func writeFile(data: Data, filename: String, subdirectory: String? = nil) async throws -> URL {
        guard let baseDirectory = selectedDirectory else {
            throw FileAccessError.noDirectorySelected
        }
        
        guard baseDirectory.startAccessingSecurityScopedResource() else {
            throw FileAccessError.cannotAccessSecurityScopedResource
        }
        defer { baseDirectory.stopAccessingSecurityScopedResource() }
        
        var targetDirectory = baseDirectory
        if let subdirectory = subdirectory {
            targetDirectory = baseDirectory.appendingPathComponent(subdirectory)
        }
        
        try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        let finalURL = try findUniqueFilename(in: targetDirectory, filename: filename)
        try data.write(to: finalURL)
        
        print("✅ File written: \(finalURL.path)")
        return finalURL
    }
    
    private func findUniqueFilename(in directory: URL, filename: String) throws -> URL {
        let fileManager = FileManager.default
        let fileBase = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension
        
        var targetURL = directory.appendingPathComponent(filename)
        var counter = 1
        
        while fileManager.fileExists(atPath: targetURL.path) {
            let newFilename: String
            if fileExtension.isEmpty {
                newFilename = "\(fileBase)_\(counter)"
            } else {
                newFilename = "\(fileBase)_\(counter).\(fileExtension)"
            }
            targetURL = directory.appendingPathComponent(newFilename)
            counter += 1
        }
        
        return targetURL
    }
    
    // MARK: - Utility Methods
    
    func clearDirectoryAccess() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        selectedDirectory = nil
        hasDirectoryAccess = false
    }
    
    func getSelectedDirectoryInfo() -> DirectoryInfo? {
        guard let url = selectedDirectory else { return nil }
        
        let isNetwork = isNetworkVolume(url: url)
        let isWritable = FileManager.default.isWritableFile(atPath: url.path)
        
        return DirectoryInfo(
            url: url,
            path: url.path,
            isNetwork: isNetwork,
            isWritable: isWritable,
            displayName: url.lastPathComponent
        )
    }
    
    private func isNetworkVolume(url: URL) -> Bool {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.volumeIsLocalKey])
            return !(resourceValues.volumeIsLocal ?? true)
        } catch {
            // Fallback: check if path contains common network mount patterns
            let path = url.path.lowercased()
            return path.contains("/volumes/") ||
                   path.contains("/mount/") ||
                   path.contains("/mnt/")
        }
    }
}

// MARK: - Supporting Types

enum FileAccessError: Error, LocalizedError {
    case noDirectorySelected
    case cannotAccessSecurityScopedResource
    case writePermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noDirectorySelected:
            return "No output directory selected. Please choose a directory first."
        case .cannotAccessSecurityScopedResource:
            return "Cannot access the selected directory. Please reselect the directory."
        case .writePermissionDenied:
            return "Permission denied. Cannot write to the selected directory."
        }
    }
}

struct DirectoryInfo {
    let url: URL
    let path: String
    let isNetwork: Bool
    let isWritable: Bool
    let displayName: String
    
    var description: String {
        let type = isNetwork ? "Network" : "Local"
        let writable = isWritable ? "âœ… Writable" : "âŒ Read-only"
        return "\(displayName) (\(type), \(writable))"
    }
}

// MARK: - Usage Example

extension UnifiedFileManager {
    func downloadAndSaveImage(from urlString: String, filename: String, subdirectory: String? = nil) async -> Bool {
        guard let url = URL(string: urlString) else {
            print("âŒ Invalid URL: \(urlString)")
            return false
        }
        
        do {
            // Download image
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Save to selected directory
            let savedURL = try await writeFile(data: data, filename: filename, subdirectory: subdirectory)
            
            print("Image saved: \(savedURL.lastPathComponent)")
            return true
            
        } catch {
            print("Failed to download/save image: \(error)")
            return false
        }
    }
}
