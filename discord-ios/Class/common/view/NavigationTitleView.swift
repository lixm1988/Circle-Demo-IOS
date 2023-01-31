//
//  NavigationTitleView.swift
//  discord-ios
//
//  Created by 冯钊 on 2023/1/17.
//

import UIKit

class NavigationTitleView: UIView {

    private var imageView: UIImageView = UIImageView()
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.titleLabel = UILabel()
        self.titleLabel?.textColor = UIColor.white
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        self.addSubview(self.titleLabel!)
        self.subtitleLabel = UILabel()
        self.subtitleLabel?.font = UIFont.systemFont(ofSize: 10)
        self.subtitleLabel?.textColor = UIColor(named: ColorName_BDBDBD)
        self.addSubview(self.subtitleLabel!)
        self.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var titleLeftImageName: String? {
        didSet {
            if let imageName = titleLeftImageName {
                self.imageView.image = UIImage(named: imageName)
            } else {
                self.imageView.image = nil
            }
            self.setNeedsLayout()
        }
    }
    
    var title: String? {
        didSet {
            self.titleLabel?.text = title
            self.setNeedsLayout()
        }
    }
    
    var subtitle: String? {
        didSet {
            self.subtitleLabel?.text = subtitle
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: 0, y: (self.bounds.height - 32) / 2, width: 32, height: 32)
        let x: CGFloat = self.imageView.image == nil ? 0 : 40
        let w: CGFloat = self.bounds.width - x
        if self.subtitle == nil {
            self.titleLabel!.frame = CGRect(x: x, y: 0, width: w, height: self.bounds.height)
        } else {
            self.titleLabel!.frame = CGRect(x: x, y: 6, width: w, height: 16)
            self.subtitleLabel?.frame = CGRect(x: x, y: 26, width: w, height: 12)
        }
    }
}
