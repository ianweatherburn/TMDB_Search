//
//  ImageGridItem.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Image Grid Item
struct ImageGridItem: View {
    let image: TMDBImage
    let loadedImage: NSImage?
    let imageType: ImageType  // Back to ImageType enum
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Main image
                if let loadedImage = loadedImage {
                    Image(nsImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.quaternary)
                        .aspectRatio(aspectRatioForImageType, contentMode: .fit)
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                }
                
                // Overlay with image info
                if loadedImage != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            // Resolution badge
                            Text("\(image.width)×\(image.height)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                                .opacity(isHovered ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: isHovered)
                           
                        }
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.primary.opacity(isHovered ? 0.3 : 0), lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var aspectRatioForImageType: CGFloat {
        switch imageType {
        case .poster: return Constants.Image.Poster.ratio
        case .backdrop: return Constants.Image.Backdrop.ratio
        }
    }
}
