//
//  NotificationNames.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/7/14.
//

import Foundation

let EMCircleDidCreateServer = Notification.Name("EMCircleDidCreateServer")
let EMCircleDidUpdateServer = Notification.Name("EMCircleDidUpdateServer")
let EMCircleDidDestroyServer = Notification.Name("EMCircleDidDestroyServer")
let EMCircleDidJoinedServer = Notification.Name("EMCircleDidJoinedServer")
let EMCircleDidExitedServer = Notification.Name("EMCircleDidExitedServer")

let EMCircleDidCreateChannel = Notification.Name("EMCircleDidCreateChannel")
let EMCircleDidDestroyChannel = Notification.Name("EMCircleDidDestroyChannel")
let EMCircleDidUpdateChannel = Notification.Name("EMCircleDidUpdateChannel")
let EMCircleDidJoinChannel = Notification.Name("EMCircleDidJoinChannel")
let EMCircleDidExitedChannel = Notification.Name("EMCircleDidExitedChannel")

let EMThreadDidDestroy = Notification.Name("EMThreadDidDestroy")
let EMThreadDidExited = Notification.Name("EMThreadDidExited")

let EMCurrentUserInfoUpdate = Notification.Name("EMCurrentUserInfoUpdate")
let EMUserInfoUpdate = Notification.Name("EMUserInfoUpdate")

let MainShouldSelectedServer = Notification.Name("MainShouldSelectedServer")

let EMCircleDidCreateCategory = Notification.Name("EMCircleDidCreateCategory")
let EMCircleDidDestroyCategory = Notification.Name("EMCircleDidDestroyCategory")
let EMCircleDidUpdateCategory = Notification.Name("EMCircleDidUpdateCategory")
let EMCircleDidTransferChannelCategory = Notification.Name("EMCircleDidTransferChannelCategory")

let EMChatMarkAllMessagesAsRead = Notification.Name("EMChatMarkAllMessagesAsRead")
let EMChatMessageUnreadCountChange = Notification.Name("EMChatMessageUnreadCountChange")
let EMCircleServerMessageUnreadCountChange = Notification.Name("EMCircleServerMessageUnreadCountChange")
