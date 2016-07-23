//
//  CommentsListViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 16/05/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class CommentsListViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate {
    
    // Outlets
    @IBOutlet var chargerTitleLabel: UILabel!
    @IBOutlet var chargerCommentsTableView: UITableView!
    @IBOutlet var chargerCommentTextView: UITextField!
    @IBOutlet var chargerCommentSubmitButton: UIButton!
    @IBOutlet var noCommentsView: UIView!
    @IBOutlet var commentsTableView: UITableView!
    
    var charger: ChargerPrimary?
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
        
        if (comments.count == 0) {
            showNoCommentsView()
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
    
    func generateCommentButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let commentButtonTitle = NSLocalizedString("Write Comment", comment: "Write Comment")
        let commentButtonItem = UIBarButtonItem(title: commentButtonTitle, style: .Plain, target: self, action: #selector(CommentsListViewController.commentButtonTapped))
        
        navigationButtonItems.append(commentButtonItem)
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
        
    }
    
    func commentButtonTapped(){
        // Direct user to OCM comment page
        if let chargerId = self.charger?.chargerId{
            //UIApplication.sharedApplication().openURL(NSURL(string: "http://openchargemap.org/site/poi/addcomment/\(chargerId)")!)
            if AuthenticationManager.doWeHaveCredentails(){
                let vc = CommentComposerViewController()
                vc.chargerID = Int(chargerId)
                vc.chargingStationTitle = charger?.chargerTitle
                showViewController(vc, sender: nil)
            } else {
                let vc = OCMSignInViewController()
                showViewController(vc, sender: nil)
            }
        }
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
