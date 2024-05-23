//
//  PostIntent.swift
//
//
//  Created by Alex Austin on 3/25/24.
//

import Foundation
import UIKit

@objc(Atar)
public class Atar: NSObject {
    @objc static var shared: Atar? = nil
    
    private var delegateInterceptor: NotificationDelegateLayer?
    private var sessionEndMonitor: SessionEndMonitor?
    private var interstitialView: InterstitialView?
    private var messageView: MessageView?

    @objc
    public static func getInstance() -> Atar {
        if (shared == nil) {
            shared = Atar()
        }
        return shared!
    }
    
    @objc
    public func didFinishLaunching(appKey: String) {
        Logger.shared.log("Atar register: \(appKey)")
        
        ConfigurationManager.shared.appKey = appKey
        
        // Generate the session id if not set
        if ConfigurationManager.shared.anonId == nil {
            ConfigurationManager.shared.anonId = UUID().uuidString
        }
        
        // Disintermediate the notification delegate
        let currentDelegate = UNUserNotificationCenter.current().delegate
        delegateInterceptor = NotificationDelegateLayer(withOriginalDelegate: currentDelegate)
        UNUserNotificationCenter.current().delegate = delegateInterceptor
        
        // Sync the config
        ConfigNetworkRequest.shared.sync()
        
        // Initialize the lifecyle monintors
        sessionEndMonitor = SessionEndMonitor.shared
        
        self.interstitialView = InterstitialView()
    }
    
    @objc
    public func didFinishLaunching(appKey: String, debugMode: Bool) {
        Logger.shared.setDebugMode(debugMode)
        didFinishLaunching(appKey: appKey)
    }
    
    public func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Logger.shared.log("Atar didReceive: \(request)")
        if NotificationManager.isNotificationFromAtar(id: request.identifier) {
            NotificationManager.didReceive(request, withContentHandler: contentHandler)
        }
    }

    @objc
    public func setPostSessionNotifDisabled(disabled: Bool) {
        ConfigurationManager.shared.postSessionNotifDisabledClient = disabled
    }
    
    @objc
    public func triggerOfferNotification(request: OfferRequest, titlePrefix: String = "") {
        var internalTitlePrefix = titlePrefix
        if internalTitlePrefix.isEmpty {
            internalTitlePrefix = ConfigurationManager.shared.triggeredNotifPrefix
        }
        NotificationManager.checkNotificationAuthorization { enabled in
            if enabled {
                DispatchQueue.global(qos: .background).async {
                    NotificationManager.triggerImmediateNotif(request: request, titlePrefix: internalTitlePrefix)
                }
            } else {
                Logger.shared.log("Atar will not show offers. Notifications are not enabled.")
                if (request.onNotifScheduled != nil) {
                    DispatchQueue.main.async {
                        request.onNotifScheduled!(false, "Notification permissions are not enabled")
                    }
                }
            }
        }
        registerConversion(request: request)
    }
    
    @objc
    public func showOfferPopup(request: OfferRequest) {
        if !ConfigurationManager.shared.interstitialAdEnabled {
            Logger.shared.log("Atar will not show offers. Interstitial ad is not enabled.")
            if (request.onPopupShown != nil) {
                DispatchQueue.main.async {
                    request.onPopupShown!(false, "Interstitial ad is not enabled")
                }
            }
            return
        }
        if !FrequencyCapTracker.shared.canShowInterstitial() {
            Logger.shared.log("Atar will not show offers. Frequency cap is reached.")
            if (request.onPopupShown != nil) {
                DispatchQueue.main.async {
                    request.onPopupShown!(false, "Frequency cap is reached")
                }
            }
            return
        }
        FrequencyCapTracker.shared.incrementInterstitialCount()
        
        if (interstitialView == nil) {
            interstitialView = InterstitialView()
        }
        
        interstitialView!.configure(withRequest: request)
        interstitialView!.show()
    }
    
    @objc
    public func showOfferMessage(request: OfferRequest) {
        messageView = MessageView(url: OfferFetcher.getMessageWebUrl(with: request)!, tapAction: {
            Logger.shared.log("Atar show offer message tapped")
            self.showOfferPopup(request: request)
        })
    }
    
    @objc
    public func registerConversion(request: OfferRequest) {
        Logger.shared.log("Atar register conversion: \(request)")
        ConfigurationManager.shared.lastOfferRequest = request
        ConfigurationManager.shared.lastOfferRequestDate = Date()
    }
}
