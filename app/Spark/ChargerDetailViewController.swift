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
import SafariServices

class ChargerDetailViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UIViewControllerPreviewingDelegate {
    // Outlets
    @IBOutlet var imageThumbnail: UIImageView!
    @IBOutlet var buttonOperator: UIButton!
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
    @IBOutlet var viewTransportETA: UIView!
    
    // Location
    var locationManager: CLLocationManager?
    
    /* We will use this property to keep track on whether
     or not positioning is active */
    var isActive: Bool = false
    
    // Use this to indicate whether we have a proper travel ETA
    var gotETA: Bool = false
    
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
        chargingPointTableView.register(nib, forCellReuseIdentifier: "net.zygotelabs.connectioncell")
        chargingPointTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        
        // Download charger thumbnail image
        if let thumbnailImageURL = charger?.chargerImage {
            downloadThumbnailImage(thumbnailImageURL)
        } else {
            // Add gestureRecognizer that lets user take and upload photo
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ChargerDetailViewController.grabAndLoadUserPhoto(_:)))
            imageThumbnail.isUserInteractionEnabled = true
            imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
            
            if let image = UIImage(named: "PlaceholderImageIcon") {
                imageThumbnail.image = image
            }
        }
        
        // Add Gesture recognizer for launching navigation when tapping the travel ETA label.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ChargerDetailViewController.etaLabelTapped(_:)))
        viewTransportETA.addGestureRecognizer(tapGesture)
        
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
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: imageThumbnail)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Set up peeking
        let vc = ChargingStationPhotoViewController()
        vc.chargingStationImageUrl = self.charger?.chargerImage
        vc.chargingStationImage = self.imageThumbnail.image
        previewingContext.sourceRect = imageThumbnail.frame
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Set up Popping
        if showingLargeImage != nil {
            if showingLargeImage! {
                toggleFullThumbnilImage()
            }
        }
        show(viewControllerToCommit, sender: self)
    }
    
    func checkLocationAuthorization() -> Bool{
        let authStatus = CLLocationManager.authorizationStatus()
        
        switch authStatus {
        case CLAuthorizationStatus.authorizedWhenInUse:
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
        let navigationButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(ChargerDetailViewController.navigateButtonTapped))
        navigationButtonItem.image = UIImage(named: "CarIcon")
        navigationButtonItem.title = " "
        return navigationButtonItem
        
    }
    
    func generateCallButton() -> UIBarButtonItem {
        // Button that lets user call the number associated wtih the charging station.
        let callButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(ChargerDetailViewController.callButtonTapped))
        callButtonItem.image = UIImage(named: "CallIcon")
        callButtonItem.title = " "
        return callButtonItem
    }
    
    func navigateButtonTapped() {
        startNavigation()
    }
    
    func etaLabelTapped(_ gesture: UITapGestureRecognizer) {
        if gotETA {
            startNavigation()
        }
    }
    
    func startNavigation() {
        let addressDictionary = [String(CNPostalAddressStreetKey): labelSubtitle.text as AnyObject]
        let chargingPointPlaceCoordinate = CLLocationCoordinate2D(latitude: (charger?.chargerLatitude)!, longitude: (charger?.chargerLongitude)!)
        let placemark = MKPlacemark(coordinate: chargingPointPlaceCoordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = labelSubtitle.text
        
        let options = [MKLaunchOptionsDirectionsModeKey:
            MKLaunchOptionsDirectionsModeDriving]
        
        mapItem.openInMaps(launchOptions: options)
    }
    
    func callButtonTapped() {
        let phoneNumber = charger?.chargerDetails?.chargerPrimaryContactNumber?.replacingOccurrences(of: " ", with: "")
        
        if let callUrl = URL(string: "tel:\(phoneNumber!)") {
            UIApplication.shared.openURL(callUrl)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
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
        UIView.animate(withDuration: 0.5, animations: {
            if (self.viewLastUpdateTime.alpha > 0){
                self.viewLastUpdateTime.alpha = 0.0
            }else {
                self.viewLastUpdateTime.alpha = 1.0
            }
        })
    }
    
    @IBAction func editChargingStation() {
        if let chargerId = self.charger?.chargerId{
            let safariViewController = SFSafariViewController(url: URL(string: "http://openchargemap.org/site/poi/edit/\(chargerId)")!)
            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func checkAndAnimateRecentlyVerifiedView() {
        if let isRecentlyVerified = charger?.chargerDetails?.chargerRecentlyVerified {
            if isRecentlyVerified {
                self.viewRecentlyVerified.frame.size.width = 0
                // Charger was recently verified. Show the badge.
                UIView.animate(withDuration: 0.5, animations: {
                    self.viewRecentlyVerified.alpha = 1.0
                    self.viewRecentlyVerified.frame.size.width = 123
                })
            }
        }
    }
    
    func addViewAppearanceElements(){
        viewNumberOfPoints.layer.borderWidth = 0.25
        viewNumberOfPoints.layer.borderColor = UIColor.white.cgColor
        viewChargerStatus.layer.borderWidth = 0.25
        viewChargerStatus.layer.borderColor = UIColor.white.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors =  [
            UIColor(red: 93, green: 116, blue: 177, alpha: 1),
            UIColor(red: 92, green: 108, blue: 171, alpha: 1)
        ]
        
        gradientLayer.frame = viewNumberOfPoints.bounds
        self.viewNumberOfPoints.layer.addSublayer(gradientLayer)
    }
    
    func grabAndLoadUserPhoto(_ img: AnyObject)
    {
        /* Define a UIImagePickerController that lets the user
         supply a photo of a charging station */
        
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        
        // Camera Source Action
        let cameraSourceString = NSLocalizedString("Camera", comment: "Camera Source")
        let cameraSourceAction = UIAlertAction(title: cameraSourceString, style: .default) { (alert: UIAlertAction!) -> Void in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        // Album Source Action
        let albumSourceString = NSLocalizedString("Photo Library", comment: "Library Source")
        let albumSourceAction = UIAlertAction(title: albumSourceString, style: .default) { (alert: UIAlertAction!) -> Void in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
        // Dismiss Action
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "Cancel Action Text")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel) { (alert: UIAlertAction!) -> Void in
        }
        
        // Ask user whether to grab photo from the camera or the photo album.
        let photoSubmissionTitleString = NSLocalizedString("Photo Submission", comment: "Photo Submission")
        let photoSubmissionMessageString = NSLocalizedString("Submit a photo for this charging station", comment: "Submit a photo description text")
        let photoSourcePromptAlert = UIAlertController(title: photoSubmissionTitleString, message: photoSubmissionMessageString, preferredStyle: UIAlertControllerStyle.actionSheet)
        photoSourcePromptAlert.addAction(cameraSourceAction)
        photoSourcePromptAlert.addAction(albumSourceAction)
        photoSourcePromptAlert.addAction(cancelAction)
        self.present(photoSourcePromptAlert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imageThumbnail.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // Ask user for confirmation before uploading photo.
        //Action
        let yesString = NSLocalizedString("Yes", comment: "Yes")
        let noString = NSLocalizedString("No", comment: "No")
        
        let photoUploadAction = UIAlertAction(title: yesString, style: .default) { (alert: UIAlertAction!) -> Void in
            // User confirmed. Post the photo
            let userPhotoSubmissionManager = UserPhotoSubmissionManager()
            if let chargerId = self.charger?.chargerId{
                userPhotoSubmissionManager.userPhotoUploadRequest(self.imageThumbnail, chargerId: chargerId)
                self.registerPhotoUploadNotificationObservers()
                self.indicatorImageLoader.startAnimating()
            }
        }
        //AlertController
        let photoSubmissionConfirmationRequestString = NSLocalizedString("Awesome. Go ahead and upload the photo?", comment: "Photo submission request message")
        let photoSubmissionConfirmationTitleString = NSLocalizedString("Upload photo", comment: "Photo Submitted")
        let photoSubmissionRequestAlert = UIAlertController(title: photoSubmissionConfirmationTitleString, message: photoSubmissionConfirmationRequestString, preferredStyle: UIAlertControllerStyle.alert)
        photoSubmissionRequestAlert.addAction(UIAlertAction(title: noString, style: UIAlertActionStyle.default, handler: nil))
        photoSubmissionRequestAlert.addAction(photoUploadAction)
        self.present(photoSubmissionRequestAlert, animated: true, completion: nil)
        
    }
    
    func registerPhotoUploadNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(ChargerDetailViewController.userPhotoPostSuccess(_:)), name: NSNotification.Name(rawValue: "PhotoPostSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChargerDetailViewController.userPhotoPostFailed(_:)), name: NSNotification.Name(rawValue: "PhotoPostFailed"), object: nil)
    }
    
    func userPhotoPostSuccess(_ notification: Notification) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.indicatorImageLoader.stopAnimating()
        })
    }
    
    func userPhotoPostFailed(_ notification: Notification) {
        // User image posting failed. Alert user
        DispatchQueue.main.async(execute: { () -> Void in
            self.indicatorImageLoader.stopAnimating()
            let okString = NSLocalizedString("OK", comment: "OK")
            let photoSubmissionFailedTitleString = NSLocalizedString("Photo upload failed.", comment: "User photo upload failed")
            let photoSubmissionFailedDescriptionString = NSLocalizedString("Could not post the photo. Please try again later.", comment: "User photo upload failed description message.")
            let photoSubmissionFailedAlert = UIAlertController(title: photoSubmissionFailedTitleString, message: photoSubmissionFailedDescriptionString, preferredStyle: UIAlertControllerStyle.alert)
            photoSubmissionFailedAlert.addAction(UIAlertAction(title: okString, style: UIAlertActionStyle.default, handler: nil))
            self.present(photoSubmissionFailedAlert, animated: true, completion: nil)
        })
    }
    
    func toggleFullImage(_ img: AnyObject) {
        toggleFullThumbnilImage()
    }
    
    func toggleFullThumbnilImage(){
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 8, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
            
            if (self.imageThumbnail.frame == self.viewHeader.layer.bounds){
                self.imageThumbnail.frame = self.originalThumbnailImageFrame!
                self.buttonLastUpdateTime.alpha = 1
                self.buttonComments.alpha = 1
                self.labelNumberOfComments.alpha = 1
                self.labelSubtitle.alpha = 1
                self.buttonOperator.alpha = 1
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
                self.buttonOperator.alpha = 0
                self.showingLargeImage = true
            }
            self.view.layoutIfNeeded()
            }, completion: nil)
        
    }
    
    func manipulateThumbnailImage(){
        
        self.imageThumbnail.layer.borderWidth = 1.0
        self.imageThumbnail.layer.masksToBounds = false
        self.imageThumbnail.layer.borderColor = UIColor.white.cgColor
        self.imageThumbnail.layer.cornerRadius = self.imageThumbnail.frame.size.width/2
        self.imageThumbnail.clipsToBounds = true
        
    }
    
    func manageNavigationButtons(){
        var navigationButtonItems = [UIBarButtonItem]()
        
        if let subtitle = charger?.chargerSubtitle {
            labelSubtitle.text = subtitle
            // Configure navigation button
            navigationButtonItems.append(generateNavigationButton())
        }
        
        if let primaryPhoneNumber = charger?.chargerDetails?.chargerPrimaryContactNumber {
            if primaryPhoneNumber.characters.count > 3 {
                navigationButtonItems.append(generateCallButton())
            }
        }
        
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
    }
    
    func setChargerInfoToOutlets(){

        if let title = charger?.chargerTitle {
            self.title = title
        }
        
        if let operatorName = charger?.chargerOperator?.operatorName {
            if operatorName == "(Unknown Operator)" {
                buttonOperator.alpha = 0
            }
            buttonOperator.setTitle(operatorName, for: UIControlState())
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
            let date = Date(timeIntervalSinceReferenceDate: dataLastUpdateTime)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = DateFormatter.Style.medium
            let convertedDate = dateFormatter.string(from: date)
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
        
        manageNavigationButtons()
        
    }
    
    func updateChargerOperationalStatus(_ isOperational: Bool){
        //TODO: Implement "Offline" Indication.
        if (isOperational){
            let statusOperationalString = NSLocalizedString("Operational", comment: "Charging Status Operational")
            labelStatus.text = statusOperationalString
        } else {
            let statusUnknownString = NSLocalizedString("Unknown", comment: "Charging Status Unknown")
            labelStatus.text = statusUnknownString
            UIView.animate(withDuration: 1.0, animations: {
                self.viewChargerStatus.backgroundColor = UIColor(red: 234/255, green: 155/255, blue: 3/255, alpha: 1.0)
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func downloadThumbnailImage(_ imageUrl: String){
        if let url = URL(string: imageUrl) {
            indicatorImageLoader.startAnimating()
            let request: URLRequest = URLRequest(url: url)
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: {
                (data, response, error) -> Void in
                
                if (error == nil && data != nil)
                {
                    func displayImage()
                    {
                        // Animate the fade in of the image
                        UIView.animate(withDuration: 1.0, animations: {
                            self.imageThumbnail.alpha = 0.0
                            self.imageThumbnail.image = UIImage(data: data!)
                            self.imageThumbnail.alpha = 1.0
                            
                            // Register 3d Touch capabilties
                            self.registerForceTouchCapability()
                            
                            // Add gestureRecognizer
                            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(ChargerDetailViewController.toggleFullImage(_:)))
                            self.imageThumbnail.isUserInteractionEnabled = true
                            self.imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
                        })
                    }
                    
                    DispatchQueue.main.async(execute: displayImage)
                }
                
                func dismissActivityIndicator(){
                    self.indicatorImageLoader.stopAnimating()
                }
                
                DispatchQueue.main.async(execute: dismissActivityIndicator)
            })
            
            task.resume()
        }
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "net.zygotelabs.connectioncell", for: indexPath) as! ConnectionTableViewCell
        
        let connectionTypeId = (connections[(indexPath as NSIndexPath).row] as Connection).connectionTypeId
        if connectionTypeId == 33 {
            let connectionTypeCCSString = NSLocalizedString("CCS Combo", comment: "Navigate")
            cell.connectionTypeLabel?.text = connectionTypeCCSString
        } else {
            cell.connectionTypeLabel?.text = (connections[(indexPath as NSIndexPath).row] as Connection).connectionTypeTitle
        }
        
        //Only show Quantity if > 0
        let connectionQuantity = (connections[(indexPath as NSIndexPath).row] as Connection).connectionQuantity
        if (connectionQuantity > 0) {
            cell.connectionQuantityLabel?.text = String(connectionQuantity)
            // If total connection quantity is unavaible, we calculate and display.
            if (totalChargingPointQuantityAvailable == false) {
                labelNumberOfPoints.text = String(Int(labelNumberOfPoints.text!)! + Int(connectionQuantity))
            }
        } else {
            cell.connectionQuantityLabel?.text = ""
        }
        
        var connectionPowerParams = ""
        let connectionCurrent = (connections[(indexPath as NSIndexPath).row] as Connection).connectionAmp
        var gotCurrent = false
        if (connectionCurrent > 0){
            connectionPowerParams = String((connections[(indexPath as NSIndexPath).row] as Connection).connectionAmp) + "A"
            gotCurrent = true
        }
        let connectionPower = (connections[(indexPath as NSIndexPath).row] as Connection).connectionPowerKW
        if (connectionPower > 0) {
            if gotCurrent {
                connectionPowerParams += "/"
            }
            connectionPowerParams += (String((connections[(indexPath as NSIndexPath).row] as Connection).connectionPowerKW) + "KW")
        }
        
        cell.connectionAmpLabel?.text = connectionPowerParams
        
        // Show status indicator if applicable
        let connectionStatusTypeID = (connections[(indexPath as NSIndexPath).row] as Connection).connectionStatusTypeID
        if connectionStatusTypeID == 100 {
            cell.connectionStatusView.backgroundColor = UIColor(red: 223/255, green: 105/255, blue: 93/255, alpha: 1.0)
        } else if connectionStatusTypeID == 50{
            cell.connectionStatusView.backgroundColor = UIColor(red: 107/255, green: 211/255, blue: 124/255, alpha: 1.0)
        } else if connectionStatusTypeID == 75 {
            cell.connectionStatusView.backgroundColor = UIColor(red: 196/255, green: 137/255, blue: 34/255, alpha: 1.0)
        } else {
            cell.connectionStatusView.backgroundColor = UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 1.0)
        }
        
        return cell
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location has been updated.
        if let location = locations.last {
            calculateDestinationETA(location.coordinate)
        }
    }
    
    func calculateDestinationETA(_ userLocation: CLLocationCoordinate2D){
        // Calulcate driving ETA to charger
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (charger?.chargerLatitude)!, longitude: (charger?.chargerLongitude)!), addressDictionary: nil))
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculateETA { response, error -> Void in
            if let err = error {
                self.labelTransportETA.text = (err as NSError).userInfo["NSLocalizedFailureReason"] as? String
                self.gotETA = false
                return
            }
            let travelTime = String(Double(round(100 * (response!.expectedTravelTime/60))/100))
            let travelTimeString = String.localizedStringWithFormat(NSLocalizedString("%@ minutes of travel time", comment: "Minutes of travel time"), travelTime)
            self.labelTransportETA.text = travelTimeString
            self.gotETA = true
        }
    }
    
    func determineCommentIconType(){
        let comments = charger!.chargerDetails?.comments?.allObjects as! [Comment]
        let numberOfComments = comments.count
        if (numberOfComments > 0) {
            // We have comments. Show filled icon
            let image = UIImage(named: "ChatFilledIcon")
            buttonComments.setImage(image, for: UIControlState())
            labelNumberOfComments.text = String(numberOfComments)
        }
    }
    
    @IBAction func showOperatorWebsite(){
        
        if let operatorWebsiteURLString = charger?.chargerOperator?.operatorWeb {
            if let url = URL(string: operatorWebsiteURLString) {
                let safariViewController = SFSafariViewController(url: url)
                self.present(safariViewController, animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func showCommentViewController(){
        let vc = CommentsListViewController()
        vc.charger = charger
        vc.comments = charger!.chargerDetails?.comments?.allObjects as! [Comment]
        vc.hidesBottomBarWhenPushed = true
        show(vc, sender: nil)
    }
    
    func showChargingStationPhotoViewController(){
        let vc = ChargingStationPhotoViewController()
        vc.chargingStationImageUrl = self.charger?.chargerImage
        vc.hidesBottomBarWhenPushed = true
        self.show(vc, sender: nil)
    }
}
