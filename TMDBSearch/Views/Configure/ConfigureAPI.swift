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
            
            TextField("Asset Path", text: $plexServerAssetPath, prompt: Text("/path/to/assets"))
                .font(.system(.body, design: .monospaced))
        } header: {
            Text("Plex Server (Optional)")
        } footer: {
            Text("Server address should include http:// or https:// prefix (e.g., http://192.168.1.100:32400). Asset path is the server-side path where Plex can access metadata files.")
                .font(.caption)
        }
    }
}
