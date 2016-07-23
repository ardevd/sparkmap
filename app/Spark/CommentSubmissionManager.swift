//
//  CommentSubmissionManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

class CommentSubmissionManager {
    
    static func submitComment(chargerId: Int, commentText: String, rating: Int, accessToken: String) {
        let commentSubmissionURL = "https://api.openchargemap.io/v3/comment"
        guard let url = NSURL(string: commentSubmissionURL) else { return }
        
        let json = [ "ChargePointID": chargerId , "UserCommentTypeID": 10, "Comment": commentText, "Rating": rating, "CheckinStatusTypeID": 10 ]
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            // For a HTTP POST, do the following.
            let urlRequest = NSMutableURLRequest(URL: url)
            urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            urlRequest.HTTPMethod = "POST"
            // insert json data to the request
            urlRequest.HTTPBody = jsonData
            
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest){ data, response, error in
                if error != nil{
                    print("Error -> \(error)")
                    NSNotificationCenter.defaultCenter().postNotificationName("OCMCommentPostError", object: nil, userInfo:
                        ["errorMesssage": error!.localizedDescription])
                    return
                }
                
                do {
                    if let httpResponse = response as? NSHTTPURLResponse {
                        let responseCode = httpResponse.statusCode
                        print(responseCode)
                        if responseCode == 200 {
                            NSNotificationCenter.defaultCenter().postNotificationName("OCMCommentPostSuccess", object: nil)
                        } else if responseCode == 401 {
                            let unauthorizedErrorString = NSLocalizedString("Authentication Failed", comment: "Authentication Failed Message")
                            let errorMessage = unauthorizedErrorString
                            NSNotificationCenter.defaultCenter().postNotificationName("OCMCommentPostError", object: nil, userInfo:
                                ["errorMesssage": errorMessage])
                        } else {
                            let unauthorizedErrorString = NSLocalizedString("Invalid Response from server", comment: "Invalid Response From Server")
                            let errorMessage = unauthorizedErrorString
                            NSNotificationCenter.defaultCenter().postNotificationName("OCMCommentPostError", object: nil, userInfo:
                                ["errorMesssage": errorMessage])
                        }
                    }
                    
                }
            }
            task.resume()
        } catch {
            print(error)
        }
    }
}