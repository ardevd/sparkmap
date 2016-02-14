//
//  AnnotationCharger.swift
//  Spark
//
//  Created by Edvard Holst on 31/10/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import MapKit

class AnnotationCharger: NSObject, MKAnnotation {
    
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var charger: ChargerPrimary
    
    init(coordinate: CLLocationCoordinate2D, charger: ChargerPrimary) {
        self.coordinate = coordinate
        self.charger = charger
        super.init()
    }
    
}