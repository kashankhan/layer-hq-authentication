//
//  SDLayerMessengerAuthenticator.swift
//  ShreddDemand
//
//  Created by Kabir on 04/11/2015.
//  Copyright © 2015 Folio3. All rights reserved.
//

import Foundation
import LayerKit

class SDLayerMessengerAuthenticator: SDLayerBaseSerivce {

    private let providerId: String!
    private let authenticationKey: String!
    private var userId: String!
    
    typealias SDLMAuthenticationCompletionBlock = (error: NSError?) -> Void
    private typealias SDLMIdentityTokenCompletionBlock  = (String?, NSError?) -> Void
    
    /**
    new instance of SDLayerMessengerAuthenticator
    
    - Parameter layerClient: Layer client
    - Parameter providerId: Provided by layer
    - Parameter authenticationKey: Provided by layer
    
    - Throws: nil
    
    - Returns: new instance of SDLayerMessengerAuthenticator
    */
    required init(layerClient: LYRClient, providerId: String, authenticationKey: String!) {
        self.providerId = providerId
        self.authenticationKey = authenticationKey
        super.init(layerClient: layerClient)

    }

    // MARK: - Public Interface
    
    /**
    Authenticate user to layer.
    
    - Parameter userId: Unique identifier (e.g email, userId, phone number)
    - Parameter complition: block restuns error
  
    - Throws: nil
    
    - Returns: nil
    */
    func authenticate(userId: String, completion: SDLMAuthenticationCompletionBlock) {
        self.userId = userId
        if !self.layerClient.isConnected && !self.layerClient.isConnecting {
            layerClient.connectWithCompletion { success, error in
                if let error = error {
                    completion(error: error)
                } else {
                    // Once connected, authenticate user.
                    // Check Authenticate step for authenticateLayerWithUserID source
                    guard let userId = self.userId else {
                        return completion(error: nil)
                    }
                    self.authenticateLayerWithUserID(userId) { error in
                        if let error = error {
                            completion(error: error)
                            print("Failed Authenticating Layer Client with error: \(error.localizedDescription)")
                        } else if success {
                            completion(error: nil)
                        }
                    }
                }
            }
        }
        else {
            self.deauthenticate({ (error) -> Void in
                self.authenticate(self.userId, completion: completion)
            })
        }
    }
    
    /**
    Deauthenticate user to layer.
    
    - Parameter complition: block restuns error
    - Throws: nil
    
    - Returns: nil
    */
    func deauthenticate(complition: SDLMAuthenticationCompletionBlock) {
        self.layerClient.deauthenticateWithCompletion { (sucess, error) -> Void in
            complition(error: error)
        }
    }
    
    // MARK: - Private Methods
    
    private func authenticateLayerWithUserID(userID: String, authenticationCompletion: SDLMAuthenticationCompletionBlock) {
        // Check to see if the layerClient is already authenticated.
        if let authenticatedUserID = layerClient.authenticatedUser?.userID {
            // If the layerClient is authenticated with the requested userID, complete the authentication process.
            if authenticatedUserID == userID {
                print("Layer Authenticated as User \(authenticatedUserID)")
                authenticationCompletion(error: nil)
            } else {
                // If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
                layerClient.deauthenticateWithCompletion { success, error in
                    if success {
                        self.authenticationTokenWithUserId(userID, authenticationCompletion: authenticationCompletion)
                    } else if let error = error {
                        authenticationCompletion(error: error)
                    } else {
                        assertionFailure("Must have an error when success = false")
                    }
                }
            }
        } else {
            // If the layerClient isn't already authenticated, then authenticate.
            authenticationTokenWithUserId(userID, authenticationCompletion: authenticationCompletion)
        }
    }
    
