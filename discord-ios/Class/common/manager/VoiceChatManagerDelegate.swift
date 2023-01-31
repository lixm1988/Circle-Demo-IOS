//
//  VoiceChatManagerDelegate.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/4.
//

import Foundation

protocol VoiceChatManagerDelegate: NSObjectProtocol {
    func voiceManagerDidJoinChannel(channel: String)
    func voiceManagerDidLeaveChannel(channel: String)
    func voiceManagerDidAudioMuted(channel: String, username: String, muted: Bool)
    func voiceManagerDidUserSpeak(channel: String, usernames: [String])
    func voiceManagerDidUserSpeakEnd(channel: String, usernames: [String])
}
