//
//  UnifiedFieldManager.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/25.
//

import Foundation
import AppKit

// class UnifiedFileManager: ObservableObject {
//    @Published var selectedDirectory: URL?
//    @Published var hasDirectoryAccess = false
@Observable
final class UnifiedFileManager {
    var selectedDirectory: URL?
    var hasDirectoryAccess = false
    private let bookmarkKey = "SelectedDirectoryBookmark"
    
    init() {
        restoreDirectoryAccess()
    }
    
    // MARK: - Directory Selection
    
    /// Async version using sheet modal - prevents window ordering issues
    func requestDirectoryAccessAsync(from window: NSWindow, completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select Output Directory"
        openPanel.message = "Choose where to save your images (local folder or network share)"
        openPanel.prompt = "Select"
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        // Present as sheet - this maintains proper window hierarchy
        openPanel.beginSheetModal(for: window) { [weak self] response in
            guard let self = self else {
                completion(false)
                return
            }
            
            if response == .OK, let selectedURL = openPanel.url {
                let success = self.setSelectedDirectory(selectedURL)
                
                // Ensure settings window stays key
                DispatchQueue.main.async {
                    window.makeKey()
                }
                
                completion(success)
            } else {
                completion(false)
            }
        }
    }
    
    /// Synchronous version - for backward compatibility
    func requestDirectoryAccess(from window: NSWindow? = nil) -> Bool {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.title = "Select Output Directory"
        openPanel.message = "Choose where to save your images (local folder or network share)"
        openPanel.prompt = "Select"
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        // Run the panel modally
        let response = openPanel.runModal()
        
        // Restore focus to window if provided
        if let window = window {
            DispatchQueue.main.async {
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        // Process the result
        if response == .OK, let selectedURL = openPanel.url {
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
                DebugLogger.log("✅ Directory access granted: \(url.path)")
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
                DebugLogger.log("✅ Restored RW access to: \(url.path)")
            } else {
                print("❌ Failed to restore RW access to: \(url.path)")
            }
            
        } catch {
            print("❌ Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }
    

    
    // MARK: - File Operations
    func writeFile(data: Data, filename: String, subdirectory: String? = nil) async throws -> URL {
        guard let baseDirectory = selectedDirectory else {
            throw FileAccessError.noDirectorySelected
        }
        
        // Security-scoped resource access is already active from setSelectedDirectory or restoreDirectoryAccess
        // We don't need to call startAccessingSecurityScopedResource again here
        
        var targetDirectory = baseDirectory
        if let subdirectory = subdirectory {
            targetDirectory = baseDirectory.appendingPathComponent(subdirectory)
        }
        
        // Create directory with full permissions
        try FileManager.default.createDirectory(
            at: targetDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let finalURL = try findUniqueFilename(in: targetDirectory, filename: filename)
        
        // Write with explicit options for better error reporting
        try data.write(to: finalURL, options: [.atomic])
        
        DebugLogger.log("✅ File written: \(finalURL.path)")
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
            DebugLogger.log("Invalid URL: \(urlString)")
            return false
        }
        
        do {
            // Download image
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Save to selected directory
            let savedURL = try await writeFile(data: data, filename: filename, subdirectory: subdirectory)
            
            DebugLogger.log("Image saved: \(savedURL.lastPathComponent)")
            return true
            
        } catch {
            print("❌ Failed to download/save image: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Saves image data directly to the security-scoped directory
    /// - Parameters:
    ///   - data: The image data to save
    ///   - filename: The desired filename
    ///   - subdirectory: Optional subdirectory path
    /// - Returns: True if successful, false otherwise
    func saveImageData(_ data: Data, filename: String, subdirectory: String? = nil) async -> Bool {
        do {
            let savedURL = try await writeFile(data: data, filename: filename, subdirectory: subdirectory)
            DebugLogger.log("✅ Image saved: \(savedURL.lastPathComponent)")
            return true
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            return false
        }
    }
}
