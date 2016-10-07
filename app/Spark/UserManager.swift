//
//  UserManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 08/08/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

class UserManager {
    
    var username: String?
    var reputation: Int?
    var emailAddress: String?
    var location: String?
    
    
    func commitUserData() {
        // Store user data.
        let defaults = UserDefaults.standard
        
        if let ocmUsername = username {
            defaults.set(ocmUsername, forKey: "ocmUserNick")
        }
        
        if let ocmReputation = reputation {
            defaults.set(ocmReputation, forKey: "ocmReputation")
        }
        
        if let ocmEmailAddress  = emailAddress {
            defaults.set(ocmEmailAddress, forKey: "ocmEmailAddress")
        }
        
        if let ocmLocation = location {
            defaults.set(ocmLocation, forKey: "ocmLocation")
        }
    }
    
    func loadUserDataFromUserDefaults() {
        // Load stored user data
        let defaults = UserDefaults.standard
        username = defaults.object(forKey: "ocmUserNick") as? String
        reputation = defaults.integer(forKey: "ocmReputation")
        emailAddress = defaults.object(forKey: "ocmEmailAddress") as? String
        location = defaults.object(forKey: "ocmLocation") as? String
    }
}
