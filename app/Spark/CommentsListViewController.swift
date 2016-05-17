//
//  CommentsListViewController.swift
//  SparkMap
//
//  Created by Edvard Holst on 16/05/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class CommentsListViewController: UIViewController, UITableViewDelegate, UINavigationControllerDelegate {
    
    // Outlets
    @IBOutlet var chargerTitleLabel: UILabel!
    @IBOutlet var chargerCommentsTableView: UITableView!
    @IBOutlet var chargerCommentTextView: UITextField!
    @IBOutlet var chargerCommentSubmitButton: UIButton!
    
    var charger: ChargerPrimary?
    var comments: [Comment] = [Comment]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure TableView
        let nib = UINib(nibName: "CommentTableViewCell", bundle: nil)
        chargerCommentsTableView.registerNib(nib, forCellReuseIdentifier: "net.zygotelabs.commentcell")
        chargerCommentsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        chargerTitleLabel.text = charger?.chargerTitle
        generateCommentButton()
    
    }
    
    func generateCommentButton() {
        var navigationButtonItems = [UIBarButtonItem]()
        // Button that lets user submit a comment
        let commentButtonTitle = NSLocalizedString("Write Comment", comment: "Write Comment")
        let commentButtonItem = UIBarButtonItem(title: commentButtonTitle, style: .Plain, target: self, action: #selector(CommentsListViewController.commentButtonTapped))
        
        navigationButtonItems.append(commentButtonItem)
        self.navigationItem.setRightBarButtonItems(navigationButtonItems, animated: true)

    }
    
    func commentButtonTapped(){
        // Direct user to OCM comment page
        if let chargerId = self.charger?.chargerId{
            UIApplication.sharedApplication().openURL(NSURL(string: "http://openchargemap.org/site/poi/details/\(chargerId)#tab-comments")!)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("net.zygotelabs.commentcell", forIndexPath: indexPath) as! CommentTableViewCell
        
        cell.commentTextLabel?.text = (comments[indexPath.row] as Comment).comment
        cell.commentRatingLabel?.text = String((comments[indexPath.row] as Comment).rating)
        return cell
    }
    
    deinit {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
