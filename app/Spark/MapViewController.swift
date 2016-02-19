//
//  MapViewController.swift
//  Spark
//
//  Created by Edvard Holst on 29/10/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate, UISearchBarDelegate {
    
    var chargers: [ChargerPrimary] = [ChargerPrimary]()
    lazy var dataManager: DataManager = DataManager()
    var locationManager: LocationManager = LocationManager()
    
    lazy var searchController:UISearchController  = { [unowned self] in
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.placeholder = "Search for a place or address"
        
        return self.searchController
        }()
    
    
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    
    // Views
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Format UINavBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAnnotationsFromNotification:", name: "ChargerDataUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAnnotationsFromNotification:", name: "SettingsUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRegionFromNotification:", name: "LocationUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enableUserLocationInMap:", name: "LocationAuthorized", object: nil)
        
        // Location Authorization
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            locationManager.requestStartLocationUpdate()
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        default:
            // Request permission
            locationManager.requestStartLocationUpdate()
            mapView.showsUserLocation = false
        }
        
        // Update map center singelton
        updateMapCenterCoordinateSingelton()
        
    }
    
    func enableUserLocationInMap(notification: NSNotification) {
        mapView.showsUserLocation = true
    }
    
    func updateRegionFromNotification(notification: NSNotification) {
        if let latValue = notification.userInfo?["latitude"] as? CLLocationDegrees {
            if let longValue = notification.userInfo?["longitude"] as? CLLocationDegrees {
                let locationCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latValue, longitude: longValue)
                updateCurrentMapRegion(locationCoordinate, distance: 3000)
            }
        }
    }
    
    func updateAnnotationsFromNotification(notification: NSNotification){
        updateAnnotations()
    }
    
    
    func updateAnnotations() {
        // Needs to be executed on the main queue as it will update the UI.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // Remove existing annotations
            if self.mapView.annotations.count != 0{
                var annotations: [MKAnnotation] = [MKAnnotation]()
                annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
            }
            let mapCenterCoordinate = self.mapView.region.center
            // Retrieve chargers from CoreData
            self.chargers = self.dataManager.retrieveNearbyChargerData(Latitude: mapCenterCoordinate.latitude, Longitude: mapCenterCoordinate.longitude)!
            var annotations: [MKAnnotation] = [MKAnnotation]()
            for charger in self.chargers {
                let chargerCoordinate = CLLocationCoordinate2DMake(charger.chargerLatitude, charger.chargerLongitude)
                let chargerAnnotation = AnnotationCharger(coordinate: chargerCoordinate, charger: charger)
                chargerAnnotation.title = charger.chargerTitle
                chargerAnnotation.subtitle = charger.chargerSubtitle
                
                annotations.append(chargerAnnotation)
                
            }
            
            self.mapView.addAnnotations(annotations)
        })
        
    }
    
    @IBAction func refreshDataFromCurrentLocation(){
        let coordinate = mapView.centerCoordinate
        updateAnnotations()
        getAnnotationsFromNewLocation(coordinate)
        updateMapCenterCoordinateSingelton()
    }
    
    @IBAction func updateCurrentLocation(){
        locationManager.requestStartLocationUpdate()
        mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }
    
    func getAnnotationsFromNewLocation(coordinate: CLLocationCoordinate2D){
        
        dataManager.downloadNearbyChargers(Latitude: coordinate.latitude, Longitude: coordinate.longitude)
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("net.zygotelabs.pin") as? MKPinAnnotationView
        if pin == nil {
            // If the pin is not in the cache, we create it.
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "net.zygotelabs.pin")
            
        }
        let thumbnailImageView = UIImageView(frame: CGRectMake(0, 0, 59, 59))
        
        pin?.leftCalloutAccessoryView = thumbnailImageView
        if (annotation is AnnotationCharger) {
            pin?.pinTintColor = UIColor(red: 140/255, green: 186/255, blue: 50/255, alpha: 1.0)
        } else {
            return nil
        }
        
        
        //pin?.pinTintColor = UIColor.blueColor()
        pin?.enabled = true
        pin?.canShowCallout = true
        pin?.selected = true
        let button = UIButton(type: UIButtonType.DetailDisclosure)
        pin?.rightCalloutAccessoryView = button
        
        return pin
    }
    
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            //print("Disclosure Pressed!")
            if let chargerAnnotation = annotationView.annotation as? AnnotationCharger {
                
                
                let charger = chargerAnnotation.charger
                print(charger.chargerTitle)
                let vc = ChargerDetailViewController()
                vc.charger = charger
                vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
                vc.hidesBottomBarWhenPushed = true
                showViewController(vc, sender: nil)
            }
        }
    }
    
    
    @IBAction func showSearchBar(sender: AnyObject) {
        
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    // When user submits search query
    func searchBarSearchButtonClicked(searchBar: UISearchBar){
        // resign first responder and dismiss the searchbar.
        searchBar.resignFirstResponder()
        dismissViewControllerAnimated(true, completion: nil)
        
        // Create and start search request
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearchRequest.region = mapView.region
        localSearch = MKLocalSearch(request: localSearchRequest)
        
        localSearch.startWithCompletionHandler { (localSearchResponse, error) -> Void in
            
            guard let localSearchResponse = localSearchResponse, mapItem = localSearchResponse.mapItems.first else {
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            
            let center = mapItem.placemark.coordinate
            self.mapView.setRegion(localSearchResponse.boundingRegion, animated: true)
            NSNotificationCenter.defaultCenter().postNotificationName("LocationUpdate", object: nil, userInfo: ["latitude": center.latitude, "longitude": center.longitude])
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "ChargerDataUpdate", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "LocationUpdate", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "LocationAuthorized", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "SettingsUpdate", object: nil)
    }
    
    func updateCurrentMapRegion(coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
        mapView.region = region
        
        updateMapCenterCoordinateSingelton()
        
        // Show stored annotations for the new location
        updateAnnotations()
        // Download charging station data for the area
        getAnnotationsFromNewLocation(coordinate)
    }
    
    func updateMapCenterCoordinateSingelton(){
        //Update singelton point
        MapCenterCoordinateSingelton.center.coordinate = mapView.centerCoordinate

    }
    
}
