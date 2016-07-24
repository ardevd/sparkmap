//
//  CommentComposerViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 22/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class CommentComposerViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet var commentTextView: UITextView!
    @IBOutlet var chargingStationTitleLabel: UILabel!
    @IBOutlet var ratingSegmentedControl: UISegmentedControl!
    
    // Charging Station Details
    var chargerID: Int!
    var chargingStationTitle: String!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CommentComposerViewController.tapOutsideTextView(_:)))
        view.addGestureRecognizer(tapGesture)
        formatTextView()
        commentTextView.becomeFirstResponder()
        
        // Register to be notified if the keyboard is changing size
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.keyboardWillShowOrHide(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.keyboardWillShowOrHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        chargingStationTitleLabel.text = chargingStationTitle
        let newCommentString = NSLocalizedString("New Comment", comment: "New Comment")
        self.title = newCommentString
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShowOrHide(notification: NSNotification) {
        
        // Pull a bunch of info out of the notification
        if let scrollView = scrollView, userInfo = notification.userInfo, endValue = userInfo[UIKeyboardFrameEndUserInfoKey], durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] {
            
            // Transform the keyboard's frame into our view's coordinate system
            let endRect = view.convertRect(endValue.CGRectValue, fromView: view.window)
            
            // Find out how much the keyboard overlaps the scroll view
            // We can do this because our scroll view's frame is already in our view's coordinate system
            let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
            
            // Set the scroll view's content inset to avoid the keyboard
            // Don't forget the scroll indicator too!
            scrollView.contentInset.bottom = keyboardOverlap
            scrollView.scrollIndicatorInsets.bottom = keyboardOverlap
            
            let duration = durationValue.doubleValue
            UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tapOutsideTextView(gesture: UITapGestureRecognizer) {
        commentTextView.resignFirstResponder()
    }
    
    func formatTextView() {
        self.commentTextView.layer.borderWidth = 1.0
        self.commentTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.commentTextView.layer.cornerRadius = 5.0
    }
    
    @IBAction func postCommentAction(){
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.failedToGetNewAccessToken(_:)), name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.gotNewAccessToken(_:)), name: "OCMLoginSuccess", object: nil)
        updateAccessToken()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.commentNotPosted(_:)), name: "OCMCommentPostError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentComposerViewController.commentPostedSuccessfully(_:)), name: "OCMCommentPostSuccess", object: nil)
        updateAccessToken()
        let postingCommentSpinnerString = NSLocalizedString("Posting Comment...", comment: "Posting comment spinner text")
        commentTextView.resignFirstResponder()
        SwiftSpinner.show(postingCommentSpinnerString)
    }
    
    func gotNewAccessToken(notification: NSNotification){
        // New access token received. Go ahead and post comment
        if let accessToken = notification.userInfo?["accessToken"] as? NSString {
            submitCommentToOCM(String(accessToken))
        }
    }
    
    func failedToGetNewAccessToken(notification: NSNotification) {
        // TODO: Notify user that authentication failed. Notification includes error message.
    }

    func updateAccessToken(){
        AuthenticationManager.authenticateUserWithStoredCredentials()
    }
    
    func commentPostedSuccessfully(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            SwiftSpinner.hide()
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    func commentNotPosted(notification: NSNotification) {
        // TODO: Notify user that the comment was not posted. Notification includes error message.
    }
    
    func submitCommentToOCM(accessToken: String){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginSuccess", object: nil)
        CommentSubmissionManager.submitComment(chargerID, commentText: commentTextView.text, rating: ratingSegmentedControl.selectedSegmentIndex, accessToken: accessToken)
    }
}
