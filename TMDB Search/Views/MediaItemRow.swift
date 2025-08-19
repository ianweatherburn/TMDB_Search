////
////  MediaItemRow.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI

// MARK: - Media Item Row
struct MediaItemRow: View {
    let item: TMDBMediaItem
    @Environment(AppModel.self) private var appModel
    @State private var posterImage: NSImage?
    @State private var backdropImage: NSImage?
    @State private var showingPosterDialog = false
    @State private var showingBackdropDialog = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster Thumbnail
            AsyncImage(image: posterImage, type: .poster) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 140)
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
                posterImage = await appModel.loadImage(for: item, as: .poster)
            }
            .help("Choose a poster...")
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(item.plexTitle.replacingColonsWithDashes)
                    .font(.headline)
                    .lineLimit(2)
                    .textSelection(.enabled)
                
                Text(item.overview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                
                Spacer()
            }
            
            Spacer()
            
            // Backdrop Thumbnail
            VStack {
                Spacer()
                AsyncImage(image: backdropImage, type: .backdrop) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 100)
                        .overlay {
                            if backdropImage == nil {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        }
                }
                .onTapGesture {
                    showingBackdropDialog = true
                }
                .task {
                    backdropImage = await appModel.loadImage(for: item, as: .backdrop)
                }
                .help("Choose a backdrop...")
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture(count: 1, perform: { position in
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            // Check for option key (⌥) modifier
            if NSEvent.modifierFlags.contains(.option) {
                // Copy TMDB ID only
                pasteboard.setString(String(item.id), forType: .string)
                _ = NSSound(named: NSSound.Name("Ping"))?.play()
            } else {
                // Copy Plex formatted name with title and tmdb-id
                pasteboard.setString("\(item.plexTitle.replacingColonsWithDashes)", forType: .string)
                _ = NSSound(named: NSSound.Name("Glass"))?.play()
            }
        })
        .sheet(isPresented: $showingPosterDialog) {
            ImageGalleryView(
                item: item,
                mediaType: appModel.selectedMediaType,
                imageType: .poster
            )
            .environment(appModel)
        }
        .sheet(isPresented: $showingBackdropDialog) {
            ImageGalleryView(
                item: item,
                mediaType: appModel.selectedMediaType,
                imageType: .backdrop
            )
            .environment(appModel)
        }
    }
}


