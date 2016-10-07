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
    let defaults = UserDefaults.standard
    var useClustering = false
    
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        
        // Clean up stored charging data
        dataManager.removeOldChargerData()
        dataManager.getDataFilesSize()
        
        useClustering = defaults.bool(forKey: "useClustering")
        
        if isDoneWithFirstRun(){
            registerNotificationListeners()
            verifyOrRequestLocationAuthorization()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.welcomeModuleIsDone(_:)), name: NSNotification.Name(rawValue: "WelcomeModuleDone"), object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showWelcomeIfApplicable()
    }
    
    func verifyOrRequestLocationAuthorization() {
        // Location Authorization
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case CLAuthorizationStatus.authorizedWhenInUse:
            locationManager.requestStartLocationUpdate()
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        default:
            // Request permission
            locationManager.requestStartLocationUpdate()
            mapView.showsUserLocation = false
        }
        
    }
    
    func isDoneWithFirstRun() -> Bool {
        let defaults = UserDefaults.standard
        let notFirstRun = defaults.bool(forKey: "isDoneWithFirstRun")
        
        return notFirstRun
    }
    
    func showWelcomeIfApplicable() -> Bool {
        // Show Welcome screen if this is first launch.
        if !isDoneWithFirstRun() {
            // Create a new "WelcomeStoryBoard" instance.
            let storyboard = UIStoryboard(name: "WelcomeStoryboard", bundle: nil)
            // Create an instance of the storyboard's initial view controller.
            let controller = storyboard.instantiateViewController(withIdentifier: "InitialController") as UIViewController
            // Display the new view controller.
            present(controller, animated: true, completion: nil)
            return true
        }
        
        return false
    }
    
    func isNewCenterFarFromOldCenter() -> Bool {
        let newCenter = mapView.centerCoordinate
        let newCenterLocation = CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude)
        let oldCenter = MapCenterCoordinateSingelton.center.coordinate
        let oldCenterLocation = CLLocation(latitude: oldCenter.latitude, longitude: oldCenter.longitude)
        
        if newCenterLocation.distance(from: oldCenterLocation) > 100 {
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
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.updateAnnotationsFromNotification(_:)), name: NSNotification.Name(rawValue: "ChargerDataUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.updatedSettingsRefresh(_:)), name: NSNotification.Name(rawValue: "SettingsUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.updateRegionFromNotification(_:)), name: NSNotification.Name(rawValue: "LocationUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MapViewController.enableUserLocationInMap(_:)), name: NSNotification.Name(rawValue: "LocationAuthorized"), object: nil)
    }
    
    func enableUserLocationInMap(_ notification: Notification) {
        mapView.showsUserLocation = true
    }
    
    func welcomeModuleIsDone(_ notification: Notification) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "isDoneWithFirstRun")
        registerNotificationListeners()
        verifyOrRequestLocationAuthorization()
    }
    
    func updateRegionFromNotification(_ notification: Notification) {
        
        if let searchResultAnnotation = (notification as NSNotification).userInfo?["searchResultAnnotation"] as? MKPointAnnotation {
            //mapView.addAnnotation(searchResultAnnotation)
            searchAnnotation = searchResultAnnotation
            haveSearchResult = true
        }
        
        if let latValue = (notification as NSNotification).userInfo?["latitude"] as? CLLocationDegrees {
            if let longValue = (notification as NSNotification).userInfo?["longitude"] as? CLLocationDegrees {
                let locationCoordinate : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latValue, longitude: longValue)
                updateCurrentMapRegion(locationCoordinate, distance: 3000)
                updateLastDataUpdateLocationSingelton()
            }
        }
    }
    
    func updateAnnotationsFromNotification(_ notification: Notification){
        updateMapViewSingeltons()
        updateAnnotations()
    }
    
    func updatedSettingsRefresh(_ notifcation: Notification){
        useClustering = defaults.bool(forKey: "useClustering")
        updateAnnotations()
        updateMapTypeFromSettings()
    }
    
    func updateMapTypeFromSettings() {
        let mapTypeFromSettings = UserDefaults.standard.integer(forKey: "mapType")
        
        switch mapTypeFromSettings
        {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .satellite
        case 2:
            mapView.mapType = .hybrid
        default:
            break;
        }
    }
    
    
    func updateAnnotations() {
        // Needs to be executed on the main queue as it will update the UI.
        DispatchQueue.main.async(execute: { () -> Void in
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
        mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
    }
    
    func getAnnotationsFromNewLocation(_ coordinate: CLLocationCoordinate2D){
        dataManager.downloadNearbyChargers(Latitude: coordinate.latitude, Longitude: coordinate.longitude, Distance: (getCurrentMapBoundsDistance() * 0.8) / 1000)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "net.zygotelabs.annotation")
        
        if pin == nil {
            // If the pin is not in the cache, we create it.
            pin = MKAnnotationView(annotation: annotation, reuseIdentifier: "net.zygotelabs.annotation")
        }
        
        
        if (annotation is AnnotationCharger) {
            if let chargerAnnotationView = annotation as? AnnotationCharger {
                let charger = chargerAnnotationView.charger
                let numberOfPoints = charger.chargerNumberOfPoints
                
                let connectionCountLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 29, height: 29))
                connectionCountLabel.textColor = UIColor(red: 223/255, green: 105/225, blue: 93/225, alpha: 1.0)
                if (numberOfPoints > 0) {
                    connectionCountLabel.text = String(numberOfPoints)
                }
                pin?.leftCalloutAccessoryView = connectionCountLabel
                pin?.isEnabled = true
                pin?.canShowCallout = true
                pin?.isSelected = true
                pin?.image = ChargerImageHelper.getChargerAnnotationImage(charger)
                
                pin?.frame.size = CGSize(width: 30.0, height: 30.0)
                let button = UIButton(type: UIButtonType.detailDisclosure)
                pin?.rightCalloutAccessoryView = button
            }
        } else {
            return nil
        }
        
        return pin
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            if let chargerAnnotation = annotationView.annotation as? AnnotationCharger {
                
                let charger = chargerAnnotation.charger
                let vc = ChargerDetailViewController()
                vc.charger = charger
                vc.connections = charger.chargerDetails?.connections?.allObjects as! [Connection]
                vc.hidesBottomBarWhenPushed = true
                show(vc, sender: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Map region was updated. Update data if we think the user dragged the map.

        if (!userInteractionOverride && haveLoadedInitialChargerData) {
            if (DistanceToLocationManager.distanceFromLastDataUpdateLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) > getCurrentMapBoundsDistance()) {
                // Show stored annotations for the new location
                updateAnnotations()
                // Download charging station data for the area
                getAnnotationsFromNewLocation(mapView.centerCoordinate)
                // Update MapViewSingeltons
                updateMapViewSingeltons()
            }
        }
        
    }
    
    func getCurrentMapBoundsDistance() -> CLLocationDistance{
        let mapRegionRectangle = self.mapView.visibleMapRect
        let neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mapRegionRectangle), mapRegionRectangle.origin.y)
        let swMapPoint = MKMapPointMake(mapRegionRectangle.origin.x, MKMapRectGetMaxY(mapRegionRectangle))
        let neMapCoordinate = MKCoordinateForMapPoint(neMapPoint);
        let swMapCoordinate = MKCoordinateForMapPoint(swMapPoint);
        let neMapLocation = CLLocation(latitude: neMapCoordinate.latitude, longitude: neMapCoordinate.longitude)
        let swMapLocation = CLLocation(latitude: swMapCoordinate.latitude, longitude: swMapCoordinate.longitude)
        let mapRegionDistance = neMapLocation.distance(from: swMapLocation)
        return mapRegionDistance
    }
    
    
    @IBAction func showSearchBar(_ sender: AnyObject) {
        
        present(searchController, animated: true, completion: nil)
    }
    
    // When user submits search query
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        // resign first responder and dismiss the searchbar.
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        // Create and start search request
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearchRequest.region = mapView.region
        localSearch = MKLocalSearch(request: localSearchRequest)
        
        localSearch.start { (localSearchResponse, error) -> Void in
            
            guard let localSearchResponse = localSearchResponse, let mapItem = localSearchResponse.mapItems.first else {
                let placeNotFoundString = NSLocalizedString("Place not found", comment: "User search location not found")
                let dismissString = NSLocalizedString("Dismiss", comment: "Dismiss")
                let alertController = UIAlertController(title: nil, message: placeNotFoundString, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: dismissString, style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            let center = mapItem.placemark.coordinate
            //Drop annotation here
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapItem.placemark.coordinate
            annotation.title = mapItem.placemark.title
            self.userInteractionOverride = true
            self.mapView.setRegion(localSearchResponse.boundingRegion, animated: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "LocationUpdate"), object: nil, userInfo: ["latitude": center.latitude, "longitude": center.longitude, "searchResultAnnotation": annotation])
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateCurrentMapRegion(_ coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
        userInteractionOverride = true
        mapView.region = region
        userInteractionOverride = false
        // Check if distance delta is significant.
        if isNewCenterFarFromOldCenter() {
            updateMapViewSingeltons()
            // Show stored annotations for the new location
            if (!haveSearchResult){
                updateAnnotations()
            }
            
            // Download charging station data for the area
            getAnnotationsFromNewLocation(coordinate)
        }
    }
    
    func updateLastDataUpdateLocationSingelton(){
        LastUpdateLocationSingelton.center.location = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
    }
    
    func updateMapViewSingeltons(){
        //Update map center point singelton
        MapCenterCoordinateSingelton.center.coordinate = mapView.centerCoordinate
        // Update map span singelton
        MapCoordinateSpanSingelton.span.mapSpan = mapView.region.span
    }
    
}
