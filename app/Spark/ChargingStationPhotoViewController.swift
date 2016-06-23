//
//  ChargingStationPhotoViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 23/06/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class ChargingStationPhotoViewController: UIViewController {
    
    @IBOutlet var chargingStationBackgroundImageView: UIImageView!
    @IBOutlet var chargingStationForegroundImageView: UIImageView!
    var chargingStationImageUrl: String?
    var chargingStationImage: UIImage?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.chargingStationBackgroundImageView.image = chargingStationImage
        self.chargingStationForegroundImageView.image = chargingStationImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
 }
