//
//  ServerChannelMapManager.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/10.
//

import UIKit
import HyphenateChat

class ServerChannelMapManager: NSObject {
    
    static let shared = ServerChannelMapManager()
    
    private var map: [String: Set<String>] = [:]
    
    func addDelegate() {
        EMClient.shared().circleManager?.add(serverDelegate: self, queue: nil)
        EMClient.shared().circleManager?.add(channelDelegate: self, queue: nil)
    }
    
    func append(serverId: String, channelId: String) {
        if self.map[serverId] == nil {
            self.map[serverId] = Set<String>()
        }
        self.map[serverId]?.insert(channelId)
    }
    
    func remove(serverId: String, channelId: String? = nil) {
        if let channelId = channelId {
            self.map[serverId]?.remove(channelId)
        } else {
            self.map.removeValue(forKey: serverId)
        }
    }
    
    func getJoinedChannelIds(in serverId: String) -> Set<String>? {
        return self.map[serverId]
    }
    
    func queryJoinedChannelIds(in serverId: String, completionHandle: @escaping () -> Void) {
        if self.map[serverId] != nil {
            completionHandle()
        } else {
            self.queryJoinedChannelIds(in: serverId, cursor: nil, completionHandle: completionHandle)
        }
    }
    
    private func queryJoinedChannelIds(in serverId: String, cursor: String?, completionHandle: @escaping () -> Void) {
        EMClient.shared().circleManager?.fetchJoinedChannelIds(inServer: serverId, limit: 20, cursor: cursor, completion: { result, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
                completionHandle()
                return
            } else if let result = result {
                if let list = result.list {
                    if self.map[serverId] == nil {
                        self.map[serverId] = Set<String>()
                    }
                    for i in list {
                        self.map[serverId]?.insert(i as String)
                    }
                }
                if let list = result.list, list.count >= 20, let cursor = result.cursor, cursor.count > 0 {
                    self.queryJoinedChannelIds(in: serverId, cursor: cursor, completionHandle: completionHandle)
                } else {
                    completionHandle()
                }
            }
        })
    }
}

extension ServerChannelMapManager: EMCircleManagerServerDelegate {
    
}

extension ServerChannelMapManager: EMCircleManagerChannelDelegate {
    
}
