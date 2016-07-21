//
//  UserProfileViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 21/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !doWeHaveCredentails(){
            launchOCMSignInViewController()
        }
    }
    
    func doWeHaveCredentails() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let username = defaults.stringForKey("ocm_username")
        let password = defaults.stringForKey("ocm_password")
        if username == nil || password == nil {
            return false
        }
        
        return true
    }
    
    func launchOCMSignInViewController(){
        let vc = OCMSignInViewController()
        showViewController(vc, sender: nil)
    }

}
