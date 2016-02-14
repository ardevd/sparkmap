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

class ChargerDetailViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    // Outlets
    @IBOutlet var imageThumbnail: UIImageView!
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelSubtitle: UILabel!
    @IBOutlet var labelAccess: UILabel!
    @IBOutlet var labelNumberOfPoints: UILabel!
    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var chargingPointTableView: UITableView!
    @IBOutlet var dataLastUpdateTimeLabel: UILabel!
    @IBOutlet var indicatorImageLoader: UIActivityIndicatorView!
    
    // Views
    @IBOutlet var viewNumberOfPoints: UIView!
    @IBOutlet var viewChargerStatus: UIView!
    @IBOutlet var viewHeader: UIView!
    @IBOutlet var viewLastUpdateTime: UIView!
    
    
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
            // Add gestureRecognizer if we have loaded an image
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:Selector("toggleFullImage:"))
            imageThumbnail.userInteractionEnabled = true
            imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
        } else {
            // Add gestureRecognizer that lets user take and upload photo
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:Selector("grabAndLoadUserPhoto:"))
            imageThumbnail.userInteractionEnabled = true
            imageThumbnail.addGestureRecognizer(tapGestureRecognizer)
            
            if let image = UIImage(named: "placeholder_charger_img.png") {
                imageThumbnail.image = image
            }
        }
        
        addAndConfigureNavigationButton()
        
    }
    
    func addAndConfigureNavigationButton() {
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(title: "Navigate", style: .Plain, target: self, action: "navigateButtonTapped"), animated: true)
        self.navigationItem.rightBarButtonItem?.image = UIImage(named: "CarIcon")
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
        UIView.animateWithDuration(1.0, animations: {
            if (self.viewLastUpdateTime.alpha > 0){
                self.viewLastUpdateTime.alpha = 0.0
            }else {
                self.viewLastUpdateTime.alpha = 1.0
            }
        })
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
        
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageThumbnail.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // Show UIAlertController to user.
        let alert = UIAlertController(title: "Photo Submission", message: "This feature is not yet available", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        //TODO: Upload image to own server for manual submission
    }
    
    
    
    
    func toggleFullImage(img: AnyObject)
    {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 8, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            
            if (self.imageThumbnail.frame == self.viewHeader.layer.bounds){
                self.imageThumbnail.frame = self.originalThumbnailImageFrame!
                self.manipulateThumbnailImage()
            }else{
                self.imageThumbnail.frame = self.viewHeader.layer.bounds
                self.imageThumbnail.layer.cornerRadius = 0
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
        if let title = charger?.chargerTitle {
            labelTitle.text = title
            self.title = title
        }
        
        if let subtitle = charger?.chargerSubtitle {
            labelSubtitle.text = subtitle
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
        
        if let accessComment = charger?.chargerDetails?.chargerAccessComment {
            if accessComment.characters.count >= 1 {
                labelAccess.text = accessComment
            } else {
                labelAccess.text = "No Access Information Available"
            }
        } else {
            labelAccess.text = "No Access Information Available"
        }
        
        if let chargerIsOperational = charger?.chargerIsOperational {
            updateChargerOperationalStatus(chargerIsOperational)
        }
    }
    
    func updateChargerOperationalStatus(isOperational: Bool){
        //TODO: Implement "Offline" Indication.
        if (isOperational){
            labelStatus.text = "Operational"
        } else {
            labelStatus.text = "Unknown"
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
                        self.imageThumbnail.image = UIImage(data: data!)
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
        
        return cell
    }
    
}
