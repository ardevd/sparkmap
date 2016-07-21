//
//  OCMSignInViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class OCMSignInViewController: UIViewController {
    
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var responseMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
    
    func successfulSigninOccurred(notification: NSNotification){
        // Store username and password in default preferences.
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(usernameField.text, forKey: "ocmUsername")
        defaults.setObject(passwordField.text, forKey: "ocmPassword")

    }
    
}
