//
//  UserPhotoSubmissionManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/03/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class UserPhotoSubmissionManager: NSObject {
    
    
    func userPhotoUploadRequest(userImageView: UIImageView, chargerId: String)
    {
        
        let userImage = resizeAndProcessImage(userImageView.image!)
        
        let photoUploadUrl = NSURL(string: "https://sparkmap.zygotelabs.net/photo_upload.php");
        let request = NSMutableURLRequest(URL:photoUploadUrl!);
        request.HTTPMethod = "POST";
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = UIImageJPEGRepresentation(userImage, 0.7)
        
        if(imageData==nil)
        {
            postFailureNotification()
            return
        }
        
        request.HTTPBody = createBodyWithParameters(chargerId, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        //TODO: Add an activity indicator and use it here.
        //myActivityIndicator.startAnimating();
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                NSLog("Unresolved error \(error)")
                self.postFailureNotification()
                return
            }
            
            if let httpResponse = response as? NSHTTPURLResponse {
                let responseCode = httpResponse.statusCode
                if responseCode == 200 {
                    self.postSuccessNotification()
                } else {
                    self.postFailureNotification()
                }
            }
            
            // You can print out response object
            // NSLog("******* response = \(response)")
            
            // Print out reponse body
            //let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            // NSLog("****** response data = \(responseString!)")
            
            
            dispatch_async(dispatch_get_main_queue(),{
                //TODO: Dismiss user feedback
                //self.myActivityIndicator.stopAnimating()
            });
        }
        
        task.resume()
        
    }
    
    func postSuccessNotification(){
        NSNotificationCenter.defaultCenter().postNotificationName("PhotoPostSuccess", object: nil)
    }
    
    func postFailureNotification(){
        NSNotificationCenter.defaultCenter().postNotificationName("PhotoPostFailed", object: nil)
    }
    
    
    func createBodyWithParameters(chargerId: String, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        let timeInterval = NSDate().timeIntervalSince1970
        let filename = "\(chargerId)_\(timeInterval).jpg"
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
    
    func resizeAndProcessImage(userImage: UIImage) -> UIImage {
        let image = userImage
        
        let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(0.5, 0.5))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    
    
}
extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
