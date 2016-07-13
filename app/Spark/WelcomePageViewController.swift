//
//  WelcomePageViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 13/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class WelcomePageViewController: UIPageViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 49/255, green: 48/225, blue: 54/225, alpha: 1.0)
        dataSource = self
        setViewControllers([getStepZero()], direction: .Forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getStepZero() -> WelcomeZeroViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("WelcomeZero") as! WelcomeZeroViewController
    }
    
    func getStepOne() -> WelcomeOneViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("WelcomeOne") as! WelcomeOneViewController
    }
    
    func getStepTwo() -> WelcomeTwoViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("WelcomeTwo") as! WelcomeTwoViewController
    }
    
    func getStepThree() -> WelcomeThreeViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("WelcomeThree") as! WelcomeThreeViewController
    }
    
    //Changing Status Bar
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        //LightContent
        return UIStatusBarStyle.LightContent
        
        //Default
        //return UIStatusBarStyle.Default
    }
}

extension WelcomePageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(WelcomeThreeViewController) {
            return getStepTwo()
        } else if viewController.isKindOfClass(WelcomeTwoViewController) {
            return getStepOne()
        } else if viewController.isKindOfClass(WelcomeOneViewController) {
            return getStepZero()

        } else {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(WelcomeZeroViewController) {
            return getStepOne()
        } else if viewController.isKindOfClass(WelcomeOneViewController) {
            return getStepTwo()
        } else if viewController.isKindOfClass(WelcomeTwoViewController) {
            return getStepThree()
        } else {
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 4
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
}