//
//  CommentsListViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 16/05/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit
import MapKit

class CommentsListViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate {
    
    // Outlets
    @IBOutlet var chargerTitleLabel: UILabel!
    @IBOutlet var chargerCommentsTableView: UITableView!
    @IBOutlet var chargerCommentTextView: UITextField!
    @IBOutlet var chargerCommentSubmitButton: UIButton!
    @IBOutlet var noCommentsView: UIView!
    @IBOutlet var commentsTableView: UITableView!
    
    var charger: ChargerPrimary!
    var comments: [Comment] = [Comment]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure TableView
        let nib = UINib(nibName: "CommentTableViewCell", bundle: nil)
        chargerCommentsTableView.registerNib(nib, forCellReuseIdentifier: "net.zygotelabs.commentcell")
        chargerCommentsTableView.tableFooterView = UIView(frame: CGRectZero)
        self.navigationItem.backBarButtonItem?.title = ""
        
        chargerTitleLabel.text = charger?.chargerTitle
        generateCommentButton()
        
        // Autolayout magic in order to resize the row height according to content.
        self.commentsTableView.rowHeight = UITableViewAutomaticDimension
        self.commentsTableView.estimatedRowHeight = 100; //Set this to any value that works for you.
        
        noCommentsView.alpha = 0
        
        // Register notification observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsListViewController.requestUpdatedData(_:)), name: "DataUpdateRequired", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentsListViewController.updateChargerDetails(_:)), name: "ChargerDataUpdate", object: nil)
        
        if (comments.count == 0) {
            showNoCommentsView()
        } else {
            sortCommentsList()
        }
        
    }
    
    func showNoCommentsView(){
        func displayView()
        {
            // Animate the fade in of the image
            UIView.animateWithDuration(0.7, animations: {
                self.noCommentsView.alpha = 0
                self.noCommentsView.alpha = 1.0
            })
        }
        
        dispatch_async(dispatch_get_main_queue(), displayView)
    }
    
    func updateChargerDetails(notification: NSNotification) {
        // New data downloaded. Update comments list.
        let dataManager = DataManager()
        var chargers: [ChargerPrimary] = [ChargerPrimary]()
        chargers = dataManager.retrieveNearbyChargerData(Latitude: charger.chargerLatitude, Longitude: charger.chargerLongitude)!
        for newCharger in chargers {
            if newCharger.chargerId == self.charger.chargerId {
                self.charger = newCharger
                self.comments = self.charger.chargerDetails?.comments?.allObjects as! [Comment]
                // Reload table view data in the main queue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sortCommentsList()
                })
            }
        }
    }
    
    func requestUpdatedData(notification: NSNotification) {
        // Download data for this charging station.
        let distance = CLLocationDistance(1)
        let dataManager = DataManager()
        dataManager.downloadNearbyChargers(Latitude: charger.chargerLatitude, Longitude: charger.chargerLongitude, Distance: distance)
    }
    
    func generateCommentButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let commentButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: #selector(CommentsListViewController.commentButtonTapped))
        
        navigationButtonItems.append(commentButtonItem)
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
        
    }
    
    func commentButtonTapped(){
        // Direct user to OCM comment page
        if let chargerId = self.charger?.chargerId{
            if AuthenticationManager.doWeHaveCredentails(){
                let vc = CommentComposerViewController()
                vc.chargerID = Int(chargerId)
                vc.chargingStationTitle = charger?.chargerTitle
                showViewController(vc, sender: nil)
            } else {
                let vc = OCMSignInViewController()
                vc.showBackButton = true
                showViewController(vc, sender: nil)
            }
        }
    }
    
    func sortCommentsList() { // should probably be called sort and not filter
        comments.sortInPlace() { $0.commentDate > $1.commentDate } // sort the fruit by name
        commentsTableView.reloadData(); // notify the table view the data has changed
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("net.zygotelabs.commentcell", forIndexPath: indexPath) as! CommentTableViewCell
        
        cell.commentTextLabel?.text = (comments[indexPath.row] as Comment).comment
        cell.commentUsernameLabel?.text = (comments[indexPath.row] as Comment).username
        let commentDate = (comments[indexPath.row] as Comment).commentDate
        let date = NSDate(timeIntervalSinceReferenceDate: commentDate)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        let convertedDate = dateFormatter.stringFromDate(date)
        cell.commentDateLabel?.text = convertedDate
        
        let rating = String((comments[indexPath.row] as Comment).rating)
        if rating == "5" {
            cell.commentRatingView?.backgroundColor = UIColor(red: 107/255, green: 211/255, blue: 124/255, alpha: 1.0)
        } else if rating == "4" {
            cell.commentRatingView?.backgroundColor = UIColor(red: 185/255, green: 211/255, blue: 107/255, alpha: 1.0)
        } else if rating == "3" {
            cell.commentRatingView?.backgroundColor = UIColor(red: 211/255, green: 202/255, blue: 107/255, alpha: 1.0)
        } else if rating == "2" {
            cell.commentRatingView?.backgroundColor = UIColor(red: 196/255, green: 137/255, blue: 34/255, alpha: 1.0)
        } else if rating == "1" {
            cell.commentRatingView?.backgroundColor = UIColor(red: 223/255, green: 105/255, blue: 93/255, alpha: 1.0)
        } else {
            cell.commentRatingView?.backgroundColor = UIColor(red: 109/255, green: 109/255, blue: 109/255, alpha: 1.0)
        }
        
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
        return cell
    }
    
    deinit {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
