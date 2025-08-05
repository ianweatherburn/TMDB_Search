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
    let content: () -> Content
    
    var body: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
        } else {
            content()
        }
    }
}
