//
//  SquareSearchView.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/21.
//

import UIKit
import SnapKit

class SquareSearchView: UIView {

    enum SearchType {
        case name
        case tag
    }
    
    private let label = UILabel()
    private let textField = UITextField()
    private let placeholderLabel = UILabel()
    private let searchImageView = UIImageView(image: UIImage(named: "search_white"))
    private let backButton = UIButton()
    private let searchButton = UIButton()
    private let clearButton = UIButton()
    private let changeButton = UIButton()
    private let searchTypeLabel = UILabel()
    private let searchChangeImageView = UIImageView(image: UIImage(named: "search_change"))
    
    public var didBeginEditing: (() -> Void)?
    public var didBeginSearch: ((_ text: String) -> Void)?
    public var didCancelSearch: (() -> Void)?
    
    public var searchType: SearchType = .name {
        didSet {
            self.searchTypeLabel.text = self.searchType == .name ? "社区名称" : "社区标签"
        }
    }
    
    public var isSearching = false {
        didSet {
            self.searchStateChangeAnimation()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.label.text = "广场"
        self.label.textColor = UIColor.white
        self.label.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(self.label)
        
        self.textField.layer.cornerRadius = 15
        self.textField.backgroundColor = UIColor(white: 1, alpha: 0.2)
        self.textField.textColor = UIColor.white
        self.textField.delegate = self
        self.textField.returnKeyType = .search
        self.textField.leftViewMode = .always
        self.addSubview(self.textField)
        
        self.setupChangeButton()
        self.textField.leftView = self.changeButton
        
        self.placeholderLabel.text = "搜索社区"
        self.placeholderLabel.font = UIFont.systemFont(ofSize: 15)
        self.placeholderLabel.textColor = UIColor(white: 1, alpha: 0.75)
        self.textField.addSubview(self.placeholderLabel)
        self.textField.addSubview(self.searchImageView)
        
        self.backButton.setImage(UIImage(named: "back_white"), for: .normal)
        self.backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        self.addSubview(self.backButton)
        
        self.searchButton.setTitle("搜索", for: .normal)
        self.searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.searchButton.setTitleColor(UIColor(named: ColorName_34B76B), for: .normal)
        self.searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        self.searchButton.alpha = 0
        self.addSubview(self.searchButton)
        
        self.clearButton.setImage(UIImage(named: "search_clean"), for: .normal)
        self.clearButton.addTarget(self, action: #selector(clearAction), for: .touchUpInside)
        self.clearButton.isHidden = true
        self.addSubview(self.clearButton)
        
        self.label.snp.makeConstraints { make in
            make.left.equalTo(26)
            make.centerY.equalTo(self)
        }
        self.searchImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.right.equalTo(-8)
            make.centerY.equalTo(self.textField)
        }
        self.backButton.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.width.height.equalTo(28)
            make.centerY.equalTo(self)
        }
        self.searchButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.centerY.equalTo(self)
        }
        self.clearButton.snp.makeConstraints { make in
            make.right.equalTo(self.textField.snp.right).offset(-6)
            make.width.height.equalTo(18)
            make.centerY.equalTo(self.textField)
        }
        
        self.searchStateChangeAnimation()
        
        self.textField.addTarget(self, action: #selector(textChangeAction(textField:)), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func resignFirstResponder() -> Bool {
        return self.textField.resignFirstResponder()
    }
    
    private func setupChangeButton() {
        self.changeButton.addTarget(self, action: #selector(changeAction), for: .touchUpInside)
        
        self.searchTypeLabel.textColor = .white.withAlphaComponent(0.75)
        self.searchTypeLabel.font = UIFont.systemFont(ofSize: 14)
        self.searchTypeLabel.text = self.searchType == .name ? "社区名称" : "社区标签"
        self.changeButton.addSubview(self.searchTypeLabel)
        self.changeButton.addSubview(self.searchChangeImageView)
        
        let view = UIView()
        view.backgroundColor = .white
        self.changeButton.addSubview(view)
        
        self.searchTypeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.changeButton)
            make.left.equalTo(16)
        }
        
        self.searchChangeImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self.changeButton)
            make.left.equalTo(self.searchTypeLabel.snp.right).offset(5)
        }
        
        view.snp.makeConstraints { make in
            make.centerY.equalTo(self.changeButton)
            make.left.equalTo(self.searchChangeImageView.snp.right).offset(5)
            make.width.equalTo(1)
            make.height.equalTo(16)
            make.right.equalTo(-5)
        }
    }
    
    @objc private func backAction() {
        self.textField.resignFirstResponder()
        self.clearAction()
        self.isSearching = false
        self.placeholderLabel.isHidden = false
        self.didCancelSearch?()
    }
    
    @objc private func searchAction() {
        if let text = self.textField.text, text.count > 0 {
            self.textField.resignFirstResponder()
            self.didBeginSearch?(text)
        }
    }
    
    @objc private func changeAction() {
        UIView.animate(withDuration: 0.25) {
            self.searchChangeImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }
        let bubbleView = BubbleMenuView(baseView: self.changeButton)
        bubbleView.addMenuItem(image: nil, title: "社区名称", itemType: self.searchType == .name ? .selected : .normal) { [unowned self] in
            self.searchType = .name
        }
        bubbleView.addMenuItem(image: nil, title: "社区标签", itemType: self.searchType == .tag ? .selected : .normal) { [unowned self] in
            self.searchType = .tag
        }
        bubbleView.willRemoveHandle = { [unowned self] in
            UIView.animate(withDuration: 0.25) {
                self.searchChangeImageView.transform = CGAffineTransform.identity
            }
        }
        bubbleView.show()
    }
    
    @objc private func clearAction() {
        self.textField.text = nil
        self.clearButton.isHidden = true
    }
    
    private func setupShow() {
        if self.isSearching {
            self.label.alpha = 0
            self.searchImageView.alpha = 0
            self.backButton.alpha = 1
            self.searchButton.alpha = 1
            self.changeButton.alpha = 1
        } else {
            self.label.alpha = 1
            self.searchImageView.alpha = 1
            self.backButton.alpha = 0
            self.searchButton.alpha = 0
            self.changeButton.alpha = 0
        }
    }
    
    private func setupLayout() {
        if self.isSearching {
            self.textField.snp.remakeConstraints { make in
                make.edges.equalTo(UIEdgeInsets(top: 9, left: 48, bottom: 9, right: 63))
            }
            self.placeholderLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(self.textField)
                make.left.equalTo(self.changeButton.snp.right).offset(2)
            }
            self.placeholderLabel.text = "搜索"
        } else {
            self.textField.snp.remakeConstraints { make in
                make.edges.equalTo(UIEdgeInsets(top: 9, left: 72, bottom: 9, right: 22))
            }
            self.placeholderLabel.snp.remakeConstraints { make in
                make.center.equalTo(self.textField)
            }
            self.placeholderLabel.text = "搜索社区"
        }
    }
    
    private func searchStateChangeAnimation() {
        self.setupLayout()
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
            self.setupShow()
        }
    }
    
    @objc private func textChangeAction(textField: UITextField) {
        var hidden = false
        if let text = self.textField.text, text.count > 0 {
            hidden = true
        }
        self.placeholderLabel.isHidden = hidden
        self.clearButton.isHidden = !hidden
    }
}

extension SquareSearchView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.isSearching = true
        self.didBeginEditing?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = self.textField.text, text.count > 0 {
            self.didBeginSearch?(text)
        }
        return true
    }
}
