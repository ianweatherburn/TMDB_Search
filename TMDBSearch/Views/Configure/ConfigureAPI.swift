//
//  ConfigureAPI.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI
import SFSymbol

struct ConfigureAPI: View {
    @Binding var apiKey: String
    @Binding var plexServer: String
    @Binding var plexToken: String
    @Binding var plexServerAssetPath: String
    @Environment(UnifiedFileManager.self) var fileManager: UnifiedFileManager
    @State private var directoryInfo: DirectoryInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)
                    .fontWeight(.medium)
                SecureField("Enter your TMDB API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                HStack(spacing: 2) {
                    Text("Get your API key from")
                    Link(destination: URL(string: "https://www.themoviedb.org")!) {
                        HStack(spacing: 2) {
                            Image(symbol: SFSymbol6.Network.network)
                                .imageScale(.medium)
                            Text("The Movie Database")
                        }
                    }
                    .tint(.accentColor)
                }
                .font(.caption)
            }
        }
        
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plex Server")
                    .font(.headline)
                    .fontWeight(.medium)
                TextField("Enter your Plex hostname or IP Address and Port", text: $plexServer)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text("Plex Token")
                    .font(.headline)
                    .fontWeight(.medium)
                SecureField("Enter your Plex Token", text: $plexToken)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text("Plex Asset Path")
                    .font(.headline)
                    .fontWeight(.medium)
                TextField("Enter your Plex path where assets can be found", text: $plexServerAssetPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
    
    private func selectPlexAssetFolder() {
        if fileManager.requestDirectoryAccess() {
            // Update the download path in settings
            if let selectedURL = fileManager.selectedDirectory {
                plexServerAssetPath = selectedURL.path
                updateDirectoryInfoforPlexAssetFolder()
            }
        }
    }
    
    private func clearPlexAssetFolder() {
        fileManager.clearDirectoryAccess()
        plexServerAssetPath = NSHomeDirectory() + "/Downloads/TMDB" // Reset to default
        directoryInfo = nil
    }
    
    private func updateDirectoryInfoforPlexAssetFolder() {
        directoryInfo = fileManager.getSelectedDirectoryInfo()
        
        // Sync with the binding if we have directory access
        if let selectedURL = fileManager.selectedDirectory {
            plexServerAssetPath = selectedURL.path
        }
    }
}
