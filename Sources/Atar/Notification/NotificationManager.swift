//
//  NotificationManager.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import Foundation
import UIKit

class NotificationManager {
    static let MAX_TITLE_CHARS = 30
    static let MAX_BODY_CHARS = 140
    
    private static var requests: [String: OfferRequest] = [:]
    
    static func getRequestById(_ id: String) -> OfferRequest? {
        return requests[id]
    }
    
    static func triggerImmediateNotif(request: OfferRequest, titlePrefix: String) {
        if isBlackoutWindowActive() {
            Logger.shared.log("Blackout window active, not sending notification")
            if request.onNotifScheduled != nil {
                DispatchQueue.main.async {
                    request.onNotifScheduled!(false, "Not sending because blackout window active")
                }
            }
            return
        }
        
        if FrequencyCapTracker.shared.canSendNotification() == false {
            Logger.shared.log("Frequency cap reached, not sending notification")
            if request.onNotifScheduled != nil {
                DispatchQueue.main.async {
                    request.onNotifScheduled!(false, "Frequency cap reached, not sending notification")
                }
            }
            return
        }
                
        request.referenceId = request.referenceId ?? UUID().uuidString
        
        requests[request.referenceId!] = request
        
        OfferFetcher.fetchOffer(with: request.toDictionary()) { offer, error in
            if let offer = offer {
                let title = "\(titlePrefix) \(offer.title)"
                let body = offer.description
                
                var userInfo = [
                    "offerId": offer.id,
                    "referenceId": request.referenceId,
                    "clickUrl": offer.clickUrl,
                    "destinationUrl": offer.destinationUrl
                ]
                
                if let iconUrl = offer.iconUrl {
                    userInfo["iconUrl"] = iconUrl
                }
                
                if let impressionUrl = offer.impressionUrl {
                    userInfo["impressionUrl"] = impressionUrl
                }
                
                self.genericTriggerNotif(id: offer.id, title: title, body: body, iconUrl: offer.iconUrl, userInfo: userInfo)
                
                if request.onNotifScheduled != nil {
                    DispatchQueue.main.async {
                        request.onNotifScheduled!(true, nil)
                    }
                }
            }
            
            if let error = error {
                if request.onNotifScheduled != nil {
                    DispatchQueue.main.async {
                        request.onNotifScheduled!(false, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    static func triggerSessionEndNotif(completion: @escaping (Bool) -> Void) {
        if isBlackoutWindowActive() {
            Logger.shared.log("Blackout window active, not sending notification")
            return
        }
        
        if FrequencyCapTracker.shared.canSendNotification() == false {
            Logger.shared.log("Frequency cap reached, not sending notification")
            return
        }
        
        if ConfigurationManager.shared.postSessionNotifDisabledClient {
            Logger.shared.log("Post session notif not enabled, not sending notification")
            return
        }
        
        clearAtarNotifications()
        
        let delay = ConfigurationManager.shared.postSessionNotifDelay/1000
        let lastOfferRequest = ConfigurationManager.shared.lastOfferRequest
        
        var requestParams = [String: Any]()
        if lastOfferRequest != nil {
            requestParams = lastOfferRequest!.toDictionary()
        }
        requestParams["event"] = "session_end"
                
        OfferFetcher.fetchOffer(with: requestParams) { offer, error in
            
            if let offer = offer {
                let title = "\(ConfigurationManager.shared.postSessionNotifPrefix) \(offer.title)"
                let body = offer.description
                
                var userInfo = [
                    "offerId": offer.id,
                    "clickUrl": offer.clickUrl,
                    "destinationUrl": offer.destinationUrl
                ]
                
                if let iconUrl = offer.iconUrl {
                    userInfo["iconUrl"] = iconUrl
                }
                
                if let impressionUrl = offer.impressionUrl {
                    userInfo["impressionUrl"] = impressionUrl
                }
                
                self.genericTriggerNotif(id: offer.id, title: title, body: body, iconUrl: offer.iconUrl, userInfo: userInfo, delay: TimeInterval(delay))
            }
            
            completion(error == nil)
        }
    }
    
    static func genericTriggerNotif(id: String, title: String, body: String, iconUrl: String? = nil, userInfo: [String: Any], delay: TimeInterval = 0.1) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        if iconUrl != nil {
            downloadImage(from: URL(string: iconUrl!)!, completion: { imageAttachment in
                if imageAttachment != nil {
                    content.attachments = [imageAttachment!]
                }
                let request = UNNotificationRequest(identifier: "atar-\(id)", content: content, trigger: trigger)
                fireNotification(request: request)
            })
        } else {
            let request = UNNotificationRequest(identifier: "atar-\(id)", content: content, trigger: trigger)
            fireNotification(request: request)
        }
    }
    
    static func fireNotification(request: UNNotificationRequest) {
        ConfigurationManager.shared.lastNotificationDate = Date()
        FrequencyCapTracker.shared.incrementNotificationCount()
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.log("Error \(error.localizedDescription)")
            }
        }
    }
    
    static func isNotificationFromAtar(id: String) -> Bool {
        return id.hasPrefix("atar-")
    }
    
    static func clearAtarNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
            var idsToRemove = [String]()

            for request in notificationRequests {
                // Check if a certain condition is met to decide whether to remove the notification
                // For example, you might check part of the identifier or any content you set
                if isNotificationFromAtar(id: request.identifier) {
                    idsToRemove.append(request.identifier)
                }
            }

            // Remove the notifications you've determined should be cleared
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
    
    static func isBlackoutWindowActive() -> Bool {
        let now = Date()
        let lastNotificationDate = ConfigurationManager.shared.lastNotificationDate
        if lastNotificationDate == nil {
            return false
        }
        let blackoutWindowEnd = lastNotificationDate!.addingTimeInterval(TimeInterval(ConfigurationManager.shared.notifBlackoutWindow*60))
        return now < blackoutWindowEnd
    }
 
    static func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Extract the image URL from the notification's userInfo or other relevant field
        guard let userInfo = request.content.userInfo as? [String: Any],
              let imageUrlString = userInfo["iconUrl"] as? String,
              let imageUrl = URL(string: imageUrlString) else {
            contentHandler(request.content)
            return
        }

        downloadImage(from: imageUrl) { attachment in
            let content = request.content.mutableCopy() as! UNMutableNotificationContent
            if let attachment = attachment {
                content.attachments = [attachment]
            }
            contentHandler(content)
        }
    }
    
    private static func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let tmpDirectory = NSTemporaryDirectory()
            let tmpFile = "atar-image\(url.lastPathComponent)"
            let tmpUrl = URL(fileURLWithPath: tmpDirectory).appendingPathComponent(tmpFile)
            do {
                try data.write(to: tmpUrl)
                let attachment = try UNNotificationAttachment(identifier: tmpFile, url: tmpUrl, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
    
    static func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                // App is authorized to post notifications
                completion(true)
            case .denied, .notDetermined, .ephemeral:
                // App is not authorized to post notifications
                completion(false)
            @unknown default:
                // Default case for future iOS versions
                completion(false)
            }
            
        }
    }
}
