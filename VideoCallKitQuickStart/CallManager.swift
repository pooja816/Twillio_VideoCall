//
//  CallManager.swift
//  VideoCallKitQuickStart
//
//  Created by Pooja Gupta on 10/05/18.
//  Copyright © 2018 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVideo
import CallKit

class CallManager: NSObject {

     var room: TVIRoom?
    var remoteParticipant: TVIRemoteParticipant?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    
    
    // CallKit components
    let callKitProvider: CXProvider
    let callKitCallController: CXCallController
    var callKitCompletionHandler: ((Bool)->Swift.Void?)? = nil
    
    
    var isCallInProgress : Bool = false;
    
    
    @objc static let shared : CallManager = CallManager()
    
    
    override init() {
        
        let configuration = CXProviderConfiguration(localizedName: "CallKit Quickstart")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportsVideo = true
        if let callKitIcon = UIImage(named: "iconMask80") {
            configuration.iconTemplateImageData = UIImagePNGRepresentation(callKitIcon)
        }
        
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
    }
    
    func pushViewController(from navController : UINavigationController)  {
        
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController2");
        navController.pushViewController(vc, animated: true);
    }
    
}
