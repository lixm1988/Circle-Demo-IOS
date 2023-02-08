//
//  ChannelChangeGroupViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/12/19.
//

import UIKit
import MJRefresh
import HyphenateChat
import PKHUD

class ChannelChangeGroupViewController: BaseViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private let serverId: String
    private var categoryId: String?
    private let channelId: String
    
    private var result: EMCursorResult<EMCircleCategory>?
    
    init(serverId: String, channelId: String) {
        self.serverId = serverId
        self.channelId = channelId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "更改频道分组"
        self.view.backgroundColor = UIColor(named: ColorName_181818)
        
        self.tableView.backgroundColor = .clear
        self.tableView.rowHeight = 56
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "ServerChooseCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.loadData(refresh: true)
        })
        self.tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadData(refresh: false)
        })
        self.view.addSubview(self.tableView)
        
        self.loadData(refresh: true)
        
        EMClient.shared().circleManager?.fetchChannelDetail(self.serverId, channelId: self.channelId, completion: { channel, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else {
                self.categoryId = channel?.categoryId
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let y = self.navigationController?.navigationBar.frame.maxY ?? 0
        self.tableView.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: self.view.bounds.height - y)
    }
    
    private func loadData(refresh: Bool) {
        EMClient.shared().circleManager?.fetchCategories(inServer: self.serverId, limit: 20, cursor: refresh ? nil : self.result?.cursor, completion: { result, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let result = result {
                if let old = self.result {
                    old.append(result)
                } else {
                    self.result = result
                }
                self.tableView.reloadData()
                self.tableView.mj_header?.endRefreshing()
                if result.cursor?.count ?? 0 <= 0 || result.list?.count ?? 0 < 20 {
                    self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                } else {
                    self.tableView.mj_footer?.endRefreshing()
                }
            }
        })
    }
}

extension ChannelChangeGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.result?.list?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? ServerChooseCell {
            let item = self.result?.list?[indexPath.row]
            if item?.isDefault == true {
                cell.label.text = "不属于任何分组"
            } else {
                cell.label.text = item?.name
            }
            cell.isSelect = item?.categoryId == self.categoryId
        }
        return cell
    }
}

extension ChannelChangeGroupViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let category = self.result?.list?[indexPath.row] {
            HUD.show(.progress)
            EMClient.shared().circleManager?.transferChannel(self.serverId, channelId: self.channelId, newCategoryId: category.categoryId, completion: { error in
                HUD.hide()
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    let old = self.categoryId
                    self.categoryId = category.categoryId
                    tableView.reloadData()
                    NotificationCenter.default.post(name: EMCircleDidTransferChannelCategory, object: (self.serverId, old, self.categoryId, self.channelId))
                }
            })
        }
    }
}
