//
//  String.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/08.
//

extension String {
    var replacingColonsWithDashes: String {
        self.replacingOccurrences(of: ":", with: " -")
    }
    
    /// Convert all apostrophe variants to ASCII straight apostrophe (U+0027)
    var normalizingApostrophes: String {
        self.replacingOccurrences(of: "\u{2019}", with: "\u{0027}")  // Right single quotation mark -> ASCII apostrophe
            .replacingOccurrences(of: "\u{2018}", with: "\u{0027}")  // Left single quotation mark -> ASCII apostrophe
            .replacingOccurrences(of: "\u{02BC}", with: "\u{0027}")  // Modifier letter apostrophe -> ASCII apostrophe
    }
    
    /// Convert ASCII apostrophes to curly right apostrophe (U+2019)
    var withCurlyApostrophes: String {
        self.replacingOccurrences(of: "\u{0027}", with: "\u{2019}")  // ASCII apostrophe -> Right single quotation mark
    }
}
