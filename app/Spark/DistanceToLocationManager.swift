//
//  DistanceToLocationManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 25/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import MapKit

class DistanceToLocationManager {
    
    static func distanceFromLastDataUpdateLocation(_ currentLocation: CLLocation) -> Double {
        let lastDataUpdateLocation =  LastUpdateLocationSingelton.center.location
        return currentLocation.distance(from: lastDataUpdateLocation)
    }
    
    static func compareChargerDistance(_ firstCharger: ChargerPrimary, secondCharger: ChargerPrimary) -> Bool {
        
        let location1 = CLLocation(latitude: firstCharger.chargerLatitude, longitude: firstCharger.chargerLongitude)
        let location2 = CLLocation(latitude: secondCharger.chargerLatitude, longitude: secondCharger.chargerLongitude)
        let mapLocationCoordinate = MapCenterCoordinateSingelton.center.coordinate
        let mapLocation = CLLocation(latitude: mapLocationCoordinate.latitude, longitude: mapLocationCoordinate.longitude)
        let distanceToFirstLocation = location1.distance(from: mapLocation)
        let distanceToSecondLocation = location2.distance(from: mapLocation)
        
        if (distanceToFirstLocation < distanceToSecondLocation) {
            return true
        } else {
            return false
        }
    }
}


