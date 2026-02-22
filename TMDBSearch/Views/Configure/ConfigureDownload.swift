//
//  ConfigureDownload.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

// import SwiftUI
//
// struct ConfigureDownload: View {
//    @Binding var downloadPath: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 32) {
//            DownloadPathSection(
//                title: "Download Folder",
//                path: $downloadPath,
//                description: "Primary location where downloaded images will be saved"
//            )
//        }
//    }
// }

//
//  ConfigureDownload.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI
import SFSymbol
import AppKit

struct ConfigureDownload: View {
    @Binding var downloadPath: String
    @Environment(UnifiedFileManager.self) var fileManager: UnifiedFileManager
    @State private var directoryInfo: DirectoryInfo?
    @State private var hostingWindow: NSWindow?
    
    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let info = directoryInfo {
                        HStack(spacing: 6) {
                            Image(systemName: info.isNetwork ? 
                                  SFSymbol6.Network.network.rawValue : 
                                  SFSymbol6.Folder.folder.rawValue)
                                .foregroundStyle(.secondary)
                            Text(info.displayName)
                                .font(.body)
                        }
                        
                        HStack(spacing: 12) {
                            Label(info.isNetwork ? "Network" : "Local",
                                  systemImage: info.isNetwork ?
                                  SFSymbol6.Externaldrive.externaldriveConnectedToLineBelow.rawValue :
                                  SFSymbol6.Internaldrive.internaldrive.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Label(info.isWritable ? "Writable" : "Read-only",
                                  systemImage: info.isWritable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(info.isWritable ? .green : .red)
                        }
                    } else {
                        Text("No folder selected")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Choose...") {
                        selectDownloadFolder()
                    }
                    
                    if fileManager.hasDirectoryAccess {
                        Button("Clear") {
                            clearDownloadFolder()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        } header: {
            Text("Download Location")
        } footer: {
            if let info = directoryInfo {
                Text(info.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("Choose where to save downloaded images. Supports local folders and network shares.")
            }
        }
        .onAppear {
            updateDirectoryInfo()
        }
        .onChange(of: fileManager.selectedDirectory) { _, _ in
            updateDirectoryInfo()
        }
        .background(WindowAccessor(window: $hostingWindow))
    }
    
    private func selectDownloadFolder() {
        // Try to get the window from multiple sources
        let window = hostingWindow ?? NSApp.windows.first(where: { 
            $0.isKeyWindow || $0.title.contains("Settings") || $0.isVisible 
        })
        
        if let settingsWindow = window {
            DebugLogger.log("✅ Using window: \(settingsWindow.title) (sheet modal)")
            // Use async callback-based approach with sheet modal
            fileManager.requestDirectoryAccessAsync(from: settingsWindow) { success in
                if success, let selectedURL = fileManager.selectedDirectory {
                    downloadPath = selectedURL.path
                    updateDirectoryInfo()
                }
            }
        } else {
            DebugLogger.log("⚠️ No window found, using standalone modal")
            // Fallback to sync version with standalone modal
            if fileManager.requestDirectoryAccess() {
                if let selectedURL = fileManager.selectedDirectory {
                    downloadPath = selectedURL.path
                    updateDirectoryInfo()
                }
            }
        }
    }
    
    private func clearDownloadFolder() {
        fileManager.clearDirectoryAccess()
        downloadPath = NSHomeDirectory() + "/Downloads/TMDB" // Reset to default
        directoryInfo = nil
    }
    
    private func updateDirectoryInfo() {
        directoryInfo = fileManager.getSelectedDirectoryInfo()
        
        // Sync with the binding if we have directory access
        if let selectedURL = fileManager.selectedDirectory {
            downloadPath = selectedURL.path
        }
    }
}

// MARK: - Window Accessor Helper
private struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.window = nsView.window
        }
    }
}
