//
//  ConnectionTableViewCell.swift
//  Spark
//
//  Created by Edvard Holst on 28/01/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import UIKit

class ConnectionTableViewCell: UITableViewCell {
    
    @IBOutlet var connectionTypeLabel: UILabel?
    @IBOutlet var connectionAmpLabel: UILabel?
    @IBOutlet var connectionQuantityLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
