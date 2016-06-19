//
//  ChargerImageHelper.swift
//  SparkMap
//
//  Created by Edvard Holst on 19/06/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
import UIKit

class ChargerImageHelper {
    
    static func getChargerAnnotationImage(charger: ChargerPrimary) -> UIImage {
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