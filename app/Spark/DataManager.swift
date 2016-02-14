//
//  DataManager.swift
//  Spark
//
//  Created by Edvard Holst on 30/10/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject {
    
    
    var globalMoc: NSManagedObjectContext?
    
    override init() {
        super.init()
        globalMoc = self.managedObjectContext
        
    }
    
    lazy var mainMoc: NSManagedObjectContext = { [unowned self] in
        let moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        moc.parentContext = self.managedObjectContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
        }()
    
    //TODO: Use this MOC to do data maintenance
    lazy var secondMoc: NSManagedObjectContext = { [unowned self] in
        let moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        moc.parentContext = self.managedObjectContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
        }()
    
    
    // Define our URLSession.
    var urlSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        return session
    }()
    
    func postChargerComment(){
        
    }
    
    func downloadChargerComments(){
        
    }
    
    func fetchChargerComments(){
        
    }
    
    func downloadChargerPicture(){
        
    }
    
    func fetchChargerPictures(){
        
    }
    
    
    func retrieveNearbyChargerData(Latitude latitude: Double, Longitude longitude: Double) -> [ChargerPrimary]?{
        var chargers: [ChargerPrimary] = [ChargerPrimary]()
        
        mainMoc.performBlockAndWait {
            // Fetching data from CoreData
            let fetchRequest = NSFetchRequest()
            
            // List of NSPredicates
            var fetchChargersSubPredicates = [NSPredicate]()
            
            // Add default query predicate
            fetchChargersSubPredicates.append(NSPredicate(format: "chargerLatitude BETWEEN {%f,%f} AND chargerLongitude BETWEEN {%f,%f}", (latitude-0.10), (latitude+0.10), (longitude-0.10), (longitude+0.10)))
            
            // Optionally add connection type predicate
            if let connectionTypeIDsFromSettings = NSUserDefaults.standardUserDefaults().arrayForKey("connectionFilterIds") as? [Int] {
                if (connectionTypeIDsFromSettings.count > 0) {
                    fetchChargersSubPredicates.append(NSPredicate(format: "chargerLatitude BETWEEN {%f,%f} AND chargerLongitude BETWEEN {%f,%f} AND ANY chargerDetails.connections.connectionTypeId IN %@", (latitude-0.15), (latitude+0.15), (longitude-0.15), (longitude+0.15), connectionTypeIDsFromSettings))
                }
            }
            
            // Optionally add minAmps predicate
            let minAmpsFromSettings = NSUserDefaults.standardUserDefaults().integerForKey("minAmps")
            if (minAmpsFromSettings > 0) {
                fetchChargersSubPredicates.append(NSPredicate(format: "ANY chargerDetails.connections.connectionAmp >= %d", minAmpsFromSettings))
            }
            
            // Optionally add fastcharge predicate
            let fastChargeOnlyFromSettings = NSUserDefaults.standardUserDefaults().boolForKey("fastchargeOnly")
            if (fastChargeOnlyFromSettings) {
                fetchChargersSubPredicates.append(NSPredicate(format: "ANY chargerDetails.connections.connectionSupportsFastCharging = true"))
            }
            
            let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: fetchChargersSubPredicates)
            fetchRequest.predicate = compoundPredicate
            
            let entity = NSEntityDescription.entityForName("ChargerPrimary", inManagedObjectContext: self.mainMoc)
            fetchRequest.entity = entity
            
            let sortDescriptor = NSSortDescriptor(key: "chargerDistance", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            do {
                chargers = try self.mainMoc.executeFetchRequest(fetchRequest) as! [ChargerPrimary]
                //TODO Calculate distance and sort upon distance
                
                
            } catch {
                let jsonError = error as NSError
                NSLog("\(jsonError), \(jsonError.localizedDescription)")
                abort()
            }
        }
        
        return chargers
        
    }
    
    func uploadUserPhoto(){
//        guard let url = NSURL(string: "https://sparkmap.zygotelabs.net/upload_photo.php") else { return }
//        let urlRequest = NSMutableURLRequest(URL: url)
//        urlRequest.HTTPMethod = "POST"
//        let boundary = generateBoundaryString()
        //request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    
    func downloadNearbyChargers(Latitude latitude: Double, Longitude longitude: Double){
        //Check if we are in offline mode first.
        let defaults = NSUserDefaults.standardUserDefaults()
        let offlineMode = defaults.boolForKey("offlineMode")
        if (!offlineMode){
            // TODO - Add option to select units of measurements
            guard let url = NSURL(string: "https://api.openchargemap.io/v2/poi/?output=json&verbose=false&maxresults=100&includecomments=true&distanceunit=KM&latitude=\(latitude)&longitude=\(longitude)") else { return }
            
            // HTTP GET
            let urlRequest = NSURLRequest(URL: url)
            
            // For a HTTP POST, do the following.
            /*
            var urlRequest = NSMutableURLRequest(URL: url)
            urlRequest.HTTPMethod = "POST"
            */
            
            SwiftSpinner.show("Downloading Data").addTapHandler({
                SwiftSpinner.hide()
                }, subtitle: "Tap to hide")
            // dataTaskWithRequest will handle threading.
            let dataTask = urlSession.dataTaskWithRequest(urlRequest) { (data: NSData?, response: NSURLResponse?, errorSession: NSError?) -> Void in
                
                if let err = errorSession {
                    SwiftSpinner.show("\(err.localizedDescription)", animated: false).addTapHandler({
                        SwiftSpinner.hide()
                        }, subtitle: "Dismiss")
                    NSLog("\(err), \(err.localizedDescription)")
                    // abort()
                }
                else {
                    if let dataList = data {
                        // Convert NSData to JSON
                        do {
                            guard let jsonArray = try NSJSONSerialization.JSONObjectWithData(dataList, options: NSJSONReadingOptions.MutableContainers) as? [NSDictionary] else { return }
                            
                            guard let moc = self.globalMoc else { return }
                            moc.performBlockAndWait {
                                // Convert NSArray. Cast NSDictionary
                                for element in jsonArray {
                                    // Element = Charging station
                                    
                                    let chargerPrimary = NSEntityDescription.insertNewObjectForEntityForName("ChargerPrimary",inManagedObjectContext: moc) as! ChargerPrimary
                                    
                                    let chargerDetails = NSEntityDescription.insertNewObjectForEntityForName("ChargerDetails",inManagedObjectContext: moc) as! ChargerDetails
                                    
                                    
                                    
                                    guard let chargerId = element["ID"] else { return }
                                    if let chargerIdValue = (chargerId as? NSNumber)?.stringValue {
                                        chargerPrimary.chargerId = chargerIdValue
                                    }
                                    
                                    if let chargerNumberOfPoints = element["NumberOfPoints"] as? NSNumber {
                                        chargerPrimary.chargerNumberOfPoints = chargerNumberOfPoints.longLongValue
                                    }
                                    
                                    if let chargerDataQualityLevel = element["DataQualityLevel"] as? NSNumber {
                                        chargerPrimary.chargerDataQualityLevel = chargerDataQualityLevel.longLongValue
                                    }
                                    
                                    if let chargerDataLastUpdateTime = element["DateLastStatusUpdate"] as? String {
                                        //Format date string to NSDate
                                        let dateFormatter = NSDateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                        let cleanedUpdateDate = chargerDataLastUpdateTime.stringByReplacingOccurrencesOfString("Z", withString: "")
                                        if let date = dateFormatter.dateFromString(cleanedUpdateDate) {
                                            
                                            chargerPrimary.chargerDataLastUpdate = date.timeIntervalSinceReferenceDate
                                        }
                                        
                                    }
                                    
                                    // Media
                                    if let mediaItems = element["MediaItems"] as? [NSDictionary] {
                                        
                                        for mediaItemElement in mediaItems {
                                            if let mediaURL = mediaItemElement["ItemURL"] as? String {
                                                chargerPrimary.chargerImage = mediaURL
                                                
                                            }
                                            
                                            if let mediaURLThumb = mediaItemElement["ItemThumbnailURL"] as? String {
                                                chargerPrimary.chargerImageThumb = mediaURLThumb
                                                //NSLog("\(mediaURLThumb)")
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                    // Connections
                                    if let connectionData = element["Connections"] as? [NSDictionary] {
                                        for connectionElement in connectionData {
                                            
                                            let connection = NSEntityDescription.insertNewObjectForEntityForName("Connection", inManagedObjectContext: moc) as! Connection
                                            
                                            if let connectionId = connectionElement["ID"] as? NSNumber {
                                                connection.connectionId = connectionId.longLongValue
                                            }
                                            
                                            if let connectionTypeId = connectionElement["ConnectionTypeID"] as? NSNumber {
                                                connection.connectionTypeId = connectionTypeId.longLongValue
                                            }
                                            
                                            if let connectionQuantity = connectionElement["Quantity"] as? NSNumber {
                                                connection.connectionQuantity = connectionQuantity.longLongValue
                                            }
                                            
                                            if let connectionAmp = connectionElement["Amps"] as? NSNumber {
                                                connection.connectionAmp = connectionAmp.longLongValue
                                            }
                                            
                                            if let connectionVoltage = connectionElement["Voltage"] as? NSNumber {
                                                connection.connectionVoltage = connectionVoltage.longLongValue
                                            }
                                            
                                            if let connectionPowerKW = connectionElement["PowerKW"] as? NSNumber {
                                                connection.connectionPowerKW = connectionPowerKW.longLongValue
                                            }
                                            
                                            if let connectionTypeData = connectionElement["ConnectionType"] {
                                                if let connectionTypeTitle = connectionTypeData["Title"] as? String {
                                                    connection.connectionTypeTitle = connectionTypeTitle
                                                }
                                            }
                                            
                                            if let connectionLevelData = connectionElement["Level"] {
                                                if let connectionSupportsFastCharging = connectionLevelData["IsFastChargeCapable"] as? Bool {
                                                    connection.connectionSupportsFastCharging = connectionSupportsFastCharging
                                                }
                                            }
                                            
                                            connection.chargerSecondary = chargerDetails
                                        }
                                    }
                                    
                                    if let addressData = element["AddressInfo"] {
                                        
                                        if let chargerTitle = addressData["Title"] as? String {
                                            chargerPrimary.chargerTitle = chargerTitle
                                        }
                                        
                                        if let chargerSubtitle = addressData["AddressLine1"] as? String {
                                            chargerPrimary.chargerSubtitle = chargerSubtitle
                                        }
                                        
                                        if let chargerLatitude = addressData["Latitude"] as? Double {
                                            chargerPrimary.chargerLatitude = chargerLatitude
                                        }
                                        
                                        if let chargerLongitude = addressData["Longitude"] as? Double {
                                            chargerPrimary.chargerLongitude = chargerLongitude
                                        }
                                        
                                        if let chargerDistance = addressData["Distance"] as? Double {
                                            chargerPrimary.chargerDistance = chargerDistance
                                        }
                                        
                                        if let accessComment = addressData["AccessComments"] as? String {
                                            chargerDetails.chargerAccessComment = accessComment
                                        }
                                        
                                        if let addressLine1 = addressData["AddressLine1"] as? String {
                                            chargerDetails.chargerAddress1 = addressLine1
                                            //NSLog("\(addressLine1)")
                                        }
                                        
                                        if let addressLine2 = addressData["AddressLine2"] as? String {
                                            chargerDetails.chargerAddress2 = addressLine2
                                        }
                                        
                                        if let chargerContact = addressData["ContactEmail"] as? String {
                                            chargerDetails.chargerContact = chargerContact
                                        }
                                        
                                        if let postcode = addressData["Postcode"] as? String {
                                            chargerDetails.chargerPostcode = postcode
                                        }
                                        
                                        if let town = addressData["Town"] as? String {
                                            chargerDetails.chargerTown = town
                                        }
                                        
                                        if let countryData = addressData["Country"] {
                                            
                                            if let country = countryData!["Title"] as? String {
                                                chargerDetails.chargerCountry = country
                                            }
                                        }
                                        
                                    }
                                    
                                    
                                    if let recentlyVerified = element["IsRecentlyVerified"] as? Bool {
                                        chargerDetails.chargerRecentlyVerified = recentlyVerified
                                    }
                                    
                                    if let generalComment = element["GeneralComments"] as? String {
                                        chargerDetails.chargerGeneralComment = generalComment
                                    }
                                    
                                    if let usageData = element["UsageType"] {
                                        if let usageType = usageData["Title"] as? String {
                                            chargerDetails.chargerUsageType = usageType
                                        }
                                    }
                                    
                                    if let chargerStatus = element["StatusType"] {
                                        if let chargerIsOperational = chargerStatus["IsOperational"] as? Bool {
                                            chargerPrimary.chargerIsOperational = chargerIsOperational
                                        }
                                    }
                                    
                                    if let operatorData = element["OperatorInfoX"] {
                                        let chargerOperator = NSEntityDescription.insertNewObjectForEntityForName("ChargerOperator",inManagedObjectContext: moc) as! ChargerOperator
                                        
                                        
                                        if let operatorEmail = operatorData["ContactEmail"] as? String {
                                            chargerOperator.operatorEmail = operatorEmail
                                        }
                                        
                                        guard let operatorId = operatorData["ID"] else { return }
                                        let operatorIdValue = (operatorId as? NSNumber)
                                        chargerOperator.operatorId = operatorIdValue!.stringValue
                                        
                                        
                                        if let operatorName = operatorData["Title"] as? String {
                                            chargerOperator.operatorName = operatorName
                                        }
                                        
                                        if let operatorWeb = operatorData["WebsiteURL"] as? String {
                                            chargerOperator.operatorWeb = operatorWeb
                                        }
                                        
                                        // Relationships
                                        chargerOperator.chargerPrimary = chargerPrimary
                                        
                                    }
                                    
                                    chargerPrimary.chargerDetails = chargerDetails
                                    
                                }
                                
                                do{
                                    try moc.save()
                                    // Data is saved, send notification
                                    NSNotificationCenter.defaultCenter().postNotificationName("ChargerDataUpdate", object: nil)
                                    SwiftSpinner.hide()
                                    
                                }catch {
                                    let jsonError = error as NSError
                                    NSLog("\(jsonError), \(jsonError.localizedDescription)")
                                    
                                }
                            }
                            
                        } catch {
                            let jsonError = error as NSError
                            NSLog("\(jsonError), \(jsonError.localizedDescription)")
                            abort()
                        }
                    }
                    else {
                        NSLog("No data available")
                        abort()
                    }
                }
            }
            // if you forget this line, nothing will happen
            dataTask.resume()
        }
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.zygotelabs.Spark" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Spark", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
                configuration: nil,
                URL: url,
                options: [NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        // We make the concurrencyType for this MOC Private in order to prevent it from running on the Main Thread.
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        // Set merge policy to overwrite existing record if duplicate is detected.
        managedObjectContext.mergePolicy = NSOverwriteMergePolicy
        
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            
            mainMoc.performBlock({ () -> Void in
                do {
                    
                    try self.mainMoc.save()
                    self.managedObjectContext.performBlockAndWait({ () -> Void in
                        do {
                            
                            try self.managedObjectContext.save()
                        } catch {
                            let nserror = error as NSError
                            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                            abort()
                            
                        }
                        
                    })
                } catch {
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                    
                }
            })
        }         }
    
}
