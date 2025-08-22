//
//  DownloadPathSection.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct DownloadPathSection: View {
    let title: String
    @Binding var path: String
    let description: String
    var choosePath: (() -> String?)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                TextField("Select folder", text: $path)
                    .textFieldStyle(.roundedBorder)

                if let choosePath = choosePath {
                    Button("Choose...") {
                        if let newPath = choosePath() {
                            path = newPath
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !path.isEmpty {
                Label(path, systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
