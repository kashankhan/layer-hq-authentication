//
//  SDLayerMessengerBaseService.swift
//  ShreddDemand
//
//  Created by Kabir on 05/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit

class SDLayerBaseSerivce {

    var layerClient: LYRClient!
    
    /**
    new instance of SDLayerMessengerService
    
    - Parameter appId: Layer app id
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerService
    */
    
    init(layerClient: LYRClient) {
        self.layerClient = layerClient
    }
}

