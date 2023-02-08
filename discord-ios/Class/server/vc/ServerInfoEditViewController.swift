//
//  ServerInfoEditViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/29.
//

import UIKit
import HyphenateChat
import PKHUD
import Kingfisher
import SnapKit
import TZImagePickerController

class ServerInfoEditViewController: BaseViewController {

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var descTextView: UITextView!
    @IBOutlet private weak var tagListView: ServerTagListView!
    @IBOutlet private weak var nameLengthLabel: UILabel!
    @IBOutlet private weak var descLengthLabel: UILabel!
    @IBOutlet private weak var tagCountLabel: UILabel!
    @IBOutlet private weak var tagListViewHeightConstraint: NSLayoutConstraint!
    
    private let saveButton = UIButton(type: .custom)
    private var tagLengthLabel = UILabel()
    
    private let serverId: String
    private var server: EMCircleServer?
    
    init(serverId: String) {
        self.serverId = serverId
        super.init(nibName: "ServerInfoEditViewController", bundle: nil)
        self.modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "编辑概览"
        self.saveButton.setTitle("保存", for: .normal)
        self.saveButton.setTitleColor(UIColor(named: ColorName_979797), for: .disabled)
        self.saveButton.setTitleColor(UIColor(named: ColorName_27AE60), for: .normal)
        self.saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.saveButton)
        self.saveButton.isEnabled = false

        self.descTextView.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        self.tagLengthLabel.textColor = UIColor(white: 0, alpha: 0.6)
        self.tagLengthLabel.font = UIFont.systemFont(ofSize: 14)
        
        self.tagListView.deleteHandle = { [unowned self] tag in
            if let tag = tag {
                self.deleteTag(tag)
            }
        }
        self.tagListView.heightChangeHandle = { [unowned self] height in
            self.tagListViewHeightConstraint.constant = height
        }
        
        HUD.show(.progress, onView: self.view)
        ServerInfoManager.shared.getServerInfo(serverId: self.serverId, refresh: true) { [weak self] server, error in
            HUD.hide()
            guard let self = self else {
                return
            }
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
                return
            }
            self.server = server
            if self.serverId != server?.serverId {
                return
            }
            self.nameTextField.text = server?.name
            self.tagListView.setTags(server?.tags, itemHeight: 16, showType: .delete)
            self.descTextView.text = server?.desc
            self.updateNameLength()
            self.updateDescLength()
            self.tagCountLabel.text = "\(server?.tags?.count ?? 0)/10"
        }
        
        self.nameTextField.setMaxLength(16) { [unowned self] _ in
            self.saveButton.isEnabled = true
            self.updateNameLength()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func updateNameLength() {
        self.nameLengthLabel.text = "\(self.nameTextField.text?.count ?? 0)/16"
        self.saveButton.isEnabled = (self.nameTextField.text?.count ?? 0) > 0 && self.saveButton.isEnabled
    }
    
    private func updateDescLength() {
        self.descLengthLabel.text = "\(self.descTextView.text?.count ?? 0)/120"
    }
    
    @objc private func saveAction() {
        guard let name = self.nameTextField.text else {
            return
        }
        HUD.show(.progress, onView: self.view)
        let attribute = EMCircleServerAttribute()
        attribute.name = name
        attribute.desc = self.descTextView.text
        EMClient.shared().circleManager?.updateServer(serverId, attribute: attribute) { server, error in
            HUD.hide()
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else {
                Toast.show("修改成功", duration: 2)
                if let server = server {
                    ServerInfoManager.shared.saveServerInfo(servers: [server])
                    NotificationCenter.default.post(name: EMCircleDidUpdateServer, object: server)
                }
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func nameClearAction() {
        self.nameTextField.text = nil
        self.updateNameLength()
    }
    
    @IBAction func tagAddAction() {
        let vc = UIAlertController(title: "添加标签", message: nil, preferredStyle: .alert)
        vc.addTextField { textField in
            textField.placeholder = "在此输入标签"
            self.tagLengthLabel.removeFromSuperview()
            textField.addSubview(self.tagLengthLabel)
            self.tagLengthLabel.snp.makeConstraints { make in
                make.right.equalTo(textField)
                make.centerY.equalTo(textField)
            }
            self.tagLengthLabel.text = "0/16"
            textField.setMaxLength(16) { length in
                self.tagLengthLabel.text = "\(length)/16"
            }
        }
        vc.addAction(UIAlertAction(title: "取消", style: .default))
        vc.addAction(UIAlertAction(title: "确认", style: .default, handler: { _ in
            if let tag = vc.textFields?[0].text {
                if let tags = self.server?.tags {
                    for i in tags where i.name == tag {
                        Toast.show("社区标签已存在", duration: 2)
                        return
                    }
                }
                
                EMClient.shared().circleManager?.addTags(toServer: self.serverId, tags: [tag]) { tags, error in
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                    } else if let tags = tags {
                        Toast.show("添加成功", duration: 2)
                        if let server = ServerInfoManager.shared.getServerInfo(serverId: self.serverId) {
                            var old = server.tags ?? []
                            old.append(contentsOf: tags)
                            server.tags = old
                            self.tagListView.setTags(server.tags, itemHeight: 16, showType: .delete)
                            self.tagCountLabel.text = "\(server.tags?.count ?? 0)/10"
                            NotificationCenter.default.post(name: EMCircleDidUpdateServer, object: server)
                        }
                    }
                }
            }
        }))
        self.present(vc, animated: true)
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        self.nameTextField.resignFirstResponder()
        self.descTextView.resignFirstResponder()
    }
    
    private func deleteTag(_ tag: EMCircleServerTag) {
        guard let tagId = tag.tagId else {
            return
        }
        EMClient.shared().circleManager?.removeTags(fromServer: self.serverId, tagIds: [tagId]) { error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else {
                Toast.show("删除成功", duration: 2)
                if let server = ServerInfoManager.shared.getServerInfo(serverId: self.serverId) {
                    var old = server.tags ?? []
                    for i in 0..<old.count where old[i].tagId == tagId {
                        old.remove(at: i)
                        break
                    }
                    server.tags = old
                    self.tagListView.setTags(server.tags, itemHeight: 16, showType: .delete)
                    self.tagCountLabel.text = "\(server.tags?.count ?? 0)/10"
                    NotificationCenter.default.post(name: EMCircleDidUpdateServer, object: server)
                }
            }
        }
    }
}

extension ServerInfoEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        self.saveButton.isEnabled = true
        var count = self.descTextView.text.count
        if count > 120 {
            count = 120
            textView.text = textView.text.subsring(to: 120)
        }
        self.updateDescLength()
    }
}
