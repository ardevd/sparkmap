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
        view.backgroundColor = .darkGrayColor()
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
}

extension WelcomePageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(WelcomeTwoViewController) {
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
        } else {
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 3
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
}