//
//  ServerUserMenuViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/7/7.
//

import UIKit
import HyphenateChat
import SnapKit

class ServerUserMenuViewController: UIViewController {

    enum ShowType {
        case server(serverId: String)
        case channel(serverId: String, channelId: String)
        case voiceChannel(serverId: String, channelId: String)
        case thread(threadId: String)
    }
    
    @IBOutlet private weak var headImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var muteStateImageView: UIImageView!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var accountLabel: UILabel!
    @IBOutlet private weak var chatButton: UIButton!
    @IBOutlet private weak var muteButton: UIButton!
    @IBOutlet private weak var setManagerButton: UIButton!
    @IBOutlet private weak var kickButton: UIButton!
    @IBOutlet private weak var roleLeftConstraint: NSLayoutConstraint!
    
    private let userId: String
    private let showType: ShowType
    private var role: EMCircleUserRole
    private var targetRole: EMCircleUserRole
    private let onlineState: UserStatusView.Status
    private var isMute: Bool {
        didSet {
            if self.isViewLoaded {
                self.muteButton.isSelected = self.isMute
                self.muteStateImageView.isHidden = !self.isMute
                self.updateRoleLabel()
            }
        }
    }
    private var isDefaultChannel: Bool?
    
    var didRoleChangeHandle: ((_ userId: String, _ role: EMCircleUserRole) -> Void)?
    var didKickHandle: ((_ userId: String) -> Void)?
    var didMuteHandle: ((_ userId: String, _ duration: UInt64?) -> Void)?
    
