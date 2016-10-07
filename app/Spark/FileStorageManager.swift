//
//  FileStorageManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 03/09/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class FileStorageManager {
    
    func storeImageFile(_ image: UIImage, path: String ) -> Bool{
        let pngImageData = UIImagePNGRepresentation(image)
        let result = (try? pngImageData!.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil
        
        return result
    }

    func getDocumentsURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    func fileInDocumentsDirectory(_ filename: String) -> String {
        
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL.path
        
    }
    
    func loadImageFromPath(_ path: String) -> UIImage? {
        
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
