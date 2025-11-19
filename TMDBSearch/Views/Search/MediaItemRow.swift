////
////  MediaItemRow.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI
import SFSymbol

// MARK: - Media Item Row
struct MediaItemRow: View {
    let item: TMDBMediaItem
    let type: MediaType
    @Environment(AppModel.self) private var appModel
    @State private var posterImage: NSImage?
    @State private var backdropImage: NSImage?
    @State private var showingPosterDialog = false
    @State private var showingBackdropDialog = false
    
    private var mediaPopover: String {
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
            contentRow(for: item, type: type)

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
                //
                // Tap: Copy the media name followed by the year (ie "The Matrix (1999)"
                // Cmd+Click: Copy the media name only (ie "The Matrix)
                // Opt+Click: Copy the media TMDB-ID (ie 603)
                // Ctrl+Click: Copy the full update-poster script command
                //
                .onTapGesture {
                    if NSEvent.modifierFlags.contains(.option) {
                        appModel.copyToClipboard(item, element: .id, type: type)
                    } else if NSEvent.modifierFlags.contains(.control) {
                        appModel.copyToClipboard(item, element: .updatePoster, type: type)
                    } else if NSEvent.modifierFlags.contains(.command) {
                        appModel.copyToClipboard(item, element: .name, type: type)
                    } else {
                        appModel.copyToClipboard(item, element: .folder, type: type)
                    }
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
    private func contentRow(for item: TMDBMediaItem, type: MediaType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.formattedTitle.replacingColonsWithDashes)
                    .font(.headline)
                    .lineLimit(2)
                    .textSelection(.enabled)
                    .help(Constants.App.Help.tapHelp)
                
                Spacer()
                
                if appModel.settingsManager.showTMDBID {
                    Text("\(item.id)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(.leading, 8)
                        .help("TMDB-ID")
                }
            }

            Text(item.overview)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .allowsHitTesting(false)
                .help(Constants.App.Help.tapHelp)

            Spacer()
            
            contentRowFunctions(for: item, type: type)
        }
    }
    
    @ViewBuilder
    private func contentRowFunctions(for item: TMDBMediaItem, type: MediaType) -> some View {
        HStack {
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    appModel.copyToClipboard(item, element: .name, type: type)
                }, label: {
                    Image(symbol: SFSymbol6.Pencil.pencilCircle)
                })
                .buttonStyle(PlainButtonStyle())
                .help(Constants.Media.Actions.Tooltip.name)
                
                Button(action: {
                    appModel.copyToClipboard(item, element: .folder)
                }, label: {
                    Image(symbol: SFSymbol6.Folder.folderCircle)
                })
                .buttonStyle(PlainButtonStyle())
                .help(Constants.Media.Actions.Tooltip.folder)
                
                Button(action: {
                    appModel.copyToClipboard(item, element: .id)
                }, label: {
                    Image(symbol: SFSymbol6.Number.numberCircle)
                })
                .buttonStyle(PlainButtonStyle())
                .help(Constants.Media.Actions.Tooltip.id)
                
                Button(action: {
                    appModel.copyToClipboard(item, element: .updatePoster, type: type)
                }, label: {
                    Image(symbol: SFSymbol6.Figure.figureRunCircle)
                })
                .buttonStyle(PlainButtonStyle())
                .help(Constants.Media.Actions.Tooltip.updatePoster)

/*
                Button(action: {
                    // Action for updating Plex Server metadata
                    // You'll need to implement this action
                }, label: {
                    Image(symbol: SFSymbol6.Film.filmCircle)
                })
                .buttonStyle(PlainButtonStyle())
                .help(Constants.Media.Action.Tooltip.updatePlex)
 */
            }
            .font(.title)

        }
    }
}
