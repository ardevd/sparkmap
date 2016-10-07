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
        view.backgroundColor = UIColor(red: 49/255, green: 42/225, blue: 48/225, alpha: 1.0)
        dataSource = self
        setViewControllers([getStepZero()], direction: .forward, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getStepZero() -> WelcomeZeroViewController {
        return storyboard!.instantiateViewController(withIdentifier: "WelcomeZero") as! WelcomeZeroViewController
    }
    
    func getStepOne() -> WelcomeOneViewController {
        return storyboard!.instantiateViewController(withIdentifier: "WelcomeOne") as! WelcomeOneViewController
    }
    
    func getStepTwo() -> WelcomeTwoViewController {
        return storyboard!.instantiateViewController(withIdentifier: "WelcomeTwo") as! WelcomeTwoViewController
    }
    
    func getStepThree() -> WelcomeThreeViewController {
        return storyboard!.instantiateViewController(withIdentifier: "WelcomeThree") as! WelcomeThreeViewController
    }
    
    func getStepFour() -> WelcomeFourViewController {
        return storyboard!.instantiateViewController(withIdentifier: "WelcomeFour") as! WelcomeFourViewController
    }

    
    //Changing Status Bar
    override var preferredStatusBarStyle : UIStatusBarStyle {
        
        //LightContent
        return UIStatusBarStyle.lightContent
        
        //Default
        //return UIStatusBarStyle.Default
    }
}

extension WelcomePageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKind(of: WelcomeFourViewController.self) {
            return getStepThree()
        } else if viewController.isKind(of: WelcomeThreeViewController.self) {
            return getStepTwo()
        } else if viewController.isKind(of: WelcomeTwoViewController.self) {
            return getStepOne()
        } else if viewController.isKind(of: WelcomeOneViewController.self) {
            return getStepZero()
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController.isKind(of: WelcomeZeroViewController.self) {
            return getStepOne()
        } else if viewController.isKind(of: WelcomeOneViewController.self) {
            return getStepTwo()
        } else if viewController.isKind(of: WelcomeTwoViewController.self) {
            return getStepThree()
        } else if viewController.isKind(of: WelcomeThreeViewController.self) {
            return getStepFour()
        } else {
            return nil
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 5
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
}
