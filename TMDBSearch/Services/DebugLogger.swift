//
//  DebugLogger.swift
//  TMDB Search
//
//  Created by Codex on 2026/02/22.
//

import Foundation

enum DebugLogger {
    static let plexDebugLoggingKey = "PlexDebugLogging"

    static func log(_ message: @autoclosure () -> String) {
        guard UserDefaults.standard.bool(forKey: plexDebugLoggingKey) else { return }
        print(message())
    }
}
