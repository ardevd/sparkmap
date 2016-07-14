//
//  ChargerDetailViewController.swift
//  Spark
//
//  Created by Edvard Holst on 28/11/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class ChargerDetailViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UIViewControllerPreviewingDelegate {
    // Outlets
    @IBOutlet var imageThumbnail: UIImageView!
    @IBOutlet var labelOperatorTitle: UILabel!
    @IBOutlet var labelSubtitle: UILabel!
    @IBOutlet var labelAccess: UILabel!
    @IBOutlet var labelNumberOfPoints: UILabel!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var chargingPointTableView: UITableView!
    @IBOutlet var dataLastUpdateTimeLabel: UILabel!
    @IBOutlet var labelTransportETA: UILabel!
    @IBOutlet var indicatorImageLoader: UIActivityIndicatorView!
    @IBOutlet var buttonLastUpdateTime: UIButton!
    @IBOutlet var buttonComments: UIButton!
    @IBOutlet var labelNumberOfComments: UILabel!
    @IBOutlet var labelUsageType: UILabel!
    
    // Views
    @IBOutlet var viewNumberOfPoints: UIView!
    @IBOutlet var viewChargerStatus: UIView!
    @IBOutlet var viewHeader: UIView!
    @IBOutlet var viewLastUpdateTime: UIView!
    @IBOutlet var viewRecentlyVerified: UIView!
    
    // Location
    var locationManager: CLLocationManager?
    /* We will use this property to keep track on whether
     or not positioning is active */
    var isActive: Bool = false
    
    
    var charger: ChargerPrimary?
    var connections: [Connection] = [Connection]()
    
    var showingLargeImage: Bool?
    var originalThumbnailImageFrame: CGRect?
    
    var totalChargingPointQuantityAvailable: Bool?
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelAccess.text = ""
        
        // Formatting the tableView
        let nib = UINib(nibName: "ConnectionTableViewCell", bundle: nil)
        chargingPointTableView.registerNib(nib, forCellReuseIdentifier: "net.zygotelabs.connectioncell")
        chargingPointTableView.tableFooterView = UIView(frame: CGRectZero)
    
        
        // Download charger thumbnail image
        if let thumbnailImageURL = charger?.chargerImage {
            downloadThumbnailImage(thumbnailImageURL)
        } else {
            // Add gestureRecognizer that lets user take and upload photo
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ChargerDetailViewController.grabAndLoadUserPhoto(_:)))
            imageThumbnail.userInteractionEnabled = true
            imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
            
            if let image = UIImage(named: "PlaceholderImageIcon") {
                imageThumbnail.image = image
            }
        }
        
        determineCommentIconType()
        checkAndAnimateRecentlyVerifiedView()
        
        // Check location permission and start location update.
        if checkLocationAuthorization(){
            locationManager?.desiredAccuracy = 50
            locationManager?.distanceFilter = 50
            locationManager?.startUpdatingLocation()
            isActive = true
        }

    }
    
    func registerForceTouchCapability(){
        if(traitCollection.forceTouchCapability == .Available){
            registerForPreviewingWithDelegate(self, sourceView: imageThumbnail)
        }
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Set up peeking
        let vc = ChargingStationPhotoViewController()
        vc.chargingStationImageUrl = self.charger?.chargerImage
        vc.chargingStationImage = self.imageThumbnail.image
        previewingContext.sourceRect = imageThumbnail.frame
        return vc
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Set up Popping
        if showingLargeImage != nil {
            if showingLargeImage! {
                toggleFullThumbnilImage()
            }
        }
        showViewController(viewControllerToCommit, sender: self)
    }
    
    func checkLocationAuthorization() -> Bool{
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case CLAuthorizationStatus.AuthorizedWhenInUse:
            // Permission already granted
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            return true
            
        default:
            // Permission not granted.
            return false
        }
    }
    
    func generateNavigationButton() -> UIBarButtonItem {
        // Button that lets user navigate to charger address.
        let navigateTitle = NSLocalizedString("Navigate", comment: "Navigate")
        let navigationButtonItem = UIBarButtonItem(title: navigateTitle, style: .Plain, target: self, action: #selector(ChargerDetailViewController.navigateButtonTapped))
        navigationButtonItem.image = UIImage(named: "CarIcon")
        
        return navigationButtonItem
        
    }
    
    func generateCallButton() -> UIBarButtonItem {
        // Button that lets user call the number associated wtih the charging station.
        let callString = NSLocalizedString("Call", comment: "Call Button String")
        let callButtonItem = UIBarButtonItem(title: callString, style: .Plain, target: self, action: #selector(ChargerDetailViewController.callButtonTapped))
        callButtonItem.image = UIImage(named: "CallIcon")
        
        return callButtonItem
    }
    
    func navigateButtonTapped() {
        let addressDictionary = [String(CNPostalAddressStreetKey): labelSubtitle.text as! AnyObject]
        let chargingPointPlaceCoordinate = CLLocationCoordinate2D(latitude: (charger?.chargerLatitude)!, longitude: (charger?.chargerLongitude)!)
        let placemark = MKPlacemark(coordinate: chargingPointPlaceCoordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = labelSubtitle.text
        
        let options = [MKLaunchOptionsDirectionsModeKey:
            MKLaunchOptionsDirectionsModeDriving]
        
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    func callButtonTapped() {
        let phoneNumber = charger?.chargerDetails?.chargerPrimaryContactNumber?.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        if let callUrl = NSURL(string: "tel:\(phoneNumber!)") {
            UIApplication.sharedApplication().openURL(callUrl)
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        manipulateThumbnailImage()
        setChargerInfoToOutlets()
        
        addViewAppearanceElements()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        showingLargeImage = false
        originalThumbnailImageFrame = imageThumbnail.frame
    }
    
    @IBAction func animateDateView() {
        UIView.animateWithDuration(0.5, animations: {
            if (self.viewLastUpdateTime.alpha > 0){
                self.viewLastUpdateTime.alpha = 0.0
            }else {
                self.viewLastUpdateTime.alpha = 1.0
            }
        })
    }
    
    func checkAndAnimateRecentlyVerifiedView() {
        if let isRecentlyVerified = charger?.chargerDetails?.chargerRecentlyVerified {
            if isRecentlyVerified {
                self.viewRecentlyVerified.frame.size.width = 0
                // Charger was recently verified. Show the badge.
                UIView.animateWithDuration(0.5, animations: {
                    self.viewRecentlyVerified.alpha = 1.0
                    self.viewRecentlyVerified.frame.size.width = 123
                })
            }
        }
    }
    
    func addViewAppearanceElements(){
        viewNumberOfPoints.layer.borderWidth = 0.25
        viewNumberOfPoints.layer.borderColor = UIColor.whiteColor().CGColor
        viewChargerStatus.layer.borderWidth = 0.25
        viewChargerStatus.layer.borderColor = UIColor.whiteColor().CGColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors =  [
            UIColor(red: 93, green: 116, blue: 177, alpha: 1),
            UIColor(red: 92, green: 108, blue: 171, alpha: 1)
        ]
        
        gradientLayer.frame = viewNumberOfPoints.bounds
        self.viewNumberOfPoints.layer.addSublayer(gradientLayer)
    }
    
    func grabAndLoadUserPhoto(img: AnyObject)
    {
        /* Define a UIImagePickerController that lets the user
         supply a photo of a charging station */
        
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        
        // Camera Source Action
        let cameraSourceString = NSLocalizedString("Camera", comment: "Camera Source")
        let cameraSourceAction = UIAlertAction(title: cameraSourceString, style: .Default) { (alert: UIAlertAction!) -> Void in
            self.imagePicker.sourceType = .Camera
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        
        // Album Source Action
        let albumSourceString = NSLocalizedString("Photo Library", comment: "Library Source")
        let albumSourceAction = UIAlertAction(title: albumSourceString, style: .Default) { (alert: UIAlertAction!) -> Void in
            self.imagePicker.sourceType = .PhotoLibrary
            self.presentViewController(self.imagePicker, animated: true, completion: nil)
        }
        
        // Dismiss Action
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "Cancel Action Text")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel) { (alert: UIAlertAction!) -> Void in
        }
        
        // Ask user whether to grab photo from the camera or the photo album.
        let photoSubmissionTitleString = NSLocalizedString("Photo Submission", comment: "Photo Submission")
        let photoSubmissionMessageString = NSLocalizedString("Submit a photo for this charging station", comment: "Submit a photo description text")
        let photoSourcePromptAlert = UIAlertController(title: photoSubmissionTitleString, message: photoSubmissionMessageString, preferredStyle: UIAlertControllerStyle.ActionSheet)
        photoSourcePromptAlert.addAction(cameraSourceAction)
        photoSourcePromptAlert.addAction(albumSourceAction)
        photoSourcePromptAlert.addAction(cancelAction)
        self.presentViewController(photoSourcePromptAlert, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageThumbnail.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // Ask user for confirmation before uploading photo.
        //Action
        let yesString = NSLocalizedString("Yes", comment: "Yes")
        let noString = NSLocalizedString("No", comment: "No")
        
        let photoUploadAction = UIAlertAction(title: yesString, style: .Default) { (alert: UIAlertAction!) -> Void in
            // User confirmed. Post the photo
            let userPhotoSubmissionManager = UserPhotoSubmissionManager()
            if let chargerId = self.charger?.chargerId{
                userPhotoSubmissionManager.userPhotoUploadRequest(self.imageThumbnail, chargerId: chargerId)
                self.showPhotoSubmissionConfirmationAlert()
            }
        }
        //AlertController
        let photoSubmissionConfirmationRequestString = NSLocalizedString("Awesome. Go ahead and upload the photo?", comment: "Photo submission request message")
        let photoSubmissionConfirmationTitleString = NSLocalizedString("Upload photo", comment: "Photo Submitted")
        let photoSubmissionRequestAlert = UIAlertController(title: photoSubmissionConfirmationTitleString, message: photoSubmissionConfirmationRequestString, preferredStyle: UIAlertControllerStyle.Alert)
        photoSubmissionRequestAlert.addAction(UIAlertAction(title: noString, style: UIAlertActionStyle.Default, handler: nil))
        photoSubmissionRequestAlert.addAction(photoUploadAction)
        self.presentViewController(photoSubmissionRequestAlert, animated: true, completion: nil)
        
    }
    
    func showPhotoSubmissionConfirmationAlert(){
        // Show UIAlertController to user.
        let okString = NSLocalizedString("OK", comment: "OK")
        let photoSubmittedTitleString = NSLocalizedString("Photo Submitted", comment: "Photo Submitted")
        let photoSubmissionConfirmationString = NSLocalizedString("Your photo will be submitted for review. Thank you!", comment: "Photo submission confirmation message")
        let photoSubmissionConfirmationAlert = UIAlertController(title: photoSubmittedTitleString, message: photoSubmissionConfirmationString, preferredStyle: UIAlertControllerStyle.Alert)
        photoSubmissionConfirmationAlert.addAction(UIAlertAction(title: okString, style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(photoSubmissionConfirmationAlert, animated: true, completion: nil)
    }
    
    func toggleFullImage(img: AnyObject) {
        toggleFullThumbnilImage()
    }
    
    func toggleFullThumbnilImage(){
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 8, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            
            if (self.imageThumbnail.frame == self.viewHeader.layer.bounds){
                self.imageThumbnail.frame = self.originalThumbnailImageFrame!
                self.buttonLastUpdateTime.alpha = 1
                self.buttonComments.alpha = 1
                self.labelNumberOfComments.alpha = 1
                self.labelSubtitle.alpha = 1
                self.labelOperatorTitle.alpha = 1
                self.checkAndAnimateRecentlyVerifiedView()
                self.manipulateThumbnailImage()
                self.showingLargeImage = false
            }else{
                self.imageThumbnail.frame = self.viewHeader.layer.bounds
                self.imageThumbnail.layer.cornerRadius = 0
                self.imageThumbnail.layer.borderWidth = 0
                self.buttonComments.alpha = 0
                self.labelNumberOfComments.alpha = 0
                self.buttonLastUpdateTime.alpha = 0
                self.viewRecentlyVerified.alpha = 0
                self.viewLastUpdateTime.alpha = 0
                self.labelSubtitle.alpha = 0
                self.labelOperatorTitle.alpha = 0
                self.showingLargeImage = true
            }
            self.view.layoutIfNeeded()
            }, completion: nil)

    }
    
    func manipulateThumbnailImage(){
        
        self.imageThumbnail.layer.borderWidth = 1.0
        self.imageThumbnail.layer.masksToBounds = false
        self.imageThumbnail.layer.borderColor = UIColor.whiteColor().CGColor
        self.imageThumbnail.layer.cornerRadius = self.imageThumbnail.frame.size.width/2
        self.imageThumbnail.clipsToBounds = true
        
    }
    
    func setChargerInfoToOutlets(){
        var navigationButtonItems = [UIBarButtonItem]()
        
        
        if let title = charger?.chargerTitle {
            self.title = title
        }
        
        if let subtitle = charger?.chargerSubtitle {
            labelSubtitle.text = subtitle
            // Configure navigation button
            navigationButtonItems.append(generateNavigationButton())
        }
        
        if let operatorName = charger?.chargerOperator?.operatorName {
            labelOperatorTitle.text = operatorName
        }
        
        if let primaryPhoneNumber = charger?.chargerDetails?.chargerPrimaryContactNumber {
            if primaryPhoneNumber.characters.count > 3 {
                navigationButtonItems.append(generateCallButton())
            }
        }
        
        if let numberOfPoints = charger?.chargerNumberOfPoints {
            labelNumberOfPoints.text = String(numberOfPoints)
            if (numberOfPoints > 0){
                totalChargingPointQuantityAvailable = true
            } else {
                totalChargingPointQuantityAvailable = false
            }
        }
        
        if let dataLastUpdateTime = charger?.chargerDataLastUpdate {
            let date = NSDate(timeIntervalSinceReferenceDate: dataLastUpdateTime)
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            let convertedDate = dateFormatter.stringFromDate(date)
            dataLastUpdateTimeLabel.text = convertedDate
            
        }
        
        if let usageType = charger?.chargerDetails?.chargerUsageTypeId {
            if usageType == 0 {
                let unknownUsageTypeString = NSLocalizedString("Unknown usage type", comment: "Unknown Usage Type")
                labelUsageType.text = unknownUsageTypeString
            } else if usageType == 1 {
                let publicUsageTypeString = NSLocalizedString("Public use", comment: "Public Usage Type")
                labelUsageType.text = publicUsageTypeString
            } else if usageType == 2 {
                let publicUsagePrivateTypeString = NSLocalizedString("Private - Restricted Access", comment: "Private Access Usage Type")
                labelUsageType.text = publicUsagePrivateTypeString
            } else if usageType == 3 {
                let publicUsagePrivateOwnedTypeString = NSLocalizedString("Privately Owned - Notice Required", comment: "Privately Owned Usage Type")
                labelUsageType.text = publicUsagePrivateOwnedTypeString
            } else if usageType == 4 {
                let publicUsageMembershipTypeString = NSLocalizedString("Public use - Membership required", comment: "Public Membership Usage Type")
                labelUsageType.text = publicUsageMembershipTypeString
            } else if usageType == 5 {
                let publicUsagePayAtLocationTypeString = NSLocalizedString("Public use - Pay at location", comment: "Public Pay at location Usage Type")
                labelUsageType.text = publicUsagePayAtLocationTypeString
            } else if usageType == 6 {
                let publicUsagePrivateForVIPTypeString = NSLocalizedString("Private - For Staff, Visitors or Customers", comment: "Private - For staff or customers usage type")
                labelUsageType.text = publicUsagePrivateForVIPTypeString
            } else if usageType == 7 {
                let publicUsagePublicWithNoticeTypeString = NSLocalizedString("Public - Notice Required", comment: "Public - Notice required usage type")
                labelUsageType.text = publicUsagePublicWithNoticeTypeString
            }
            
        }
        
        let noAccessInfoAvailableString = NSLocalizedString("No Access Information Available", comment: "No Access Information")
        if let accessComment = charger?.chargerDetails?.chargerAccessComment {
            
            if accessComment.characters.count >= 1 {
                labelAccess.text = accessComment
            } else {
                labelAccess.text = noAccessInfoAvailableString
            }
        }
        else {
            labelAccess.text = noAccessInfoAvailableString
        }
        
        if let chargerIsOperational = charger?.chargerIsOperational {
            updateChargerOperationalStatus(chargerIsOperational)
        }
        
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
        
    }
    
    func updateChargerOperationalStatus(isOperational: Bool){
        //TODO: Implement "Offline" Indication.
        if (isOperational){
            let statusOperationalString = NSLocalizedString("Operational", comment: "Charging Status Operational")
            labelStatus.text = statusOperationalString
        } else {
            let statusUnknownString = NSLocalizedString("Unknown", comment: "Charging Status Unknown")
            labelStatus.text = statusUnknownString
            UIView.animateWithDuration(1.0, animations: {
                self.viewChargerStatus.backgroundColor = UIColor(red: 234/255, green: 155/255, blue: 3/255, alpha: 1.0)
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func downloadThumbnailImage(imageUrl: String){
        if let url = NSURL(string: imageUrl) {
            indicatorImageLoader.startAnimating()
            let request: NSURLRequest = NSURLRequest(URL: url)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){
                (data, response, error) -> Void in
                
                if (error == nil && data != nil)
                {
                    func displayImage()
                    {
                        // Animate the fade in of the image
                        UIView.animateWithDuration(1.0, animations: {
                            self.imageThumbnail.alpha = 0.0
                            self.imageThumbnail.image = UIImage(data: data!)
                            self.imageThumbnail.alpha = 1.0
                            
                            // Register 3d Touch capabilties
                            self.registerForceTouchCapability()
                            
                            // Add gestureRecognizer
                            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ChargerDetailViewController.toggleFullImage(_:)))
                            self.imageThumbnail.userInteractionEnabled = true
                            self.imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
                        })
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), displayImage)
                }
                
                func dismissActivityIndicator(){
                    self.indicatorImageLoader.stopAnimating()
                }
                
                dispatch_async(dispatch_get_main_queue(), dismissActivityIndicator)
            }
            
            task.resume()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("net.zygotelabs.connectioncell", forIndexPath: indexPath) as! ConnectionTableViewCell
        
        cell.connectionTypeLabel?.text = (connections[indexPath.row] as Connection).connectionTypeTitle
        
        //Only show Quantity if > 0
        let connectionQuantity = (connections[indexPath.row] as Connection).connectionQuantity
        if (connectionQuantity > 0) {
            cell.connectionQuantityLabel?.text = String(connectionQuantity) + "x"
            // If total connection quantity is unavaible, we calculate and display.
            if (totalChargingPointQuantityAvailable == false) {
                labelNumberOfPoints.text = String(Int(labelNumberOfPoints.text!)! + Int(connectionQuantity))
            }
        } else {
            cell.connectionQuantityLabel?.text = ""
        }
        
        var connectionPowerParams = ""
        let connectionCurrent = (connections[indexPath.row] as Connection).connectionAmp
        if (connectionCurrent > 0){
            connectionPowerParams = String((connections[indexPath.row] as Connection).connectionAmp) + "A"
        }
        let connectionPower = (connections[indexPath.row] as Connection).connectionPowerKW
        if (connectionPower > 0) {
            connectionPowerParams += "/" + (String((connections[indexPath.row] as Connection).connectionPowerKW) + "KW")
        }
        
        cell.connectionAmpLabel?.text = connectionPowerParams
        
        // Show status indicator if applicable
        let connectionIsOperational = (connections[indexPath.row] as Connection).connectionIsOperational
        if connectionIsOperational == 1 {
            cell.connectionStatusView.backgroundColor = UIColor.redColor()
        } else if connectionIsOperational == 2{
            cell.connectionStatusView.backgroundColor = UIColor.greenColor()
        } else {
            cell.connectionStatusView.alpha = 0.0
        }
        
        return cell
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location has been updated.
        if let location = locations.last {
            calculateDestinationETA(location.coordinate)
        }
    }
    
    func calculateDestinationETA(userLocation: CLLocationCoordinate2D){
        // Calulcate driving ETA to charger
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (charger?.chargerLatitude)!, longitude: (charger?.chargerLongitude)!), addressDictionary: nil))
        request.transportType = .Automobile
        let directions = MKDirections(request: request)
        directions.calculateETAWithCompletionHandler { response, error -> Void in
            if let err = error {
                self.labelTransportETA.text = err.userInfo["NSLocalizedFailureReason"] as? String
                return
            }
            let travelTime = String(Double(round(100 * (response!.expectedTravelTime/60))/100))
            let travelTimeString = String.localizedStringWithFormat(NSLocalizedString("%@ minutes of travel time", comment: "Minutes of travel time"), travelTime)
            self.labelTransportETA.text = travelTimeString
            
        }
    }
    
    func determineCommentIconType(){
        let comments = charger!.chargerDetails?.comments?.allObjects as! [Comment]
        let numberOfComments = comments.count
        if (numberOfComments > 0) {
            // We have comments. Show filled icon
            let image = UIImage(named: "ChatFilledIcon")
            buttonComments.setImage(image, forState: .Normal)
            labelNumberOfComments.text = String(numberOfComments)
        }
    }
    
    @IBAction func showCommentViewController(){
        let vc = CommentsListViewController()
        vc.charger = charger
        vc.comments = charger!.chargerDetails?.comments?.allObjects as! [Comment]
        vc.hidesBottomBarWhenPushed = true
        showViewController(vc, sender: nil)
    }
    
    func showChargingStationPhotoViewController(){
        let vc = ChargingStationPhotoViewController()
        vc.chargingStationImageUrl = self.charger?.chargerImage
        vc.hidesBottomBarWhenPushed = true
        self.showViewController(vc, sender: nil)
    }
}