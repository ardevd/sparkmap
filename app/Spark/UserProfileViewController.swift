//
//  UserProfileViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var reputationLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manipulateViews()
        
        //Customize appearance
        // Format UINavBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        
        generateSignoutButton()
        
        if doWeHaveCredentails(){
            registerNotificationListeners()
            authenticateUser()
        } else {
            registerSignupNotificationListener()
            launchOCMSignInViewController()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func registerNotificationListeners(){
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserProfileViewController.userAuthenticationFailed(_:)), name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserProfileViewController.successfulSigninOccurred(_:)), name: "OCMLoginSuccess", object: nil)
    }
    
    func authenticateUser(){
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.stringForKey("ocmUsername")
        let password = defaults.stringForKey("ocmPassword")
        AuthenticationManager.getSessionToken(String(username!), password: String(password!))
    }
    
    func successfulSigninOccurred(notification: NSNotification){
        // User is authenticated, populate views with stuff.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let username = notification.userInfo?["username"] as? NSString {
                self.usernameLabel.text = String(username)
            }
            
            if let email = notification.userInfo?["email"] as? NSString {
                self.emailLabel.text = String(email)
            }
            
            if let location = notification.userInfo?["location"] as? NSString {
                self.locationLabel.text = String(location)
            }
            
            if let reputationPoints = notification.userInfo?["reputation"] as? NSString {
                self.reputationLabel.text = String(reputationPoints)
                
            }
            
            if let avatarURL = notification.userInfo?["avatarURL"] as? NSString {
                self.downloadAvatarImage(String(avatarURL))
            }
        })
    }
    
    func downloadAvatarImage(imageUrl: String){
        if let url = NSURL(string: imageUrl) {
            let request: NSURLRequest = NSURLRequest(URL: url)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request){
                (data, response, error) -> Void in
                
                if (error == nil && data != nil)
                {
                    func displayImage()
                    {
                        self.avatarImageView.image = UIImage(data: data!)
                        self.avatarImageView.alpha = 1.0
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), displayImage)
                }
            }
            
            task.resume()
        }
    }
    
    func userAuthenticationFailed(notification: NSNotification){
        // TODO: Handle user authentication failure.
        signOutOfOCMAccount()
    }
    
    func userLoginCompleted(notification: NSNotification) {
        registerNotificationListeners()
        authenticateUser()
    }
    
    func generateSignoutButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let signoutButtonTitle = NSLocalizedString("Sign Out", comment: "Sign out of OCM")
        let signoutButtonItem = UIBarButtonItem(title: signoutButtonTitle, style: .Plain, target: self, action: #selector(UserProfileViewController.signOutOfOCMAccount))
        
        navigationButtonItems.append(signoutButtonItem)
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)
    }
    
    func signOutOfOCMAccount(){
        launchOCMSignInViewController()
        clearAuthenticationCredentials()
        removeNotificationObservers()
        registerSignupNotificationListener()
    }
    
    func removeNotificationObservers(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginSuccess", object: nil)
    }
    
    func registerSignupNotificationListener(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserProfileViewController.userLoginCompleted(_:)), name: "OCMUserLoginDone", object: nil)
    }
    
    func doWeHaveCredentails() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.stringForKey("ocmUsername")
        let password = defaults.stringForKey("ocmPassword")
        if username == nil || password == nil {
            return false
        }
        
        return true
    }
    
    func clearAuthenticationCredentials(){
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "ocmUsername")
        defaults.setObject(nil, forKey: "ocmPassword")
        
    }
    
    func launchOCMSignInViewController(){
        let vc = OCMSignInViewController()
        showViewController(vc, sender: nil)
    }
    
    func manipulateViews(){
        // Make the reputation and avatar views circular.
        self.avatarImageView.layer.borderWidth = 2.0
        self.avatarImageView.layer.masksToBounds = false
        self.avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2
        self.avatarImageView.clipsToBounds = true
    }
    
}
