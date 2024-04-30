//
//  SessionEndMonitor.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import UIKit

class SessionEndMonitor {
    static let shared = SessionEndMonitor()
    private var startTime: Date?
    private let minimumActiveTime: TimeInterval = 5
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive), 
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc private func appDidBecomeActive() {
        startTime = Date()
    }
    
    @objc private func appDidEnterBackground() {
        if ConfigurationManager.shared.postSessionNotifEnabled == false {
            return
        }
        
        if Date().timeIntervalSince(startTime ?? Date()) < minimumActiveTime {
            return
        }
        
        // Initiate a background task when the app goes into the background.
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            // This block is executed when the background time is about to expire.
            self?.endBackgroundTask()
        }
        
        fireNotification { [weak self] success in
            // Network sync completed, end the background task.
            self?.endBackgroundTask()
            Logger.shared.log("Background notification sent. Success: \(success)")
        }
    }
    
    private func fireNotification(completion: @escaping (Bool) -> Void) {
        NotificationManager.checkNotificationAuthorization { enabled in
            if enabled {
                DispatchQueue.global(qos: .background).async {
                    NotificationManager.triggerSessionEndNotif(completion: completion)
                }
            }
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
    }
}
