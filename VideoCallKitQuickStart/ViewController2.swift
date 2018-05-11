//
//  ViewController.swift
//  VideoCallKitQuickStart
//
//  Copyright © 2016-2017 Twilio, Inc. All rights reserved.
//

import UIKit

import TwilioVideo
import CallKit

class ViewController2: UIViewController {

    // MARK: View Controller Members
    
    // Configure access token manually for testing, if desired! Create one manually in the console
    // at https://www.twilio.com/console/video/runtime/testing-tools
    var accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzA2YjJkNjU1ZmEzMmI2NGZkMDY2MDAzMmEwMzFmYzY2LTE1MjU5NTYxNjIiLCJpc3MiOiJTSzA2YjJkNjU1ZmEzMmI2NGZkMDY2MDAzMmEwMzFmYzY2Iiwic3ViIjoiQUNiYTBjZWQ4YjFjNTNhZjgxY2JiYWFjYWU4NDJiYjJlMCIsImV4cCI6MTUyNTk1OTc2MiwiZ3JhbnRzIjp7ImlkZW50aXR5IjoicG9vamExMiIsInZpZGVvIjp7InJvb20iOiJyb29tIn19fQ.n904DcSN3mAw043EtyeMru36iO7Cbv91JZRhwoUBdrc"

    // Configure remote URL to fetch token from
    var tokenUrl = "http://localhost:8000/token.php"
    
    // Video SDK components
   
    /**
     * We will create an audio device and manage it's lifecycle in response to CallKit events.
     */
    var audioDevice: TVIDefaultAudioDevice = TVIDefaultAudioDevice()
    var camera: TVICameraCapturer?
   
    
    var remoteView: TVIVideoView?

    

    // MARK: UI Element Outlets and handles
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var simulateIncomingButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var roomLine: UIView!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    
    // `TVIVideoView` created from a storyboard
    @IBOutlet weak var previewView: TVIVideoView!

