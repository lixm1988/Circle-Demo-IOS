//
//  VoiceChatManager.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/3.
//

import UIKit
import AgoraRtcKit
import HyphenateChat
import AVFoundation

class VoiceChatManager: NSObject {
    
    static let shared = VoiceChatManager()
    
    private var agoraKit: AgoraRtcEngineKit!
    private var agoraUid: UInt = 0
    var currentChannel: (serverId: String, channelId: String)?
    private var userIdMap: [UInt: String]?
    private var delegates: [VoiceChatManagerDelegate] = []
    
    private var isMute = false
    private var speakMap: [String: CFTimeInterval] = [:]
    private var muteSet = Set<String>()
    private var timer: Timer?
    
    private lazy var voiceChannelMiniView: VoiceChannelMiniView = {
        let view = VoiceChannelMiniView(frame: CGRect.zero)
        view.clickHandle = {
            guard let currentChannel = self.currentChannel, let rootViewController = UIApplication.shared.keyWindow?.rootViewController, let tabbarCurrentController = (rootViewController as? UITabBarController)?.selectedViewController, let navigationCurrentController = (tabbarCurrentController as? UINavigationController)?.viewControllers.last else {
                return
            }
            let vc = VoiceChannelViewController(showType: .id(serverId: currentChannel.serverId, channelId: currentChannel.channelId, closeHandle: {
                view.isHidden = false
            }), fromViewController: navigationCurrentController)
            rootViewController.present(vc, animated: true)
        }
        if let superView = UIApplication.shared.keyWindow?.rootViewController?.view {
            superView.addSubview(view)
            view.frame = CGRect(x: superView.bounds.width - 22 - 52, y: superView.bounds.height - 78 - 52 - superView.safeAreaInsets.bottom, width: 52, height: 52)
        }
        return view
    }()
    
    override init() {
        super.init()
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "15cb0d28b87b425ea613fc46f7c9f974", delegate: self)
        self.agoraKit.setChannelProfile(AgoraChannelProfile.liveBroadcasting)
        self.agoraKit.setClientRole(AgoraClientRole.broadcaster)
        self.agoraKit.enableAudioVolumeIndication(1000, smooth: 5, reportVad: false)
        
        EMClient.shared().roomManager?.add(self, delegateQueue: nil)
        EMClient.shared().circleManager?.add(channelDelegate: self, queue: nil)
        EMClient.shared().addMultiDevices(delegate: self, queue: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didRecvDestroyChannel(_:)), name: EMCircleDidDestroyChannel, object: nil)
    }
    
    func addDelegate(_ delegate: VoiceChatManagerDelegate) {
        self.delegates.append(delegate)
    }
    
    func removeDelegate(_ delegate: VoiceChatManagerDelegate) {
        for i in 0..<self.delegates.count where self.delegates[i].isEqual(delegate) {
            self.delegates.remove(at: i)
            break
        }
    }
    
    func joinChannel(serverId: String, channel: String) {
        self.muteSet.removeAll()
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            return
        }
        if self.currentChannel != nil {
            self.agoraKit.leaveChannel { _ in
                self.joinChannelAction(serverId: serverId, channel: channel)
            }
        } else {
            self.joinChannelAction(serverId: serverId, channel: channel)
        }
    }
    
    func leaveChannel() {
        self.muteSet.removeAll()
        guard let currentChannel = self.currentChannel else {
            return
        }
        self.agoraKit.leaveChannel { _ in
            
        }
        self.timer?.invalidate()
        self.timer = nil
        self.currentChannel = nil
        for delegate in self.delegates {
            delegate.voiceManagerDidLeaveChannel(channel: currentChannel.channelId)
        }
        self.voiceChannelMiniView.isHidden = true
    }
    
    func mute(_ mute: Bool) {
        self.isMute = mute
        self.agoraKit.muteLocalAudioStream(mute)
        self.voiceChannelMiniView.isMuted = mute
        if let currentUser = EMClient.shared().currentUsername, let channelId = self.currentChannel?.channelId {
            if mute {
                self.muteSet.insert(currentUser)
            } else {
                self.muteSet.remove(currentUser)
            }
            for i in self.delegates {
                i.voiceManagerDidAudioMuted(channel: channelId, username: currentUser, muted: mute)
            }
        }
    }
    
    func isMuted(username: String? = nil) -> Bool {
        if let username = username {
            return self.muteSet.contains(username)
        }
        return self.isMute
    }
    
    func isSpeak(username: String) -> Bool {
        if let value = self.speakMap[username] {
            let now = CFAbsoluteTimeGetCurrent()
            if now - value > 0.3 || now < value {
                return false
            }
            return true
        }
        return false
    }
    
    private func joinChannelAction(serverId: String, channel: String) {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let strUrl = "http://a1.easemob.com/inside/token/rtc/channel/\(channel)"
        guard let utf8Url = strUrl.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            return
        }
        guard let url = URL(string: utf8Url) else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(EMClient.shared().accessUserToken ?? "")", forHTTPHeaderField: "Authorization")
        let task = session.dataTask(with: request) { data, _, error in
            guard let data = data else {
                if let error = error {
                    Toast.show(error.localizedDescription, duration: 2)
                }
                return
            }
            guard let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            let resCode = body["code"] as? Int
            if resCode == 200, let rtcToken = body["accessToken"] as? String, let agoraUid = body["agoraUid"] as? String, let uid = UInt(agoraUid) {
                self.agoraKit.joinChannel(byToken: rtcToken, channelId: channel, info: nil, uid: uid) { channel, uid, _ in
                    self.agoraUid = uid
                    self.currentChannel = (serverId: serverId, channelId: channel)
                    self.mute(true)
    
                    for delegate in self.delegates {
                        delegate.voiceManagerDidJoinChannel(channel: channel)
                    }
    
                    guard let currentUser = EMClient.shared().currentUsername else {
                        return
                    }
                    EMClient.shared().roomManager?.setChatroomAttribute(channel, key: currentUser, value: "\(uid)", autoDelete: false, completionBlock: { error in
                        if let error = error {
                            Toast.show(error.errorDescription, duration: 2)
                        }
                        self.fetchChannelAttributes(channelName: channel)
                    })
                    self.startTimer()
                    
                    self.voiceChannelMiniView.isHidden = false
                    self.voiceChannelMiniView.serverId = serverId
                    self.voiceChannelMiniView.isMuted = self.isMute
                }
            }
        }
        task.resume()
    }
    
    private func fetchChannelAttributes(channelName: String) {
        EMClient.shared().roomManager?.fetchChatroomAllAttributes(channelName, completion: { error, attributes in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let attributes = attributes {
                var map: [UInt: String] = [:]
                for attribute in attributes {
                    if let value = UInt(attribute.value) {
                        map[value] = attribute.key
                    }
                }
                self.userIdMap = map
            }
        })
    }
    
    private func startTimer() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            guard let currentChannel = self.currentChannel else {
                return
            }
            let now = CFAbsoluteTimeGetCurrent()
            var speakEndList: [String] = []
            for (key, value) in self.speakMap {
                if now - value > 0.3 || now < value {
                    self.speakMap.removeValue(forKey: key)
                    speakEndList.append(key)
                }
            }
            if speakEndList.count > 0 {
                DispatchQueue.main.async {
                    for delegate in self.delegates {
                        delegate.voiceManagerDidUserSpeakEnd(channel: currentChannel.channelId, usernames: speakEndList)
                    }
                    if let currentUsername = EMClient.shared().currentUsername, speakEndList.contains(currentUsername) {
                        self.voiceChannelMiniView.isSpeak = false
                    }
                }
            }
        })
    }
    
    @objc private func didRecvDestroyChannel(_ notification: Notification) {
        if let channel = notification.object as? (String, String), channel.1 == self.currentChannel?.channelId {
            self.leaveChannel()
        }
    }
}

