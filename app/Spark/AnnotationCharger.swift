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
    
    func getChargerAnnotationImage() -> UIImage {
        // Return annotation image according to charging type.
        var chargerAnnotationImage: UIImage
        let connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
        var stationSupportsFastCharging = false
        var stationIsTeslaSupercharger = false
        
        for connection in connections {
            if connection.connectionTypeId == 27 {
                stationIsTeslaSupercharger = true
            }
            if connection.connectionSupportsFastCharging {
                stationSupportsFastCharging = true
            }
        }
        if stationSupportsFastCharging && !stationIsTeslaSupercharger{
            chargerAnnotationImage = UIImage(named: "ChargerBlue")!
        } else if stationIsTeslaSupercharger {
            chargerAnnotationImage = UIImage(named: "ChargerTesla")!
        } else {
            chargerAnnotationImage = UIImage(named: "ChargerGreen")!
        }
        
        return chargerAnnotationImage
    }
}