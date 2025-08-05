//
//  MediaItemRow.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Media Item Row
struct MediaItemRow: View {
    let item: TMDBMediaItem
    @Environment(AppModel.self) private var appModel
    @State private var posterImage: NSImage?
    @State private var showingPosterDialog = false
    @State private var showingBackdropDialog = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster Thumbnail
            AsyncImage(image: posterImage) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 120)
                    .overlay {
                        if posterImage == nil {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
            }
            .onTapGesture {
                showingPosterDialog = true
            }
            .task {
                posterImage = await appModel.loadPosterImage(for: item)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(item.formattedTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.overview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                
                Spacer()
            }
            
            Spacer()
            
            // Backdrop Button
            Button(action: {
                showingBackdropDialog = true
            }) {
                Image(systemName: "photo.artframe")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
            .help("Load backdrops")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture {
            // Copy TMDB ID to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(String(item.id), forType: .string)
            NSSound.beep()
        }
        .sheet(isPresented: $showingPosterDialog) {
            ImageGalleryView(
                itemId: item.id,
                mediaType: appModel.selectedMediaType,
                imageType: .poster,
                title: "Posters - \(item.displayTitle)"
            )
            .environment(appModel)
        }
        .sheet(isPresented: $showingBackdropDialog) {
            ImageGalleryView(
                itemId: item.id,
                mediaType: appModel.selectedMediaType,
                imageType: .backdrop,
                title: "Backdrops - \(item.displayTitle)"
            )
            .environment(appModel)
        }
    }
}
