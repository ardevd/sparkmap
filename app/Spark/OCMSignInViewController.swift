//
//  OCMSignInViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit
import SafariServices

class OCMSignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var responseMessageLabel: UILabel!
    @IBOutlet var submitButton: UIButton!
    
    var showBackButton: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        self.submitButton.layer.cornerRadius = 5.0
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        
        if (showBackButton == false) {
            self.navigationItem.hidesBackButton = true
        }
        
        // Handle the text fields user input through delegate callbacks.
        usernameField.delegate = self
        passwordField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(OCMSignInViewController.tapOutsideTextView(_:)))
        view.addGestureRecognizer(tapGesture)

        
        registerNotificationListeners()
    }
    
    override func viewDidLayoutSubviews() {
        let userIsAuthenticated = AuthenticationManager.doWeHaveCredentails()
        if userIsAuthenticated {
            popThisViewController()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitLoginCredentials(){
        self.responseMessageLabel.text = ""
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        let signingInSpinnerString = NSLocalizedString("Signing in...", comment: "Signing in spinner text")
        SwiftSpinner.show(signingInSpinnerString)
        AuthenticationManager.getSessionToken(usernameField.text!, password: passwordField.text!)
    }
    
    @IBAction func showOCMSignupPage(){
        let safariViewController = SFSafariViewController(url: URL(string: "http://openchargemap.org/site/loginprovider/register")!)
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    func tapOutsideTextView(_ gesture: UITapGestureRecognizer) {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    func registerNotificationListeners() {
        // Register notification listeners
        NotificationCenter.default.addObserver(self, selector: #selector(OCMSignInViewController.updateResponseStatusLabel(_:)), name: NSNotification.Name(rawValue: "OCMLoginFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OCMSignInViewController.successfulSigninOccurred(_:)), name: NSNotification.Name(rawValue: "OCMLoginSuccess"), object: nil)
    }
    
    func updateResponseStatusLabel(_ notification: Notification){
        SwiftSpinner.hide()
        if let errorMessage = (notification as NSNotification).userInfo?["errorMesssage"] as? NSString {
            DispatchQueue.main.async(execute: { () -> Void in
                self.responseMessageLabel.text = String(errorMessage)
            })
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide and/or toggle the keyboard.
        textField.resignFirstResponder()
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            submitLoginCredentials()
        }
        
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func popThisViewController(){
        self.navigationController?.popViewController(animated: true)
    }
    
    func successfulSigninOccurred(_ notification: Notification){
        // Store username and password in default preferences.
        let defaults = UserDefaults.standard
        defaults.set(usernameField.text, forKey: "ocmUsername")
        defaults.set(passwordField.text, forKey: "ocmPassword")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "OCMUserLoginDone"), object: nil)
        DispatchQueue.main.async(execute: { () -> Void in
            SwiftSpinner.hide()
            self.popThisViewController()
        })
    }
}
