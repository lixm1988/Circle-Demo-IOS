//
//  ServerChooseCell.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/23.
//

import UIKit

class ServerChooseCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var isSelect: Bool = false {
        didSet {
            self.selectedImageView.image = UIImage(named: self.isSelect ? "radio_checked" : "radio_unchecked")
        }
    }
}