    required init?(coder aDecoder: NSCoder) {
       
        super.init(coder: aDecoder)

        CallManager.shared.callKitProvider.setDelegate(self, queue: nil)
    }

    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
    //    CallManager.shared.callKitProvider.invalidate()
    }

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "QuickStart"

        /*
         * The important thing to remember when providing a TVIAudioDevice is that the device must be set
         * before performing any other actions with the SDK (such as creating Tracks, or connecting to a Room).
         * In this case we've already initialized our own `TVIDefaultAudioDevice` instance which we will now set.
         */
        
        if !CallManager.shared.isCallInProgress {
            TwilioVideo.audioDevice = self.audioDevice;
        }
        
        
        if PlatformUtils.isSimulator {
            self.previewView.removeFromSuperview()
        } else {
            // Preview our local camera track in the local video preview view.
            self.startPreview()
        }
        
        // Disconnect and mic button will be displayed when the Client is connected to a Room.
        self.disconnectButton.isHidden = true
        self.micButton.isHidden = true
        
        self.roomTextField.autocapitalizationType = .none
        self.roomTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController2.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        if CallManager.shared.isCallInProgress {
            prepareLocalMedia();
            showRoomUI(inRoom: true);
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        CallManager.shared.localVideoTrack?.isEnabled = false;
        super.viewWillDisappear(animated);
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewWillAppear(true);
        CallManager.shared.localVideoTrack?.isEnabled = true;
        
    }
    
    func setupRemoteVideoView() {
        // Creating `TVIVideoView` programmatically
        self.remoteView = TVIVideoView.init(frame: CGRect.zero, delegate: self)
        
        self.view.insertSubview(self.remoteView!, at: 0)
        
        // `TVIVideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `TVIVideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFit;
        
        let centerX = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutAttribute.centerX,
                                         relatedBy: NSLayoutRelation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutAttribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutAttribute.centerY,
                                         relatedBy: NSLayoutRelation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutAttribute.centerY,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: self.remoteView!,
                                       attribute: NSLayoutAttribute.width,
                                       relatedBy: NSLayoutRelation.equal,
                                       toItem: self.view,
                                       attribute: NSLayoutAttribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: self.remoteView!,
                                        attribute: NSLayoutAttribute.height,
                                        relatedBy: NSLayoutRelation.equal,
                                        toItem: self.view,
                                        attribute: NSLayoutAttribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
    }

    // MARK: IBActions
    @IBAction func connect(sender: AnyObject) {
        performStartCallAction(uuid: UUID.init(), roomName: self.roomTextField.text)
        self.dismissKeyboard()
    }

    @IBAction func disconnect(sender: AnyObject) {
        if let room = CallManager.shared.room, let uuid = room.uuid {
            logMessage(messageText: "Attempting to disconnect from room \(room.name)")
            performEndCallAction(uuid: uuid)
        }
    }
    
    @IBAction func toggleMic(sender: AnyObject) {
        if (CallManager.shared.localAudioTrack != nil) {
            CallManager.shared.localAudioTrack?.isEnabled = !(CallManager.shared.localAudioTrack?.isEnabled)!
            
            // Update the button title
            if (CallManager.shared.localAudioTrack?.isEnabled == true) {
                micButton.setTitle("Mute", for: .normal)
            } else {
                micButton.setTitle("Unmute", for: .normal)
            }
        }
    }

    // MARK: Private
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }

        CallManager.shared.localVideoTrack?.isEnabled = false;
        // Preview our local camera track in the local video preview view.
        camera = TVICameraCapturer(source: .frontCamera, delegate: self)
        CallManager.shared.localVideoTrack = TVILocalVideoTrack.init(capturer: camera!)
        if (CallManager.shared.localVideoTrack == nil) {
            logMessage(messageText: "Failed to create video track")
        } else {
            // Add renderer to video track for local preview
            CallManager.shared.localVideoTrack!.addRenderer(self.previewView)

            logMessage(messageText: "Video track created")

            // We will flip camera on tap.
            let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController2.flipCamera))
            self.previewView.addGestureRecognizer(tap)
        }
    }

    func flipCamera() {
        if (self.camera?.source == .frontCamera) {
            self.camera?.selectSource(.backCameraWide)
        } else {
            self.camera?.selectSource(.frontCamera)
        }
    }

    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.

        // Create an audio track.
        if (CallManager.shared.localAudioTrack == nil) {
            CallManager.shared.localAudioTrack = TVILocalAudioTrack.init()

            if (CallManager.shared.localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }

        // Create a video track which captures from the camera.
        if (CallManager.shared.localVideoTrack == nil) {
            self.startPreview()
        }
    }

    // Update our UI based upon if we are in a Room or not
    func showRoomUI(inRoom: Bool) {
        self.connectButton.isHidden = inRoom
        self.simulateIncomingButton.isHidden = inRoom
        self.roomTextField.isHidden = inRoom
        self.roomLine.isHidden = inRoom
        self.roomLabel.isHidden = inRoom
        self.micButton.isHidden = !inRoom
        self.disconnectButton.isHidden = !inRoom
        
        UIApplication.shared.isIdleTimerDisabled = inRoom
    }
    
    func dismissKeyboard() {
        if (self.roomTextField.isFirstResponder) {
            self.roomTextField.resignFirstResponder()
        }
    }
    
    func cleanupRemoteParticipant() {
        if ((CallManager.shared.remoteParticipant) != nil) {
            if ((CallManager.shared.remoteParticipant?.videoTracks.count)! > 0) {
                let remoteVideoTrack = CallManager.shared.remoteParticipant?.remoteVideoTracks[0].remoteTrack
                remoteVideoTrack?.removeRenderer(self.remoteView!)
                self.remoteView?.removeFromSuperview()
                self.remoteView = nil
            }
        }
        CallManager.shared.remoteParticipant = nil
    }
    
    func logMessage(messageText: String) {
        NSLog(messageText)
  //      messageLabel.text = messageText
    }

    func holdCall(onHold: Bool) {
        CallManager.shared.localAudioTrack?.isEnabled = !onHold
        CallManager.shared.localVideoTrack?.isEnabled = !onHold
    }
}

