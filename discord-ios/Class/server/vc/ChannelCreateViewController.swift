//
//  ChannelCreateViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/12/5.
//

import UIKit
import HyphenateChat
import PKHUD

class ChannelCreateViewController: BaseViewController {

    @IBOutlet weak var chatRadioImageView: UIImageView!
    @IBOutlet weak var voiceRadioImageView: UIImageView!
    @IBOutlet weak var nameLengthLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var publicSwitch: UISwitch!
    
    private var mode: EMCircleChannelMode = .chat
    
    let createButton = UIButton()
    
    private let serverId: String
    private let categoryId: String?
    
    init(serverId: String, categoryId: String?) {
        self.serverId = serverId
        self.categoryId = categoryId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "创建频道"
        
        self.createButton.setTitle("创建", for: .normal)
        self.createButton.setTitleColor(UIColor(named: ColorName_979797), for: .disabled)
        self.createButton.setTitleColor(UIColor(named: ColorName_27AE60), for: .normal)
        self.createButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.createButton.addTarget(self, action: #selector(createAction), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.createButton)
        self.createButton.isEnabled = false

        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "输入频道名称", attributes: [
            .foregroundColor: UIColor(named: ColorName_A7A9AC)!
        ])
        self.nameTextField.setMaxLength(16) { [unowned self] length in
            self.nameLengthLabel.text = "\(length)/16"
            self.createButton.isEnabled = length > 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func chatAction() {
        self.nameTextField.resignFirstResponder()
        self.chatRadioImageView.image = UIImage(named: "radio_checked")
        self.voiceRadioImageView.image = UIImage(named: "radio_unchecked")
        self.mode = .chat
    }
    
    @IBAction func voiceAction() {
        self.nameTextField.resignFirstResponder()
        self.chatRadioImageView.image = UIImage(named: "radio_unchecked")
        self.voiceRadioImageView.image = UIImage(named: "radio_checked")
        self.mode = .voice
    }
    
    @objc func createAction() {
        self.nameTextField.resignFirstResponder()
        let attribute = EMCircleChannelAttribute()
        attribute.name = self.nameTextField.text ?? ""
        attribute.type = self.publicSwitch.isOn ? .public : .private
        HUD.show(.progress)
        EMClient.shared().circleManager?.createChannel(self.serverId, categoryId: self.categoryId, attribute: attribute, mode: self.mode, completion: { channel, error in
            HUD.hide()
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let channel = channel {
                let navigationController = self.navigationController
                navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: EMCircleDidCreateChannel, object: channel)
                if self.mode == .chat {
                    let vc = ChatViewController(chatType: .channel(serverId: self.serverId, channelId: channel.channelId))
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        })
    }
    
    @IBAction func onSwitchValueChange() {
        self.nameTextField.resignFirstResponder()
    }
    
    @IBAction func onTapAction() {
        self.nameTextField.resignFirstResponder()
    }
}
