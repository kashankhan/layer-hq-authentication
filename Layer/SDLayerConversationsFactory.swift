//
//  SDLayerConversationsFactory.swift
//  ShreddDemand
//
//  Created by Kabir on 06/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit

class SDLayerConversationsFactory: SDLayerBaseSerivce {
    
    /**
    new instance of distinct Layer conversation, where key is participants
    
    - Parameter participants: Sets of user identifiers
    - Parameter distinctByParticipants: Bool to return distinc participants
     
    - Returns: new instance of LYRConversation
    */
    func createConversation(participants: [String], distinctByParticipants: Bool) -> LYRConversation? {
        var conversation: LYRConversation?
        let options = [LYRConversationOptionsDistinctByParticipantsKey: distinctByParticipants]
        do {
            try conversation = self.layerClient.newConversationWithParticipants(Set(participants), options: options)
        }
        catch let error as NSError {
            conversation = error.userInfo[LYRExistingDistinctConversationKey] as? LYRConversation
        }
        
        return conversation
    }
}