//
//  ChannelInfoEditViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/30.
//

import UIKit
import HyphenateChat
import PKHUD

class ChannelInfoEditViewController: BaseViewController {
    
    enum ShowType {
        case update(serverId: String, channelId: String)
    }
    
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var descTextView: UITextView!
    @IBOutlet private weak var descPlaceholderLabel: UILabel!
    @IBOutlet private weak var nameCountLabel: UILabel!
    @IBOutlet private weak var descCountLabel: UILabel!
    @IBOutlet private weak var descView: UIView!
    
    var createButton: UIButton!
    
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
        self.createButton = UIButton()
        switch self.showType {
        case .update(serverId: let serverId, channelId: let channelId):
            self.title = "频道概览"
            self.createButton.setTitle("保存", for: .normal)
            EMClient.shared().circleManager?.fetchChannelDetail(serverId, channelId: channelId) { channel, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.descView.isHidden = channel?.mode == .voice
                    self.nameTextField.text = channel?.name
                    self.descTextView.text = channel?.desc
                    self.descPlaceholderLabel.isHidden = channel?.desc?.count ?? 0 > 0
                }
            }
        }
        self.createButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.createButton.setTitleColor(UIColor(named: ColorName_979797), for: .disabled)
        self.createButton.setTitleColor(UIColor(named: ColorName_27AE60), for: .normal)
        self.createButton.addTarget(self, action: #selector(createAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.createButton)
        switch self.showType {
        case .update:
            self.createButton.isEnabled = true
        }
        
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "必填项", attributes: [
            .foregroundColor: UIColor(named: ColorName_A7A9AC) ?? UIColor.gray
        ])
        self.descTextView.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        self.descTextView.delegate = self
        self.descTextView.textContainerInset = UIEdgeInsets.zero
        
        self.nameTextField.setMaxLength(16) { [unowned self] length in
            self.nameCountLabel.text = "\(length)/16"
            self.createButton.isEnabled = length > 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc private func createAction() {
        guard let name = self.nameTextField.text, name.count > 0 else {
            return
        }
        switch self.showType {
        case .update(serverId: let serverId, channelId: let channelId):
            let channelAttr = EMCircleChannelAttribute()
            channelAttr.name = self.nameTextField.text
            channelAttr.desc = self.descTextView.text
            HUD.show(.progress, onView: self.view)
            EMClient.shared().circleManager?.updateChannel(serverId, channelId: channelId, attribute: channelAttr) { channel, error in
                HUD.hide()
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("修改成功", duration: 2)
                    self.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: EMCircleDidUpdateChannel, object: channel)
                }
            }
        }
    }
}

extension ChannelInfoEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        var count = self.descTextView.text.count
        self.descPlaceholderLabel.isHidden = count > 0
        if count > 120 {
            count = 120
            textView.text = textView.text.subsring(to: 120)
        }
        self.descCountLabel.text = "\(count)/120"
    }
}
