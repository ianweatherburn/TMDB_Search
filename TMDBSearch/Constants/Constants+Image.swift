//
//  Constants+Image.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import Foundation

// swiftlint:disable nesting

// Image Display Constants
extension Constants.Image {
    enum Poster {
        static let ratio: CGFloat = 2.0 / 3.0 // Typical movie poster ratio
        static let width: CGFloat = 100
        static let height: CGFloat = width / ratio
        static let spacing: CGFloat = 12
        enum Gallery {
            enum Count {
                static let small = 8
                static let medium = 6
                static let large = 5
                static let huge = 4
            }
        }
    }
    enum Backdrop {
        static let ratio: CGFloat = 16.0 / 9.0 // Widescreen ratio for backdrops
        static let height: CGFloat = 100
        static let width: CGFloat = height * ratio
        static let spacing: CGFloat = 12
        enum Gallery {
            enum Count {
                static let small = 5
                static let medium = 4
                static let large = 3
                static let huge = 2
            }
        }
    }
    enum Gallery {
        static let width: CGFloat = 1_366
        static let height: CGFloat = 768
        static let scaleEffect: CGFloat = 1.04
    }
    enum Types {
        static let poster = "poster.jpg"
        static let backdrop = "backdrop.jpg"
    }
}

// swiftlint:enable nesting
