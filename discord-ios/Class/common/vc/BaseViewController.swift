//
//  BaseViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/27.
//

import UIKit

class BaseViewController: UIViewController {
    
    private var titleView: NavigationTitleView?
    
    var titleViewLeftInset: CGFloat = 0 {
        didSet {
            self.view.setNeedsLayout()
        }
    }
    var titleViewRightInset: CGFloat = 48 {
        didSet {
            self.view.setNeedsLayout()
        }
    }
    
    var titleLeftImageName: String? {
        didSet {
            self.createTitleView()
            self.titleView?.titleLeftImageName = titleLeftImageName
        }
    }
    
    override var title: String? {
        didSet {
            self.createTitleView()
            self.titleView?.title = title
        }
    }
    
    var subtitle: String? {
        didSet {
            self.createTitleView()
            self.titleView?.subtitle = subtitle
        }
    }
    
    private func createTitleView() {
        if self.titleView == nil {
            self.titleView = NavigationTitleView()
            self.navigationItem.titleView = self.titleView
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let navigationBar = self.navigationController?.navigationBar {
            self.titleView!.frame = CGRect(x: self.titleViewLeftInset, y: 0, width: navigationBar.frame.width - self.titleViewLeftInset - self.titleViewRightInset, height: navigationBar.frame.height)
        }
    }
}
