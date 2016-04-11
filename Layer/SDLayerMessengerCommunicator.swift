//
//  SDLayerMessengerCommunicator.swift
//  ShreddDemand
//
//  Created by Kabir on 04/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit
import CoreLocation

class SDLayerMessengerCommunicator: SDLayerBaseSerivce {
    
    private let messageFactory: SDLayerMessagesFactory!
    private let messageService: SDLayerMessengerMessagesSerivce!
    
    var conversation: LYRConversation!
    
    enum ConversationEror: ErrorType {
        case
        UnableToAddParticipants,
        UnableToRemoveParticipants,
        UnableToSendMessage,
        UnableToMarkMesssagesAsRead
    }
    
    /**
    new instance of SDLayerMessengerService
    
    - Parameter appId: Layer app id
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerService
    */
    
    override init(layerClient: LYRClient) {
        self.messageFactory = SDLayerMessagesFactory(layerClient: layerClient)
        self.messageService = SDLayerMessengerMessagesSerivce(layerClient: layerClient)
        super.init(layerClient: layerClient)
    }
    
    /**
    new instance of SDLayerMessengerCommunicator
    
    - Parameter appId: Layer app id
    - Parameter participants: Distinct paticipants in conversation
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerCommunicator
    */
    convenience init(layerClient: LYRClient, participants: [String]) {
        self.init(layerClient: layerClient)
        self.initializeConversation(participants)
    }
    
    /**
    new instance of SDLayerMessengerCommunicator
    
    - Parameter appId: Layer app id
    - Parameter conversation: If convesation not exisit
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerCommunicator
    */
    convenience init(layerClient: LYRClient, conversation: LYRConversation) {
        self.init(layerClient: layerClient)
        self.conversation = conversation
    }
    
    /**
    new instance of distinct Layer conversation, where key is participants,
    If there is only one partcipant then the existing conversation will recive
    otherwise new conversation will be created. However in the case of muliple
    participant it will always create new conversation.
    
    - Parameter participants: Sets of user identifiers
    
    - Throws: nil
    
    - Returns: new instance of LYRConversation
    */
    private func initializeConversation(participants: [String]) {
        let minParticipants = 2
        print(self.layerClient.authenticatedUser?.userID)
 
        let conversationFactory = SDLayerConversationsFactory(layerClient: layerClient)
        let distinct = minParticipants == participants.count ? true : false
        self.conversation = getConversation(participants)
        if self.conversation == nil {
            self.conversation =  conversationFactory.createConversation(participants, distinctByParticipants: distinct)
        }
    }
    
    private func getConversation(participants: [String]) -> LYRConversation? {
        let layerClient = self.layerClient
        let query: LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.IsEqualTo, value: participants)
        query.limit = 1
        
        do {
            return try layerClient.executeQuery(query).firstObject as? LYRConversation
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return nil
    }
    /**
    This method will update chat meta data, like image, title, theme
    - Parameter meta: including participants objet, theme
    - Parameter imageUri: conversation image uri 
    
    - Throws: nil
    
    - Returns: nil
    */
    func updateConversationMeta(meta: [String: String]) {
//        NSDictionary *metadata = @{@"title" : @"My Conversation",
//            @"theme" : @{
//                @"background_color" : @"333333",
//                @"text_color" : @"F8F8EC",
//                @"link_color" : @"21AAE1"},
//            @"created_at" : @"Dec, 01, 2014",
//            @"img_url" : @"/path/to/img/url"}
        conversation.setValuesForMetadataKeyPathsWithDictionary(meta, merge: false)
    }
    
    /**
    // New participants will gain access to all previous messages in a conversation.
    
    - Parameter participants: Sets of user identifiers
    
    - Throws: UnableToAddParticipants
    - Return: nil
    */

    func addParticipants(participants: [String]) throws {
       
        do {
          
            try conversation.addParticipants(NSSet(objects: participants) as! Set<String>)
        }
        catch _ as NSError {
            throw ConversationEror.UnableToAddParticipants
        }
    }
    
    /**
    // New participants will gain access to all previous messages in a conversation.
    
    - Parameter participants: Sets of user identifiers
    
    - Throws: UnableToAddParticipants
    - Return: nil
    */
    
