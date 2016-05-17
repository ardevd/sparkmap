//
//  ChargerDetails+CoreDataProperties.swift
//  SparkMap
//
//  Created by Edvard Holst on 17/05/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChargerDetails {

    @NSManaged var chargerAccessComment: String?
    @NSManaged var chargerAddress1: String?
    @NSManaged var chargerAddress2: String?
    @NSManaged var chargerContact: String?
    @NSManaged var chargerCountry: String?
    @NSManaged var chargerGeneralComment: String?
    @NSManaged var chargerPostcode: String?
    @NSManaged var chargerPrimaryContactNumber: String?
    @NSManaged var chargerProvince: String?
    @NSManaged var chargerRecentlyVerified: Bool
    @NSManaged var chargerTown: String?
    @NSManaged var chargerUsageType: String?
    @NSManaged var chargerPrimary: ChargerPrimary?
    @NSManaged var comments: NSSet?
    @NSManaged var connections: NSSet?

}
