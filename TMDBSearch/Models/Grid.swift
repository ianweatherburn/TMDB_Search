//
//  Grid.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/25.
//

// MARK: - Grid Size Enum
enum GridSize: String, CaseIterable, Identifiable, Equatable {
    case tiny
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny:
            return "Tiny"
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        }
    }

    var helpText: String {
        switch self {
        case .tiny:
            return "Show more items in a smaller grid layout"
        case .small:
            return "Show items in a medium-sized grid layout"
        case .medium:
            return "Show fewer items in a larger grid layout"
        case .large:
            return "Show items in the largest grid layou"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .tiny:
            return "1"
        case .small:
            return "2"
        case .medium:
            return "3"
        case .large:
            return "4"
        }
    }

    func columnCount(for imageType: ImageType) -> Int {
        switch imageType {
        case .poster:
            switch self {
            case .tiny:  return Constants.Image.Poster.Gallery.Count.small
            case .small: return Constants.Image.Poster.Gallery.Count.medium
            case .medium:  return Constants.Image.Poster.Gallery.Count.large
            case .large:   return Constants.Image.Poster.Gallery.Count.huge
            }
        case .backdrop:
            switch self {
            case .tiny:  return Constants.Image.Backdrop.Gallery.Count.small
            case .small: return Constants.Image.Backdrop.Gallery.Count.medium
            case .medium:  return Constants.Image.Backdrop.Gallery.Count.large
            case .large:   return Constants.Image.Backdrop.Gallery.Count.huge
            }
        }
    }
}
