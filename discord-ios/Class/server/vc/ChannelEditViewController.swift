//
//  ChannelEditViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/23.
//

import UIKit
import HyphenateChat

class ChannelEditViewController: BaseViewController {
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    private let serverId: String
    private let channelId: String
    
    init(serverId: String, channelId: String) {
        self.serverId = serverId
        self.channelId = channelId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "编辑频道"
        
        EMClient.shared().circleManager?.fetchChannelDetail(self.serverId, channelId: self.channelId, completion: { channel, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let categoryId = channel?.categoryId {
                self.updateCategoryName(categoryId: categoryId)
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func updateCategoryName(categoryId: String, cursor: String? = nil) {
        EMClient.shared().circleManager?.fetchCategories(inServer: self.serverId, limit: 20, cursor: cursor, completion: { result, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let result = result {
                if let list = result.list, let cursor = result.cursor {
                    for i in list where i.categoryId == categoryId {
                        if !i.isDefault {
                            self.categoryNameLabel.text = i.name
                        }
                        return
                    }
                    if list.count >= 20, cursor.count > 0 {
                        self.updateCategoryName(categoryId: categoryId, cursor: cursor)
                    }
                }
            }
        })
    }

    @IBAction func editAction() {
        let vc = ChannelInfoEditViewController(showType: .update(serverId: self.serverId, channelId: self.channelId))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func settingAction() {
        let vc = ServerPermissionSettingViewController(showType: .channel(serverId: self.serverId, channelId: self.channelId))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func changeGroupAction() {
        let vc = ChannelChangeGroupViewController(serverId: self.serverId, channelId: self.channelId)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func destroyAction() {
        let vc = UIAlertController(title: "删除频道", message: "确认删除频道？本操作不可撤销。", preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "取消", style: .default))
        vc.addAction(UIAlertAction(title: "确认", style: .destructive, handler: { _ in
            EMClient.shared().circleManager?.destroyChannel(self.serverId, channelId: self.channelId) { error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("删除频道成功", duration: 2)
                    NotificationCenter.default.post(name: EMCircleDidDestroyChannel, object: (self.serverId, self.channelId))
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }))
        self.present(vc, animated: true)
    }
}
