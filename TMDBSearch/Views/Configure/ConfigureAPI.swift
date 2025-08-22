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
    }
}

#Preview {
    @Previewable @State var apiKey = "12345"
    ConfigureAPI(apiKey: $apiKey)
}
