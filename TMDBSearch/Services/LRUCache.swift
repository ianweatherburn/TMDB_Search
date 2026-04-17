//
//  LRUCache.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2026/04/17.
//

import Foundation

// MARK: - LRU Cache

/// A generic LRU (Least Recently Used) cache implemented as an actor for thread safety.
actor LRUCache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private(set) var capacity: Int

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    func get(_ key: Key) -> Value? {
        guard let value = storage[key] else { return nil }
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        return value
    }

    func set(_ key: Key, value: Value) {
        if storage[key] != nil {
            accessOrder.removeAll { $0 == key }
        } else if storage.count >= capacity {
            if let evicted = accessOrder.first {
                accessOrder.removeFirst()
                storage.removeValue(forKey: evicted)
            }
        }
        storage[key] = value
        accessOrder.append(key)
    }

    func resize(to newCapacity: Int) {
        capacity = max(1, newCapacity)
        while storage.count > capacity {
            if let evicted = accessOrder.first {
                accessOrder.removeFirst()
                storage.removeValue(forKey: evicted)
            }
        }
    }

    func clear() {
        storage.removeAll()
        accessOrder.removeAll()
    }

    var count: Int { storage.count }
}

// MARK: - Cache Key Types

struct SearchCacheKey: Hashable, Sendable {
    let query: String
    let mediaType: MediaType
}

struct ImageMetadataCacheKey: Hashable, Sendable {
    let itemId: Int
    let mediaType: MediaType
    let languages: [String]
}

struct ThumbnailCacheKey: Hashable, Sendable {
    let path: String
    let size: String
}
