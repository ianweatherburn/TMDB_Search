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

struct ConfigureDownload: View {
    @Binding var downloadPath: String
    @EnvironmentObject var fileManager: UnifiedFileManager
    @State private var directoryInfo: DirectoryInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Primary Download Folder Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Download Folder")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    TextField("Select folder", text: $downloadPath)
                        .textFieldStyle(.roundedBorder)
                        .disabled(true) // Make read-only since we use the file manager
                    
                    Button("Choose...") {
                        selectDownloadFolder()
                    }
                    .buttonStyle(.bordered)
                    
                    if fileManager.hasDirectoryAccess {
                        Button("Clear") {
                            clearDownloadFolder()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                
                // Show current directory info
                if let info = directoryInfo {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(info.path,
                              systemImage: info.isNetwork ?
                              SFSymbol6.Network.network.rawValue :
                              SFSymbol6.Folder.folder.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        HStack {
                            Label(info.isNetwork ? "Network Share" : "Local Folder",
                                  systemImage: info.isNetwork ?
                                  SFSymbol6.Externaldrive.externaldriveConnectedToLineBelow.rawValue :
                                  SFSymbol6.Internaldrive.internaldrive.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Label(info.isWritable ? "Writable" : "Read-only",
                                  systemImage: info.isWritable ? "checkmark.circle" : "xmark.circle")
                                .font(.caption2)
                                .foregroundColor(info.isWritable ? .green : .red)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                } else if !downloadPath.isEmpty {
                    Label(downloadPath, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Text("Location where downloaded images will be saved. Supports both local folders and network shares.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            updateDirectoryInfo()
        }
        .onChange(of: fileManager.selectedDirectory) { _, _ in
            updateDirectoryInfo()
        }
    }
    
    private func selectDownloadFolder() {
        if fileManager.requestDirectoryAccess() {
            // Update the download path in settings
            if let selectedURL = fileManager.selectedDirectory {
                downloadPath = selectedURL.path
                updateDirectoryInfo()
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
