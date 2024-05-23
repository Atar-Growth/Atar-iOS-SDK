//
//  OfferRequest.swift
//
//
//  Created by Alex Austin on 4/1/24.
//
import Foundation

@objc(OfferRequest)
public class OfferRequest: NSObject {
    public var onNotifScheduled: ((Bool, String?) -> Void)?
    public var onNotifSent: (() -> Void)?
    
    public var onPopupShown: ((Bool, String?) -> Void)?
    public var onPopupCanceled: (() -> Void)?
    
    public var onClicked: (() -> Void)?

    public var event: String?
    public var referenceId: String?
    public var email: String?
    public var userId: String?
    public var amount: Double?
    public var firstName: String?
    public var lastName: String?
    public var gender: String?
    public var dob: String?
    public var phone: String?
    public var address1: String?
    public var address2: String?
    public var city: String?
    public var state: String?
    public var zip: String?
    public var country: String?
    public var quantity: Int?
    public var paymentType: String?
    
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        
        if let event = self.event { dict[OfferRequestKeys.event] = event }
        if let referenceId = self.referenceId { dict[OfferRequestKeys.referenceId] = referenceId }
        if let email = self.email { dict[OfferRequestKeys.email] = email }
        if let userId = self.userId { dict[OfferRequestKeys.userId] = userId }
        if let amount = self.amount { dict[OfferRequestKeys.amount] = amount }
        if let firstName = self.firstName { dict[OfferRequestKeys.firstName] = firstName }
        if let lastName = self.lastName { dict[OfferRequestKeys.lastName] = lastName }
        if let gender = self.gender { dict[OfferRequestKeys.gender] = gender }
        if let dob = self.dob { dict[OfferRequestKeys.dob] = dob }
        if let phone = self.phone { dict[OfferRequestKeys.phone] = phone }
        if let address1 = self.address1 { dict[OfferRequestKeys.address1] = address1 }
        if let address2 = self.address2 { dict[OfferRequestKeys.address2] = address2 }
        if let city = self.city { dict[OfferRequestKeys.city] = city }
        if let state = self.state { dict[OfferRequestKeys.state] = state }
        if let zip = self.zip { dict[OfferRequestKeys.zip] = zip }
        if let country = self.country { dict[OfferRequestKeys.country] = country }
        if let quantity = self.quantity { dict[OfferRequestKeys.quantity] = quantity }
        if let paymentType = self.paymentType { dict[OfferRequestKeys.paymentType] = paymentType }
        
        return dict
    }
    
    func fromDictionary(dictionary: [String: Any]) {
        self.event = dictionary[OfferRequestKeys.event] as? String
        self.referenceId = dictionary[OfferRequestKeys.referenceId] as? String
        self.email = dictionary[OfferRequestKeys.email] as? String
        self.userId = dictionary[OfferRequestKeys.userId] as? String
        self.amount = dictionary[OfferRequestKeys.amount] as? Double
        self.firstName = dictionary[OfferRequestKeys.firstName] as? String
        self.lastName = dictionary[OfferRequestKeys.lastName] as? String
        self.gender = dictionary[OfferRequestKeys.gender] as? String
        self.dob = dictionary[OfferRequestKeys.dob] as? String
        self.phone = dictionary[OfferRequestKeys.phone] as? String
        self.address1 = dictionary[OfferRequestKeys.address1] as? String
        self.address2 = dictionary[OfferRequestKeys.address2] as? String
        self.city = dictionary[OfferRequestKeys.city] as? String
        self.state = dictionary[OfferRequestKeys.state] as? String
        self.zip = dictionary[OfferRequestKeys.zip] as? String
        self.country = dictionary[OfferRequestKeys.country] as? String
        self.quantity = dictionary[OfferRequestKeys.quantity] as? Int
        self.paymentType = dictionary[OfferRequestKeys.paymentType] as? String
    }
}

struct OfferRequestKeys {
    static let event = "event"
    static let referenceId = "referenceId"
    static let email = "email"
    static let userId = "userId"
    static let amount = "amount"
    static let platform = "platform"
    static let firstName = "firstName"
    static let lastName = "lastName"
    static let gender = "gender"
    static let dob = "dob"
    static let phone = "phone"
    static let address1 = "address1"
    static let address2 = "address2"
    static let city = "city"
    static let state = "state"
    static let zip = "zip"
    static let country = "country"
    static let quantity = "quantity"
    static let paymentType = "paymentType"
}
