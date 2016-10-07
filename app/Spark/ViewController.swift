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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        
        // Register 3d Touch capabilties
        registerForceTouchCapability()
        
        // Register notification listeners
        registerNotificationObservers()
        
        updateChargersListFromMapCenter()
        let nib = UINib(nibName: "NearbyTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "net.zygotelabs.cell")
    }
    
    func updateChargersListFromMapCenter(){
        let centerGeoCoordinate = MapCenterCoordinateSingelton.center.coordinate
        chargers = dataManager.retrieveNearbyChargerData(Latitude: centerGeoCoordinate.latitude, Longitude: centerGeoCoordinate.longitude)!
        sortChargersArray()
    }
    
    func registerNotificationObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateTableView(_:)), name: NSNotification.Name(rawValue: "ChargerDataUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateChargersFromLocation(_:)), name: NSNotification.Name(rawValue: "LocationUpdate"), object: nil)
    }
    
    func sortChargersArray(){
        let queue = DispatchQueue(label: "net.zygotelabs.sortqueue", attributes: [])
        queue.async { () -> Void in
            // Sort chargers
            self.chargers.sort { (charger1, charger2) -> Bool in
                DistanceToLocationManager.compareChargerDistance(charger1, secondCharger: charger2)
            }
            // Reload table view data in the main queue
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
            })
        }
    }
    
    
    func registerForceTouchCapability(){
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Set up peeking
        guard let indexPath = tableView?.indexPathForRow(at: location) else { return nil }
        guard let cell = tableView?.cellForRow(at: indexPath) else { return nil }
        
        let charger = chargers[(indexPath as NSIndexPath).row]
        let vc = ChargerDetailViewController()
        vc.charger = charger
        vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
        vc.preferredContentSize = CGSize(width: 0.0, height: 500)
        previewingContext.sourceRect = cell.frame
        return vc
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Set up Popping
        show(viewControllerToCommit, sender: self)
    }
    
    func updateChargersFromLocation(_ notification: Notification) {
        if let latValue = (notification as NSNotification).userInfo?["latitude"] as? CLLocationDegrees {
            if let longValue = (notification as NSNotification).userInfo?["longitude"] as? CLLocationDegrees {
                chargers = dataManager.retrieveNearbyChargerData(Latitude: latValue, Longitude: longValue)!
                sortChargersArray()
            }
        }
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chargers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "net.zygotelabs.cell", for: indexPath) as! NearbyTableViewCell
        
        if let selectedCharger = chargers[(indexPath as NSIndexPath).row] as ChargerPrimary? {
            
            cell.cellTitle?.text = (chargers[(indexPath as NSIndexPath).row] as ChargerPrimary).chargerTitle
            cell.cellDescription?.text = (chargers[(indexPath as NSIndexPath).row] as ChargerPrimary).chargerSubtitle
            cell.cellAnnotationImageView?.image = ChargerImageHelper.getChargerAnnotationImage(chargers[(indexPath as NSIndexPath).row])
            // Calculate distance from current map center location
            // TODO: Figure out how we can use the value directly from the sorting fuction we already do instead of having to do it twice.
            let chargerLocation = CLLocation(latitude: selectedCharger.chargerLatitude, longitude: selectedCharger.chargerLongitude)
            let mapLocationCoordinate = MapCenterCoordinateSingelton.center.coordinate
            let mapLocation = CLLocation(latitude: mapLocationCoordinate.latitude, longitude: mapLocationCoordinate.longitude)
            let distance = chargerLocation.distance(from: mapLocation)
            let metersString = NSLocalizedString("meters", comment: "Meters")
            cell.cellDistance?.text = String(Int(distance)) + " " + metersString
        }
        
        return cell
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func updateData() {
        updateChargersListFromMapCenter()
    }
    
    func updateTableView(_ notification: Notification){
        //TODO: This seems to lock up the app. Do more testing
        //updateChargersListFromMapCenter()
        sortChargersArray()
    }
    
    func tableView(_ tableView: UITableView!, didSelectRowAtIndexPath indexPath: IndexPath!) {
        let charger = chargers[indexPath.row]
        print(charger.chargerTitle)
        let vc = ChargerDetailViewController()
        vc.charger = charger
        vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
        vc.hidesBottomBarWhenPushed = true
        show(vc, sender: nil)
    }
}

