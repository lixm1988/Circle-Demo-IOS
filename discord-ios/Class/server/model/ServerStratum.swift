//
//  ServerStratum.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/24.
//

import Foundation

enum ServerStratum {
    case server(serverId: String)
    case channel(serverId: String, channelId: String)
}

extension ServerStratum {
    var serverId: String {
        switch self {
        case .server(serverId: let serverId), .channel(serverId: let serverId, channelId: _):
            return serverId
        }
    }
}
