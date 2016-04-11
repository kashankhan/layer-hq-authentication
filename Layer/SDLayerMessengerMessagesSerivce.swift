//
//  SDLayerMessengerMessagesSerivce.swift
//  ShreddDemand
//
//  Created by Kabir on 06/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit

class SDLayerMessengerMessagesSerivce: SDLayerBaseSerivce {
    
    enum MessageRecipientStatus: Int {
        case Invalid, Sent, Delivered, Read
        //    LYRRecipientStatusInvalid - The message status cannot be determined.
        //    LYRRecipientStatusSent - The message has successfully reached the Layer service and is waiting to be synchronized with recipient devices.
        //    LYRRecipientStatusDelivered - The message has been successfully delivered to the recipients device.
        //    LYRRecipientStatusRead - The message has been marked as read` by a recipient's device.
    }
    
    enum MessageEror: ErrorType {
        case UnableToMarkAsRead
    }

    /**
    Message status
    
    - Parameter message: LYRMessage
    
    - Throws: nil
    
    - Returns: Message Status
    */
    func getStatus(message: LYRMessage) -> MessageRecipientStatus {
       let recipientStatuses = message.recipientStatusByUserID
        guard let status = recipientStatuses?[self.layerClient.authenticatedUser!.userID!] as? Int else {
            return .Invalid
        }
        
        return MessageRecipientStatus(rawValue: status)!
    }
    
    /**
    Message status
    
    - Parameter message: LYRMessage
    
    - Throws: UnableToMarkAsRead
    
    - Returns: Message Status
    */
    func markRead(message: LYRMessage) throws {
        do {
           try message.markAsRead()
        }
        catch _ as NSError {
            throw MessageEror.UnableToMarkAsRead
        }
    }
}