    private func authenticationTokenWithUserId(userID: String, authenticationCompletion: SDLMAuthenticationCompletionBlock) {
        // 1. Request an authentication Nonce from Layer
        layerClient.requestAuthenticationNonceWithCompletion { nonce, error in
            if nonce == nil {
                authenticationCompletion(error: error)
                return
            }
            
            // 2. Acquire identity Token from Layer Identity Service
            self.requestIdentityTokenForUserID(userID, appID: self.layerClient.appID.absoluteString, nonce: nonce!) { identityToken, error in
                if identityToken == nil {
                    authenticationCompletion(error: error)
                    return
                }
                
                // 3. Submit identity token to Layer for validation
                self.layerClient.authenticateWithIdentityToken(identityToken!) { authenticatedUserID, error in
                    if authenticatedUserID != nil {
                        print("Layer Authenticated as User: \(authenticatedUserID)")
                        authenticationCompletion(error: nil)
                    } else {
                        authenticationCompletion(error: error)
                    }
                }
            }
        }
    }
    
    private func requestIdentityTokenForUserID(userID: String, appID: String, nonce: String, tokenCompletion: SDLMIdentityTokenCompletionBlock) {
        let identityTokenURL = NSURL(string: "https://layer-identity-provider.herokuapp.com/identity_tokens")!
        let request = NSMutableURLRequest(URL: identityTokenURL)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = ["app_id": appID, "user_id": userID, "nonce": nonce]
        let requestBody = try? NSJSONSerialization.dataWithJSONObject(parameters, options: [])
        request.HTTPBody = requestBody
        
        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        
        let dataTask = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                tokenCompletion(nil, error)
                return
            }
            
            // Deserialize the response
            let responseObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary

            if responseObject["error"] == nil {
                let identityToken = responseObject["identity_token"] as! String
                tokenCompletion(identityToken, nil)
            } else {
                let domain = "layer-identity-provider.herokuapp.com"
                let code = responseObject["status"]!.integerValue
                let userInfo = [
                    NSLocalizedDescriptionKey: "Layer Identity Provider Returned an Error.",
                    NSLocalizedRecoverySuggestionErrorKey: "There may be a problem with your APPID."
                ]
                
                let error = NSError(domain: domain, code: code, userInfo: userInfo)
                tokenCompletion(nil, error)
            }
        }
        
        dataTask.resume()
    }

    
//    private func requestIdentityTokenForUserID(userID: String, appID: String, nonce: String, tokenCompletion: SDLMIdentityTokenCompletionBlock) {
//        let baseUri =  SDBalConstants.appBuildConfig.getBaseUri()
//        let identityTokenURL = NSURL(string: "\(baseUri)/layer/token")!
//        let request = NSMutableURLRequest(URL: identityTokenURL)
//        request.HTTPMethod = "POST"
//        request.setValue("application/vnd.shredapi.v1+json", forHTTPHeaderField: "Accept")
//       
//        let parameters = ["user_id": userID, "nonce": nonce]
//        let requestBody = try? NSJSONSerialization.dataWithJSONObject(parameters, options: [])
//        request.HTTPBody = requestBody
//        
//        let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
//        let session = NSURLSession(configuration: sessionConfiguration)
//        
//        print(identityTokenURL)
//        
//        let dataTask = session.dataTaskWithRequest(request) { data, response, error in
//            if error != nil {
//                tokenCompletion(nil, error)
//                return
//            }
//            // Deserialize the response
//            let responseObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
//            if responseObject["error"] == nil {
//                let identityToken = responseObject["identityToken"] as! String
//                tokenCompletion(identityToken, nil)
//            } else {
//                let domain = "layer-identity-provider.herokuapp.com"
//                let code = responseObject["status"]!.integerValue
//                let userInfo = [
//                    NSLocalizedDescriptionKey: "Layer Identity Provider Returned an Error.",
//                    NSLocalizedRecoverySuggestionErrorKey: "There may be a problem with your APPID."
//                ]
//                
//                let error = NSError(domain: domain, code: code, userInfo: userInfo)
//                tokenCompletion(nil, error)
//            }
//        }
//        
//        dataTask.resume()
//    }

}