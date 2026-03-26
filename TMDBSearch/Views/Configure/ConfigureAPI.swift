//
//  ConfigureAPI.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI
import SFSymbol
import AppKit

struct ConfigureAPI: View {
    @Binding var apiKey: String
    @Binding var plexServer: String
    @Binding var plexToken: String
    @Binding var plexServerAssetPath: String
    @Environment(UnifiedFileManager.self) var fileManager: UnifiedFileManager
    @State private var assetDirectoryInfo: DirectoryInfo?
    @State private var hostingWindow: NSWindow?

    var body: some View {
        Section {
            SecureField("API Key", text: $apiKey, prompt: Text("Enter your TMDB API key"))
                .font(.system(.body, design: .monospaced))
        } header: {
            Text("TMDB API Configuration")
        } footer: {
            HStack(spacing: 4) {
                Text("Get your API key from")
                Link("The Movie Database", destination: URL(string: "https://www.themoviedb.org")!)
            }
            .font(.caption)
        }
        
        Section {
            TextField("Server Address", text: $plexServer, prompt: Text("192.168.1.100:32400"))
                .font(.system(.body, design: .monospaced))
            
            SecureField("Token", text: $plexToken, prompt: Text("Enter your Plex Token"))
                .font(.system(.body, design: .monospaced))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let info = assetDirectoryInfo {
                        HStack(spacing: 6) {
                            Image(systemName: info.isNetwork ?
                                  SFSymbol6.Network.network.rawValue :
                                  SFSymbol6.Folder.folder.rawValue)
                                .foregroundStyle(.secondary)
                                .hoverEffect()
                            Text(info.displayName)
                                .font(.body)
                        }
                        
                        Label(info.isNetwork ? "Network" : "Local",
                              systemImage: info.isNetwork ?
                              SFSymbol6.Externaldrive.externaldriveConnectedToLineBelow.rawValue :
                              SFSymbol6.Internaldrive.internaldrive.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No asset folder selected")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Choose...") {
                        selectAssetFolder()
                    }
                    
                    if fileManager.hasAssetDirectoryAccess {
                        Button("Clear") {
                            clearAssetFolder()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        } header: {
            Text("Plex Server (Optional)")
        } footer: {
            if let info = assetDirectoryInfo {
                Text(info.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("Server address should include http:// or https:// prefix (e.g., http://192.168.1.100:32400). Use Choose to select the asset folder where Plex/Kometa images are stored.")
                    .font(.caption)
            }
        }
        .onAppear {
            updateAssetDirectoryInfo()
        }
        .onChange(of: fileManager.selectedAssetDirectory) { _, _ in
            updateAssetDirectoryInfo()
        }
        .background(AssetWindowAccessor(window: $hostingWindow))
    }
    
    private func selectAssetFolder() {
        let window = hostingWindow ?? NSApp.windows.first(where: {
            $0.isKeyWindow || $0.title.contains("Settings") || $0.isVisible
        })
        
        if let settingsWindow = window {
            fileManager.requestAssetDirectoryAccessAsync(from: settingsWindow) { success in
                if success, let selectedURL = fileManager.selectedAssetDirectory {
                    plexServerAssetPath = selectedURL.path
                    updateAssetDirectoryInfo()
                }
            }
        } else {
            if fileManager.requestAssetDirectoryAccess() {
                if let selectedURL = fileManager.selectedAssetDirectory {
                    plexServerAssetPath = selectedURL.path
                    updateAssetDirectoryInfo()
                }
            }
        }
    }
    
    private func clearAssetFolder() {
        fileManager.clearAssetDirectoryAccess()
        plexServerAssetPath = ""
        assetDirectoryInfo = nil
    }
    
    private func updateAssetDirectoryInfo() {
        assetDirectoryInfo = fileManager.getAssetDirectoryInfo()
        
        if let selectedURL = fileManager.selectedAssetDirectory {
            plexServerAssetPath = selectedURL.path
        }
    }
}

private struct AssetWindowAccessor: NSViewRepresentable {
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
