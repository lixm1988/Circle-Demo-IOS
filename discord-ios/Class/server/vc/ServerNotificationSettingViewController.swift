//
//  ServerNotificationSettingViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/22.
//

import UIKit
import HyphenateChat

class ServerNotificationSettingViewController: BaseViewController {
    
    private let tableView = UITableView(frame: CGRect.zero, style: .plain)
    private let dataList: [String] = ["所有消息", "无通知"]
    
    private var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    private let showType: ServerStratum
    
    init(showType: ServerStratum) {
        self.showType = showType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: ColorName_181818)
        
        switch self.showType {
        case .server:
            self.title = "通知设定"
        case .channel(_, let channelId):
            self.title = "频道通知设定"
            EMClient.shared().pushManager?.getSilentMode(forConversation: channelId, conversationType: .groupChat, completion: { result, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if let result = result {
                    self.selectedIndexPath = IndexPath(row: result.remindType == .none ? 1 : 0, section: 0)
                    self.tableView.reloadData()
                }
            })
        }
        
        self.tableView.rowHeight = 56
        self.tableView.backgroundColor = .clear
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "ServerChooseCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let y = self.navigationController?.navigationBar.frame.maxY ?? 0
        self.tableView.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: self.view.bounds.height - y)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension ServerNotificationSettingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? ServerChooseCell {
            cell.label.text = self.dataList[indexPath.row]
            cell.isSelect = self.selectedIndexPath == indexPath
        }
        return cell
    }
}

extension ServerNotificationSettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let param = EMSilentModeParam(paramType: .remindType)
        if indexPath.row == 0 {
            param.remindType = .all
        } else {
            param.remindType = .none
        }
        switch self.showType {
        case .channel(_, let channelId):
            EMClient.shared().pushManager?.setSilentModeForConversation(channelId, conversationType: .groupChat, params: param, completion: { _, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    self.selectedIndexPath = indexPath
                    tableView.reloadData()
                }
            })
        default:
            break
        }
    }
}
