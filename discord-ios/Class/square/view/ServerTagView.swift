//
//  ServerTagView.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/21.
//

import UIKit
import SnapKit

class ServerTagView: UIView {
    
    private let imageView = UIImageView(image: UIImage(named: "server_tag_icon"))
    private let label = UILabel()
    private let deleteButton = UIButton(type: .custom)
    
    enum ShowType {
        case simple
        case detail
        case delete
    }
    
    var showType: ShowType = .simple {
        didSet {
            switch self.showType {
            case .delete:
                self.backgroundColor = .clear
                self.label.font = UIFont.systemFont(ofSize: 16)
                self.deleteButton.isHidden = false
                self.imageView.snp.remakeConstraints { make in
                    make.left.centerY.equalTo(self)
                    make.width.height.equalTo(16)
                }
                self.label.snp.remakeConstraints { make in
                    make.left.equalTo(self.imageView.snp.right)
                    make.centerY.equalTo(self)
                    make.right.equalTo(-18)
                }
            default:
                self.backgroundColor = .black.withAlphaComponent(0.2)
                self.layer.cornerRadius = 4
                self.label.font = UIFont.systemFont(ofSize: 10)
                self.deleteButton.isHidden = true
                self.imageView.snp.remakeConstraints { make in
                    make.width.height.equalTo(14)
                    make.centerY.equalTo(self)
                    make.left.equalTo(2)
                }
                self.label.snp.remakeConstraints { make in
                    make.left.equalTo(self.imageView.snp.right).offset(2)
                    make.centerY.equalTo(self)
                    make.right.equalTo(-4)
                }
            }
        }
    }
    
    public class func minWidth(showDelete: Bool) -> CGFloat {
        if showDelete {
            return 54
        } else {
            return 36
        }
    }
    
    public var maxWidth: CGFloat {
        guard let serverTag = self.serverTag, let font = self.label.font else {
            return 16
        }
        let attrStr = NSAttributedString(string: serverTag, attributes: [
            .font: font
        ])
        
        let tagW = attrStr.boundingRect(with: CGSize(width: 1000, height: 1000), options: .usesFontLeading, context: nil).width
        if self.showType == .delete {
            return 34 + ceil(tagW)
        } else {
            return 22 + ceil(tagW)
        }
    }
    
    public var deleteHandle: ((_ tag: String?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.selfInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        self.selfInit()
    }
    
    public var serverTag: String? {
        didSet {
            self.label.text = serverTag
        }
    }
    
    private func selfInit() {
        self.backgroundColor = UIColor.clear
        self.imageView.contentMode = .scaleAspectFit
        self.label.font = UIFont.systemFont(ofSize: 10)
        self.label.textColor = .white
        self.deleteButton.setBackgroundImage(UIImage(named: "server_tag_delete"), for: .normal)
        self.deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        self.addSubview(self.imageView)
        self.addSubview(self.label)
        self.addSubview(self.deleteButton)

        self.imageView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
            make.centerY.equalTo(self)
            make.left.equalTo(2)
        }
        self.label.snp.makeConstraints { make in
            make.left.equalTo(self.imageView.snp.right)
            make.centerY.equalTo(self)
            if self.showType == .delete {
                make.right.equalTo(self).offset(16)
            } else {
                make.right.equalTo(self)
            }
        }
        self.deleteButton.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.right.centerY.equalTo(self)
        }
        self.deleteButton.isHidden = self.showType != .delete
    }
    
    @objc private func deleteAction() {
        self.deleteHandle?(self.serverTag)
    }
}
