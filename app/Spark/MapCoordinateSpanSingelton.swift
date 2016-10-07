//
//  MapCoordinateSpanSingelton.swift
//  SparkMap
//
//  Created by Edvard Holst on 19/04/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import MapKit

open class MapCoordinateSpanSingelton {
    var mapSpan = MKCoordinateSpan(latitudeDelta: 0.00, longitudeDelta: 0.00)
    static let span : MapCoordinateSpanSingelton = MapCoordinateSpanSingelton()
    
    fileprivate init() {}
    
}
