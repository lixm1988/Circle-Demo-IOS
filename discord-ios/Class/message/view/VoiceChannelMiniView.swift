//
//  VoiceChannelMiniView.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/6.
//

import UIKit
import Kingfisher

class VoiceChannelMiniView: UIView {

    private let button = UIButton()
    let imageView = UIImageView()
    private let muteImageView = UIImageView()
    
    var isMuted = false {
        didSet {
            self.muteImageView.image = UIImage(named: isMuted ? "mic_slash_gray" : "mic_slash_white")
        }
    }
    
    var isSpeak: Bool = false {
        didSet {
            self.imageView.layer.borderWidth = isSpeak ? 2 : 0
        }
    }
    
    var clickHandle: (() -> Void)?
    var serverId: String? {
        didSet {
            if let serverId = self.serverId {
                ServerInfoManager.shared.getServerInfo(serverId: serverId, refresh: false) { server, _ in
                    self.imageView.setImage(withUrl: server?.icon, placeholder: "server_head_placeholder")
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.selfInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.selfInit()
    }
    
    private func selfInit() {
        self.button.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        self.imageView.layer.borderColor = UIColor(named: ColorName_14FF72)?.cgColor
        self.imageView.layer.masksToBounds = true
        self.muteImageView.image = UIImage(named: "mic_slash_white")
        
        self.addSubview(self.button)
        self.addSubview(self.imageView)
        self.addSubview(self.muteImageView)
        
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPanAction(_:))))
    }
    
    override func layoutSubviews() {
        self.button.frame = self.bounds
        self.imageView.frame = self.bounds
        self.imageView.layer.cornerRadius = self.bounds.width / 2
        self.muteImageView.frame = CGRect(x: (self.bounds.width - 32) / 2, y: (self.bounds.height - 32) / 2, width: 32, height: 32)
    }
    
    @objc private func onClick() {
        self.clickHandle?()
    }
    
    var panBeginFrame: CGRect?
    @objc private func onPanAction(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.panBeginFrame = self.frame
        } else if let panBeginFrame = self.panBeginFrame {
            let offset = sender.translation(in: self)
            var x = panBeginFrame.minX + offset.x
            var y = panBeginFrame.minY + offset.y
            self.frame = CGRect(x: x, y: y, width: 52, height: 52)

            if sender.state == .ended || sender.state == .cancelled {
                if x < UIScreen.main.bounds.width / 2 {
                    x = 22
                } else {
                    x = UIScreen.main.bounds.width - 22 - 52
                }
                if y < 50 {
                    y = 50
                } else if y > UIScreen.main.bounds.height - 50 - 52 {
                    y = UIScreen.main.bounds.height - 50 - 52
                }
                UIView.animate(withDuration: 0.3) {
                    self.frame = CGRect(x: x, y: y, width: 52, height: 52)
                }
                self.panBeginFrame = nil
            }
        }
    }
}
