//
//  ChargerOperator+CoreDataProperties.swift
//  SparkMap
//
//  Created by Edvard Holst on 08/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChargerOperator {

    @NSManaged var operatorEmail: String?
    @NSManaged var operatorId: String?
    @NSManaged var operatorName: String?
    @NSManaged var operatorWeb: String?
    @NSManaged var chargerPrimary: ChargerPrimary?

}
