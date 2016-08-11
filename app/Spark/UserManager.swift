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
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let ocmUsername = username {
            defaults.setObject(ocmUsername, forKey: "ocmUserNick")
        }
        
        if let ocmReputation = reputation {
            defaults.setInteger(ocmReputation, forKey: "ocmReputation")
        }
        
        if let ocmEmailAddress  = emailAddress {
            defaults.setObject(ocmEmailAddress, forKey: "ocmEmailAddress")
        }
        
        if let ocmLocation = location {
            defaults.setObject(ocmLocation, forKey: "ocmLocation")
        }
    }
    
    func loadUserDataFromUserDefaults() {
        // Load stored user data
        let defaults = NSUserDefaults.standardUserDefaults()
        username = defaults.objectForKey("ocmUserNick") as? String
        reputation = defaults.integerForKey("ocmReputation")
        emailAddress = defaults.objectForKey("ocmEmailAddress") as? String
        location = defaults.objectForKey("ocmLocation") as? String
    }
}
