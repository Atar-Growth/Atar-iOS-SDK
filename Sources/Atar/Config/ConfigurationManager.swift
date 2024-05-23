//
//  ConfigurationManager.swift
//
//
//  Created by Alex Austin on 3/31/24.
//

import Foundation

/* Usage
 // Setting a value
 ConfigurationManager.shared.someSetting = "New Value"

 // Retrieving a value
 if let settingValue = ConfigurationManager.shared.someSetting {
     Logger.shared.log("Retrieved setting: \(settingValue)")
 }

 // Modifying another setting
 ConfigurationManager.shared.anotherSetting = true
 */

class ConfigurationManager {
    static public let LIB_VERSION = "1.0.4"
    static public let CONFIG_PATH = "/config"
    static public let SYNC_PATH = "/sync"
    static public let OFFERS_PATH = "/offers"
    static public let MESSAGE_PATH = "/message"
    
    static let shared = ConfigurationManager()
    
    private let defaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }
    
    var appKey: String? {
        get { defaults.string(forKey: "atarAppKey") }
        set { defaults.set(newValue, forKey: "atarAppKey") }
    }
    
    var apiUrl: String {
        get { return defaults.string(forKey: "atarApiUrl") ?? "https://api.atargrowth.com" }
        set { defaults.set(newValue, forKey: "atarApiUrl") }
    }
    
    var lastFetchDate: Date? {
        get { defaults.object(forKey: "atarLastFetchDate") as? Date }
        set { defaults.set(newValue, forKey: "atarLastFetchDate") }
    }
    
    var anonId: String? {
        get { defaults.string(forKey: "atarAnonId") }
        set { defaults.set(newValue, forKey: "atarAnonId") }
    }
    
    var adId : String? {
        get { defaults.string(forKey: "atarAdId") }
        set { defaults.set(newValue, forKey: "atarAdId") }
    }
    
    var notifBlackoutWindow: Int {
        get { return defaults.integer(forKey: "atarNotifBlackoutWindow") }
        set { defaults.set(newValue, forKey: "atarNotifBlackoutWindow")}
    }
    
    var notifFrequencyCap: Int {
        get { return defaults.integer(forKey: "atarNotifFrequencyCap") }
        set { defaults.set(newValue, forKey: "atarNotifFrequencyCap")}
    }
    
    var notifRouteToPopup: Bool {
        get { return defaults.bool(forKey: "notifRouteToPopup") }
        set { defaults.set(newValue, forKey: "notifRouteToPopup")}
    }
    
    var postSessionNotifEnabled: Bool {
        get { return defaults.bool(forKey: "atarPostSessionNotifEnabled") }
        set { defaults.set(newValue, forKey: "atarPostSessionNotifEnabled")}
    }
    
    var postSessionNotifDisabledClient: Bool {
        get { return defaults.bool(forKey: "atarPostSessionNotifDisabledClient") }
        set { defaults.set(newValue, forKey: "atarPostSessionNotifDisabledClient")}
    }
    
    var postSessionNotifDelay: Int {
        get { return defaults.integer(forKey: "atarPostSessionNotifDelay") }
        set { defaults.set(newValue, forKey: "atarPostSessionNotifDelay")}
    }
    
    var postSessionNotifPrefix: String {
        get { return defaults.string(forKey: "atarPostSessionNotifPrefix") ?? "Thanks!" }
        set { defaults.set(newValue, forKey: "atarPostSessionNotifPrefix")}
    }
    
    var triggeredNotifPrefix: String {
        get { return defaults.string(forKey: "atarTriggeredNotifPrefix") ?? "Thanks!" }
        set { defaults.set(newValue, forKey: "atarTriggeredNotifPrefix")}
    }
    
    var interstitialAdEnabled: Bool {
        get { return defaults.bool(forKey: "atarInterstitialAdEnabled") }
        set { defaults.set(newValue, forKey: "atarInterstitialAdEnabled")}
    }
    
    var interstitialAdHeight: Double {
        get { return defaults.double(forKey: "atarInterstitialAdHeight") }
        set { defaults.set(newValue, forKey: "atarInterstitialAdHeight")}
    }
    
    var interstitialFrequencyCap: Int {
        get { return defaults.integer(forKey: "atarInterstitialFrequencyCap") }
        set { defaults.set(newValue, forKey: "atarInterstitialFrequencyCap")}
    }
    
    
    var lastOfferRequest: OfferRequest? {
        get {
            let lastRequest = OfferRequest()
            lastRequest.fromDictionary(dictionary: defaults.object(forKey: "atarLastOfferRequest") as? [String: Any] ?? [:])
            return lastRequest
        }
        set { defaults.set(newValue?.toDictionary(), forKey: "atarLastOfferRequest") }
    }
    
    var lastOfferRequestDate: Date? {
        get { defaults.object(forKey: "atarLastOfferRequestDate") as? Date }
        set { defaults.set(newValue, forKey: "atarLastOfferRequestDate") }
    }
    
    var lastNotificationDate: Date? {
        get { defaults.object(forKey: "atarLastNotificationDate") as? Date }
        set { defaults.set(newValue, forKey: "atarLastNotificationDate") }
    }
    
    var lastInterstitialDate: Date? {
        get { defaults.object(forKey: "atarLastInterstitialDate") as? Date }
        set { defaults.set(newValue, forKey: "atarLastInterstitialDate") }
    }
}
