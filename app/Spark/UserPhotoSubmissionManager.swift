//
//  UserPhotoSubmissionManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/03/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class UserPhotoSubmissionManager: NSObject {
    
    
    func userPhotoUploadRequest(_ userImageView: UIImageView, chargerId: String)
    {
        
        let userImage = resizeAndProcessImage(userImageView.image!)
        
        let photoUploadUrl = URL(string: "https://sparkmap.zygotelabs.net/photo_upload.php");
        let request = NSMutableURLRequest(url:photoUploadUrl!);
        request.httpMethod = "POST";
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = UIImageJPEGRepresentation(userImage, 0.7)
        
        if(imageData==nil)
        {
            postFailureNotification()
            return
        }
        
        request.httpBody = createBodyWithParameters(chargerId, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        
        //TODO: Add an activity indicator and use it here.
        //myActivityIndicator.startAnimating();
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            data, response, error in
            
            if error != nil {
                NSLog("Unresolved error \(error)")
                self.postFailureNotification()
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
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
            
            
            DispatchQueue.main.async(execute: {
                //TODO: Dismiss user feedback
                //self.myActivityIndicator.stopAnimating()
            });
        }) 
        
        task.resume()
        
    }
    
    func postSuccessNotification(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PhotoPostSuccess"), object: nil)
    }
    
    func postFailureNotification(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PhotoPostFailed"), object: nil)
    }
    
    
    func createBodyWithParameters(_ chargerId: String, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
        let body = NSMutableData();
        let timeInterval = Date().timeIntervalSince1970
        let filename = "\(chargerId)_\(timeInterval).jpg"
        let mimetype = "image/jpg"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        
        return body as Data
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    func resizeAndProcessImage(_ userImage: UIImage) -> UIImage {
        let image = userImage
        
        let size = image.size.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    
    
}
extension NSMutableData {
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
