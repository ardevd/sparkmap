//
//  Comment+CoreDataProperties.swift
//  SparkMap
//
//  Created by Edvard Holst on 16/05/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Comment {

    @NSManaged var comment: String?
    @NSManaged var commentId: Int64
    @NSManaged var rating: Int32
    @NSManaged var username: String?
    @NSManaged var chargerSecondary: ChargerDetails?

}
