//
//  ChannelGroupCreateViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/23.
//

import UIKit

class ChannelGroupCreateViewController: BaseViewController {

    enum ShowType {
        case create(serverId: String)
        case update(serverId: String, groupId: String, name: String)
    }
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var nameCountLabel: UILabel!
    private let createButton = UIButton()
    private let showType: ShowType
    
    init(showType: ShowType) {
        self.showType = showType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch self.showType {
        case .create:
            self.title = "创建频道分组"
            self.createButton.setTitle("创建", for: .normal)
        case .update(_, _, let name):
            self.title = "编辑分组名称"
            self.createButton.setTitle("保存", for: .normal)
            self.nameTextField.text = name
        }
        self.createButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.createButton.setTitleColor(UIColor(named: ColorName_979797), for: .disabled)
        self.createButton.setTitleColor(UIColor(named: ColorName_27AE60), for: .normal)
        self.createButton.addTarget(self, action: #selector(createAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.createButton)
        self.createButton.isEnabled = false
        
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "必填项", attributes: [
            .foregroundColor: UIColor(named: ColorName_A7A9AC) ?? UIColor.gray
        ])
        self.nameTextField.setMaxLength(50) { [unowned self] length in
            self.nameCountLabel.text = "\(length)/50"
            self.createButton.isEnabled = length > 0
        }
        self.nameTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc private func createAction() {
        guard let name = self.nameTextField.text, name.count > 0 else {
            return
        }
        self.nameTextField.resignFirstResponder()
        switch self.showType {
        case .create(serverId: let serverId):
            EMClient.shared().circleManager?.createCategory(serverId, name: name, completion: { category, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("创建成功", duration: 2)
                    self.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: EMCircleDidCreateCategory, object: category)
                }
            })
        case .update(serverId: let serverId, groupId: let groupId, _):
            EMClient.shared().circleManager?.updateCategory(serverId, categoryId: groupId, name: name, completion: { category, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("修改成功", duration: 2)
                    NotificationCenter.default.post(name: EMCircleDidUpdateCategory, object: category)
                }
            })
        }
    }
    
    @IBAction func onTapAction() {
        self.nameTextField.resignFirstResponder()
    }
}