extension VoiceChatManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Toast.show("rtc error: \(errorCode.rawValue)", duration: 2)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, permissionError type: AgoraPermissionType) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        guard let currentChannel = self.currentChannel, let username = self.userIdMap?[uid] else {
            return
        }
        DispatchQueue.main.async {
            if muted {
                self.muteSet.insert(username)
            } else {
                self.muteSet.remove(username)
            }
            for i in self.delegates {
                i.voiceManagerDidAudioMuted(channel: currentChannel.channelId, username: username, muted: muted)
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        guard let currentChannel = self.currentChannel else {
            return
        }
        var result: [String] = []
        for i in speakers where i.volume > 5 {
            if i.uid == 0 {
                if !self.isMute, let username = EMClient.shared().currentUsername {
                    result.append(username)
                    self.speakMap[username] = CFAbsoluteTimeGetCurrent()
                    DispatchQueue.main.async {
                        self.voiceChannelMiniView.isSpeak = true
                    }
                }
            } else {
                if let username = self.userIdMap?[i.uid] {
                    result.append(username)
                    self.speakMap[username] = CFAbsoluteTimeGetCurrent()
                }
            }
        }
        if result.count > 0 {
            DispatchQueue.main.async {
                for i in self.delegates {
                    i.voiceManagerDidUserSpeak(channel: currentChannel.channelId, usernames: result)
                }
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        if let currentChannel = self.currentChannel {
            self.fetchChannelAttributes(channelName: currentChannel.channelId)
        }
    }
}

extension VoiceChatManager: EMChatroomManagerDelegate {
    func chatroomAttributesDidUpdated(_ roomId: String, attributeMap: [String: String], from fromId: String) {
        if roomId == self.currentChannel?.channelId {
            for attribute in attributeMap {
                if let uid = UInt(attribute.value) {
                    if self.userIdMap == nil {
                        self.userIdMap = [uid: attribute.key]
                    } else {
                        self.userIdMap?[uid] = attribute.key
                    }
                }
            }
        }
    }
}

extension VoiceChatManager: EMCircleManagerChannelDelegate {
    func onChannelDestroyed(_ serverId: String, channelId: String, initiator: String) {
        if channelId == self.currentChannel?.channelId {
            self.leaveChannel()
        }
    }
    
    func onMemberRemoved(fromChannel serverId: String, channelId: String, member: String, initiator: String) {
        if channelId == self.currentChannel?.channelId, member == EMClient.shared().currentUsername {
            self.leaveChannel()
        }
    }
}

extension VoiceChatManager: EMMultiDevicesDelegate {
    func multiDevicesCircleChannelEventDidReceive(_ aEvent: EMMultiDevicesEvent, channelId aChannelId: String, ext aExt: Any?) {
        if aChannelId != self.currentChannel?.channelId {
            return
        }
        switch aEvent {
        case .circleChannelDestroy:
            self.leaveChannel()
        default:
            break
        }
    }
}
