//
//  SettingsManager.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import Foundation
import Security

// MARK: - Settings Manager
@Observable
final class SettingsManager {
    
    // MARK: - Properties
    var downloadPath: DownloadPath = DownloadPath(primary: "", backup: nil)
    var gridSize: GridSize = Constants.Configure.Preferences.gridSize
    var maxHistoryItems: Int = Constants.Configure.Preferences.History.size
    var searchHistory: [SearchHistoryItem] = []
    
    // MARK: - Keychain Keys
    private enum KeychainKeys {
        static let tmdbAPIKey = "com.tmdbsearch.apikey"
    }
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let downloadPath = "DownloadPath"
        static let downloadPathBackup = "DownloadPathBackup"
        static let gridSize = "GridSize"
        static let maxHistoryItems = "MaxHistoryItems"
        static let searchHistory = "SearchHistory"
    }
    
    struct DownloadPath {
        var primary: String = ""
        var backup: String?
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        loadDownloadPaths()
        loadGridSize()
        loadMaxHistoryItems()
        loadSearchHistory()
    }
    
    func saveSettings() {
        saveDownloadPaths()
        saveGridSize()
        saveMaxHistoryItems()
        saveSearchHistory()
    }
    
    // MARK: - Download Paths
    private func loadDownloadPaths() {
        downloadPath.primary = UserDefaults.standard.string(forKey: UserDefaultsKeys.downloadPath)
            ?? NSHomeDirectory() + "/Downloads/TMDB"
        downloadPath.backup = UserDefaults.standard.string(forKey: UserDefaultsKeys.downloadPathBackup)
    }
    
    private func saveDownloadPaths() {
        UserDefaults.standard.set(downloadPath.primary, forKey: UserDefaultsKeys.downloadPath)
        UserDefaults.standard.set(downloadPath.backup, forKey: UserDefaultsKeys.downloadPathBackup)
    }
    
    // MARK: - Grid Size
    private func loadGridSize() {
        if let gridSizeRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.gridSize),
           let loadedGridSize = GridSize(rawValue: gridSizeRaw) {
            self.gridSize = loadedGridSize
        }
    }
    
    private func saveGridSize() {
        UserDefaults.standard.set(gridSize.rawValue, forKey: UserDefaultsKeys.gridSize)
    }
    
    // MARK: - Max History Items
    private func loadMaxHistoryItems() {
        maxHistoryItems = UserDefaults.standard.integer(forKey: UserDefaultsKeys.maxHistoryItems)
        if maxHistoryItems == 0 {
            maxHistoryItems = Constants.Configure.Preferences.History.size // Default value
        }
    }
    
    private func saveMaxHistoryItems() {
        UserDefaults.standard.set(maxHistoryItems, forKey: UserDefaultsKeys.maxHistoryItems)
    }
    
    // MARK: - Search History Management
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.searchHistory),
           let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            searchHistory = history
        }
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.searchHistory)
        }
    }
    
    func addToSearchHistory(searchText: String, mediaType: MediaType) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Remove any existing entry with the same search text and media type
        searchHistory.removeAll { $0.searchText.lowercased() == trimmedText.lowercased() && $0.mediaType == mediaType }

        // Add new item to the beginning
        let newItem = SearchHistoryItem(searchText: trimmedText, mediaType: mediaType)
        searchHistory.insert(newItem, at: 0)

        // Maintain maximum history size
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }

        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        saveSearchHistory()
    }
    
    // MARK: - Keychain Management for API Key
    var apiKey: String {
        get {
            return getKeychainValue(for: KeychainKeys.tmdbAPIKey) ?? ""
        }
        set {
            if newValue.isEmpty {
                deleteKeychainValue(for: KeychainKeys.tmdbAPIKey)
            } else {
                setKeychainValue(newValue, for: KeychainKeys.tmdbAPIKey)
            }
        }
    }
    
    private func setKeychainValue(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Error storing keychain item: \(status)")
        }
    }
    
    private func getKeychainValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteKeychainValue(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
