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
    @IBOutlet var submitButton: UIButton!
    
    // Charging Station Details
    var chargerID: Int!
    var chargingStationTitle: String!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Gesture recognizer for hiding the keyboard when tapping outside it.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CommentComposerViewController.tapOutsideTextView(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Prepare the comment text view.
        formatTextView()
        
        // Make the comment text view the first responder
        commentTextView.becomeFirstResponder()
        
        // Register to be notified if the keyboard is changing size
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Set the charging station title text.
        chargingStationTitleLabel.text = chargingStationTitle
        
        // Set the view controller title.
        let newCommentString = NSLocalizedString("New Comment", comment: "New Comment")
        self.title = newCommentString
        
        // Add rounded corners to the submit button.
        self.submitButton.layer.cornerRadius = 5.0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShowOrHide(_ notification: Notification) {
        
        // Pull a bunch of info out of the notification
        if let scrollView = scrollView, let userInfo = (notification as NSNotification).userInfo, let endValue = userInfo[UIKeyboardFrameEndUserInfoKey], let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] {
            
            // Transform the keyboard's frame into our view's coordinate system
            let endRect = view.convert((endValue as AnyObject).cgRectValue, from: view.window)
            
            // Find out how much the keyboard overlaps the scroll view
            // We can do this because our scroll view's frame is already in our view's coordinate system
            let keyboardOverlap = scrollView.frame.maxY - endRect.origin.y
            
            // Set the scroll view's content inset to avoid the keyboard
            // Don't forget the scroll indicator too!
            scrollView.contentInset.bottom = keyboardOverlap
            scrollView.scrollIndicatorInsets.bottom = keyboardOverlap
            
            let duration = (durationValue as AnyObject).doubleValue
            UIView.animate(withDuration: duration!, delay: 0, options: .beginFromCurrentState, animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tapOutsideTextView(_ gesture: UITapGestureRecognizer) {
        // Resign first responder from commentTextview if user taps outside the keyboard area.
        commentTextView.resignFirstResponder()
    }
    
    func formatTextView() {
        self.commentTextView.layer.borderWidth = 1.0
        self.commentTextView.layer.borderColor = UIColor.lightGray.cgColor
        self.commentTextView.layer.cornerRadius = 5.0
    }
    
    @IBAction func postCommentAction(){
        // Register notification listeners
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.failedToGetNewAccessToken(_:)), name: NSNotification.Name(rawValue: "OCMLoginFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.gotNewAccessToken(_:)), name: NSNotification.Name(rawValue: "OCMLoginSuccess"), object: nil)
        updateAccessToken()
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.commentNotPosted(_:)), name: NSNotification.Name(rawValue: "OCMCommentPostError"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentComposerViewController.commentPostedSuccessfully(_:)), name: NSNotification.Name(rawValue: "OCMCommentPostSuccess"), object: nil)
        
        // Authenticate to OCM and get a new access token
        updateAccessToken()
        
        // Resign text view first responder.
        commentTextView.resignFirstResponder()
        
        // Show loading spinner
        let postingCommentSpinnerString = NSLocalizedString("Posting Comment...", comment: "Posting comment spinner text")
        SwiftSpinner.show(postingCommentSpinnerString)
    }
    
    func gotNewAccessToken(_ notification: Notification){
        // New access token received. Go ahead and post comment
        if let accessToken = (notification as NSNotification).userInfo?["accessToken"] as? NSString {
            submitCommentToOCM(String(accessToken))
        }
    }
    
    func failedToGetNewAccessToken(_ notification: Notification) {
        // Notify user that authentication failed. Notification includes error message.
        if let errorMessage = (notification as NSNotification).userInfo?["errorMesssage"] as? NSString {
            SwiftSpinner.show(String(errorMessage), animated: false).addTapHandler({
                SwiftSpinner.hide()
            })
        }
    }

    func updateAccessToken(){
        AuthenticationManager.authenticateUserWithStoredCredentials()
    }
    
    func commentPostedSuccessfully(_ notification: Notification) {
        // Comment posted. Post notification and pop view controller.
        DispatchQueue.main.async(execute: { () -> Void in
            SwiftSpinner.hide()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "DataUpdateRequired"), object: nil)
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func commentNotPosted(_ notification: Notification) {
        // Notify user that the comment was not posted. Notification includes error message.
        if let errorMessage = (notification as NSNotification).userInfo?["errorMesssage"] as? NSString {
            SwiftSpinner.show(String(errorMessage), animated: false).addTapHandler({
                SwiftSpinner.hide()
            })
        }
    }
    
    func submitCommentToOCM(_ accessToken: String){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "OCMLoginFailed"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "OCMLoginSuccess"), object: nil)
        CommentSubmissionManager.submitComment(chargerID, commentText: commentTextView.text, rating: ratingSegmentedControl.selectedSegmentIndex, accessToken: accessToken)
    }
}
