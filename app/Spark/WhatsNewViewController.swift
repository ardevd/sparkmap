//
//  WhatsNewViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 13/06/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class WhatsNewViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let whatsNewTitleString = NSLocalizedString("Whats New", comment: "Whats New View Title")
        self.title = whatsNewTitleString
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
