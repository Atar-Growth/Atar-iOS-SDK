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
    private var didFireMessage = false
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
        Logger.shared.log( "App became active")
        if !didBackground {
            return
        }
        self.didBackground = false
        
        startTime = Date()
        
        ConfigurationManager.shared.sessionCount += 1
        if ConfigurationManager.shared.midSessionMessageSessionInterval == 0 {
            ConfigurationManager.shared.midSessionMessageSessionInterval = 2
        }
        if ConfigurationManager.shared.sessionCount % ConfigurationManager.shared.midSessionMessageSessionInterval == 0 {
            let messageDelay = ConfigurationManager.shared.midSessionMessageDelay/1000
            Logger.shared.log("Mid session message eligible, scheduling for " + String(messageDelay) + " seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(messageDelay)) {
                if self.didBackground {
                    self.didBackground = false
                    return
                }
                Logger.shared.log("Mid session message sent")
                self.didFireMessage = true
                let offerRequest = OfferRequest()
                offerRequest.event = "auto_message"
                Atar.shared?.showOfferMessage(request: offerRequest)
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        Logger.shared.log( "App entered background")
        didBackground = true
        if didFireMessage {
            didFireMessage = false
            return
        }
        if ConfigurationManager.shared.sessionCount < 2 {
            return
        }
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
