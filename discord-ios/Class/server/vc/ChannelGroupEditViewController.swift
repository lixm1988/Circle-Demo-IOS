//
//  ChannelGroupEditViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/12/5.
//

import UIKit
import HyphenateChat
import PKHUD

class ChannelGroupEditViewController: BaseViewController {

    private let serverId: String
    private let groupId: String
    private let name: String
    
    init(serverId: String, groupId: String, name: String) {
        self.serverId = serverId
        self.groupId = groupId
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "编辑频道分组"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func editAction() {
        let vc = ChannelGroupCreateViewController(showType: .update(serverId: self.serverId, groupId: self.groupId, name: self.name))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func deleteAction() {
        HUD.show(.progress, onView: self.view)
        EMClient.shared().circleManager?.destroyCategory(self.serverId, categoryId: self.groupId, completion: { error in
            HUD.hide()
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else {
                self.navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: EMCircleDidDestroyCategory, object: (self.serverId, self.groupId))
            }
        })
    }
}
