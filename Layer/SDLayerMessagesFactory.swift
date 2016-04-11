//
//  SDLayerMessagesFactory.swift
//  ShreddDemand
//
//  Created by Kabir on 05/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit
import CoreLocation

public enum SDLayerMimeType: String {
    case Text = "text/plain",
    ImagePNG = "image/png",
    ImagJPEG = "image/jpeg",
    ImageJPEGPreview = "image/jpeg+preview",
    ImageGIF = "image/gif",
    ImageGIFPreview = "image/gif+preview",
    ImageSize = "application/json+imageSize",
    VideoQuickTime = "video/quicktime",
    Location = "location/coordinate",
    Date = "text/date",
    VideoMP4 = "video/mp4",
    DefaultThumbnailSize = "512px",
    DefaultGIFThumbnailSize = "64px"
}

class SDLayerMessagesFactory: SDLayerBaseSerivce {

    
    enum CreationErorType: ErrorType {
        case UnableToCreateMessage
    }
    
    /**
    new instance of LYRMessagePart
    
    - Parameter text: String
    
    - Throws: UnableToCreateMessage
    
    - Returns: new instance of LYRMessagePart
    */
    func createTextMessagePart(text: String) throws -> LYRMessagePart {
        guard let data = text.dataUsingEncoding(NSUTF8StringEncoding) else {
            throw CreationErorType.UnableToCreateMessage
        }
        
        return LYRMessagePart(MIMEType: SDLayerMimeType.Text.rawValue, data: data)
    }
    
    
    /**
    new instance of LYRMessagePart
    
    - Parameter image: UImage
    
    - Throws: UnableToCreateMessage
    
    - Returns: new instance of LYRMessagePart
    */
    func createMediaImageMessagePart(image: UIImage) throws -> LYRMessagePart {
        guard let data = UIImagePNGRepresentation(image) else {
            throw CreationErorType.UnableToCreateMessage
        }
        
        return LYRMessagePart(MIMEType: SDLayerMimeType.ImagePNG.rawValue, data: data)
    }
    
    
    /**
     new instance of LYRMessagePart
     
     - Parameter location: CLLocationCoordinate2D
     - Parameter userInfo: Dictionary [String: AnyObject]
     
     - Throws: UnableToCreateMessage
     
     - Returns: new instance of LYRMessagePart
     */
    func createLocationMessage(location: CLLocationCoordinate2D, userInfo: [String: AnyObject]?)  throws -> LYRMessagePart {
        //serialize the response
        var locationInfo: [String: AnyObject] = ["lat": location.latitude, "lon": location.longitude]
        
        if let info = userInfo {
            locationInfo["userInfo"] = info
        }
       
        do {
            
            let data = try NSJSONSerialization.dataWithJSONObject(locationInfo, options:NSJSONWritingOptions.PrettyPrinted)
           return LYRMessagePart(MIMEType: SDLayerMimeType.Location.rawValue, data: data)
        }
        catch _ as NSError {
            throw CreationErorType.UnableToCreateMessage
        }
        
    }
}