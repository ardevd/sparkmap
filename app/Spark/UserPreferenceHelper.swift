//
//  UserPreferenceHelper.swift
//  SparkMap
//
//  Created by Edvard Holst on 03/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

class UserPreferenceHelper {
    
    static func getClusteringThresholdValue() -> Int {
        let defaults = UserDefaults.standard
        let clusteringThresholdDefaultValue = ["clusteringThreshold" : 4]
        defaults.register(defaults: clusteringThresholdDefaultValue)
        return defaults.integer(forKey: "clusteringThreshold")
    }
    
}
