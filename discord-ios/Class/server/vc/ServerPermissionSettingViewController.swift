//
//  ServerPermissionSettingViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/24.
//

import UIKit
import HyphenateChat
import PKHUD

class ServerPermissionSettingViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var changeSwitch: UISwitch!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var sliderValueLabel: UILabel!
    @IBOutlet private weak var voiceChannelSeatCountView: UIView!
    @IBOutlet private weak var voiceChannelSeatCountViewHeightContraints: NSLayoutConstraint!
    
    let showType: ServerStratum
    
    init(showType: ServerStratum) {
        self.showType = showType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch self.showType {
        case .server(serverId: let serverId):
            self.title = "设置"
            ServerInfoManager.shared.getServerInfo(serverId: serverId, refresh: false) { server, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.changeSwitch.isOn = server?.type == .public
                }
            }
        case .channel(serverId: let serverId, channelId: let channelId):
            self.title = "频道设置"
            self.titleLabel.text = "是否为公开频道"
            self.descLabel.text = "仅通过邀请的用户可以加入私密频道"
            EMClient.shared().circleManager?.fetchChannelDetail(serverId, channelId: channelId, completion: { channel, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.changeSwitch.isOn = channel?.type == .public
                    if channel?.mode == .voice, let channel = channel as? EMCircleVoiceChannel {
                        self.voiceChannelSeatCountView.isHidden = false
                        self.voiceChannelSeatCountViewHeightContraints.constant = 92
                        self.slider.value = Float(channel.seatCount)
                        self.sliderValueLabel.text = "\(UInt(channel.seatCount))"
                    }
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        switch self.showType {
        case .server(serverId: let serverId):
            let attr = EMCircleServerAttribute()
            attr.type = self.changeSwitch.isOn ? .public : .private
            HUD.show(.progress)
            EMClient.shared().circleManager?.updateServer(serverId, attribute: attr, completion: { server, error in
                HUD.hide()
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("修改成功", duration: 2)
                    if let server = server {
                        ServerInfoManager.shared.saveServerInfo(servers: [server])
                    }
                }
            })
        case .channel(serverId: let serverId, channelId: let channelId):
            let attr = EMCircleChannelAttribute()
            attr.type = self.changeSwitch.isOn ? .public : .private
            if !self.voiceChannelSeatCountView.isHidden {
                attr.seatCount = UInt8(self.slider.value)
            }
            HUD.show(.progress)
            EMClient.shared().circleManager?.updateChannel(serverId, channelId: channelId, attribute: attr, completion: { channel, error in
                HUD.hide()
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("修改成功", duration: 2)
                    NotificationCenter.default.post(name: EMCircleDidUpdateChannel, object: channel)
                }
            })
        }
    }
    
    @IBAction func onSliderValueChange() {
        self.sliderValueLabel.text = "\(UInt(self.slider.value))"
    }
}
