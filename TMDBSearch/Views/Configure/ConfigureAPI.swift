//
//  ConfigureAPI.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

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
                Text("Get your API key from [TMDB](https://www.themoviedb.org)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
