//
//  UserPhotoSubmissionManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/03/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class UserPhotoSubmissionManager: NSObject {
    
    
    func myImageUploadRequest(userImageView: UIImageView, chargerId: String)
    {
        
        let userImage = userImageView.image!
        let myUrl = NSURL(string: "https://sparkmap.zygotelabs.net/test.php");
        
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";

        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let imageData = UIImageJPEGRepresentation(userImage, 1)
        
        if(imageData==nil)
        {
            return
        }
        
        request.HTTPBody = createBodyWithParameters(chargerId, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        
        
        //myActivityIndicator.startAnimating();
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                NSLog("Unresolved error \(error)")
                return
            }
            
            // You can print out response object
            NSLog("******* response = \(response)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            NSLog("****** response data = \(responseString!)")
            
            
            dispatch_async(dispatch_get_main_queue(),{
                //TODO: Show user feedback
                //self.myActivityIndicator.stopAnimating()
                //self.myImageView.image = nil;
            });
            
            /*
            if let parseJSON = json {
            var firstNameValue = parseJSON["firstName"] as? String
            println("firstNameValue: \(firstNameValue)")
            }
            */
            
            
            
        }
        
        task.resume()
        
    }
    
    
    func createBodyWithParameters(chargerId: String, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        
        
        let filename = "\(chargerId).jpg"
        
        let mimetype = "image/jpg"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(imageDataKey)
        body.appendString("\r\n")
        
        
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    
    
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    
    
}
extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
