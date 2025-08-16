//
//  ImageGallery.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI



// MARK: - Image Gallery View
struct ImageGalleryView: View {
    let item: TMDBMediaItem
    let mediaType: MediaType
    let imageType: ImageType
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var images: [TMDBImage] = []
    @State private var loadedImages: [String: NSImage] = [:]
    @State private var isLoading = true
    @State private var gridColumns: Int = 5  // Add this to your main view

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with controls
                VStack(spacing: 0) {
                    HStack {
                        // Title and count
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(imageType, title: item.plexTitle))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if !isLoading && !images.isEmpty {
                                Text("\(images.count) images available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // View controls
                        HStack(spacing: 12) {
                            // Grid size control
                            if !images.isEmpty {
                                Menu {
                                    Button("Small Grid") {
                                        gridColumns = imageType == .poster ? 6 : 4
                                    }
                                    Button("Medium Grid") {
                                        gridColumns = imageType == .poster ? 5 : 3
                                    }
                                    Button("Large Grid") {
                                        gridColumns = imageType == .poster ? 4 : 2
                                    }
                                } label: {
                                    Image(systemName: "square.grid.3x3")
                                        .font(.system(size: 16))
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                            }
                            
                            // Close button
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                }
                .background(.regularMaterial)
                
                // Main content
                Group {
                    if isLoading {
                        LoadingView()
                    } else if images.isEmpty {
                        EmptyStateView()
                    } else {
                        ImageGridView(
                            images: images,
                            loadedImages: loadedImages,
                            gridColumns: gridColumns,
                            imageType: imageType,
                            onImageTap: handleImageTap,
                            onLoadImage: loadImage
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 900, height: 700)
        .task {
            await loadImages()
        }
    }
    
    private func title(_ type: ImageType, title: String) -> String {
        return ("\(type == .poster ? "Posters" : "Backdrops") - \(title)")
    }
    
    private func loadImages() async {
        guard let response = await appModel.loadImages(for: item.id, mediaType: mediaType) else {
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
    
    private func downloadImage(_ image: TMDBImage, flip: Bool = false) async {
        let filename = imageType == .poster ? "poster.jpg" : "backdrop.jpg"

        // Determine folder prefix based on mediaType
        let folderPrefix: String
        switch mediaType {
        case .tv:
            folderPrefix = "shows"
        case .movie:
            folderPrefix = "movies"
        case .collection:
            folderPrefix = "collections"
        }
        
        // Choose title part: for collection use displayTitle, else plexTitle
        let titlePart = mediaType == .collection ? item.displayTitle : item.plexTitle
        
        // Compose the destPath as "folder/title"
        let destPath = "\(folderPrefix)/\(titlePart)".replacingColonsWithDashes
        
        let success = await appModel.downloadImage(
            sourcePath: image.filePath,
            destPath: destPath.replacingColonsWithDashes,
            filename: filename,
            flip: flip
        )
        
        if success {
            await MainActor.run {
                _ = NSSound(named: NSSound.Name("Glass"))?.play()
            }
        } else {
            await MainActor.run {
                _ = NSSound(named: NSSound.Name("Pop"))?.play()
            }
        }
    }
    
    private func handleImageTap(_ image: TMDBImage) {
        let modifiers = NSEvent.modifierFlags
        let isOptionPressed = modifiers.contains(.option)
        
        Task {
            await downloadImage(image, flip: isOptionPressed)
        }
    }
    
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading images...")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.secondary, .quaternary)
            
            VStack(spacing: 8) {
                Text("No Images Available")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("There are no images of this type for this item")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


