//
//  MessageServerThreadListFooter.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/8/2.
//

import UIKit

class MessageServerThreadListFooter: UITableViewHeaderFooterView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.nameLabel.text = "加载中..."
                self.arrowImageView.isHidden = true
            } else {
                self.nameLabel.text = "加载更多子区"
                self.arrowImageView.isHidden = false
            }
        }
    }
    
    var clickHandle: (() -> Void)?
    
    @IBAction func clickAction() {
        if !self.isLoading {
            self.clickHandle?()
        }
    }
}
