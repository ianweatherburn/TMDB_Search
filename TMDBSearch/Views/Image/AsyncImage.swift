//
//  AsyncImage.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Async Image Helper
struct AsyncImage<Content: View>: View {
    let image: NSImage?
    let type: ImageType
    let content: () -> Content
    var width: CGFloat {
        switch type {
        case .poster: return Constants.Image.Poster.width
        case .backdrop: return Constants.Image.Backdrop.width
        case .logo: return Constants.Image.Logo.width
        }
    }
    var height: CGFloat {
        switch type {
        case .poster: return Constants.Image.Poster.height
        case .backdrop: return Constants.Image.Backdrop.height
        case .logo: return Constants.Image.Logo.height
        }
    }

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            } else {
                content()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
    }
}
