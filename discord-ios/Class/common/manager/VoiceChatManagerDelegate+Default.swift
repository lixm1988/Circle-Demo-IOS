//
//  VoiceChatManagerDelegate+Default.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/9.
//

import Foundation

extension VoiceChatManagerDelegate {
    func voiceManagerDidJoinChannel(channel: String) {}
    func voiceManagerDidLeaveChannel(channel: String) {}
    func voiceManagerDidAudioMuted(channel: String, username: String, muted: Bool) {}
    func voiceManagerDidUserSpeak(channel: String, usernames: [String]) {}
    func voiceManagerDidUserSpeakEnd(channel: String, usernames: [String]) {}
}
