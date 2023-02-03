//
//  ServerDetailAlertViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/24.
//

import UIKit
import HyphenateChat
import PKHUD

class ServerDetailAlertViewController: UIViewController {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tagListView: ServerTagListView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var tagListViewHeightConstraint: NSLayoutConstraint!
    let shapeLayer = CAShapeLayer()
    
    let server: EMCircleServer
    let joinHandle: ((_ server: EMCircleServer) -> Void)?
    
    init(server: EMCircleServer, joinHandle: ((_ server: EMCircleServer) -> Void)?) {
        self.server = server
        self.joinHandle = joinHandle
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentView.layer.mask = self.shapeLayer
        
        self.nameLabel.text = self.server.name
        self.descLabel.text = self.server.desc
        self.joinButton.isHidden = self.joinHandle == nil
        self.avatarImageView.setImage(withUrl: self.server.icon, placeholder: "server_head_placeholder")
        self.tagListView.heightChangeHandle = { [unowned self] height in
            self.tagListViewHeightConstraint.constant = height
            self.scrollView.contentSize = CGSize(width: self.tagListView.bounds.width, height: height)
        }
        self.tagListView.setTags(self.server.tags, itemHeight: 18, showType: .detail)
        self.bgImageView.setImage(withUrl: self.server.background, placeholder: "message_server_bg")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let corner: UIRectCorner = [.topLeft, .topRight]
        let path = UIBezierPath(roundedRect: self.contentView.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 12, height: 12))
        self.shapeLayer.frame = self.contentView.bounds
        self.shapeLayer.path = path.cgPath
    }
    
    @IBAction func joinAction() {
        HUD.show(.progress, onView: self.contentView)
        EMClient.shared().circleManager?.joinServer(self.server.serverId) { server, error in
            HUD.hide()
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let server = server {
                Toast.show("加入成功", duration: 2)
                ServerChannelMapManager.shared.append(serverId: server.serverId, channelId: server.defaultChannelId)
                NotificationCenter.default.post(name: EMCircleDidJoinedServer, object: server)
                self.joinHandle?(server)
            }
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
}
