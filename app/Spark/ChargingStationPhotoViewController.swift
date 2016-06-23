//
//  ChargingStationPhotoViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 23/06/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class ChargingStationPhotoViewController: UIViewController {
    
    @IBOutlet var chargingStationImage: UIImageView!
    var chargingStationImageUrl: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        downloadThumbnailImage(chargingStationImageUrl!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func downloadThumbnailImage(imageUrl: String){
        // TODO: Merge this with the other thumbnail downloading code into a separate class. 
        
        if let url = NSURL(string: imageUrl) {
            let request: NSURLRequest = NSURLRequest(URL: url)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){
                (data, response, error) -> Void in
                
                if (error == nil && data != nil)
                {
                    func displayImage()
                    {
                        // Animate the fade in of the image
                        UIView.animateWithDuration(1.0, animations: {
                            self.chargingStationImage.image = UIImage(data: data!)
                        })
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), displayImage)
                }
                
                func dismissActivityIndicator(){
                }
                
                dispatch_async(dispatch_get_main_queue(), dismissActivityIndicator)
            }
            
            task.resume()
        }
    }
    

 }
