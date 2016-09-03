//
//  FileStorageManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 03/09/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class FileStorageManager {
    
    func storeImageFile(image: UIImage, path: String ) -> Bool{
        let pngImageData = UIImagePNGRepresentation(image)
        let result = pngImageData!.writeToFile(path, atomically: true)
        
        return result
    }

    func getDocumentsURL() -> NSURL {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        return documentsURL
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        
        let fileURL = getDocumentsURL().URLByAppendingPathComponent(filename)
        return fileURL.path!
        
    }
    
    func loadImageFromPath(path: String) -> UIImage? {
        
        let image = UIImage(contentsOfFile: path)
        
        if image == nil {
            
            //print("missing image at: \(path)")
        }
        // Debug print
        //print("Loading image from path: \(path)")
        
        // Return the stored image
        return image
        
    }
    
}