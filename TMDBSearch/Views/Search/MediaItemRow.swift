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
    let type: MediaType
    @Environment(AppModel.self) private var appModel
    @State private var posterImage: NSImage?
    @State private var backdropImage: NSImage?
    @State private var showingPosterDialog = false
    @State private var showingBackdropDialog = false
    
    var mediaPopover: String {
        let type = String(describing: type.displayInfo.title)
        return "\(String(type.dropLast()).lowercased()) '\(item.formattedTitle)'."
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster Thumbnail
            AsyncImage(image: posterImage, type: .poster) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: Constants.Image.Poster.width, height: Constants.Image.Poster.height)
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
            .help("Show all posters for the \(mediaPopover)")
            
            // Content
            contentRow(for: item)
            
            Spacer()
            
            // Backdrop Thumbnail
            VStack {
                Spacer()
                AsyncImage(image: backdropImage, type: .backdrop) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: Constants.Image.Backdrop.width, height: Constants.Image.Backdrop.height)
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
                .help("Show all backdrops for the \(mediaPopover)")
                Spacer()
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle()) // make the whole row tappable
                .onTapGesture {
                    appModel.copyToClipboard(item, idOnly: NSEvent.modifierFlags.contains(.option))
                }
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .cornerRadius(8)
        .sheet(isPresented: $showingPosterDialog) {
            ImageGallery(
                item: item,
                mediaType: appModel.selectedMediaType,
                imageType: .poster
            )
            .environment(appModel)
        }
        .sheet(isPresented: $showingBackdropDialog) {
            ImageGallery(
                item: item,
                mediaType: appModel.selectedMediaType,
                imageType: .backdrop
            )
            .environment(appModel)
        }
    }
    
    @ViewBuilder
    private func contentRow(for item: TMDBMediaItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.formattedTitle.replacingColonsWithDashes)
                    .font(.headline)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .help(Constants.App.Help.tapHelp)
                
                Spacer()
                
                Text("\(item.id)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                    .padding(.leading, 8)
                    .help("TMDB-ID")
            }

            Text(item.overview)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .allowsHitTesting(false)
                .help(Constants.App.Help.tapHelp)

            Spacer()
        }
    }
}
