//
//  MessageServerChannelHeader.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/8/1.
//

import UIKit

class MessageServerChannelHeader: UITableViewHeaderFooterView {

    @IBOutlet private weak var foldImageView: UIImageView!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var nameLabel: UILabel!
    
    var createHandle: (() -> Void)?
    var foldHandle: (() -> Void)?
    var longPressHandle: (() -> Void)?
    
    var createEnable: Bool = false {
        didSet {
            self.createButton.isHidden = !self.createEnable
        }
    }
    
    var isFold: Bool = true {
        didSet {
            self.foldImageView.transform = self.isFold ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat.pi)
        }
    }
    
    var name: String? {
        didSet {
            self.nameLabel.text = name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        self.addGestureRecognizer(longPressGes)
    }
    
    @IBAction func createAction() {
        self.createHandle?()
    }
    
    @IBAction func foldAction() {
        self.foldHandle?()
    }
    
    @objc func longPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            self.longPressHandle?()
            sender.state = .ended
        }
    }
}
