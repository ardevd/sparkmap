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
        chargerCommentsTableView.register(nib, forCellReuseIdentifier: "net.zygotelabs.commentcell")
        chargerCommentsTableView.tableFooterView = UIView(frame: CGRect.zero)
        self.navigationItem.backBarButtonItem?.title = ""
        
        chargerTitleLabel.text = charger?.chargerTitle
        generateCommentButton()
        
        // Autolayout magic in order to resize the row height according to content.
        self.commentsTableView.rowHeight = UITableViewAutomaticDimension
        self.commentsTableView.estimatedRowHeight = 100; //Set this to any value that works for you.
        
        noCommentsView.alpha = 0
        
        // Register notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsListViewController.requestUpdatedData(_:)), name: NSNotification.Name(rawValue: "DataUpdateRequired"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsListViewController.updateChargerDetails(_:)), name: NSNotification.Name(rawValue: "ChargerDataUpdate"), object: nil)
        
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
            UIView.animate(withDuration: 0.7, animations: {
                self.noCommentsView.alpha = 0
                self.noCommentsView.alpha = 1.0
            })
        }
        
        DispatchQueue.main.async(execute: displayView)
    }
    
    func updateChargerDetails(_ notification: Notification) {
        // New data downloaded. Update comments list.
        let dataManager = DataManager()
        var chargers: [ChargerPrimary] = [ChargerPrimary]()
        chargers = dataManager.retrieveNearbyChargerData(Latitude: charger.chargerLatitude, Longitude: charger.chargerLongitude)!
        for newCharger in chargers {
            if newCharger.chargerId == self.charger.chargerId {
                self.charger = newCharger
                self.comments = self.charger.chargerDetails?.comments?.allObjects as! [Comment]
                // Reload table view data in the main queue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.sortCommentsList()
                })
            }
        }
    }
    
    func requestUpdatedData(_ notification: Notification) {
        // Download data for this charging station.
        let delayTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: delayTime) {
            let distance = CLLocationDistance(1)
            let dataManager = DataManager()
            dataManager.downloadNearbyChargers(Latitude: self.charger.chargerLatitude, Longitude: self.charger.chargerLongitude, Distance: distance)
        }
    }
    
    func generateCommentButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let commentButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(CommentsListViewController.commentButtonTapped))
        
        navigationButtonItems.append(commentButtonItem)
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
        
    }
    
    func commentButtonTapped(){
        // Direct user to OCM comment page
        if let chargerId = self.charger?.chargerId{
            let userIsAuthenticated = AuthenticationManager.doWeHaveCredentails()
            if userIsAuthenticated {
                let vc = CommentComposerViewController()
                vc.chargerID = Int(chargerId)
                vc.chargingStationTitle = charger?.chargerTitle
                show(vc, sender: nil)
            } else {
                let vc = OCMSignInViewController()
                vc.showBackButton = true
                show(vc, sender: nil)
            }
        }
    }
    
    func sortCommentsList() {
        comments.sort() { $0.commentDate > $1.commentDate } // sort the comment by date
        commentsTableView.reloadData(); // notify the table view the data has changed
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "net.zygotelabs.commentcell", for: indexPath) as! CommentTableViewCell
        
        cell.commentTextLabel?.text = (comments[(indexPath as NSIndexPath).row] as Comment).comment
        cell.commentUsernameLabel?.text = (comments[(indexPath as NSIndexPath).row] as Comment).username
        let commentDate = (comments[(indexPath as NSIndexPath).row] as Comment).commentDate
        let date = Date(timeIntervalSinceReferenceDate: commentDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        let convertedDate = dateFormatter.string(from: date)
        cell.commentDateLabel?.text = convertedDate
        
        let rating = String((comments[(indexPath as NSIndexPath).row] as Comment).rating)
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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
