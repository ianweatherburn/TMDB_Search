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
}