// MARK: UITextFieldDelegate
extension ViewController2 : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.connect(sender: textField)
        return true
    }
}

// MARK: TVIRoomDelegate
extension ViewController2 : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        // At the moment, this example only supports rendering one Participant at a time.
        
        logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        
        if (room.remoteParticipants.count > 0) {
            CallManager.shared.remoteParticipant = room.remoteParticipants[0]
            CallManager.shared.remoteParticipant?.delegate = self
        }

        let cxObserver = CallManager.shared.callKitCallController.callObserver
        let calls = cxObserver.calls

        // Let the call provider know that the outgoing call has connected
        if let uuid = room.uuid, let call = calls.first(where:{$0.uuid == uuid}) {
            if call.isOutgoing {
                CallManager.shared.callKitProvider.reportOutgoingCall(with: uuid, connectedAt: nil)
            }
        }
        
        CallManager.shared.callKitCompletionHandler!(true)
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")
        
        self.cleanupRemoteParticipant()
        CallManager.shared.room = nil
        self.showRoomUI(inRoom: false)
        CallManager.shared.callKitCompletionHandler = nil
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        logMessage(messageText: "Failed to connect to room with error: \(error.localizedDescription)")

        CallManager.shared.callKitCompletionHandler!(false)
        CallManager.shared.room = nil
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if (CallManager.shared.remoteParticipant == nil) {
            CallManager.shared.remoteParticipant = participant
            CallManager.shared.remoteParticipant?.delegate = self
        }
       logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        if (CallManager.shared.remoteParticipant == participant) {
            cleanupRemoteParticipant()
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIRemoteParticipantDelegate
extension ViewController2 : TVIRemoteParticipantDelegate {
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedVideoTrack publication: TVIRemoteVideoTrackPublication) {
        
        // Remote Participant has offered to share the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) published video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedVideoTrack publication: TVIRemoteVideoTrackPublication) {
        
        // Remote Participant has stopped sharing the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           publishedAudioTrack publication: TVIRemoteAudioTrackPublication) {
        
        // Remote Participant has offered to share the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) published audio track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           unpublishedAudioTrack publication: TVIRemoteAudioTrackPublication) {
        
        // Remote Participant has stopped sharing the audio Track.
        
        logMessage(messageText: "Participant \(participant.identity) unpublished audio track")
    }
    
    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's video frames now.
        
        logMessage(messageText: "Subscribed to video track for Participant \(participant.identity)")
        
        if (CallManager.shared.remoteParticipant == participant) {
            setupRemoteVideoView()
            videoTrack.addRenderer(self.remoteView!)
        }
    }
    
    func unsubscribed(from videoTrack: TVIRemoteVideoTrack,
                      publication: TVIRemoteVideoTrackPublication,
                      for participant: TVIRemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        logMessage(messageText: "Unsubscribed from video track for Participant \(participant.identity)")
        
        if (CallManager.shared.remoteParticipant == participant) {
            videoTrack.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
    }
    
    func subscribed(to audioTrack: TVIRemoteAudioTrack,
                    publication: TVIRemoteAudioTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.
        
        logMessage(messageText: "Subscribed to audio track for Participant \(participant.identity)")
    }
    
    func unsubscribed(from audioTrack: TVIRemoteAudioTrack,
                      publication: TVIRemoteAudioTrackPublication,
                      for participant: TVIRemoteParticipant) {
        
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
        logMessage(messageText: "Unsubscribed from audio track for Participant \(participant.identity)")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledVideoTrack publication: TVIRemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled video track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           enabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled audio track")
    }
    
    func remoteParticipant(_ participant: TVIRemoteParticipant,
                           disabledAudioTrack publication: TVIRemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled audio track")
    }

    func failedToSubscribe(toAudioTrack publication: TVIRemoteAudioTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }

    func failedToSubscribe(toVideoTrack publication: TVIRemoteVideoTrackPublication,
                           error: Error,
                           for participant: TVIRemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}

// MARK: TVIVideoViewDelegate
extension ViewController2 : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension ViewController2 : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        self.previewView.shouldMirror = (source == .frontCamera)
    }
}
