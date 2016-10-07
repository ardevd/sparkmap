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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        
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
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerNotificationListeners(){
        // Register notification listeners
        NotificationCenter.default.addObserver(self, selector: #selector(UserProfileViewController.userAuthenticationFailed(_:)), name: NSNotification.Name(rawValue: "OCMLoginFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserProfileViewController.successfulSigninOccurred(_:)), name: NSNotification.Name(rawValue: "OCMLoginSuccess"), object: nil)
    }
    
    func authenticateUser(){
        AuthenticationManager.authenticateUserWithStoredCredentials()
        activityIndicatorView.startAnimating()
    }
    
    func populateViewsFromStoredUserData(){
        DispatchQueue.main.async(execute: { () -> Void in
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
    
    func successfulSigninOccurred(_ notification: Notification){
        // Dismiss activity indicator. Does it need to be done on the main queue?
        dismissActivityIndicatorView()
        
        // User is authenticated, handle the new user data
            if let username = (notification as NSNotification).userInfo?["username"] as? NSString {
                self.userManager.username = String(username)
            }
            
            if let email = (notification as NSNotification).userInfo?["email"] as? NSString {
                self.userManager.emailAddress = String(email)
            }
            
            if let location = (notification as NSNotification).userInfo?["location"] as? NSString {
                self.userManager.location = String(location)
            }
            
            if let reputationPoints = (notification as NSNotification).userInfo?["reputation"] as? NSString {
                self.userManager.reputation = Int(reputationPoints as String)
            }
            
            if let avatarURL = (notification as NSNotification).userInfo?["avatarURL"] as? NSString {
                self.downloadAvatarImage(String(avatarURL))
            }
        
            self.userManager.commitUserData()
            self.populateViewsFromStoredUserData()
    }
    
    func downloadAvatarImage(_ imageUrl: String){
        if let url = URL(string: imageUrl) {
            let request: URLRequest = URLRequest(url: url)
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: {
                (data, response, error) -> Void in
                
                if (error == nil && data != nil)
                {
                    func displayImage()
                    {
                        self.avatarImageView.image = UIImage(data: data!)
                        self.avatarImageView.alpha = 1.0
                        self.saveAvatarImage(self.avatarImageView.image!)
                    }
                    
                    DispatchQueue.main.async(execute: displayImage)
                }
            })
            
            task.resume()
        }
    }
    
    func saveAvatarImage(_ avatarImage: UIImage){
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
        DispatchQueue.main.async(execute: { () -> Void in
        self.activityIndicatorView.stopAnimating()
        })
    }
    
    func userAuthenticationFailed(_ notification: Notification){
        // Dismiss activity indicator view.
        dismissActivityIndicatorView()
        
        // TODO: Handle user authentication failure.
        if let errorCode = (notification as NSNotification).userInfo?["errorCode"] as? NSNumber {
            if errorCode == 100 {
                signOutOfOCMAccount()
            }
        }
    }
    
    func userLoginCompleted(_ notification: Notification) {
        dismissActivityIndicatorView()
        registerNotificationListeners()
        authenticateUser()
    }
    
    func generateSignoutButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let signoutButtonTitle = NSLocalizedString("Sign Out", comment: "Sign out of OCM")
        let signoutButtonItem = UIBarButtonItem(title: signoutButtonTitle, style: .plain, target: self, action: #selector(UserProfileViewController.signOutOfOCMAccount))
        
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "OCMLoginFailed"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "OCMLoginSuccess"), object: nil)
    }
    
    func registerSignupNotificationListener(){
        NotificationCenter.default.addObserver(self, selector: #selector(UserProfileViewController.userLoginCompleted(_:)), name: NSNotification.Name(rawValue: "OCMUserLoginDone"), object: nil)
    }
    
    func clearAuthenticationCredentials(){
        let defaults = UserDefaults.standard
        defaults.set(nil, forKey: "ocmUsername")
        defaults.set(nil, forKey: "ocmPassword")
        
    }
    
    func launchOCMSignInViewController(){
        let vc = OCMSignInViewController()
        vc.showBackButton = false
        show(vc, sender: nil)
    }
    
    func manipulateViews(){
        // Make the reputation and avatar views circular.
        self.avatarImageView.layer.borderWidth = 2.0
        self.avatarImageView.layer.masksToBounds = false
        self.avatarImageView.layer.borderColor = UIColor.white.cgColor
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2
        self.avatarImageView.clipsToBounds = true
    }
    
}
