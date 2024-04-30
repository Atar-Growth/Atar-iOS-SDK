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
            
            let startTime = Date()
            
            let userInfo = response.notification.request.content.userInfo
            
            if let referenceId = userInfo["referenceId"] {
                if let request = NotificationManager.getRequestById(referenceId as! String) {
                    request.onClicked?()
                }
            }
            
            let offerId = userInfo["offerId"] as? String
            let clickUrl = userInfo["clickUrl"] as? String
            let destinationUrl = userInfo["destinationUrl"] as? String
            
            let lastRequest = ConfigurationManager.shared.lastOfferRequest
            if lastRequest != nil {
                Atar.getInstance().showOfferPopup(request: lastRequest!)
            } else {
                if clickUrl != nil {
                    UIApplication.shared.open(URL(string: clickUrl!)!, options: [:], completionHandler: nil)
                } else if destinationUrl != nil {
                    UIApplication.shared.open(URL(string: destinationUrl!)!, options: [:], completionHandler: nil)
                }
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)*1000
            var clickEventMetadata: [String: Any] = [
                "notifId": response.notification.request.identifier,
                "offerId": offerId ?? "",
                "clickUrl": clickUrl ?? "",
                "destinationUrl": destinationUrl ?? ""
            ]
                
            StatsRecorder.shared.add(event: "click-notif", value: Int(duration), metadata: clickEventMetadata)
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
                if let request = NotificationManager.getRequestById(referenceId as! String) {
                    request.onSent?()
                }
            }
            
            let startTime = Date()
            
            // fire impression URL if exists
            let impressionUrl = userInfo["impressionUrl"] as? String
            if let impressionUrl = impressionUrl {
                NetworkManager.shared.getRequest(url: URL(string: impressionUrl)!)  { [] result in
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)*1000
                    
                    var impressionEventMetadata: [String: Any] = [
                        "notifId": notification.request.identifier,
                        "offerId": userInfo["offerId"] as? String ?? "",
                        "url": impressionUrl]
                                                   
                    switch result {
                    case .success(let json):
                        impressionEventMetadata["result"] = "success"
                    case .failure(let error):
                        impressionEventMetadata["result"] = "failure"
                        impressionEventMetadata["error"] = error.localizedDescription
                    }
                    
                    StatsRecorder.shared.add(event: "view-notif", value: Int(duration), metadata: impressionEventMetadata)
                }
            } else {
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)*1000
                var impressionEventMetadata: [String: Any] = [
                    "notifId": notification.request.identifier,
                    "offerId": userInfo["offerId"] as? String ?? "",
                ]
                
                // TODO fill out more details
                StatsRecorder.shared.add(event: "view-notif", value: Int(duration), metadata: impressionEventMetadata)
            }
        }
        
        originalDelegate?.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler) ?? completionHandler([.alert, .sound])
    }
}

