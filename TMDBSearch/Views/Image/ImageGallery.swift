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
                                    Text(images.count.pluralize("image"))
                                    Text(" available")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            // View controls
                            HStack(spacing: 12) {
                                
                                Spacer()
                                
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
                                            .hoverEffect()
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
                            .padding(.horizontal, 0)
                            
                            saveInstructionText
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
        let label: String
        switch type {
        case .poster: label = "Posters"
        case .backdrop: label = "Backdrops"
        case .logo: label = "Logos"
        }
        return "\(label) - \(title)"
    }
    
    private func loadImages() async {
        guard let response = await appModel.loadImages(for: item.id, mediaType: mediaType) else {
            isLoading = false
            return
        }
        
        switch imageType {
        case .poster: images = response.posters
        case .backdrop: images = response.backdrops
        case .logo: images = response.logos
        }
        isLoading = false
    }
    
    private func loadImage(_ image: TMDBImage) async {
        guard loadedImages[image.filePath] == nil else { return }
        guard let loadedData = await appModel.tmdbService.loadImage(
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
        let filename: String
        switch imageType {
        case .poster: filename = Constants.Image.Types.poster
        case .backdrop: filename = Constants.Image.Types.backdrop
        case .logo: filename = Constants.Image.Types.logo
        }

        // Determine folder prefix based on mediaType
        let folderPrefix: String
        switch mediaType {
        case .tv:
            folderPrefix = Constants.Media.Types.shows
        case .movie:
            folderPrefix = Constants.Media.Types.movies
        case .collection:
            folderPrefix = Constants.Media.Types.movies
        }
        
        // Choose title part: for collection use displayTitle, else plexTitle
        // Apply filesystem-safe conversion to the title only, not the full path
        let titlePart = (mediaType == .collection ? item.displayTitle : item.plexTitle).toFileSystemSafe
        
        // Compose the destPath as "folder/title"
        let destPath = "\(folderPrefix)/\(titlePart)"
        
        let success = await appModel.downloadImage(
            sourcePath: image.filePath,
            destPath: destPath,
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
    
    @ViewBuilder
    private var saveInstructionText: some View {
        let tapIcon = Text(Image(systemName: "hand.tap.fill"))
        let optionIcon = Text(Image(systemName: "option"))
        
        let save = tapIcon + Text(" to save •")
        let optionSave = optionIcon + tapIcon + Text(" to flip and save")
        
        (save + optionSave)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
