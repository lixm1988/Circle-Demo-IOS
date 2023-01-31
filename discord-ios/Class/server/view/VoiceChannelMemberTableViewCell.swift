//
//  VoiceChannelMemberTableViewCell.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/12/23.
//

import UIKit

class VoiceChannelMemberTableViewCell: UITableViewCell {

    enum ShowType {
        case list
        case sublist
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var muteImageView: UIImageView!
    @IBOutlet weak var avatarImageViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    
    var showType: ShowType = .list {
        didSet {
            if showType == .list {
                self.avatarImageViewLeftConstraint.constant = 14
                self.avatarImageViewWidthConstraint.constant = 36
                self.avatarImageView.layer.cornerRadius = 18
            } else {
                self.avatarImageViewLeftConstraint.constant = 44
                self.avatarImageViewWidthConstraint.constant = 24
                self.avatarImageView.layer.cornerRadius = 12
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatarImageView.layer.borderColor = UIColor(named: ColorName_14FF72)?.cgColor
    }
    
    var isSpeak: Bool = false {
        didSet {
            self.avatarImageView.layer.borderWidth = isSpeak ? 2 : 0
        }
    }
}
