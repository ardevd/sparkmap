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
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    lazy var userManager: UserManager = UserManager()
    lazy var fileStorageManager: FileStorageManager = FileStorageManager()
    
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
        
        if AuthenticationManager.doWeHaveCredentails(){
            registerNotificationListeners()
            authenticateUser()
            populateViewsFromStoredUserData()
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
        AuthenticationManager.authenticateUserWithStoredCredentials()
        activityIndicatorView.startAnimating()
    }
    
    func populateViewsFromStoredUserData(){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.userManager.loadUserDataFromUserDefaults()
            self.usernameLabel.text = self.userManager.username
            self.emailLabel.text = self.userManager.emailAddress
            self.locationLabel.text = self.userManager.location
            self.loadAvatarImageFromStorage()
            if let reputationValue = self.userManager.reputation {
            self.reputationLabel.text = "\(reputationValue)"
            }
        })
    }
    
    func successfulSigninOccurred(notification: NSNotification){
        // Dismiss activity indicator. Does it need to be done on the main queue?
        dismissActivityIndicatorView()
        
        // User is authenticated, handle the new user data
            if let username = notification.userInfo?["username"] as? NSString {
                self.userManager.username = String(username)
            }
            
            if let email = notification.userInfo?["email"] as? NSString {
                self.userManager.emailAddress = String(email)
            }
            
            if let location = notification.userInfo?["location"] as? NSString {
                self.userManager.location = String(location)
            }
            
            if let reputationPoints = notification.userInfo?["reputation"] as? NSString {
                self.userManager.reputation = Int(reputationPoints as String)
            }
            
            if let avatarURL = notification.userInfo?["avatarURL"] as? NSString {
                self.downloadAvatarImage(String(avatarURL))
            }
        
            self.userManager.commitUserData()
            self.populateViewsFromStoredUserData()
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
                        self.saveAvatarImage(self.avatarImageView.image!)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), displayImage)
                }
            }
            
            task.resume()
        }
    }
    
    func saveAvatarImage(avatarImage: UIImage){
        fileStorageManager.storeImageFile(avatarImage, path: getAvatarImagePath())
    }
    
    func loadAvatarImageFromStorage(){
        if let loadedImage = fileStorageManager.loadImageFromPath(getAvatarImagePath()) {
            self.avatarImageView.image = loadedImage
        }
    }
    
    func getAvatarImagePath() -> String {
        let avatarImageName = "avatar.png"
        return fileStorageManager.fileInDocumentsDirectory(avatarImageName)
    }
    
    func dismissActivityIndicatorView() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.activityIndicatorView.stopAnimating()
        })
    }
    
    func userAuthenticationFailed(notification: NSNotification){
        // Dismiss activity indicator view.
        dismissActivityIndicatorView()
        
        // TODO: Handle user authentication failure.
        if let errorCode = notification.userInfo?["errorCode"] as? NSNumber {
            if errorCode == 100 {
                signOutOfOCMAccount()
            }
        }
    }
    
    func userLoginCompleted(notification: NSNotification) {
        dismissActivityIndicatorView()
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
    
    func clearAuthenticationCredentials(){
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "ocmUsername")
        defaults.setObject(nil, forKey: "ocmPassword")
        
    }
    
    func launchOCMSignInViewController(){
        let vc = OCMSignInViewController()
        vc.showBackButton = false
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
