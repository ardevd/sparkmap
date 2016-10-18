//
//  CommentSubmissionManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

class CommentSubmissionManager {
    
    static func submitComment(_ chargerId: Int, commentText: String, rating: Int, accessToken: String) {
        let commentSubmissionURL = "https://api.openchargemap.io/v3/comment"
        guard let url = URL(string: commentSubmissionURL) else { return }
        
        let json = [ "ChargePointID": chargerId , "UserCommentTypeID": 10, "Comment": commentText, "Rating": rating, "CheckinStatusTypeID": 10 ] as [String : Any]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            // For a HTTP POST, do the following.
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            urlRequest.httpMethod = "POST"
            // insert json data to the request
            urlRequest.httpBody = jsonData
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                //URLSession.shared.dataTask(with: request) {data, response, err in
                if error != nil{
                    print("Error -> \(error)")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMCommentPostError"), object: nil, userInfo:
                        ["errorMesssage": error!.localizedDescription])
                    return
                }
                
                do {
                    if let httpResponse = response as? HTTPURLResponse {
                        let responseCode = httpResponse.statusCode
                        print(responseCode)
                        if responseCode == 200 {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMCommentPostSuccess"), object: nil)
                        } else if responseCode == 401 {
                            let unauthorizedErrorString = NSLocalizedString("Authentication Failed", comment: "Authentication Failed Message")
                            let errorMessage = unauthorizedErrorString
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMCommentPostError"), object: nil, userInfo:
                                ["errorMesssage": errorMessage])
                        } else {
                            let unauthorizedErrorString = NSLocalizedString("Invalid Response from server", comment: "Invalid Response From Server")
                            let errorMessage = unauthorizedErrorString
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMCommentPostError"), object: nil, userInfo:
                                ["errorMesssage": errorMessage])
                        }
                    }
                    
                }
            }.resume()
        } catch {
            print(error)
        }
    }
}
