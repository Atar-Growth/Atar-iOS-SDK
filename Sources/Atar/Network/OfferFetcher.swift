//
//  OfferFetcher.swift
//
//
//  Created by Alex Austin on 4/1/24.
//

import UIKit

/*
 OfferFetcher.fetchOffer(with: parameters) { offer, error in
     guard let offer = offer else {
         Logger.shared.log("Error fetching offer: \(error?.localizedDescription ?? "Unknown error")")
         return
     }
     
     Logger.shared.log("Offer ID: \(offer.id), Title: \(offer.title)")
     // Utilize the fetched offer as needed
 }
 */

class OfferFetcher {
        
    static func fetchOffer(with parameters: [String: Any], completion: @escaping (Offer?, Error?) -> Void) {
        let baseUrl = ConfigurationManager.shared.apiUrl
        let urlString = "\(baseUrl)\(ConfigurationManager.OFFER_PATH)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "URLError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
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
            "request": parameters
        ]
        
        if let adId = ConfigurationManager.shared.adId {
            postDictionary["adId"] = adId
        }
        
        Logger.shared.log("Offer request: \(postDictionary)")
        
        NetworkManager.shared.postRequest(url: url, body: postDictionary) { result in
            switch result {
            case .success(let response):
                Logger.shared.log("Offer result: \(response)")
                
                guard let dict = response as? [String: Any] else {
                    Logger.shared.log("Invalid data format")
                    completion(nil, NSError(domain: "DataError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]))
                    return
                }
                Logger.shared.log("Offer dict: \(dict)")
                
                if let successString = dict["success"] as? String, successString == "false" {
                    let errorMessage = dict["message"] as? String ?? "Unknown error"
                    Logger.shared.log("Error fetching offer: \(errorMessage)")
                    completion(nil, nil)
                } else {
                    if dict["offer"] != nil {
                        let offer = Offer(from: dict["offer"] as? [String: Any] ?? [:])
                        completion(offer, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            case .failure(let error):
                Logger.shared.log("Error fetching offer: \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    public static func getOfferWebUrl(with offerRequest: OfferRequest) -> URL? {
//        return URL(string: "https://postintent-hosting.s3.amazonaws.com/public/carousel.html")
        return getWebUrlWithPath(ConfigurationManager.OFFERS_PATH, offerRequest: offerRequest)
    }
    
    public static func getMessageWebUrl(with offerRequest: OfferRequest) -> URL? {
        return getWebUrlWithPath(ConfigurationManager.MESSAGE_PATH, offerRequest: offerRequest)
    }
    
    public static func getWebUrlWithPath(_ path: String, offerRequest: OfferRequest) -> URL? {
        let configManager = ConfigurationManager.shared
        let baseUrl = configManager.apiUrl
        let urlString = "\(baseUrl)\(path)"
        guard var components = URLComponents(string: urlString) else { return nil }

        // Predefined parameters
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let deviceModel = UIDevice.current.model

        var queryItems = [
            URLQueryItem(name: "aK", value: configManager.appKey),
            URLQueryItem(name: "aId", value: configManager.anonId),
            URLQueryItem(name: "bId", value: bundleId),
            URLQueryItem(name: "aV", value: appVersion),
            URLQueryItem(name: "os", value: "ios"),
            URLQueryItem(name: "platform", value: deviceModel),
            URLQueryItem(name: "lV", value: ConfigurationManager.LIB_VERSION),
            URLQueryItem(name: "startTime", value: ISO8601DateFormatter().string(from: Date()))
        ]

        // Add adId if available
        if let adId = configManager.adId {
            queryItems.append(URLQueryItem(name: "adId", value: adId))
        }

        // Append parameters from the OfferRequest instance
        let requestParameters = offerRequest.toDictionary().compactMapValues { $0 }
        let requestQueryItems = requestParameters.map { key, value -> URLQueryItem in
            let valueString = "\(value)"
            return URLQueryItem(name: key, value: valueString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
        }
        
        // Combine predefined and request-specific query items
        queryItems.append(contentsOf: requestQueryItems)

        components.queryItems = queryItems
        
        return components.url
    }
}

struct Offer {
    let id: String
    let title: String
    let description: String
    let iconUrl: String?
    let type: String
    let clickUrl: String
    let destinationUrl: String
    let impressionUrl: String?
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let description = dictionary["description"] as? String,
              let type = dictionary["type"] as? String,
              let clickUrl = dictionary["clickUrl"] as? String,
              let destinationUrl = dictionary["destinationUrl"] as? String else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.clickUrl = clickUrl
        self.destinationUrl = destinationUrl
        if let iconUrl = dictionary["iconUrl"] as? String, iconUrl != "<null>" {
            self.iconUrl = iconUrl
        } else {
            self.iconUrl = nil
        }
        if let impressionUrl = dictionary["impressionUrl"] as? String, impressionUrl != "<null>" {
            self.impressionUrl = impressionUrl
        } else {
            self.impressionUrl = nil  // Or provide a default value or handle appropriately
        }
    }
}

