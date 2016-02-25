//
//  LastDataUpdateLocationSingelton.swift
//  SparkMap
//
//  Created by Edvard Holst on 25/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import MapKit

public class LastUpdateLocationSingelton {
    var location = CLLocation(latitude: 0.00, longitude: 0.00)
    static let center : LastUpdateLocationSingelton = LastUpdateLocationSingelton()
    
    private init() {}
    
}
