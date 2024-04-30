//
//  SyncNetworkManager.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import UIKit

class SyncNetworkManager {
    
    static let shared = SyncNetworkManager()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc private func appDidEnterBackground() {
        // Initiate a background task when the app goes into the background.
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            // This block is executed when the background time is about to expire.
            self?.endBackgroundTask()
        }
        
        performNetworkSync()
    }

    private func performNetworkSync() {
        syncData { [weak self] success in
            // Network sync completed, end the background task.
            self?.endBackgroundTask()
            Logger.shared.log("Network sync completed. Success: \(success)")
        }
    }

    private func syncData(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let stats = StatsRecorder.shared.getAll()
            guard !stats.isEmpty else {
                completion(true)  // Nothing to sync, complete successfully.
                return
            }
            
            let startTime = Date()
            
            let baseApiUrl = ConfigurationManager.shared.apiUrl
            let urlString = "\(baseApiUrl)\(ConfigurationManager.SYNC_PATH)"
            let url = URL(string: urlString)!
            
            // Bundle id, app version, and package version.
            let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let deviceModel = UIDevice.current.model
            var postDictionary: [String: Any] = [
                "bId": bundleId,
                "aV": appVersion,
                "lV": ConfigurationManager.LIB_VERSION,
                "aId": ConfigurationManager.shared.anonId ?? "none",
                "os": "ios",
                "platform": deviceModel,
                "stats": stats
            ]
            
            if let adId = ConfigurationManager.shared.adId {
                postDictionary["adId"] = adId
            }
            
            Logger.shared.log("Sync request: \(postDictionary)")
            
            // Making the POST request using NetworkManager.
            NetworkManager.shared.postRequest(url: url, body: postDictionary) { [] result in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)*1000
                var syncEventMetadata: [String: Any] = [
                    "url": url.absoluteString
                ]
                
                Logger.shared.log("Sync request succeeded in \(duration) ms")
                Logger.shared.log("JSON response: \(result)")
                
                switch result {
                case .success(_):
                    // Clearing stats that were successfully uploaded.
                    let ids = stats.compactMap { $0[StatKeys.id] as? String }
                    StatsRecorder.shared.clearIds(ids)
                    
                    syncEventMetadata["result"] = "success"
                    completion(true)
                case .failure(let error):
                    syncEventMetadata["result"] = "failure"
                    syncEventMetadata["error"] = error.localizedDescription
                    
                    Logger.shared.log("POST request failed with error: \(error.localizedDescription)")
                    
                    completion(false)
                }
                
                // Log the sync event.
                StatsRecorder.shared.add(event: "sync-request", value: Int(duration), metadata: syncEventMetadata)
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
