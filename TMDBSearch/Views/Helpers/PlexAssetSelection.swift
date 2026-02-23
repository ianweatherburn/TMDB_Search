//
//  PlexAssetSelection.swift
//  TMDB Search
//

import SwiftUI
import ImageIO

// MARK: - Preview Constants

private enum PreviewConfig {
    static let maxPixelSize: CGFloat = 250
    static let sidebarWidth: CGFloat = 280
    static let cornerRadius: CGFloat = 6
    static let listWidth: CGFloat = 340
}

// MARK: - Plex Asset Selection View

struct PlexAssetSelection: View {
    let mediaTitle: String
    let settingsManager: SettingsManager
    @Binding var tasks: [AssetUploadTask]
    @Binding var selections: [UUID: Bool]
    @Binding var includeUHD: Bool
    let onToggleUHD: () -> Void
    let onUpdate: () -> Void
    let onCancel: () -> Void
    
    @State private var showPreview: Bool = true
    @State private var focusedTaskId: UUID?
    
    private var allSelected: Bool {
        tasks.allSatisfy { selections[$0.id] == true }
    }
    
    private var selectedCount: Int {
        tasks.filter { selections[$0.id] == true }.count
    }
    
    private var focusedTask: AssetUploadTask? {
        tasks.first { $0.id == focusedTaskId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("Update Plex Assets")
                    .font(.headline)
                
                Text(mediaTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // Toolbar
            HStack {
                Button(action: toggleAll) {
                    Label(
                        allSelected
                            ? "Unselect All (\(selectedCount) of \(tasks.count) selected)"
                            : "Select All (\(selectedCount) of \(tasks.count) selected)",
                        systemImage: allSelected
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    includeUHD.toggle()
                    onToggleUHD()
                }) {
                    Label(
                        "Include 4K?",
                        systemImage: includeUHD ? "4k.tv.fill" : "4k.tv"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(includeUHD ? .primary : .secondary)
                
                Spacer()
                
                Button(action: togglePreview) {
                    Label(
                        "Preview",
                        systemImage: showPreview ? "eye.fill" : "eye.slash"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(showPreview ? .primary : .secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            Divider()
            
            // Main content: list + optional preview sidebar
            HStack(spacing: 0) {
                // Asset list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            AssetSelectionRow(
                                task: task,
                                isFocused: focusedTaskId == task.id,
                                isChecked: Binding<Bool>(
                                    get: { selections[task.id] == true },
                                    set: { selections[task.id] = $0 }
                                ),
                                onSelect: {
                                    focusedTaskId = task.id
                                }
                            )
                            
                            if task.id != tasks.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(width: showPreview
                       ? PreviewConfig.listWidth
                       : PreviewConfig.listWidth + PreviewConfig.sidebarWidth + 1,
                       alignment: .leading)
                .frame(minHeight: 180, maxHeight: 500)

                if showPreview {
                    Divider()

                    AssetPreviewPane(task: focusedTask)
                        .frame(width: PreviewConfig.sidebarWidth)
                        .frame(minHeight: 180, maxHeight: 500)
                }
            }
            
            Divider()
            
            // Status bar showing full file path of focused item
            HStack(spacing: 4) {
                if let focusedTask {
                    Image(systemName: "folder.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(focusedTask.filePath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(focusedTask.filePath)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Update") {
                    onUpdate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedCount == 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: PreviewConfig.listWidth + PreviewConfig.sidebarWidth + 1)
        .onAppear {
            showPreview = settingsManager.plexShowAssetPreview
            if showPreview, let firstTask = tasks.first {
                focusedTaskId = firstTask.id
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPreview)
    }
    
    // MARK: - Helpers
    
    private func toggleAll() {
        let newValue = !allSelected
        for task in tasks {
            selections[task.id] = newValue
        }
    }
    
    private func togglePreview() {
        showPreview.toggle()
        settingsManager.plexShowAssetPreview = showPreview
        settingsManager.saveSettings()
        
        // Auto-select first item when enabling preview
        if showPreview, focusedTaskId == nil, let firstTask = tasks.first {
            focusedTaskId = firstTask.id
        }
    }
}

// MARK: - Asset Selection Row

private struct AssetSelectionRow: View {
    let task: AssetUploadTask
    let isFocused: Bool
    @Binding var isChecked: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $isChecked) {
                EmptyView()
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            
            Image(systemName: iconName(for: task.type))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.displayName)
                    .font(.body)
                
                Text((task.filePath as NSString).lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(isFocused ? Color.accentColor.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private func iconName(for type: AssetType) -> String {
        switch type {
        case .showPoster, .moviePoster, .seasonPoster:
            return "photo.fill"
        case .showBackdrop, .movieBackdrop:
            return "photo.on.rectangle.fill"
        case .episodeTitleCard:
            return "tv.fill"
        case .logo:
            return "textformat"
        case .squareArt:
            return "square.fill"
        }
    }
}

// MARK: - Asset Preview Pane

private struct AssetPreviewPane: View {
    let task: AssetUploadTask?
    @State private var previewImage: NSImage?
    @State private var isLoading = false
    @State private var currentPath: String?
    @State private var imageDimensions: String?
    @State private var fileSize: String?
    
    var body: some View {
        VStack {
            Spacer()
            
            if let task {
                if let previewImage {
                    let size = previewFrameSize(for: task.type)
                    
                    Image(nsImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: size.width, maxHeight: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: PreviewConfig.cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PreviewConfig.cornerRadius, style: .continuous)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Text(task.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    
                    Text((task.filePath as NSString).lastPathComponent)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 12)
                    
                    if let imageDimensions {
                        Text(imageDimensions)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if let fileSize {
                        Text(fileSize)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                } else if isLoading {
                    ProgressView()
                        .controlSize(.small)
                    
                    Text("Loading preview...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    
                    Text("No preview")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.quaternary)
                
                Text("Select an item")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onChange(of: task?.id) { _, _ in
            loadPreview()
        }
        .onAppear {
            loadPreview()
        }
    }
    
    private func loadPreview() {
        guard let task else {
            previewImage = nil
            currentPath = nil
            imageDimensions = nil
            fileSize = nil
            return
        }
        
        let path = task.filePath
        guard path != currentPath else { return }
        
        currentPath = path
        previewImage = nil
        imageDimensions = nil
        fileSize = nil
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            let image = ThumbnailGenerator.generateThumbnail(
                atPath: path,
                maxPixelSize: PreviewConfig.maxPixelSize
            )
            
            // Get original image dimensions from source (without decoding)
            let dimensions = ThumbnailGenerator.imageDimensions(atPath: path)
            
            // Get file size
            let size = ThumbnailGenerator.formattedFileSize(atPath: path)
            
            await MainActor.run {
                // Only apply if still the current path
                if currentPath == path {
                    previewImage = image
                    imageDimensions = dimensions
                    fileSize = size
                    isLoading = false
                }
            }
        }
    }
    
    private func previewFrameSize(for type: AssetType) -> CGSize {
        let maxDimension = PreviewConfig.maxPixelSize
        
        switch type {
        case .showPoster, .moviePoster, .seasonPoster:
            let height = maxDimension
            let width = height * (2.0 / 3.0)
            return CGSize(width: width, height: height)
            
        case .showBackdrop, .movieBackdrop, .episodeTitleCard:
            let width = maxDimension
            let height = width * (9.0 / 16.0)
            return CGSize(width: width, height: height)
            
        case .logo:
            let width = maxDimension
            let height = width * (9.0 / 16.0)
            return CGSize(width: width, height: height)
            
        case .squareArt:
            return CGSize(width: maxDimension, height: maxDimension)
        }
    }
}

// MARK: - Thumbnail Generator

enum ThumbnailGenerator {
    /// Generate a thumbnail from a local file path using CGImageSource.
    /// Returns nil if the file cannot be read or decoded.
    static func generateThumbnail(atPath path: String, maxPixelSize: CGFloat) -> NSImage? {
        let url = URL(fileURLWithPath: path)
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize),
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    /// Get original image dimensions without decoding the full image.
    static func imageDimensions(atPath path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        
        return "\(width) × \(height)"
    }
    
    /// Get formatted file size string.
    static func formattedFileSize(atPath path: String) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let bytes = attributes[.size] as? Int64 else {
            return nil
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview

#Preview {
    PlexAssetSelection(
        mediaTitle: "Breaking Bad (2008)",
        settingsManager: SettingsManager(),
        tasks: .constant([
            AssetUploadTask(
                type: .showPoster,
                filePath: "/path/to/poster.png",
                ratingKey: "123",
                displayName: "Show Poster"
            ),
            AssetUploadTask(
                type: .showBackdrop,
                filePath: "/path/to/background.jpg",
                ratingKey: "123",
                displayName: "Show Backdrop"
            ),
            AssetUploadTask(
                type: .logo,
                filePath: "/path/to/logo.png",
                ratingKey: "123",
                displayName: "Show Logo"
            ),
            AssetUploadTask(
                type: .seasonPoster,
                filePath: "/path/to/Season01.png",
                ratingKey: "124",
                displayName: "Season 01 Poster"
            ),
            AssetUploadTask(
                type: .episodeTitleCard,
                filePath: "/path/to/S01E01.png",
                ratingKey: "125",
                displayName: "S01E01"
            )
        ]),
        selections: .constant([:]),
        includeUHD: .constant(false),
        onToggleUHD: {},
        onUpdate: {},
        onCancel: {}
    )
}
