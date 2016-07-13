//
//  WelcomeThreeViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 13/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class WelcomeThreeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneButtonTapped(sender: AnyObject) {
        // Notify that welcome module is complete
        NSNotificationCenter.defaultCenter().postNotificationName("WelcomeModuleDone", object: nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
   }
