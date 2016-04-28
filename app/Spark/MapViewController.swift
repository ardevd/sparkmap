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
    lazy var searchAnnotation: MKPointAnnotation = MKPointAnnotation()
    var haveSearchResult: Bool = false
    var haveLoadedInitialChargerData: Bool = false
    var locationManager: LocationManager = LocationManager()
    
    lazy var searchController:UISearchController  = { [unowned self] in
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        let searchbarPlaceholderString = NSLocalizedString("Search for a place or address", comment: "Searchbar placeholder string")
        self.searchController.searchBar.placeholder = searchbarPlaceholderString
        
        return self.searchController
        }()
    
    
    var localSearchRequest:MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    
    // Views
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var actionButton: UIBarButtonItem!
    
    // User map interaction bool
    var userInteractionOverride: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Format UINavBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        
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
        
        registerNotificationListeners()
        
        // Clean up stored charging data
        dataManager.removeOldChargerData()
    }
    
    func isNewCenterFarFromOldCenter() -> Bool {
        let newCenter = mapView.centerCoordinate
        let newCenterLocation = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
        let oldCenter = MapCenterCoordinateSingelton.center.coordinate
        let oldCenterLocation = CLLocation(latitude: oldCenter.latitude, longitude: oldCenter.longitude)
        
        if newCenterLocation.distanceFromLocation(oldCenterLocation) > 100 {
            return true
        }
        
        return false
    }
    
    override func viewDidLayoutSubviews() {
        
        // Update map center singelton
        updateMapViewSingeltons()
    }
    
    func registerNotificationListeners() {
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.updateAnnotationsFromNotification(_:)), name: "ChargerDataUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.updatedSettingsRefresh(_:)), name: "SettingsUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.updateRegionFromNotification(_:)), name: "LocationUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MapViewController.enableUserLocationInMap(_:)), name: "LocationAuthorized", object: nil)
    }
    
    func enableUserLocationInMap(notification: NSNotification) {
        mapView.showsUserLocation = true
    }
    
    func updateRegionFromNotification(notification: NSNotification) {
        
        if let searchResultAnnotation = notification.userInfo?["searchResultAnnotation"] as? MKPointAnnotation {
            //mapView.addAnnotation(searchResultAnnotation)
            searchAnnotation = searchResultAnnotation
            haveSearchResult = true
        }
        
        if let latValue = notification.userInfo?["latitude"] as? CLLocationDegrees {
            if let longValue = notification.userInfo?["longitude"] as? CLLocationDegrees {
                let locationCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latValue, longitude: longValue)
                updateCurrentMapRegion(locationCoordinate, distance: 3000)
            }
        }
    }
    
    func updateAnnotationsFromNotification(notification: NSNotification){
        if isNewCenterFarFromOldCenter() || !haveLoadedInitialChargerData{
            updateMapViewSingeltons()
            updateAnnotations()
        }
        
    }
    
    func updatedSettingsRefresh(notifcation: NSNotification){
        updateAnnotations()
        updateMapTypeFromSettings()
    }
    
    func updateMapTypeFromSettings() {
        let mapTypeFromSettings = NSUserDefaults.standardUserDefaults().integerForKey("mapType")
        
        switch mapTypeFromSettings
        {
        case 0:
            mapView.mapType = .Standard
        case 1:
            mapView.mapType = .Satellite
        case 2:
            mapView.mapType = .Hybrid
        default:
            break;
        }
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
                self.haveLoadedInitialChargerData = true

                
            }
            
            self.mapView.addAnnotations(annotations)
            
            if (self.haveSearchResult) {
                self.mapView.addAnnotation(self.searchAnnotation)
                self.haveSearchResult = false
            }
        })
        
    }
    
    @IBAction func refreshDataFromCurrentLocation(){
        let coordinate = mapView.centerCoordinate
        updateAnnotations()
        getAnnotationsFromNewLocation(coordinate)
        updateMapViewSingeltons()
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
        
        if (annotation is AnnotationCharger) {
            pin?.pinTintColor = UIColor(red: 140/255, green: 186/255, blue: 50/255, alpha: 1.0)
            
            if let chargerAnnotationView = annotation as? AnnotationCharger {
                let charger = chargerAnnotationView.charger
                let numberOfPoints = charger.chargerNumberOfPoints
                
                let connectionCountLabel = UILabel(frame: CGRectMake(0, 0, 29, 29))
                connectionCountLabel.textColor = UIColor(red: 223/255, green: 105/225, blue: 93/225, alpha: 1.0)
                if (numberOfPoints > 0) {
                    connectionCountLabel.text = String(numberOfPoints)
                }
                pin?.leftCalloutAccessoryView = connectionCountLabel
                
                pin?.enabled = true
                pin?.canShowCallout = true
                pin?.selected = true
                let button = UIButton(type: UIButtonType.DetailDisclosure)
                pin?.rightCalloutAccessoryView = button
            }
        } else {
            return nil
        }
        
        return pin
    }
    
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Map region was updated. Update data if we think the user dragged the map.
        
        if (!userInteractionOverride) {
            if (DistanceToLocationManager.distanceFromLastDataUpdateLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) > 5000) {
                // Show stored annotations for the new location
                updateAnnotations()
                // Download charging station data for the area
                getAnnotationsFromNewLocation(mapView.centerCoordinate)
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
                let placeNotFoundString = NSLocalizedString("Place Not Found", comment: "User search location not found")
                let dismissString = NSLocalizedString("Dismiss", comment: "Dismiss")
                let alertController = UIAlertController(title: nil, message: placeNotFoundString, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: dismissString, style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            
            let center = mapItem.placemark.coordinate
            //Drop annotation here
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.title = mapItem.placemark.title
            self.userInteractionOverride = true
            self.mapView.setRegion(localSearchResponse.boundingRegion, animated: true)
            NSNotificationCenter.defaultCenter().postNotificationName("LocationUpdate", object: nil, userInfo: ["latitude": center.latitude, "longitude": center.longitude, "searchResultAnnotation": annotation])
            
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
        userInteractionOverride = true
        mapView.region = region
        userInteractionOverride = false
        
        // Show stored annotations for the new location
        if (!haveSearchResult){
            updateAnnotations()
        }
        
        // Download charging station data for the area
        getAnnotationsFromNewLocation(coordinate)
    }
    
    func updateMapViewSingeltons(){
        //Update map center point singelton
        MapCenterCoordinateSingelton.center.coordinate = mapView.centerCoordinate
        // Update map span singelton
        MapCoordinateSpanSingelton.span.mapSpan = mapView.region.span
        
        
    }
    
}
