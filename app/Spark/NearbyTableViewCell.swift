//
//  NearbyTableViewCell.swift
//  Spark
//
//  Created by Edvard Holst on 03/11/15.
//  Copyright © 2015 Zygote Labs. All rights reserved.
//

import UIKit

class NearbyTableViewCell: UITableViewCell {
    
    @IBOutlet var cellTitle: UILabel?
    @IBOutlet var cellDescription: UILabel?
    @IBOutlet var cellDistance: UILabel?
    @IBOutlet var cellAnnotationImageView: UIImageView?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
