//
//  SDLayerMessengerService.swift
//  ShreddDemand
//
//  Created by Kabir on 04/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit

class SDLayerMessengerService {

    private var appId: NSURL!
    private var providerId: String!
    private var authenticationKey: String!
    private var layerClient: LYRClient!
    private var authenticator: SDLayerMessengerAuthenticator!
 
    typealias SDLMSCompletionBlock = (error: NSError?) -> Void
    
    /**
    Configure layer messenger
    
    - Parameter appId: Layer app id
    - Parameter providerId: Provided by layer
    - Parameter authenticationKey: Provided by layer
    
    - Throws: nil
    
    - Returns: nil
    */
    
    func configure(appId: String, providerId: String, authenticationKey: String) {
        self.appId = NSURL(string: appId)
        self.providerId = providerId
        self.authenticationKey = authenticationKey
        if  self.layerClient == nil {
            self.layerClient = LYRClient(appID: self.appId)
        }
        self.authenticator = SDLayerMessengerAuthenticator(layerClient: self.layerClient, providerId: self.providerId, authenticationKey: self.authenticationKey)

    }
    
    /**
    Instance of layer messenger
    
    - Parameter nil
    
    - Throws: nil
    
    - Returns: Instance of layer client
    */
    func getLayerClient() -> LYRClient! {
        return self.layerClient
    }
    
    // MARK: Authentication.
    
    /**
    Authenticate user to layer.
    
    - Parameter userId: Unique identifier (e.g email, userId, phone number)
    - Parameter complition: block restuns error
    - Throws: nil
    
    - Returns: nil
    */
    func authenticate(userId: String, complition: SDLMSCompletionBlock)  {
        self.authenticator.authenticate(userId, completion: complition)
    }
    
    /**
    Deauthenticate user to layer.
    
    - Parameter complition: block restuns error
    - Throws: nil
    
    - Returns: nil
    */
    func deauthenticate(complition: SDLMSCompletionBlock) {
        self.authenticator.deauthenticate(complition)
        if self.layerClient.isConnected {
            self.layerClient.disconnect()
        }
    }
    
    // MARK: Conversation
    
    /**
    new instance of SDLayerMessengerCommunicator
    - Parameter participants: Distinct paticipants in conversation
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerCommunicator
    */
     func getCommunictor(participants: [String]) -> SDLayerMessengerCommunicator {
        return SDLayerMessengerCommunicator(layerClient: self.layerClient, participants: participants)
    }
    
    /**
    new instance of SDLayerMessengerCommunicator

    - Parameter conversation: If convesation not exisit
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerCommunicator
    */
    func getCommunictor(conversation: LYRConversation) -> SDLayerMessengerCommunicator {
        return SDLayerMessengerCommunicator(layerClient: self.layerClient, conversation: conversation)
    }
    
    func getAllExistingConversation() -> [LYRConversation]? {
        let query: LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        
        query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.IsIn, value: self.layerClient.authenticatedUser?.userID)
        query.sortDescriptors = [NSSortDescriptor(key: "lastMessage.receivedAt", ascending: false)]
        do {
            return try self.layerClient.executeQuery(query).array as? [LYRConversation]
        } catch {
            // This should never happen?
            return nil
        }
    }
    
    func getConversation(identifier: NSURL) -> LYRConversation? {
        let query: LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        var conversation: LYRConversation?
        query.predicate = LYRPredicate(property: "identifier", predicateOperator: LYRPredicateOperator.IsEqualTo, value:identifier)
        do {
            if let conversations = try self.layerClient.executeQuery(query).array as? [LYRConversation] {
                conversation = conversations.count > 0 ? conversations[0] : nil
            }
            return conversation
        } catch {
            return conversation
        }
    }
    
    
    func getCountOfConversationsWithUnreadMessages() -> Int {
        let query: LYRQuery = LYRQuery(queryableClass: LYRMessage.self)
        query.predicate = LYRPredicate(property: "isUnread", predicateOperator: LYRPredicateOperator.IsEqualTo, value:true)
        var error: NSError?
        let count = Int(self.layerClient.countForQuery(query, error: &error))
        return error == nil ? count : 0
    }
    
    func synchronizeWithRemoteNotification(userInfo: [NSObject : AnyObject], completion: (LYRConversation?, LYRMessage?, NSError?) -> Void) -> Bool {
        return self.layerClient.synchronizeWithRemoteNotification(userInfo, completion: completion)
    }
    
    func getQueryContorller() -> LYRQueryController? {
        let layerClient = self.getLayerClient()
        let query: LYRQuery = LYRQuery(queryableClass: LYRConversation.self)
        query.predicate = LYRPredicate(property: "participants", predicateOperator: LYRPredicateOperator.IsIn, value: layerClient.authenticatedUser?.userID)
        query.sortDescriptors = [NSSortDescriptor(key: "lastMessage.receivedAt", ascending: false)]
        do {
            return try layerClient.queryControllerWithQuery(query)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return nil
    }
}