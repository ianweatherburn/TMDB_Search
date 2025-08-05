//
//  ImageGallery.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Image Gallery View
struct ImageGalleryView: View {
    let itemId: Int
    let mediaType: MediaType
    let imageType: ImageType
    let title: String
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var images: [TMDBImage] = []
    @State private var loadedImages: [String: NSImage] = [:]
    @State private var isLoading = true
    
    enum ImageType {
        case poster, backdrop
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading images...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if images.isEmpty {
                    Text("No images available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(images) { image in
                                ImageGridItem(
                                    image: image,
                                    loadedImage: loadedImages[image.filePath],
                                    onTap: {
                                        Task {
                                            await downloadImage(image)
                                        }
                                    }
                                )
                                .task {
                                    await loadImage(image)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        guard let response = await appModel.loadImages(for: itemId, mediaType: mediaType) else {
            isLoading = false
            return
        }
        
        images = imageType == .poster ? response.posters : response.backdrops
        isLoading = false
    }
    
    private func loadImage(_ image: TMDBImage) async {
        guard loadedImages[image.filePath] == nil else { return }
        guard let loadedData = await TMDBService().loadImage(path: image.filePath, size: TMDBService.ImageSize.w342) else { return }
        await MainActor.run {
            loadedImages[image.filePath] = NSImage(data: loadedData)
        }
    }
    
    private func downloadImage(_ image: TMDBImage) async {
        let filename = "\(itemId)_\(imageType == .poster ? "poster" : "backdrop")_\(image.filePath.replacingOccurrences(of: "/", with: ""))"
        let success = await appModel.downloadImage(path: image.filePath, filename: filename)
        
        if success {
            await MainActor.run {
                NSSound.beep() // Success sound
            }
        } else {
            await MainActor.run {
                NSSound.beep()
            }
        }
    }
}
