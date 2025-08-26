//
//  AppDelegates.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    let fileManager = UnifiedFileManager()
    
    func applicationDidFinishLaunching(_ _: Notification) {
        // File manager automatically tries to restore previous directory access
        if fileManager.hasDirectoryAccess {
            print("✅ Restored access to: \(fileManager.selectedDirectory?.path ?? "Unknown")")
        } else {
            print("ℹ️ No previous directory access found")
        }
    }
    
//    func applicationWillTerminate(_ notification: Notification) {
//        // Any cleanup if needed
//    }
}
