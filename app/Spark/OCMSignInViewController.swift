//
//  OCMSignInViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class OCMSignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var responseMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Customize appearance
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.tabBarController?.tabBar.tintColor = UIColor(red: 221/255, green: 106/255, blue: 88/255, alpha: 1.0)
        self.tabBarController?.tabBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationItem.hidesBackButton = true
        
        // Handle the text fields user input through delegate callbacks.
        usernameField.delegate = self
        passwordField.delegate = self
        usernameField.tag = 100
        passwordField.tag = 101
        
        registerNotificationListeners()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitLoginCredentials(){
        self.responseMessageLabel.text = ""
        AuthenticationManager.getSessionToken(usernameField.text!, password: passwordField.text!)
    }
    
    func registerNotificationListeners() {
        // Register notification listeners
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OCMSignInViewController.updateResponseStatusLabel(_:)), name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OCMSignInViewController.successfulSigninOccurred(_:)), name: "OCMLoginSuccess", object: nil)
    }
    
    func updateResponseStatusLabel(notification: NSNotification){
        if let errorMessage = notification.userInfo?["errorMesssage"] as? NSString {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.responseMessageLabel.text = String(errorMessage)
            })
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard.
        let textFieldTag = textField.tag
        textField.resignFirstResponder()
        if textFieldTag == 100 {
            passwordField.becomeFirstResponder()
        } else if textFieldTag == 101 {
            submitLoginCredentials()
        }
        
        return true
    }
    
    func successfulSigninOccurred(notification: NSNotification){
        // Store username and password in default preferences.
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(usernameField.text, forKey: "ocmUsername")
        defaults.setObject(passwordField.text, forKey: "ocmPassword")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginFailed", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "OCMLoginSuccess", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("OCMUserLoginDone", object: nil)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
}
