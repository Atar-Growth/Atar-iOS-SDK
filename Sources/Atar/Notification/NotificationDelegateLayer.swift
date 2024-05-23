//
//  NotificationDelegateLayer.swift
//
//
//  Created by Alex Austin on 3/31/24.
//

import UIKit
import UserNotifications

class NotificationDelegateLayer: NSObject, UNUserNotificationCenterDelegate {
    weak var originalDelegate: UNUserNotificationCenterDelegate?
    
    init(withOriginalDelegate originalDelegate: UNUserNotificationCenterDelegate?) {
        self.originalDelegate = originalDelegate
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if NotificationManager.isNotificationFromAtar(id: response.notification.request.identifier) {
            // Handle the tap and routing
            Logger.shared.log("User clicked notification")
            
            
            let userInfo = response.notification.request.content.userInfo
            
            if let referenceId = userInfo["referenceId"] {
                if let request = NotificationManager.getRequestById(referenceId as! String) {
                    request.onClicked?()
                }
            }
            
            let clickUrl = userInfo["clickUrl"] as? String
            let destinationUrl = userInfo["destinationUrl"] as? String
            
            let lastRequest = ConfigurationManager.shared.lastOfferRequest
            if lastRequest != nil && ConfigurationManager.shared.notifRouteToPopup {
                Atar.getInstance().showOfferPopup(request: lastRequest!)
            } else {
                if clickUrl != nil {
                    UIApplication.shared.open(URL(string: clickUrl!)!, options: [:], completionHandler: nil)
                } else if destinationUrl != nil {
                    UIApplication.shared.open(URL(string: destinationUrl!)!, options: [:], completionHandler: nil)
                }
            }
        }
        
        originalDelegate?.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler) ?? completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if NotificationManager.isNotificationFromAtar(id: notification.request.identifier) {
            // Handle the impression
            Logger.shared.log("User saw notification")
            
            let userInfo = notification.request.content.userInfo
            
            if let referenceId = userInfo["referenceId"] {
                Logger.shared.log("Reference ID: \(referenceId)")
                if let request = NotificationManager.getRequestById(referenceId as! String) {
                    Logger.shared.log("Found request")
                    request.onNotifSent?()
                }
            }
            
            // fire impression URL if exists
            let impressionUrl = userInfo["impressionUrl"] as? String
            if let impressionUrl = impressionUrl {
                Logger.shared.log("Impression URL: \(impressionUrl)")
                NetworkManager.shared.getRequest(url: URL(string: impressionUrl)!) { _ in }
            }
        }
        
        originalDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler) ?? completionHandler([.alert, .sound])
    }
}

