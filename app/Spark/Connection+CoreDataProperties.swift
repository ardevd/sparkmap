//
//  Connection+CoreDataProperties.swift
//  SparkMap
//
//  Created by Edvard Holst on 19/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Connection {

    @NSManaged var connectionAmp: Int64
    @NSManaged var connectionId: Int64
    @NSManaged var connectionPowerKW: Int64
    @NSManaged var connectionQuantity: Int64
    @NSManaged var connectionSupportsFastCharging: Bool
    @NSManaged var connectionTypeId: Int64
    @NSManaged var connectionTypeTitle: String?
    @NSManaged var connectionVoltage: Int64
    @NSManaged var chargerSecondary: ChargerDetails?

}
