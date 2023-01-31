//
//  SquareCollectionViewCell.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/21.
//

import UIKit
import HyphenateChat
import Kingfisher

class SquareCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var bgImageView: UIImageView!
    @IBOutlet private weak var headImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var tagListView: ServerTagListView!
    
    private var downloadTask: DownloadTask?
    private var bgDownloadTask: DownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.headImageView.layer.borderColor = UIColor(named: ColorName_282828)?.cgColor
        self.headImageView.layer.borderWidth = 4
    }
    
    public var server: EMCircleServer? {
        didSet {
            self.downloadTask?.cancel()
            self.bgDownloadTask?.cancel()
            self.downloadTask = self.headImageView.setImage(withUrl: server?.icon, placeholder: "server_head_placeholder")
            self.bgDownloadTask = self.bgImageView.setImage(withUrl: server?.background, placeholder: "message_server_bg")
            self.nameLabel.text = server?.name
            self.descLabel.text = server?.desc
            self.tagListView.setTags(server?.tags, itemHeight: self.tagListView.bounds.height)
        }
    }
}
