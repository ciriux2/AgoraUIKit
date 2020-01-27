//
//  AgoraVideoViewController.swift
//  AgoraDemo
//
//  Created by Jonathan Fotland on 9/23/19.
//  Copyright © 2019 Jonathan Fotland. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

public class AgoraVideoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var hangUpButton: UIButton!
    @IBOutlet var toggleVideoButton: UIButton!
    @IBOutlet var switchCameraButton: UIButton!
    
    var appID = "YourAppIDHere"
    var agoraKit: AgoraRtcEngineKit?
    var tempToken: String? = nil
    var userID: UInt = 0
    var userName: String? = nil
    var channelName = "default"
    var remoteUserIDs: [UInt] = []
    var activeVideoIDs: [UInt] = []
    var numFeeds: Int {
        get {
            return activeVideoIDs.count
        }
    }
    
    var showingVideo = true
    
    var muted = false
    
    public static func initialize(appID: String, token: String?, channel: String) -> AgoraVideoViewController {
        
        let myBundle = Bundle(for: self)
        let myStoryboard = UIStoryboard(name: "AgoraVideoViewController", bundle: myBundle)
        
        let viewController = myStoryboard.instantiateInitialViewController() as! AgoraVideoViewController
        
        viewController.appID = appID
        viewController.tempToken = token
        viewController.channelName = channel
        
        return viewController
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true

        // Do any additional setup after loading the view.
        setUpVideo()
        joinChannel()
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func setUpVideo() {
        getAgoraEngine().enableVideo()
        
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = userID
//        videoCanvas.view = localVideoView
//        videoCanvas.renderMode = .fit
//        getAgoraEngine().setupLocalVideo(videoCanvas)
    }
    
    func joinChannel() {
        
        if let name = userName {
            getAgoraEngine().joinChannel(byUserAccount: name, token: tempToken, channelId: channelName) { [weak self] (sid, uid, elapsed) in
                self?.userID = uid
                self?.activeVideoIDs.insert(uid, at: 0)
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            }
        } else {
            getAgoraEngine().joinChannel(byToken: tempToken, channelId: channelName, info: nil, uid: userID) { [weak self] (sid, uid, elapsed) in
                self?.userID = uid
                self?.activeVideoIDs.insert(uid, at: 0)
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    private func getAgoraEngine() -> AgoraRtcEngineKit {
        if agoraKit == nil {
            agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        }
        
        return agoraKit!
    }
    
    @IBAction func didToggleMute(_ sender: Any) {
        getAgoraEngine().muteLocalAudioStream(!muted)

        muted = !muted
        
        if muted {
            muteButton.setImage(UIImage(named: "btn_mute_normal"), for: .normal)
            muteButton.setImage(UIImage(named: "btn_mute_pressed"), for: .selected)
        } else {
            muteButton.setImage(UIImage(named: "btn_unmute_normal"), for: .normal)
            muteButton.setImage(UIImage(named: "btn_unmute_pressed"), for: .selected)
        }
    }
    
    @IBAction func didToggleVideo(_ sender: Any) {
        getAgoraEngine().enableLocalVideo(!showingVideo)
        
        showingVideo = !showingVideo
        
        if !showingVideo {
            activeVideoIDs = activeVideoIDs.filter { $0 != userID }
        } else {
            activeVideoIDs.insert(userID, at: 0)
        }
        collectionView.reloadData()
    }
    
    @IBAction func didSwitchCamera(_ sender: Any) {
        getAgoraEngine().switchCamera()
    }
    
    @IBAction func didTapHangUp(_ sender: Any) {
        leaveChannel()
        if let navigation = navigationController {
            navigation.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func leaveChannel() {
        getAgoraEngine().leaveChannel(nil)
        remoteUserIDs.removeAll()
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(4, numFeeds)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath)
        
        let uid = activeVideoIDs[indexPath.row]
        let isLocal = uid == userID
        
        if let videoCell = cell as? VideoCollectionViewCell {
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = uid
            videoCanvas.view = videoCell.videoView
            videoCanvas.renderMode = .hidden
            if isLocal {
                getAgoraEngine().setupLocalVideo(videoCanvas)
            } else {
                getAgoraEngine().setupRemoteVideo(videoCanvas)
            }
            
            
            if let userInfo = getAgoraEngine().getUserInfo(byUid: uid, withError: nil),
                let username = userInfo.userAccount {
                videoCell.nameplateView.isHidden = false
                videoCell.usernameLabel.text = username
            } else {
                videoCell.nameplateView.isHidden = true
            }
        }
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AgoraVideoViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if numFeeds == 1 {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if numFeeds == 2 {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height / 2)
        } else if numFeeds == 3 {
            if indexPath.row == 0 {
                return CGSize(width: collectionView.frame.width, height: collectionView.frame.height / 2)
            } else {
                return CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height / 2)
            }
        } else {
            return CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height / 2)
        }
    }
}

extension AgoraVideoViewController: AgoraRtcEngineDelegate {
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        remoteUserIDs.append(uid)
        activeVideoIDs.append(uid)
        collectionView.reloadData()
    }
    
    //Sometimes, user info isn't immediately available when a remote user joins - if we get it later, reload their nameplate.
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didUpdatedUserInfo userInfo: AgoraUserInfo, withUid uid: UInt) {
        if let index = remoteUserIDs.first(where: { $0 == uid }) {
            collectionView.reloadItems(at: [IndexPath(item: Int(index), section: 0)])
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if let index = remoteUserIDs.firstIndex(where: { $0 == uid }) {
            remoteUserIDs.remove(at: index)
            activeVideoIDs = activeVideoIDs.filter { $0 != uid }
            collectionView.reloadData()
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
        if state == .failed || state == .stopped {
            activeVideoIDs = activeVideoIDs.filter { $0 != uid }
        } else if state == .starting {
            activeVideoIDs.append(uid)
        }
        collectionView.reloadData()
    }
}
