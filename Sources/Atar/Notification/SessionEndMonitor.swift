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
    private var didBackground = true
    public var justClicked = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let queue = DispatchQueue(label: "com.atar.sessionmonitor", qos: .utility)

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
        Logger.shared.log("App became active")
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.didBackground {
                return
            }
            self.justClicked = false
            self.didBackground = false
            
            // Set startTime on our queue to avoid main queue dependency
            self.startTime = Date()
            
            ConfigurationManager.shared.sessionCount += 1
            
            // Ensure interval is never 0 to prevent division by zero crashes
            let messageInterval = ConfigurationManager.shared.midSessionMessageSessionInterval
            if messageInterval == 0 {
                Logger.shared.log("Mid session message interval not initialized, setting default")
                ConfigurationManager.shared.midSessionMessageSessionInterval = 2
            }
            
            // Double-check the value before modulo operation
            let finalInterval = ConfigurationManager.shared.midSessionMessageSessionInterval
            guard finalInterval > 0 else {
                Logger.shared.log("Mid session message interval still 0, skipping to prevent crash")
                return
            }
            
            if ConfigurationManager.shared.sessionCount % finalInterval == 0 {
                let messageDelay = ConfigurationManager.shared.midSessionMessageDelay/1000
                Logger.shared.log("Mid session message eligible, scheduling for " + String(messageDelay) + " seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(messageDelay)) { [weak self] in
                    guard let self = self else { return }
                    self.queue.async {
                        if self.didBackground {
                            self.didBackground = false
                            return
                        }
                        Logger.shared.log("Mid session message sent")
                        DispatchQueue.main.async {
                            let offerRequest = OfferRequest()
                            offerRequest.event = "auto_message"
                            Atar.shared?.showOfferMessage(request: offerRequest)
                        }
                    }
                }
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        Logger.shared.log("App entered background")
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.didBackground = true
            if self.justClicked {
                self.justClicked = false
                return
            }
            
            // Check if we already have a background task running
            if self.backgroundTask != .invalid {
                Logger.shared.log("Background task already running, skipping")
                return
            }
            
            if ConfigurationManager.shared.sessionCount < ConfigurationManager.shared.postSessionNotifMinSessionCount {
                Logger.shared.log("Post session notif not sent. Session count less than minimum.")
                return
            }
            
            // Double-check interval value before modulo operation to prevent crashes
            let sessionInterval = ConfigurationManager.shared.postSessionNotifSessionInterval
            guard sessionInterval > 0 else {
                Logger.shared.log("Post session notif interval is 0, config not initialized properly")
                return
            }
            
            if ConfigurationManager.shared.postSessionNotifEnabled == false {
                Logger.shared.log("Post session notif not enabled.")
                return
            }
            
            if ConfigurationManager.shared.sessionCount % sessionInterval != 0 {
                Logger.shared.log("Post session notif not sent. Session interval not reached.")
                return
            }
            
            // Access startTime safely without main queue dependency
            let currentStartTime = self.startTime
            if Int(Date().timeIntervalSince(currentStartTime ?? Date())) < ConfigurationManager.shared.postSessionNotifMinActiveTime/1000 {
                Logger.shared.log("Post session notif not sent. Min active time not reached.")
                return
            }
            
            // Background task creation MUST be on main queue (iOS requirement)
            // But we'll do it without blocking our background queue
            let backgroundTaskCreation = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                self.backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                    // This block is executed when the background time is about to expire.
                    Logger.shared.log("Background task expiring, cleaning up")
                    self?.endBackgroundTask()
                }
                
                guard self.backgroundTask != .invalid else {
                    Logger.shared.log("Failed to start background task")
                    return
                }
                
                Logger.shared.log("Background task started successfully")
                
                // Now execute the notification logic on background queue
                self.queue.async { [weak self] in
                    self?.fireNotification { [weak self] success in
                        // Network sync completed, end the background task.
                        self?.endBackgroundTask()
                        Logger.shared.log("Background notification sent. Success: \(success)")
                    }
                }
            }
            
            // Try to execute on main queue, but with timeout protection
            if Thread.isMainThread {
                backgroundTaskCreation.perform()
            } else {
                DispatchQueue.main.async(execute: backgroundTaskCreation)
                
                // Fallback: if main queue is stuck, at least try to fire notification
                // after a brief delay (though without background task protection)
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    if self.backgroundTask == .invalid {
                        Logger.shared.log("Background task creation may have failed, attempting notification anyway")
                        self.fireNotification { success in
                            Logger.shared.log("Fallback notification sent. Success: \(success)")
                        }
                    }
                }
            }
        }
    }
    
    private func fireNotification(completion: @escaping (Bool) -> Void) {
        NotificationManager.checkNotificationAuthorization { enabled in
            ConfigurationManager.shared.notifsEnabled = enabled
            if enabled {
                DispatchQueue.global(qos: .background).async {
                    NotificationManager.triggerSessionEndNotif(completion: completion)
                }
            } else {
                // Always call completion handler, even if notifications are disabled
                completion(false)
            }
        }
    }
    
    private func endBackgroundTask() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.backgroundTask != .invalid {
                let taskToEnd = self.backgroundTask
                self.backgroundTask = .invalid
                
                if Thread.isMainThread {
                    UIApplication.shared.endBackgroundTask(taskToEnd)
                } else {
                    DispatchQueue.main.async {
                        UIApplication.shared.endBackgroundTask(taskToEnd)
                    }
                }
                Logger.shared.log("Background task ended")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
    }
}
