//
//  ViewController.swift
//  Spark
//
//  Created by Edvard Holst on 29/10/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ViewController: UIViewController, UIViewControllerPreviewingDelegate {
    
    //Chargers
    var chargers: [ChargerPrimary] = [ChargerPrimary]()
    
    
    // Views
    @IBOutlet var tableView: UITableView!
    
    lazy var dataManager: DataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Format UINavBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        // Register 3d Touch capabilties
        registerForceTouchCapability()
        
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updateTableView(_:)), name: "ChargerDataUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.updateChargersFromLocation(_:)), name: "LocationUpdate", object: nil)
        
        updateChargersListFromMapCenter()
        let nib = UINib(nibName: "NearbyTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "net.zygotelabs.cell")
    }
    
    func updateChargersListFromMapCenter(){
        let centerGeoCoordinate = MapCenterCoordinateSingelton.center.coordinate
        chargers = dataManager.retrieveNearbyChargerData(Latitude: centerGeoCoordinate.latitude, Longitude: centerGeoCoordinate.longitude)!
        sortChargersArray()
    }
    
    func sortChargersArray(){
        let queue = dispatch_queue_create("net.zygotelabs.sortqueue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(queue) { () -> Void in
            // Sort chargers
            self.chargers.sortInPlace { (charger1, charger2) -> Bool in
                //self.compareChargerDistance(charger1, secondCharger: charger2)
                DistanceToLocationManager.compareChargerDistance(charger1, secondCharger: charger2)
            }
            // Reload table view data in the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }


    func registerForceTouchCapability(){
        if(traitCollection.forceTouchCapability == .Available){
            registerForPreviewingWithDelegate(self, sourceView: tableView)
        }
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
    
        // Set up peeking
        guard let indexPath = tableView?.indexPathForRowAtPoint(location) else { return nil }
        guard let cell = tableView?.cellForRowAtIndexPath(indexPath) else { return nil }
        
        let charger = chargers[indexPath.row]
        let vc = ChargerDetailViewController()
        vc.charger = charger
        vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
        vc.preferredContentSize = CGSize(width: 0.0, height: 500)
        previewingContext.sourceRect = cell.frame
        return vc
        
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        // Set up Popping
        showViewController(viewControllerToCommit, sender: self)
    }
    
    func updateChargersFromLocation(notification: NSNotification) {
        if let latValue = notification.userInfo?["latitude"] as? CLLocationDegrees {
            if let longValue = notification.userInfo?["longitude"] as? CLLocationDegrees {
                chargers = dataManager.retrieveNearbyChargerData(Latitude: latValue, Longitude: longValue)!
                sortChargersArray()
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chargers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("net.zygotelabs.cell", forIndexPath: indexPath) as! NearbyTableViewCell
        
        let selectedCharger = chargers[indexPath.row] as ChargerPrimary
        
        cell.cellTitle?.text = (chargers[indexPath.row] as ChargerPrimary).chargerTitle
        cell.cellDescription?.text = (chargers[indexPath.row] as ChargerPrimary).chargerSubtitle
        //cell.cellDistance?.text = String(round(1000*(chargers[indexPath.row] as ChargerPrimary).chargerDistance)/1000) + "km"
        
        // Calculate distance from current map center location
        // TODO: Figure out how we can use the value directly from the sorting fuction we already do instead of having to do it twice.
        let chargerLocation = CLLocation(latitude: selectedCharger.chargerLatitude, longitude: selectedCharger.chargerLongitude)
        let mapLocationCoordinate = MapCenterCoordinateSingelton.center.coordinate
        let mapLocation = CLLocation(latitude: mapLocationCoordinate.latitude, longitude: mapLocationCoordinate.longitude)
        let distance = chargerLocation.distanceFromLocation(mapLocation)
        let metersString = NSLocalizedString("meters", comment: "Meters")
        cell.cellDistance?.text = String(Int(distance)) + " " + metersString
        return cell
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ChargerDataUpdate", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "LocationUpdate", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateData() {
        updateChargersListFromMapCenter()
    }
    
    func updateTableView(notification: NSNotification){
        //TODO: This seems to lock up the app. Do more testing
        //updateChargersListFromMapCenter()
        sortChargersArray()
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let charger = chargers[indexPath.row]
        print(charger.chargerTitle)
        let vc = ChargerDetailViewController()
        vc.charger = charger
        vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
        vc.hidesBottomBarWhenPushed = true
        showViewController(vc, sender: nil)
    }
}

