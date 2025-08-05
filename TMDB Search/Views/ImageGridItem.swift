//
//  ImageGridItem.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Image Grid Item
struct ImageGridItem: View {
    let image: TMDBImage
    let loadedImage: NSImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Group {
                if let loadedImage = loadedImage {
                    Image(nsImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                }
            }
            .frame(height: 200)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help("Click to download")
    }
}
