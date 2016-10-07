//
//  MapCenterCoordinateSingelton
//  Spark
//
//  Created by Edvard Holst on 04/02/16.
//  Copyright © 2016 Zygote Labs. All rights reserved.
//

import MapKit

open class MapCenterCoordinateSingelton {
    var coordinate = CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00)
    static let center : MapCenterCoordinateSingelton = MapCenterCoordinateSingelton()
    
    fileprivate init() {}
    
}
