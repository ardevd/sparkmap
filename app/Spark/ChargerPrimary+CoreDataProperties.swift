//
//  ChargerPrimary+CoreDataProperties.swift
//  SparkMap
//
//  Created by Edvard Holst on 28/04/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChargerPrimary {

    @NSManaged var chargerDataLastUpdate: NSTimeInterval
    @NSManaged var chargerDataQualityLevel: Int64
    @NSManaged var chargerDistance: Double
    @NSManaged var chargerId: String?
    @NSManaged var chargerImage: String?
    @NSManaged var chargerImageThumb: String?
    @NSManaged var chargerIsOperational: Bool
    @NSManaged var chargerLatitude: Double
    @NSManaged var chargerLongitude: Double
    @NSManaged var chargerNumberOfPoints: Int64
    @NSManaged var chargerSubtitle: String?
    @NSManaged var chargerTitle: String?
    @NSManaged var chargerWasAddedDate: Double
    @NSManaged var chargerDetails: ChargerDetails?
    @NSManaged var chargerOperator: ChargerOperator?

}
