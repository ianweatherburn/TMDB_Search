//
//  Bundle.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//
import Foundation

extension Bundle {
    var appDisplayTitle: String {
        infoDictionary?["CFBundleDescription"] as? String ?? "TMDB Search"
    }
    
    var version: String {
        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") " +
        "(\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))"
    }
}
