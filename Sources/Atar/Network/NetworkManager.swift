//
//  NetworkManager.swift
//
//
//  Created by Alex Austin on 3/31/24.
//

import Foundation

/*
 
 let url = URL(string: "https://api.example.com/data")!
 NetworkManager.shared.getRequest(url: url) { result in
    // returns on background thread
     switch result {
     case .success(let json):
         Logger.shared.log("GET request succeeded with JSON response: \(json)")
     case .failure(let error):
         Logger.shared.log("GET request failed with error: \(error)")
     }
 }

 let postUrl = URL(string: "https://api.example.com/submit")!
 let body = ["key": "value"]
 NetworkManager.shared.postRequest(url: postUrl, body: body) { result in
 // returns on background thread
     switch result {
     case .success(let json):
         Logger.shared.log("POST request succeeded with JSON response: \(json)")
     case .failure(let error):
         Logger.shared.log("POST request failed with error: \(error)")
     }
 }
 */

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    
    func getRequest(url: URL, completion: @escaping (Result<Any, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                completion(.success(jsonResult))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func postRequest(url: URL, body: [String: Any], completion: @escaping (Result<Any, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(ConfigurationManager.shared.appKey ?? "none")", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch let error {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                completion(.success(jsonResult))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
