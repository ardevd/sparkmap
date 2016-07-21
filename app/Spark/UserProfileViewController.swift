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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manipulateViews()
        if !doWeHaveCredentails(){
            
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
    
    func manipulateViews(){
        // Make the reputation and avatar views circular.
        self.avatarImageView.layer.borderWidth = 2.0
        self.avatarImageView.layer.masksToBounds = false
        self.avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2
        self.avatarImageView.clipsToBounds = true
    }

}
