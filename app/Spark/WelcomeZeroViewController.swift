//
//  WelcomeZeroViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 13/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class WelcomeZeroViewController: UIViewController {
    
    @IBOutlet var cardView: UIView!
    @IBOutlet var cardTitle: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        manipulateCardView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        animateTitle()
    }
    

    func manipulateCardView(){
        // Adjust the card view. Make the edges rounded.
        self.cardView.layer.masksToBounds = false
        self.cardView.layer.cornerRadius = 15
        self.cardView.clipsToBounds = true
    }
    
    func animateTitle(){
        // Fade in the card title
        UIView.animateWithDuration(2.0, animations: {
                self.cardTitle.alpha = 1.0
        })
    }

}
