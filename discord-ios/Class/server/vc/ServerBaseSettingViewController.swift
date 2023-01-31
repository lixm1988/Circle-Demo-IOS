//
//  ServerBaseSettingViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/22.
//

import UIKit

class ServerBaseSettingViewController: UIViewController {

    typealias DataType = (image: String, title: String, handle: () -> Void)
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    let shapeLayer = CAShapeLayer()
    
    var collectionViewDataSource: [DataType]? {
        didSet {
            self.collectionView.reloadData()
            self.view.setNeedsLayout()
        }
    }
    var tableViewDataSource: [DataType]? {
        didSet {
            self.tableView.reloadData()
            self.tableViewHeightConstraint.constant = CGFloat(56 * (self.tableViewDataSource?.count ?? 0))
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "ServerBaseSettingViewController", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.register(UINib(nibName: "ServerBaseSettingCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        self.tableView.register(UINib(nibName: "ServerBaseSettingTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        self.mainView.layer.mask = self.shapeLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let corner: UIRectCorner = [.topLeft, .topRight]
        let path = UIBezierPath(roundedRect: self.mainView.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 16, height: 16))
        self.shapeLayer.frame = self.mainView.bounds
        self.shapeLayer.path = path.cgPath
        
        let count = self.collectionViewDataSource?.count ?? 0
        let width = count > 1 ? (count * 90 + (count - 1) * 12) : 90
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: (self.collectionView.bounds.width - CGFloat(width)) / 2, bottom: 0, right: 0)
    }
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
}

extension ServerBaseSettingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionViewDataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let cell = cell as? ServerBaseSettingCollectionViewCell, let item = self.collectionViewDataSource?[indexPath.item] {
            cell.imageView.image = UIImage(named: item.image)
            cell.label.text = item.title
        }
        return cell
    }
}

extension ServerBaseSettingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionViewDataSource?[indexPath.row].handle()
    }
}

extension ServerBaseSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? ServerBaseSettingTableViewCell, let item = self.tableViewDataSource?[indexPath.row] {
            cell.iconImageView.image = UIImage(named: item.image)
            cell.nameLabel.text = item.title
        }
        return cell
    }
}

extension ServerBaseSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableViewDataSource?[indexPath.row].handle()
    }
}
