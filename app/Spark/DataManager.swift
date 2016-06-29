//
//  DataManager.swift
//  Spark
//
//  Created by Edvard Holst on 30/10/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class DataManager: NSObject {
    
    
    var globalMoc: NSManagedObjectContext?
    
    override init() {
        super.init()
        globalMoc = self.managedObjectContext
        
    }
    
    enum DataManagerError: ErrorType {
        case InvalidDateFormat
    }
    
    lazy var mainMoc: NSManagedObjectContext = { [unowned self] in
        let moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        moc.parentContext = self.managedObjectContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
        }()
    
    // Use this MOC to do data maintenance
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
    
    func getDataFilesSize() -> UInt64{
        var filePaths = [String]()
        // Sqlite file
        let databaseFileUrl = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let databaseFilePath = databaseFileUrl.path
        filePaths.append(databaseFilePath!)
        
        // wal journal file
        let walJournalFileUrl = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let walJournalFilePath = walJournalFileUrl.path
        filePaths.append(walJournalFilePath!)
        
        // shm journal file
        let shmJournalFileUrl = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let shmJournalFilePath = shmJournalFileUrl.path
        filePaths.append(shmJournalFilePath!)
        
        var totalCacheFilesSize : UInt64 = 0
        
        for filePath in filePaths {
            
            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
                
                if let _attr = attr {
                    totalCacheFilesSize += _attr.fileSize();
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        return totalCacheFilesSize
    }
    
    func removeAllChargerData(){
        // Remove all charging data from persistent storage
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("ChargerPrimary", inManagedObjectContext: self.secondMoc)
        fetchRequest.entity = entity
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try self.secondMoc.executeRequest(deleteRequest)
        } catch {
            let deleteError = error as NSError
            NSLog("\(deleteError), \(deleteError.localizedDescription)")
        }
        
    }
    
    func removeOldChargerData(){
        // Remove old charger data to prevent database from growing too big
        // Delete chargers older than 30 days
        let fetchRequest = NSFetchRequest()
        let timestampThirtyDaysAgo = NSDate().timeIntervalSince1970 - 2505600
        fetchRequest.predicate = NSPredicate(format: "chargerWasAddedDate =< %f", timestampThirtyDaysAgo)
        let entity = NSEntityDescription.entityForName("ChargerPrimary", inManagedObjectContext: self.secondMoc)
        fetchRequest.entity = entity
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try self.secondMoc.executeRequest(deleteRequest)
        } catch {
            let deleteError = error as NSError
            NSLog("\(deleteError), \(deleteError.localizedDescription)")
        }
    }
    
    
    func retrieveNearbyChargerData(Latitude latitude: Double, Longitude longitude: Double) -> [ChargerPrimary]?{
        var chargers: [ChargerPrimary] = [ChargerPrimary]()
        
        mainMoc.performBlockAndWait {
            // Fetching data from CoreData
            let fetchRequest = NSFetchRequest()
            
            // List of NSPredicates
            var fetchChargersSubPredicates = [NSPredicate]()
            
            // Add default query predicate
            // Get map span singelton value
            let mapSpan = MapCoordinateSpanSingelton.span.mapSpan
            fetchChargersSubPredicates.append(NSPredicate(format: "chargerLatitude BETWEEN {%f,%f} AND chargerLongitude BETWEEN {%f,%f}", (latitude-mapSpan.latitudeDelta * 1.2), (latitude+mapSpan.latitudeDelta * 1.2), (longitude-mapSpan.longitudeDelta * 1.2), (longitude+mapSpan.longitudeDelta * 1.2)))
            
            // Optionally add connection type predicate
            if let connectionTypeIDsFromSettings = NSUserDefaults.standardUserDefaults().arrayForKey("connectionFilterIds") as? [Int] {
                if (connectionTypeIDsFromSettings.count > 0) {
                    fetchChargersSubPredicates.append(NSPredicate(format: "chargerLatitude BETWEEN {%f,%f} AND chargerLongitude BETWEEN {%f,%f} AND ANY chargerDetails.connections.connectionTypeId IN %@", (latitude-0.20), (latitude+0.20), (longitude-0.20), (longitude+0.20), connectionTypeIDsFromSettings))
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
    
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func ocmDateFormatParser(OCMDateString dateString: String) throws -> NSDate {
        //Format date string from OCM to NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let cleanedUpdateDate = dateString.stringByReplacingOccurrencesOfString("Z", withString: "")
        guard let formattedDate = dateFormatter.dateFromString(cleanedUpdateDate) else {
            throw DataManagerError.InvalidDateFormat
        }
        return formattedDate
    }
    
    func ocmCommentDateFormatParser(OCMDateString dateString: String) throws -> NSDate  {
        //Format comment date string from OCM to NSDate
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
        let cleanedUpdateDate = dateString.stringByReplacingOccurrencesOfString("Z", withString: "")
        guard let formattedDate = dateFormatter.dateFromString(cleanedUpdateDate) else {
            throw DataManagerError.InvalidDateFormat
        }
        return formattedDate
    }
    
    
    func downloadNearbyChargers(Latitude latitude: Double, Longitude longitude: Double){
        //Check if we are in offline mode first.
        let defaults = NSUserDefaults.standardUserDefaults()
        // Set defaults. TODO - Do this separately.
        let appDefaults = ["showDownloadDialog" : true]
        defaults.registerDefaults(appDefaults)
        let offlineMode = defaults.boolForKey("offlineMode")
        let showDownloadDialog = defaults.boolForKey("showDownloadDialog")
        
        if (!offlineMode){
            // TODO - Add option to select units of measurements
            guard let url = NSURL(string: "https://api.openchargemap.io/v2/poi/?output=json&verbose=false&maxresults=500&includecomments=true&distanceunit=KM&latitude=\(latitude)&longitude=\(longitude)") else { return }
            
            // HTTP GET
            let urlRequest = NSURLRequest(URL: url)
            
            // For a HTTP POST, do the following.
            /*
             var urlRequest = NSMutableURLRequest(URL: url)
             urlRequest.HTTPMethod = "POST"
             */
            
            let dismissString = NSLocalizedString("Dismiss", comment:"Download Spinner dismiss button text")
            if showDownloadDialog{
                let downloadingDataString = NSLocalizedString("Downloading Data...", comment: "Downloading Data Spinner Text")
                let tapToHideSubtitleString = NSLocalizedString("Tap to hide", comment: "Tap to hide subtitle")
                SwiftSpinner.show(downloadingDataString).addTapHandler({
                    SwiftSpinner.hide()
                    }, subtitle: tapToHideSubtitleString)
            }
            // dataTaskWithRequest will handle threading.
            let dataTask = urlSession.dataTaskWithRequest(urlRequest) { (data: NSData?, response: NSURLResponse?, errorSession: NSError?) -> Void in
                
                if let err = errorSession {
                    SwiftSpinner.show("\(err.localizedDescription)", animated: false).addTapHandler({
                        SwiftSpinner.hide()
                        }, subtitle: dismissString)
                    NSLog("\(err), \(err.localizedDescription)")
                }
                else {
                    if let dataList = data {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let processingDataString = NSLocalizedString("Processing Data...", comment: "Processing Data Spinner Text")
                            SwiftSpinner.sharedInstance.titleLabel.text = processingDataString
                            
                        })
                        
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
                                        do {
                                        let date = try self.ocmDateFormatParser(OCMDateString: chargerDataLastUpdateTime)
                                        chargerPrimary.chargerDataLastUpdate = date.timeIntervalSinceReferenceDate
                                        } catch DataManagerError.InvalidDateFormat {
                                            NSLog("Invalid Status Update date format")
                                        } catch {
                                            let nserror = error as NSError
                                            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
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
                                    
                                    // Comments
                                    if let commentData = element["UserComments"] as? [NSDictionary] {
                                        for commentElement in commentData {
                                            
                                            if let commentText = commentElement["Comment"] as? String {
                                                if (commentText.characters.count > 0) {
                                                    let comment = NSEntityDescription.insertNewObjectForEntityForName("Comment", inManagedObjectContext: moc) as! Comment
                                                    
                                                    comment.comment = commentText
                                                    if let commentId = commentElement["ID"] as? NSNumber {
                                                        comment.commentId = commentId.stringValue
                                                    }
                                    
                                                    if let commentRating = commentElement["Rating"] as? NSNumber {
                                                        comment.rating = commentRating.intValue
                                                    }
                                                    
                                                    if let commentUsername = commentElement["UserName"] as? String {
                                                        comment.username = commentUsername
                                                    }
                                                    
                                                    if let commentDate = commentElement["DateCreated"] as? String {
                                                        do {
                                                        let date = try self.ocmCommentDateFormatParser(OCMDateString: commentDate)
                                                            comment.commentDate = date.timeIntervalSinceReferenceDate
                                                        } catch DataManagerError.InvalidDateFormat {
                                                            NSLog("Invalid comment date format")
                                                        } catch {
                                                            let nserror = error as NSError
                                                            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                                                        }
                                                        
                                                    }
                                                    
                                                    comment.chargerSecondary = chargerDetails
                                                }
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
                                        
                                        if let chargerContactNumber = addressData["ContactTelephone1"] as? String {
                                            chargerDetails.chargerPrimaryContactNumber = chargerContactNumber
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
                                    
                                    if let operatorData = element["OperatorInfo"] {
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
                                    // Add current timestamp
                                    chargerPrimary.chargerWasAddedDate = NSDate().timeIntervalSince1970
                                    
                                }
                                
                                do{
                                    try moc.save()
                                    // Data is saved, store location
                                    LastUpdateLocationSingelton.center.location = CLLocation(latitude: latitude, longitude: longitude)
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
                            let dataParsingErrorString = NSLocalizedString("Invalid data returned from server. Please try again later.", comment: "Data download parsing error")
                            SwiftSpinner.show(dataParsingErrorString, animated: false).addTapHandler({
                                SwiftSpinner.hide()
                                }, subtitle: dismissString)
                        }
                    }
                    else {
                        NSLog("No data available")
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
            let wrappedError = NSError(domain: "SPARKMAP_ERROR_DOMAIN", code: 9999, userInfo: dict)
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
