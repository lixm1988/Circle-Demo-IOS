//
//  TagListView.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/21.
//

import UIKit
import HyphenateChat

class ServerTagListView: UIView {

    private static var tagViewPool: Set<ServerTagView> = Set()
    
    private var tagViews: [ServerTagView] = []
    public var deleteHandle: ((_ tag: EMCircleServerTag?) -> Void)?
    public var heightChangeHandle: ((_ height: CGFloat) -> Void)?
    
    private var tags: [EMCircleServerTag]?
    private var itemHeight: CGFloat = 0
    private var showType: ServerTagView.ShowType = .simple
    private lazy var moreButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("...", for: .normal)
        btn.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        self.addSubview(btn)
        return btn
    }()
    
    var moreHandle: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let tags = self.tags, tags.count > 0 else {
            self.moreButton.isHidden = true
            self.clearAll()
            return
        }
        if tags.count < self.tagViews.count {
            self.removeTagViews(fromIndex: tags.count)
        }
        
        var beginX: CGFloat = 0
        var beginY: CGFloat = 0
        let space: CGFloat = self.showType == .delete ? 12 : 4
        let right = self.showType == .simple ? 13.0 : 0
        for i in 0..<tags.count {
            if ServerTagView.minWidth(showDelete: self.showType == .delete) + beginX + right > self.bounds.width {
                if self.showType == .simple {
                    self.removeTagViews(fromIndex: i)
                    self.moreButton.isHidden = false
                    self.moreButton.frame = CGRect(x: beginX, y: beginY, width: 13, height: self.itemHeight)
                    break
                }
            }
            var tagView: ServerTagView!
            if i < self.tagViews.count {
                tagView = self.tagViews[i]
            } else {
                tagView = ServerTagListView.tagViewPool.popFirst()
                if tagView == nil {
                    tagView = ServerTagView()
                }
                self.tagViews.append(tagView)
                self.addSubview(tagView)
            }
            tagView.serverTag = tags[i].name
            tagView.deleteHandle = { [weak self] tag in
                if let tags = self?.tags {
                    for item in tags where item.name == tag {
                        self?.deleteHandle?(item)
                    }
                }
            }
            tagView.showType = self.showType
            if self.showType != .simple && beginX + tagView.maxWidth > self.bounds.width {
                beginY += self.itemHeight + 4
                beginX = 0
            }
            let width = beginX + tagView.maxWidth > (self.bounds.width - right) ? self.bounds.width - beginX - right : tagView.maxWidth
            tagView.frame = CGRect(x: beginX, y: beginY, width: width, height: itemHeight)
            beginX += width + space
            
            if i == tags.count - 1, self.showType == .simple {
                self.moreButton.isHidden = true
            }
        }
        
        self.heightChangeHandle?(self.tagViews.last?.frame.maxY ?? 0)
    }
    
    public func setTags(_ tags: [EMCircleServerTag]?, itemHeight: CGFloat, showType: ServerTagView.ShowType = .simple) {
        self.tags = tags
        self.itemHeight = itemHeight
        self.showType = showType
        self.setNeedsLayout()
    }
    
    private func clearAll() {
        for tagView in self.tagViews {
            tagView.removeFromSuperview()
            ServerTagListView.tagViewPool.insert(tagView)
        }
        self.tagViews.removeAll()
    }
    
    private func removeTagViews(fromIndex: Int) {
        for i in fromIndex..<self.tagViews.count {
            let tagView = self.tagViews[i]
            tagView.removeFromSuperview()
            ServerTagListView.tagViewPool.insert(tagView)
        }
        if self.tagViews.count > fromIndex {
            self.tagViews.removeSubrange(fromIndex..<self.tagViews.count)
        }
    }
    
    @objc private func moreAction() {
        self.moreHandle?()
    }
}
