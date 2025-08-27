//
//  ImageGallery.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI
import SFSymbol

// MARK: - Image Gallery View
struct ImageGallery: View {
    let item: TMDBMediaItem
    let mediaType: MediaType
    let imageType: ImageType
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var images: [TMDBImage] = []
    @State private var loadedImages: [String: NSImage] = [:]
    @State private var isLoading = true
    @State private var gridColumns: Int = 0
    @State private var showDownloadFailedAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with controls
                VStack(spacing: 0) {
                    HStack {
                        // Title and count
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(imageType, title: item.formattedTitle))
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if !isLoading && !images.isEmpty {
                                HStack(spacing: 0) {
                                    Text(images.count.inflect("image"))
                                    Text(" available")
                                }
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
                                    ForEach(GridSize.allCases) { gridSize in
                                        Button(gridSize.displayName) {
                                            setGridSize(gridSize)
                                        }
                                        .keyboardShortcut(KeyEquivalent(Character(gridSize.keyboardShortcut)),
                                                          modifiers: .control)
                                        .help(gridSize.helpText)
                                    }
                                } label: {
//                                    Image(systemName: "square.grid.3x3")
                                    Image(symbol: SFSymbol6.Square.squareGrid3x3)
                                        .font(.system(size: 16))
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                                .help("Change grid size")
                            }
                            
                            // Close button
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .background {
                        // Hidden buttons for reliable keyboard shortcuts
                        ForEach(GridSize.allCases) { gridSize in
                            Button("") {
                                setGridSize(gridSize)
                            }
                            .keyboardShortcut(KeyEquivalent(Character(gridSize.keyboardShortcut)), modifiers: .control)
                            .hidden()
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
                        ImageGrid(
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
        .frame(width: Constants.Image.Gallery.width, height: Constants.Image.Gallery.height)
        .task {
            await loadImages()
        }
        .alert("Download Failed", isPresented: $showDownloadFailedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The image could not be downloaded. Please try again.")
        }
        .onAppear {
            // Set initial grid size from app model
            if gridColumns == 0 { // Only set if not already configured
                gridColumns = appModel.settingsManager.gridSize.columnCount(for: imageType)
            }
        }
        .onChange(of: appModel.settingsManager.gridSize) { _, newValue in
            gridColumns = newValue.columnCount(for: imageType)
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
        guard let loadedData = await TMDBServices().loadImage(
            path: image.filePath,
            size: TMDBServices.ImageSize.w342
        ) else {
            return
        }
        await MainActor.run {
            loadedImages[image.filePath] = NSImage(data: loadedData)
        }
    }
    
    private func downloadImage(_ image: TMDBImage, flip: Bool = false) async {
        let filename = imageType == .poster ? Constants.Image.Types.poster : Constants.Image.Types.backdrop

        // Determine folder prefix based on mediaType
        let folderPrefix: String
        switch mediaType {
        case .tv:
            folderPrefix = Constants.Media.Types.shows
        case .movie:
            folderPrefix = Constants.Media.Types.movies
        case .collection:
            folderPrefix = Constants.Media.Types.collections
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
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.success))?.play()
            }
        } else {
            showDownloadFailedAlert = true
            await MainActor.run {
                _ = NSSound(named: NSSound.Name(Constants.App.Sounds.failure))?.play()
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
    
    private func setGridSize(_ size: GridSize) {
        gridColumns = size.columnCount(for: imageType)
    }
}
