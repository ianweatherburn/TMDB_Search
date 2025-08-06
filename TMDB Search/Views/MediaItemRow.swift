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
        RightClickableView {
            HStack(alignment: .top, spacing: 12) {
                // Poster Thumbnail
                AsyncImage(image: posterImage) {
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
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.mint.opacity(0.9), .mint.opacity(0.5))
                }
                .buttonStyle(.borderless)
                .help("Choose a backdrop...")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .onTapGesture {
                // Copy Plex formatted name with title and tmdb-id to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("\(item.plexTitle)", forType: .string)
                NSSound.beep()
            }
            .sheet(isPresented: $showingPosterDialog) {
                ImageGalleryView(
                    item: item,
                    mediaType: appModel.selectedMediaType,
                    imageType: .poster,
                )
                .environment(appModel)
            }
            .sheet(isPresented: $showingBackdropDialog) {
                ImageGalleryView(
                    item: item,
                    mediaType: appModel.selectedMediaType,
                    imageType: .backdrop,
                )
                .environment(appModel)
            }
        } onRightClick: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(String(item.id), forType: .string)
            NSSound.beep()
        }
    }
}

struct RightClickableView<Content: View>: NSViewRepresentable {
    let content: Content
    let onRightClick: () -> Void

    init(@ViewBuilder content: () -> Content, onRightClick: @escaping () -> Void) {
        self.content = content()
        self.onRightClick = onRightClick
    }

    func makeNSView(context: Context) -> NSHostingView<Content> {
        let hostingView = NSHostingView(rootView: content)
        let rightClick = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRightClick(_:)))
        rightClick.buttonMask = 0x2 // Right mouse button
        hostingView.addGestureRecognizer(rightClick)
        return hostingView
    }

    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRightClick: onRightClick)
    }

    class Coordinator: NSObject {
        let onRightClick: () -> Void

        init(onRightClick: @escaping () -> Void) {
            self.onRightClick = onRightClick
        }

        @objc func handleRightClick(_ sender: NSClickGestureRecognizer) {
            onRightClick()
        }
    }
}
