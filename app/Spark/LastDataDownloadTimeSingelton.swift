//
//  LastDataDownloadTimeSingelton.swift
//  SparkMap
//
//  Created by Edvard Holst on 01/07/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import Foundation

open class LastDataDownloadTimeSingelton {
    
    var time = UInt64(floor(Date().timeIntervalSince1970)-2)
    static let lastDataDownload : LastDataDownloadTimeSingelton = LastDataDownloadTimeSingelton()
    
    fileprivate init() {}
    
}
