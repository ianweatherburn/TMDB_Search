//
//  EmptyState.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI
import SFSymbol

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.secondary, .quaternary)
            
            VStack(spacing: 8) {
                Text("No Images Available")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("There are no images of this type for this item")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
