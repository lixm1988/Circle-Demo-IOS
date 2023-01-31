//
//  BubbleMenuView.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/30.
//

import UIKit

class BubbleMenuView: UIView {

    enum ItemType {
        case normal
        case selected
    }
    
    private let contentView = UIView()
    
    private var menuItem: [(UIImage?, String, () -> Void, ItemType)] = []
    private let baseView: UIView
    
    var willRemoveHandle: (() -> Void)?
    
    class BubbleMenuItem: UIButton {
        override func layoutSubviews() {
            super.layoutSubviews()
            let y = (self.bounds.height - 24) / 2
            if self.imageView?.image != nil {
                self.imageView?.frame = CGRect(x: 6, y: y, width: 24, height: 24)
                self.titleLabel?.frame = CGRect(x: 34, y: 0, width: self.bounds.width - 34, height: self.bounds.height)
            } else {
                self.titleLabel?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
            }
        }
    }
    
    init(baseView: UIView) {
        self.baseView = baseView
        super.init(frame: CGRect.zero)
        self.contentView.backgroundColor = UIColor.white
        self.contentView.layer.cornerRadius = 4
        self.addSubview(self.contentView)
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tapGes)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let window = UIApplication.shared.keyWindow!
        let baseViewFrameInWindow = self.baseView.superview?.convert(self.baseView.frame, to: window)
        let w = 105.0
        let h = CGFloat(self.menuItem.count * 44)
        var x = baseViewFrameInWindow!.midX - 52
        let y = baseViewFrameInWindow!.maxY + 8
        if x + w > window.bounds.maxX {
            x = window.bounds.maxX - 8 - w
        }
        self.contentView.frame = CGRect(x: x, y: y, width: w, height: h)
    }

    public func addMenuItem(image: UIImage?, title: String, itemType: ItemType = .normal, handle: @escaping () -> Void) {
        self.menuItem.append((image, title, handle, itemType))
    }
    
    public func show() {
        for i in 0..<self.menuItem.count {
            let btn = BubbleMenuView.BubbleMenuItem(type: .custom)
            if let image = self.menuItem[i].0 {
                btn.setImage(image, for: .normal)
                btn.titleLabel?.textAlignment = .left
            } else {
                btn.titleLabel?.textAlignment = .center
            }
            btn.setTitle(self.menuItem[i].1, for: .normal)
            let color: UIColor? = self.menuItem[i].3 == .normal ? .black : UIColor(named: ColorName_34B76B)
            btn.setTitleColor(color, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            btn.frame = CGRect(x: 0, y: i * 44, width: 104, height: 44)
            btn.addTarget(self, action: #selector(clickAction(_:)), for: .touchUpInside)
            btn.tag = i
            self.contentView.addSubview(btn)
        }
        let window = UIApplication.shared.keyWindow!
        self.frame = window.bounds
        window.addSubview(self)
    }
    
    @objc private func clickAction(_ sender: UIButton) {
        self.menuItem[sender.tag].2()
        self.willRemoveHandle?()
        self.removeFromSuperview()
    }
    
    @objc private func tapAction() {
        self.willRemoveHandle?()
        self.removeFromSuperview()
    }
}
