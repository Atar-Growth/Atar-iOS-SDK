//
//  FrequencyCapTracker.swift
//
//
//  Created by Alex Austin on 4/3/24.
//
import Foundation

class FrequencyCapTracker {
    
    static let shared = FrequencyCapTracker()
    
    private let defaults = UserDefaults.standard
    private let sentNotificationsKey = "atarSentNotificationsCount"
    private let showedInterstitialKey = "atarShowedInterstitial"
    
    private init() {}
    
    func incrementNotificationCount() {
        let today = startOfDay(for: Date())
        
        var count = 0
        if let lastSentDate = ConfigurationManager.shared.lastNotificationDate as? Date, startOfDay(for: lastSentDate) == today {
            count = defaults.integer(forKey: sentNotificationsKey)
        }
        
        count += 1
        defaults.set(count, forKey: sentNotificationsKey)
    }
    
    func incrementInterstitialCount() {
        let today = startOfDay(for: Date())
        
        var count = 0
        if let lastSentDate = ConfigurationManager.shared.lastInterstitialDate as? Date, startOfDay(for: lastSentDate) == today {
            count = defaults.integer(forKey: showedInterstitialKey)
        }
        
        count += 1
        defaults.set(count, forKey: showedInterstitialKey)
    }
    
    func canSendNotification() -> Bool {
        let today = startOfDay(for: Date())
        
        if let lastSentDate = ConfigurationManager.shared.lastNotificationDate as? Date, startOfDay(for: lastSentDate) == today {
            let count = defaults.integer(forKey: sentNotificationsKey)
            return count < ConfigurationManager.shared.notifFrequencyCap
        }
        
        // No notifications sent today or date mismatch; can send
        return true
    }
    
    func canShowInterstitial() -> Bool {
        let today = startOfDay(for: Date())
        
        if let lastSentDate = ConfigurationManager.shared.lastInterstitialDate as? Date, startOfDay(for: lastSentDate) == today {
            let count = defaults.integer(forKey: showedInterstitialKey)
            return count < ConfigurationManager.shared.notifFrequencyCap
        }
        
        // No notifications sent today or date mismatch; can send
        return true
    }
    
    private func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
}
