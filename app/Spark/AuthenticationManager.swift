//
//  AuthenticationManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

class AuthenticationManager {
    
    static func authenticateUserWithStoredCredentials() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.stringForKey("ocmUsername")
        let password = defaults.stringForKey("ocmPassword")
        getSessionToken(String(username!), password: String(password!))
    }
    
    static func doWeHaveCredentails() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.stringForKey("ocmUsername")
        let password = defaults.stringForKey("ocmPassword")
        if username == nil || password == nil {
            return false
        }
        
        return true
    }
    
    static func getSessionToken(username: String, password: String) {
        let authenticationURLString = "https://api.openchargemap.io/v3/profile/authenticate/"
        guard let url = NSURL(string: authenticationURLString) else { return }
        
        let json = [ "emailaddress": String(username) , "password": String(password) ]
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            // For a HTTP POST, do the following.
            let urlRequest = NSMutableURLRequest(URL: url)
            urlRequest.HTTPMethod = "POST"
            // insert json data to the request
            urlRequest.HTTPBody = jsonData
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest){ data, response, error in
                if error != nil{
                    print("Error -> \(error)")
                    NSNotificationCenter.defaultCenter().postNotificationName("OCMLoginFailed", object: nil, userInfo:
                        ["errorMesssage": error!.localizedDescription])
                    return
                }
                
                do {
                    guard let result = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String:AnyObject] else {
                        return
                    }
                    guard let responseData = result["Data"] else { return }
                    guard let userData = responseData["UserProfile"] else { return }
                    
                    let sessionToken = userData!["CurrentSessionToken"] as? NSString
                    let profileUsername = userData!["Username"] as? NSString
                    let profileReputationpoints = userData!["ReputationPoints"] as? NSNumber
                    let profileAvatarImage = userData!["ProfileImageURL"] as? NSString
                    let profileAvatarImageFixed = profileAvatarImage!.stringByReplacingOccurrencesOfString("s=80", withString: "s=200")
                    let accessToken = responseData["access_token"] as? NSString
                    let profileEmail = userData!["EmailAddress"] as? NSString
                    let profileLocation = userData!["Location"] as? NSString
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setObject(accessToken, forKey: "ocmAccessToken")
                    NSNotificationCenter.defaultCenter().postNotificationName("OCMLoginSuccess", object: nil, userInfo: ["accessToken": accessToken!, "username": profileUsername!, "reputation": String(profileReputationpoints!),
                        "avatarURL": profileAvatarImageFixed, "email": profileEmail!, "location": profileLocation!, "sessionToken": sessionToken!])
                    
                } catch {
                    let unknownErrorString = NSLocalizedString("Unknown Error", comment: "Unkown Error")
                    var errorMessage = unknownErrorString
                    if let httpResponse = response as? NSHTTPURLResponse {
                        let responseCode = httpResponse.statusCode
                        if responseCode == 401 {
                            let unauthorizedErrorString = NSLocalizedString("Incorrect credentails", comment: "Incorrect username/password")
                            errorMessage = unauthorizedErrorString
                        }
                        print(httpResponse.statusCode)
                    }
                    print("Error -> \(error)")
                    NSNotificationCenter.defaultCenter().postNotificationName("OCMLoginFailed", object: nil, userInfo:
                    ["errorMesssage": errorMessage])
                }
            }
            task.resume()
        } catch {
            print(error)
        }
    }
    
}