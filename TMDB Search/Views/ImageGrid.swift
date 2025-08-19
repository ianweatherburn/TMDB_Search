//
//  ImageGrid.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/16.
//

import SwiftUI

// MARK: - Image Grid Item
struct ImageGrid: View {
    let images: [TMDBImage]
    let loadedImages: [String: NSImage]
    let gridColumns: Int
    let imageType: ImageType  // Back to ImageType enum
    let onImageTap: (TMDBImage) -> Void
    let onLoadImage: (TMDBImage) async -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: gridColumns),
                spacing: gridSpacing
            ) {
                ForEach(images) { image in
                    ImageGridItem(
                        image: image,
                        loadedImage: loadedImages[image.filePath],
                        imageType: imageType,
                        onTap: { onImageTap(image) }
                    )
                    .task {
                        await onLoadImage(image)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeOut(duration: 0.25), value: loadedImages[image.filePath])
                }
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var gridSpacing: CGFloat {
        imageType == .poster ? Constants.Image.Poster.spacing : Constants.Image.Backdrop.spacing
    }
}