    func removeParticipants(participants: [String]) throws {
        do {
            try conversation.removeParticipants(NSSet(objects: participants) as! Set<String>)
        }
        catch _ as NSError {
            throw ConversationEror.UnableToRemoveParticipants
        }
    }
    
    // MARK: Message sending
    
    /**
    // Sends the specified message
    
    - Parameter participants: Sets of user identifiers
    
    - Throws: UnableToSendMessage
    - Return: nil
    */
    
    func sendMessage(message: String) throws -> LYRMessage {
        do {
             let layerMessage = try self.messageFactory.createTextMessagePart(message)
            return try self.sendMessage(layerMessage)
        }
        catch _ as NSError {
            throw ConversationEror.UnableToSendMessage
        }
    }
    
    /**
    // Sends the specified message
    
    - Parameter image: UImage
    - Parameter caption: String
    
    - Throws: UnableToSendMessage
    - Return: nil
    */
    
    func sendMessage(image: UIImage) throws -> LYRMessage {
        do {
            let layerMessage = try self.messageFactory.createMediaImageMessagePart(image)
           return try self.sendMessage(layerMessage)
        }
        catch _ as NSError {
            throw ConversationEror.UnableToSendMessage
        }
    }
    
    // MARK: Message sending
    
    /**
    // Sends the specified message
    
     - Parameter location: CLLocationCoordinate2D
     - Parameter userInfo: Dictionary [String: AnyObject]
    
    - Throws: UnableToSendMessage
    - Return: nil
    */
    func sendMessage(location: CLLocationCoordinate2D, userInfo: [String: AnyObject]?) throws -> LYRMessage {
        do {
            let layerMessage = try self.messageFactory.createLocationMessage(location, userInfo: userInfo)
            return try self.sendMessage(layerMessage)
        }
        catch _ as NSError {
            throw ConversationEror.UnableToSendMessage
        }
    }
    /**
    // Sends the specified message

    - Parameter messagePart: message
    
    - Throws: UnableToSendMessage
    - Return: nil
    */
    
    private func sendMessage(messagePart: LYRMessagePart) throws -> LYRMessage {
        do {
            // Creates and returns a new message object with the given conversation and array of message parts
            let configuration = LYRPushNotificationConfiguration()
            configuration.alert = self.getPushAlert(messagePart)
            configuration.sound = "chime.aiff"
            
            let pushOptions = [LYRMessageOptionsPushNotificationConfigurationKey: configuration]

            let message = try self.layerClient.newMessageWithParts([messagePart], options: pushOptions)
            
            try self.conversation.sendMessage(message)
            
            return message
            
        }
        catch _ as NSError {
            throw ConversationEror.UnableToSendMessage
        }
        catch {
            throw ConversationEror.UnableToSendMessage
        }
    }

    /**
    // Sends the specified message
    
    - Throws: UnableToMarkMesssagesAsRead
    - Return: nil
    */
    
    func markAllMessage() throws {
        do {
            try conversation.markAllMessagesAsRead()
        }
        catch _ as NSError {
            throw ConversationEror.UnableToMarkMesssagesAsRead
        }
    }
    
    // MARK: Private
    
    func getUserInfo() -> ( userId: String, name: String) {
        let userId = layerClient.authenticatedUser?.userID ?? ""
        var name = ""
        let predicate = NSPredicate(format: "SELF.email == '\(userId)'")
        if let profile = UserProfile.MR_findFirstWithPredicate(predicate) {
            name = profile.name ?? ""
        }
        
        return (userId, name)
    }
    
    func getPushAlert(messagePart: LYRMessagePart) -> String {
        let (_, name) = self.getUserInfo()
        var text = "sent you a message."
        if let type = SDLayerMimeType(rawValue: messagePart.MIMEType) {
            switch type {
                
            case .Text:
                text = String(data: messagePart.data!, encoding: NSUTF8StringEncoding) ?? text
                text = "said, \(text)"
            case .ImageGIF:
                text = "sent you a GIF.";
            case .Location:
                text = "sent you a location."
            case .VideoMP4:
                text = "sent you a video."
            default:
                break
            }

        }
        return "\(name) \(text)"
    }
}