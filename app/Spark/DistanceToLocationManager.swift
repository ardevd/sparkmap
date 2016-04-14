//
//  DistanceToLocationManager.swift
//  SparkMap
//
//  Created by Edvard Holst on 25/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import MapKit

class DistanceToLocationManager {
    
    static func distanceFromLastDataUpdateLocation(currentLocation: CLLocation) -> Double {
        let lastDataUpdateLocation =  LastUpdateLocationSingelton.center.location
        return currentLocation.distanceFromLocation(lastDataUpdateLocation)
    }
    
    static func compareChargerDistance(firstCharger: ChargerPrimary, secondCharger: ChargerPrimary) -> Bool {
        
        let location1 = CLLocation(latitude: firstCharger.chargerLatitude, longitude: firstCharger.chargerLongitude)
        let location2 = CLLocation(latitude: secondCharger.chargerLatitude, longitude: secondCharger.chargerLongitude)
        let mapLocationCoordinate = MapCenterCoordinateSingelton.center.coordinate
        let mapLocation = CLLocation(latitude: mapLocationCoordinate.latitude, longitude: mapLocationCoordinate.longitude)
        let distanceToFirstLocation = location1.distanceFromLocation(mapLocation)
        let distanceToSecondLocation = location2.distanceFromLocation(mapLocation)
        
        if (distanceToFirstLocation < distanceToSecondLocation) {
            return true
        } else {
            return false
        }
    }
}


