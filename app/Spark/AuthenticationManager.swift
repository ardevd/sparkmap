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
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "ocmUsername")
        let password = defaults.string(forKey: "ocmPassword")
        getSessionToken(String(username!), password: String(password!))
    }
    
    static func doWeHaveCredentails() -> Bool {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "ocmUsername")
        let password = defaults.string(forKey: "ocmPassword")
        if username == nil || password == nil {
            return false
        }
        
        return true
    }
    
    static func getSessionToken(_ username: String, password: String) {
        let authenticationURLString = "https://api.openchargemap.io/v3/profile/authenticate/"
        guard let url = URL(string: authenticationURLString) else { return }
        
        let json = [ "emailaddress": String(username) , "password": String(password) ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            // For a HTTP POST, do the following.
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            // insert json data to the request
            urlRequest.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
                if error != nil{
                    print("Error -> \(error)")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMLoginFailed"), object: nil, userInfo:
                        ["errorMesssage": error!.localizedDescription, "errorCode": -1])
                    return
                }
                
                do {
                    guard let result = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject] else {
                        return
                    }
                    guard let responseData = result["Data"] else { return }
                    guard let userData = responseData["UserProfile"] as? [String : AnyObject] else { return }
                    
                    var userProfileFieldsDict = [String: String]()
                    
                    if let sessionToken = userData["CurrentSessionToken"] as? String {
                        userProfileFieldsDict["sessionToken"] = sessionToken
                        
                    }
                    if let profileUsername = userData["Username"] as? String {
                        userProfileFieldsDict["username"] = profileUsername
                    }
                    if let profileReputationpoints = userData["ReputationPoints"] as? Int {
                        userProfileFieldsDict["reputation"] = String(profileReputationpoints)
                    }
                    
                    if let profileAvatarImage = userData["ProfileImageURL"] as? String {
                        userProfileFieldsDict["avatarURL"] = String(profileAvatarImage.replacingOccurrences(of: "s=80", with: "s=200"))
                    }
                    
                    if let accessToken = responseData["access_token"] as? String {
                        userProfileFieldsDict["accessToken"] = (accessToken)
                        let defaults = UserDefaults.standard
                        defaults.set(accessToken, forKey: "ocmAccessToken")
                    }
                    
                    if let profileEmail = userData["EmailAddress"] as? String {
                        userProfileFieldsDict["email"] = profileEmail
                    }
                    
                    if let profileLocation = userData["Location"] as? String {
                        userProfileFieldsDict["location"] = profileLocation
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMLoginSuccess"), object: nil, userInfo: userProfileFieldsDict)
                    
                } catch {
                    let unknownErrorString = NSLocalizedString("Unknown Error", comment: "Unkown Error")
                    var errorMessage = unknownErrorString
                    var errorCode = -1
                    if let httpResponse = response as? HTTPURLResponse {
                        let responseCode = httpResponse.statusCode
                        if responseCode == 401 {
                            let unauthorizedErrorString = NSLocalizedString("Incorrect credentails", comment: "Incorrect username/password")
                            errorCode = 100
                            errorMessage = unauthorizedErrorString
                        }
                        print(httpResponse.statusCode)
                    }
                    print("Error -> \(error)")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMLoginFailed"), object: nil, userInfo:
                        ["errorMesssage": errorMessage, "errorCode": errorCode])
                }
            })
            task.resume()
        } catch {
            print(error)
        }
    }
    
}