    init(userId: String, showType: ShowType, role: EMCircleUserRole, targetRole: EMCircleUserRole, onlineState: UserStatusView.Status, isMute: Bool = false) {
        self.userId = userId
        self.showType = showType
        self.role = role
        self.targetRole = targetRole
        self.onlineState = onlineState
        self.isMute = isMute
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUserInfo()
        self.muteStateImageView.isHidden = !self.isMute
        self.updateShowUI()
        
        switch self.showType {
        case .server:
            self.kickButton.setTitle("踢出社区", for: .normal)
            EMClient.shared().circleManager?.add(serverDelegate: self, queue: nil)
        case .channel(serverId: let serverId, channelId: let channelId), .voiceChannel(serverId: let serverId, channelId: let channelId):
            EMClient.shared().circleManager?.add(serverDelegate: self, queue: nil)
            EMClient.shared().circleManager?.fetchChannelDetail(serverId, channelId: channelId) { channel, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                    return
                }
                self.kickButton.setTitle("踢出频道", for: .normal)
                self.isDefaultChannel = channel?.isDefault
                self.updateShowUI()
            }
        default:
            break
        }
    }
    
    private func updateRoleLabel() {
        switch self.targetRole {
        case .owner:
            self.roleLabel.backgroundColor = UIColor(named: ColorName_27AE60)
            self.roleLabel.text = "创建者"
            self.roleLabel.isHidden = false
        case .moderator:
            self.roleLabel.backgroundColor = UIColor(named: ColorName_6C6FF8)
            self.roleLabel.text = "管理员"
            self.roleLabel.isHidden = false
        default:
            self.roleLabel.isHidden = true
        }
        self.roleLeftConstraint.constant = self.isMute ? 30 : 8
    }
    
    private func setupUserInfo() {
        UserInfoManager.share.queryUserInfo(userId: userId, loadCache: true) { userInfo, _ in
            self.headImageView.setImage(withUrl: userInfo?.avatarUrl, placeholder: "head_placeholder")
            if let userInfo = userInfo {
                self.nameLabel.text = userInfo.showname
            } else {
                self.nameLabel.text = self.userId
            }
            self.accountLabel.text = self.userId
        }
    }
    
    @IBAction func tapAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func chatAction() {
        let vc = ChatViewController(chatType: .single(userId: self.userId))
        if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            tabBarController.dismiss(animated: true) {
                (tabBarController.selectedViewController as? UINavigationController)?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func muteAction() {
        switch self.showType {
        case .channel(serverId: let serverId, channelId: let channelId):
            if self.muteButton.isSelected {
                EMClient.shared().circleManager?.unmuteUserInChannel(userId: self.userId, serverId: serverId, channelId: channelId) { error in
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                    } else {
                        self.isMute = false
                        self.didMuteHandle?(self.userId, nil)
                    }
                }
            } else {
                EMClient.shared().circleManager?.muteUserInChannel(userId: self.userId, serverId: serverId, channelId: channelId, duration: 86400) { error in
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                    } else {
                        self.isMute = true
                        self.didMuteHandle?(self.userId, 86400)
                    }
                }
            }
        default:
            break
        }
    }
    
    @IBAction func setManagerAction() {
        switch self.showType {
        case .server(serverId: let serverId), .channel(serverId: let serverId, channelId: _):
            if self.setManagerButton.isSelected {
                EMClient.shared().circleManager?.removeModerator(fromServer: serverId, userId: userId) { error in
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                    } else {
                        self.setManagerButton.isSelected = !self.setManagerButton.isSelected
                        self.didRoleChangeHandle?(self.userId, .user)
                    }
                }
            } else {
                EMClient.shared().circleManager?.addModerator(toServer: serverId, userId: userId) { error in
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                    } else {
                        self.setManagerButton.isSelected = !self.setManagerButton.isSelected
                        self.didRoleChangeHandle?(self.userId, .moderator)
                    }
                }
            }
        default:
            break
        }
    }
    
    @IBAction func kickAction() {
        switch self.showType {
        case .server(serverId: let serverId):
            EMClient.shared().circleManager?.removeUser(fromServer: serverId, userId: self.userId) { error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.dismiss(animated: true)
                    self.didKickHandle?(self.userId)
                }
            }
        case .channel(serverId: let serverId, channelId: let channelId),
             .voiceChannel(serverId: let serverId, channelId: let channelId):
            EMClient.shared().circleManager?.removeUser(fromChannel: serverId, channelId: channelId, userId: self.userId) { error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.dismiss(animated: true)
                    self.didKickHandle?(self.userId)
                }
            }
        default:
            break
        }
    }
    
    private func updateShowUI() {
        switch self.showType {
        case .server:
            self.updateServerShow()
        case .channel:
            self.updateChannelShow()
        case .voiceChannel:
            self.updateVoiceChannelShow()
        case .thread:
            self.updateThreadShow()
        }
        self.updateLayout()
    }
    
    private func updateServerShow() {
        self.updateRoleLabel()
        switch (self.role, self.targetRole) {
        case (.owner, .moderator):
            self.kickButton.isHidden = false
            self.setManagerButton.isSelected = true
            self.muteButton.isHidden = true
            self.setManagerButton.isHidden = false
        case (.owner, _):
            self.kickButton.isHidden = false
            self.setManagerButton.isSelected = false
            self.muteButton.isHidden = true
            self.setManagerButton.isHidden = false
        case (.moderator, .user):
            self.kickButton.isHidden = false
            self.setManagerButton.isHidden = true
            self.muteButton.isHidden = true
        default:
            self.kickButton.isHidden = true
            self.setManagerButton.isHidden = true
            self.muteButton.isHidden = true
        }
    }
    
    private func updateChannelShow() {
        if self.role != .user {
            self.muteButton.isSelected = self.isMute
        }
        self.updateRoleLabel()
        
        switch (self.role, self.targetRole) {
        case (.owner, .moderator):
            self.kickButton.isHidden = self.isDefaultChannel ?? false
            self.setManagerButton.isSelected = true
            self.muteButton.isHidden = false
            self.setManagerButton.isHidden = false
        case (.owner, _):
            self.kickButton.isHidden = self.isDefaultChannel ?? false
            self.setManagerButton.isSelected = false
            self.muteButton.isHidden = false
            self.setManagerButton.isHidden = false
        case (.moderator, .user):
            self.kickButton.isHidden = self.isDefaultChannel ?? false
            self.setManagerButton.isHidden = true
            self.muteButton.isHidden = false
        default:
            self.kickButton.isHidden = true
            self.setManagerButton.isHidden = true
            self.muteButton.isHidden = true
        }
    }
    
    private func updateVoiceChannelShow() {
        self.updateRoleLabel()
        
        self.muteButton.isHidden = true
        self.setManagerButton.isHidden = true
        switch (self.role, self.targetRole) {
        case (.owner, .moderator):
            self.kickButton.isHidden = false
        case (.owner, _):
            self.kickButton.isHidden = false
        case (.moderator, .user):
            self.kickButton.isHidden = false
        default:
            self.kickButton.isHidden = true
        }
    }
    
    private func updateThreadShow() {
        self.kickButton.isHidden = true
        self.muteButton.isHidden = true
        self.setManagerButton.isHidden = true
    }
    
    private func updateLayout() {
        self.chatButton.snp.remakeConstraints { make in
            make.left.equalTo(self.view)
            make.top.equalTo(self.headImageView.snp.bottom).offset(32)
            make.height.equalTo(66)
        }
        self.muteButton.snp.remakeConstraints { make in
            make.left.equalTo(self.chatButton.snp.right)
            make.top.height.equalTo(self.chatButton)
            if self.muteButton.isHidden {
                make.width.equalTo(0)
            } else {
                make.width.equalTo(self.chatButton)
            }
        }
        self.setManagerButton.snp.remakeConstraints { make in
            make.left.equalTo(self.muteButton.snp.right)
            make.top.height.equalTo(self.chatButton)
            if self.setManagerButton.isHidden {
                make.width.equalTo(0)
            } else {
                make.width.equalTo(self.chatButton)
            }
        }
        self.kickButton.snp.remakeConstraints { make in
            make.left.equalTo(self.setManagerButton.snp.right)
            make.top.height.equalTo(self.chatButton)
            make.right.equalTo(self.view)
            if self.kickButton.isHidden {
                make.width.equalTo(0)
            } else {
                make.width.equalTo(self.chatButton)
            }
        }
    }
}

extension ServerUserMenuViewController: EMCircleManagerServerDelegate {
    func onServerRoleAssigned(_ serverId: String, member: String, role: EMCircleUserRole) {
        switch self.showType {
        case .server(serverId: let sId), .channel(serverId: let sId, channelId: _):
            if serverId == sId {
                if member == EMClient.shared().currentUsername {
                    self.role = role
                } else if member == self.userId {
                    self.targetRole = role
                }
                self.updateShowUI()
            }
        default:
            break
        }
    }
}
