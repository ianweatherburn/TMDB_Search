//
//  StatusMessage.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//

import SwiftUI

// MARK: - Status Message View
struct StatusMessage: View {
    let icon: String
    let message: String
    let style: MessageStyle
    
    enum MessageStyle {
        case error, loading, info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .loading: return .blue
            case .info: return .secondary
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if style == .loading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .foregroundStyle(style.color)
                        .font(.system(size: 16))
                }
            }
            
            Text(message)
                .foregroundStyle(style.color)
                .font(.system(size: 13))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style.color.opacity(0.3), lineWidth: 1)
        )
    }
}
