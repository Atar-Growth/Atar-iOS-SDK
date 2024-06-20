//
//  ConfigNetworkRequest.swift
//
//
//  Created by Alex Austin on 3/31/24.
//

import Foundation
import UIKit

class ConfigNetworkRequest {
    
    static let shared = ConfigNetworkRequest()

    private let networkManager = NetworkManager.shared
    private let configManager = ConfigurationManager.shared
    private var inProgess = false
    
    func sync() {
        guard shouldFetchConfig() else {
            Logger.shared.log("Config should not be fetched")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            self.inProgess = true
            
            let baseApiUrl = self.configManager.apiUrl
            let urlString = "\(baseApiUrl)\(ConfigurationManager.CONFIG_PATH)"
            var components = URLComponents(string: urlString)
            
            let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let deviceModel = UIDevice.current.model
            
            var queryItems = [URLQueryItem(name: "aK", value: self.configManager.appKey),
                              URLQueryItem(name: "aId", value: self.configManager.anonId),
                              URLQueryItem(name: "bId", value: bundleId),
                              URLQueryItem(name: "aV", value: appVersion),
                              URLQueryItem(name: "os", value: "ios"),
                              URLQueryItem(name: "platform", value: deviceModel),
                              URLQueryItem(name: "lV", value: ConfigurationManager.LIB_VERSION)]
            if self.configManager.adId != nil {
                queryItems.append(URLQueryItem(name: "adId", value: self.configManager.adId))
            }
            components?.queryItems = queryItems
            
            guard let url = components?.url else {
                Logger.shared.log("URL failed to format")
                self.inProgess = false
                return
            }
            
            let startTime = Date()
            
            self.networkManager.getRequest(url: url) { [weak self] result in
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)*1000
                
                Logger.shared.log("Config request succeeded in \(duration) seconds")
                
                switch result {
                case .success(let json):
                    Logger.shared.log("JSON response: \(json)")
                    self?.updateConfig(with: json)
                    self?.configManager.lastFetchDate = Date()
                case .failure(let error):
                    Logger.shared.log("GET request failed with error: \(error)")
                }
                
                self?.inProgess = false
            }
        }
    }
    
    private func shouldFetchConfig() -> Bool {
        if inProgess { return false }
        guard let lastFetchDate = configManager.lastFetchDate else {
            return true  // No fetch date recorded, should fetch.
        }
        
        let currentTime = Date()
        let fetchInterval = TimeInterval(6 * 60 * 60) // 24 * 60 * 60
        let fetchTime = lastFetchDate.addingTimeInterval(fetchInterval)
        
        return currentTime > fetchTime
    }
    
    private func updateConfig(with json: Any) {
        guard let dict = json as? [String: Any] else { return }
        
        if let apiUrl = dict["apiUrl"] as? String {
            configManager.apiUrl = apiUrl
        }
        
        if let notifBlackoutWindow = dict["notifBlackoutWindow"] as? Int {
            configManager.notifBlackoutWindow = notifBlackoutWindow
        }
        
        if let notifFrequencyCap = dict["notifFrequencyCap"] as? Int {
            configManager.notifFrequencyCap = notifFrequencyCap
        }
        
        if let notifRouteToPopup = dict["notifRouteToPopup"] as? Bool {
            configManager.notifRouteToPopup = notifRouteToPopup
        }
        
        if let postSessionNotifEnabled = dict["postSessionNotifEnabled"] as? Bool {
            configManager.postSessionNotifEnabled = postSessionNotifEnabled
        }
        
        if let postSessionNotifPrefix = dict["postSessionNotifPrefix"] as? String {
            configManager.postSessionNotifPrefix = postSessionNotifPrefix
        }
        
        if let postSessionNotifDelay = dict["postSessionNotifDelay"] as? Int {
            configManager.postSessionNotifDelay = postSessionNotifDelay
        }
        
        if let triggeredNotifPrefix = dict["triggeredNotifPrefix"] as? String {
            configManager.triggeredNotifPrefix = triggeredNotifPrefix
        }
        
        if let interstitialAdEnabled = dict["interstitialAdEnabled"] as? Bool {
            configManager.interstitialAdEnabled = interstitialAdEnabled
        }
        
        if let interstitialAdHeight = dict["interstitialAdHeight"] as? Double {
            configManager.interstitialAdHeight = interstitialAdHeight
        }
        
        if let interstitialFrequencyCap = dict["interstitialFrequencyCap"] as? Int {
            configManager.interstitialFrequencyCap = interstitialFrequencyCap
        }
        
        if let midSessionMessageEnabled = dict["midSessionMessageEnabled"] as? Bool {
            configManager.midSessionMessageEnabled = midSessionMessageEnabled
        }
        
        if let midSessionMessageSessionInterval = dict["midSessionMessageSessionInterval"] as? Int {
            configManager.midSessionMessageSessionInterval = midSessionMessageSessionInterval
        }
        
        if let midSessionMessageDelay = dict["midSessionMessageDelay"] as? Int {
            configManager.midSessionMessageDelay = midSessionMessageDelay
        }
        
        if let midSessionMessageFrequencyCap = dict["midSessionMessageFrequencyCap"] as? Int {
            configManager.midSessionMessageFrequencyCap = midSessionMessageFrequencyCap
        }
        
        if let midSessionMessageVibrate = dict["midSessionMessageVibrate"] as? Bool {
            configManager.midSessionMessageVibrate = midSessionMessageVibrate
        }
        
        if let midSessionMessageForcePopup = dict["midSessionMessageForcePopup"] as? Bool {
            configManager.midSessionMessageForcePopup = midSessionMessageForcePopup
        }
        
        if let midSessionMessageVTA = dict["midSessionMessageVTA"] as? Bool {
            configManager.midSessionMessageVTA = midSessionMessageVTA
        }
        
        if let midSessionMessageOverlayDelay = dict["midSessionMessageOverlayDelay"] as? Int {
            configManager.midSessionMessageOverlayDelay = midSessionMessageOverlayDelay
        }
        
        if configManager.adId == nil {
            retrieveIDFA { idfa in
                if let idfa = idfa {
                    self.configManager.adId = idfa
                }
            }
        }
    }
    
    func retrieveIDFA(completion: @escaping (String?) -> Void) {
        if #available(iOS 14, *), let atTrackingManager = NSClassFromString("ATTrackingManager") as? NSObject.Type {
            // Dynamically obtaining the authorization status
            if let trackingAuthorizationStatus = atTrackingManager.value(forKey: "trackingAuthorizationStatus") as? Int {
                // '3' represents ATTrackingManager.AuthorizationStatus.authorized
                if trackingAuthorizationStatus == 3,
                   let asIdentifierManager = NSClassFromString("ASIdentifierManager") as? NSObject.Type,
                   let sharedManager = asIdentifierManager.perform(Selector(("sharedManager"))).takeUnretainedValue() as? NSObject,
                   let advertisingIdentifier = sharedManager.perform(Selector(("advertisingIdentifier"))).takeUnretainedValue() as? UUID {
                    completion(advertisingIdentifier.uuidString)
                    return
                }
            }
            completion(nil)
        } else if let asIdentifierManager = NSClassFromString("ASIdentifierManager") as? NSObject.Type,
                  let sharedManager = asIdentifierManager.perform(Selector(("sharedManager"))).takeUnretainedValue() as? NSObject,
                  let isAdvertisingTrackingEnabled = sharedManager.perform(Selector(("isAdvertisingTrackingEnabled"))).takeUnretainedValue() as? Bool,
                  isAdvertisingTrackingEnabled,
                  let advertisingIdentifier = sharedManager.perform(Selector(("advertisingIdentifier"))).takeUnretainedValue() as? UUID {
            completion(advertisingIdentifier.uuidString)
        } else {
            // Handle the case where access is unavailable or denied
            completion(nil)
        }
    }
}
