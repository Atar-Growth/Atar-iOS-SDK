//
//  StatsRecorder.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import Foundation

struct StatKeys {
    static let id = "id"
    static let event = "event"
    static let time = "time"
    static let value = "value"
    static let metadata = "metadata"
}


class StatsRecorder {
    
    static let shared = StatsRecorder()
    private let queue = DispatchQueue(label: "com.atargrowth.statsrecorder", attributes: .concurrent)
    private let defaults = UserDefaults.standard
    private let statsKey = "atarStoredStats"
    
    private init() {
        loadPersistentStats()
    }
    
    private var stats: [[String: Any]] = []
    
    // Adds a new stat object
    func add(event: String, value: Int, metadata: [String: Any]) {
        queue.async(flags: .barrier) {
            let dateFormatter = ISO8601DateFormatter()
            
            let newStat: [String: Any] = [
                StatKeys.id: UUID().uuidString,
                StatKeys.event: event,
                StatKeys.value: value,
                StatKeys.time: dateFormatter.string(from: Date()),
                StatKeys.metadata: metadata
            ]
            
            self.stats.append(newStat)
            self.savePersistentStats()
        }
    }
    
    // Retrieves all stored stat objects
    func getAll() -> [[String: Any]] {
        queue.sync {
            stats
        }
    }
    
    // Clears specified stats by their IDs
    func clearIds(_ ids: [String]) {
        queue.async(flags: .barrier) {
            self.stats.removeAll { stat in
                guard let id = stat[StatKeys.id] as? String else { return false }
                return ids.contains(id)
            }
            self.savePersistentStats()
        }
    }
    
    // Load stats from UserDefaults
    private func loadPersistentStats() {
        queue.async(flags: .barrier) {
            if let savedStats = self.defaults.array(forKey: self.statsKey) as? [[String: Any]] {
                self.stats = savedStats
            }
        }
    }
    
    // Save stats to UserDefaults
    private func savePersistentStats() {
        defaults.set(stats, forKey: statsKey)
    }
}
