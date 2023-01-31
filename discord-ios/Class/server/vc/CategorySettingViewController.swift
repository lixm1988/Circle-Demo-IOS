//
//  CategorySettingViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/12/26.
//

import UIKit

class CategorySettingViewController: ServerBaseSettingViewController {

    private let category: EMCircleChannelCategory
    private let fromViewController: UIViewController
    
    init(category: EMCircleChannelCategory, fromViewController: UIViewController) {
        self.category = category
        self.fromViewController = fromViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.text = self.category.name
        
        self.collectionViewDataSource = [
            (image: "server_setting", title: "编辑分组", handle: self.editAction)
        ]
        self.tableViewDataSource = []
    }
    
    private func editAction() {
        self.dismiss(animated: true)
        let vc = ChannelGroupEditViewController(serverId: self.category.serverId, groupId: self.category.categoryId, name: self.category.name)
        self.fromViewController.navigationController?.pushViewController(vc, animated: true)
    }
}
