//
//  MessageServerViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/6/29.
//

import UIKit
import HyphenateChat
import PKHUD
import MJRefresh

class MessageServerViewController: UIViewController {

    @IBOutlet private weak var bgImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var tagListView: ServerTagListView!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    private let gradientLayer = CAGradientLayer()

    private var categorys: EMCursorResult<EMCircleChannelCategory>?
    private var channelMap: [String: (publicResult: EMCursorResult<EMCircleChannel>?, privateResult: EMCursorResult<EMCircleChannel>?)] = [:]
    private var threadMap: [String: EMCursorResult<EMChatThread>] = [:]
    private var memberMap: [String: [(EMCircleUser, EMUserInfo)]] = [:]
    private var unfoldCategorySet = Set<String>()
    private var unfoldChannelSet = Set<String>()
    
    private var speakSet = Set<String>()
    private var muteSet = Set<String>()
    
    var serverId: String {
        didSet {
            self.server = nil
            self.updateServerDetail(refresh: true)
            self.loadCategoryData(refresh: true)
            self.unfoldCategorySet.removeAll()
            self.unfoldChannelSet.removeAll()
        }
    }
    
    var server: EMCircleServer?
    
    init(serverId: String) {
        self.serverId = serverId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        self.gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0).cgColor
        ]
        self.bgImageView.layer.insertSublayer(self.gradientLayer, at: 0)
        
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorStyle = .none
        self.tableView.separatorColor = UIColor.clear
        self.tableView.register(UINib(nibName: "MessageServerChannelHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "header")
        self.tableView.register(UINib(nibName: "MessageServerChannelCell", bundle: nil), forCellReuseIdentifier: "cell")
        self.tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [unowned self] in
            self.loadCategoryData(refresh: true)
        })
        self.tableView.mj_footer = MJRefreshAutoStateFooter(refreshingBlock: { [unowned self] in
            self.loadCategoryData(refresh: false)
        })
                
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateServerNotification(_:)), name: EMCircleDidUpdateServer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateChannelNotification(_:)), name: EMCircleDidCreateChannel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDestroyChannelNotification(_:)), name: EMCircleDidDestroyChannel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateChannelNotification(_:)), name: EMCircleDidUpdateChannel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDestroyThreadNotification(_:)), name: EMThreadDidDestroy, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLeftChannelNotification(_:)), name: EMCircleDidExitedChannel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didJoinChannelNotification(_:)), name: EMCircleDidJoinChannel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didCreateCategoryNotification(_:)), name: EMCircleDidCreateCategory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDestroyCategoryNotification(_:)), name: EMCircleDidDestroyCategory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateCategoryNotification(_:)), name: EMCircleDidUpdateCategory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didTransferChannelCategoryNotification(_:)), name: EMCircleDidTransferChannelCategory, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didServerMessageUnreadCountChangeNotification(_:)), name: EMCircleServerMessageUnreadCountChange, object: nil)
        
        EMClient.shared().circleManager?.add(serverDelegate: self, queue: nil)
        EMClient.shared().circleManager?.add(channelDelegate: self, queue: nil)
        EMClient.shared().circleManager?.add(categoryDelegate: self, queue: nil)
        EMClient.shared().addMultiDevices(delegate: self, queue: nil)
        EMClient.shared().chatManager?.add(self, delegateQueue: nil)
        EMClient.shared().threadManager?.add(self, delegateQueue: nil)
        VoiceChatManager.shared.addDelegate(self)
        
        self.updateServerDetail(refresh: true)
        self.loadCategoryData(refresh: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.gradientLayer.frame = self.bgImageView.bounds
    }
    
    private func updateServerDetail(refresh: Bool = false) {
        HUD.show(.progress, onView: self.view)
        ServerInfoManager.shared.getServerInfo(serverId: serverId, refresh: refresh) { [weak self] server, error in
            HUD.hide()
            guard let self = self else {
                return
            }
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
                return
            }
            if self.serverId != server?.serverId {
                return
            }
            self.server = server
            self.nameLabel.text = server?.name
            self.tagListView.setTags(server?.tags, itemHeight: self.tagListView.bounds.size.height, showType: .simple)
            self.descLabel.text = server?.desc
            self.bgImageView.setImage(withUrl: server?.background, placeholder: "message_server_bg")
            self.tableView.reloadData()
        }
    }

    @IBAction func addAction() {
        let vc = FriendInviteViewController()
        vc.didInviteHandle = { [weak self] userId, _ in
            guard let self = self else {
                return
            }
            EMClient.shared().circleManager?.inviteUserToServer(serverId: self.serverId, userId: userId, welcome: nil) { error in
                if let error = error {
                    if error.code == .repeatedOperation {
                        Toast.show("该用户已加入社区", duration: 2)
                    } else {
                        Toast.show(error.errorDescription, duration: 2)
                    }
                } else {
                    Toast.show("邀请成功", duration: 2)
                    let server = ServerInfoManager.shared.getServerInfo(serverId: self.serverId)
                    let body = EMCustomMessageBody(event: "invite_server", customExt: [
                        "server_id": self.serverId,
                        "server_name": server?.name ?? "",
                        "icon": server?.icon ?? "",
                        "desc": server?.desc ?? ""
                    ])
                    let message = EMChatMessage(conversationID: userId, from: EMClient.shared().currentUsername!, to: userId, body: body, ext: nil)
                    EMClient.shared().chatManager?.send(message, progress: nil)
                }
            }
        }
        self.presentNavigationController(rootViewController: vc)
    }
    
    @IBAction func moreAction() {
        let vc = ServerSettingViewController(serverId: self.serverId, fromViewController: self)
        self.present(vc, animated: true)
    }
    
    @IBAction func showDetailAction() {
        if let server = self.server {
            let vc = ServerDetailAlertViewController(server: server, joinHandle: nil)
            self.present(vc, animated: true)
        }
    }
    
    private func loadCategoryData(refresh: Bool) {
        if refresh {
            self.unfoldCategorySet.removeAll()
            self.unfoldChannelSet.removeAll()
            self.channelMap.removeAll()
            self.memberMap.removeAll()
        }
        EMClient.shared().circleManager?.fetchCategory(inServer: self.serverId, limit: 20, cursor: refresh ? nil : self.categorys?.cursor, completion: { result, error in
            if let error = error {
                Toast.show(error.errorDescription, duration: 2)
            } else if let result = result {
                if self.categorys != nil && !refresh {
                    self.categorys?.append(result)
                } else {
                    self.categorys = result
                }
                
                if let list = result.list {
                    for i in list where i.isDefault {
                        self.unfoldCategorySet.insert(i.categoryId)
                        self.loadChannlsData(categoryId: i.categoryId)
                    }
                }
                
                self.tableView.reloadData()
                self.tableView.mj_header?.endRefreshing()
                if let cursor = result.cursor, cursor.count > 0 {
                    self.tableView.mj_footer?.endRefreshing()
                    self.tableView.mj_footer?.isHidden = false
                } else {
                    self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    self.tableView.mj_footer?.isHidden = true
                }
            }
        })
    }
    
    private func loadChannlsData(categoryId: String) {
        guard let categoryList = self.categorys?.list, categoryList.count > 0 else {
            return
        }
        var section: Int?
        for i in 0..<categoryList.count where categoryList[i].categoryId == categoryId {
            section = i
            break
        }
        guard let section = section else {
            return
        }
        let result = self.channelMap[categoryId]
        let isPublic = result?.publicResult == nil || (result?.publicResult?.cursor != nil && (result?.publicResult?.cursor?.count)! > 0)
        if isPublic {
            EMClient.shared().circleManager?.fetchPublicChannel(inCategory: self.serverId, categoryId: categoryId, limit: 20, cursor: result?.publicResult?.cursor, completion: { result, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if let result = result {
                    if let publicResult = self.channelMap[categoryId]?.publicResult {
                        publicResult.append(result)
                    } else {
                        self.channelMap[categoryId] = (result, nil)
                    }
                    self.tableView.reloadSections([section], with: .fade)
                    self.loadChannlsData(categoryId: categoryId)
                }
            })
        } else {
            if let privateResult = result?.privateResult, privateResult.cursor?.count ?? 0 <= 0 {
                return
            }
            EMClient.shared().circleManager?.fetchVisibelPrivateChannels(inCategory: self.serverId, categoryId: categoryId, limit: 20, cursor: result?.privateResult?.cursor, completion: { result, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if let result = result {
                    if let old = self.channelMap[categoryId] {
                        if let privateResult = old.privateResult {
                            privateResult.append(result)
                        } else {
                            self.channelMap[categoryId] = (old.publicResult, result)
                        }
                        self.tableView.reloadSections([section], with: .fade)
                    }
                    if result.cursor?.count != 0 && result.count >= 20 {
                        self.loadChannlsData(categoryId: categoryId)
                    }
                }
            })
        }
    }
    
    private func reloadChannel(channelId: String) {
        if let index = self.index(channelId: channelId) {
            self.tableView.performBatchUpdates {
                self.tableView.reloadRows(at: [index], with: .fade)
            }
        }
    }
    
    @discardableResult private func removeChannel(channelId: String) -> EMCircleChannel? {
        var indexPath: IndexPath?
        var channel: EMCircleChannel?
        for i in 0..<(self.categorys?.list?.count ?? 0) {
            if let categoryId = self.categorys?.list?[i].categoryId, let result = self.channelMap[categoryId] {
                for j in 0..<(result.publicResult?.list?.count ?? 0) where result.publicResult?.list?[j].channelId == channelId {
                    indexPath = IndexPath(row: j, section: i)
                    channel = result.publicResult?.list?.remove(at: j)
                    break
                }
                if indexPath == nil {
                    for j in 0..<(result.privateResult?.list?.count ?? 0) where result.privateResult?.list?[j].channelId == channelId {
                        indexPath = IndexPath(row: j + (result.publicResult?.list?.count ?? 0), section: i)
                        channel = result.privateResult?.list?.remove(at: j)
                        break
                    }
                }
            }
        }
        
        if let indexPath = indexPath {
            self.tableView.performBatchUpdates {
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        return channel
    }
    
    private func channel(channelId: String) -> EMCircleChannel? {
        for result in self.channelMap.values {
            if let list = result.publicResult?.list {
                for channel in list where channel.channelId == channelId {
                    return channel
                }
            }
            if let list = result.privateResult?.list {
                for channel in list where channel.channelId == channelId {
                    return channel
                }
            }
        }
        return nil
    }

    private func channel(index: IndexPath) -> EMCircleChannel? {
        if let categoryId = self.categorys?.list?[index.section].categoryId, let result = self.channelMap[categoryId] {
            if index.row < result.publicResult?.list?.count ?? 0 {
                return result.publicResult?.list?[index.row] as? EMCircleChannel
            } else if index.row < (result.publicResult?.list?.count ?? 0) + (result.privateResult?.list?.count ?? 0) {
                return result.privateResult?.list?[index.row - (result.publicResult?.list?.count ?? 0)] as? EMCircleChannel
            }
        }
        return nil
    }
    
    private func index(channelId: String) -> IndexPath? {
        var indexPath: IndexPath?
        for i in 0..<(self.categorys?.list?.count ?? 0) {
            if let categoryId = self.categorys?.list?[i].categoryId, let result = self.channelMap[categoryId] {
                if let publicResult = result.publicResult?.list {
                    for j in 0..<publicResult.count where publicResult[j].channelId == channelId {
                        indexPath = IndexPath(row: j, section: i)
                        break
                    }
                }
                if indexPath == nil, let privateResult = result.privateResult?.list {
                    for j in 0..<privateResult.count where privateResult[j].channelId == channelId {
                        indexPath = IndexPath(row: j + (result.publicResult?.list?.count ?? 0), section: i)
                        break
                    }
                }
            }
        }
        return indexPath
    }
    
    private func addCategory(_ category: EMCircleChannelCategory) {
        if self.categorys?.cursor?.count ?? 0 > 0 {
            return
        }
        self.categorys?.list?.append(category)
        if let count = self.categorys?.list?.count {
            self.tableView.performBatchUpdates {
                self.tableView.insertSections([count - 1], with: .fade)
            }
        }
    }
    
    private func addThread(_ thread: EMChatThread) {
        if let channelId = thread.parentId, let item = self.threadMap[channelId] {
            item.list?.insert(thread, at: 0)
            self.reloadChannel(channelId: channelId)
        }
    }
    
    private func addChannel(_ channel: EMCircleChannel) {
        if channel.serverId != self.serverId {
            return
        }
        if self.index(channelId: channel.channelId) != nil {
            return
        }
        var section: Int?
        if let list = self.categorys?.list {
            for i in 0..<list.count where list[i].categoryId == channel.categoryId {
                section = i
                break
            }
        }
        
        if let section = section, let result = self.channelMap[channel.categoryId], let publicResult = result.publicResult {
            var index: IndexPath?
            if channel.type == .public {
                if let cursor = publicResult.cursor, cursor.count > 0 {
                    return
                }
                publicResult.list?.append(channel)
                if let list = publicResult.list {
                    index = IndexPath(row: list.count - 1, section: section)
                }
            } else if channel.type == .private {
                guard let privateResult = result.privateResult else {
                    return
                }
                if let cursor = privateResult.cursor, cursor.count > 0 {
                    return
                }
                privateResult.list?.append(channel)
                if let list = privateResult.list {
                    index = IndexPath(row: (list.count - 1) + Int(publicResult.count), section: section)
                }
            }
            
            if let index = index {
                self.tableView.performBatchUpdates {
                    self.tableView.insertRows(at: [index], with: .fade)
                }
            }
        }
    }
    
    private func addMember(channel: String, member: EMCircleUser) {
        if let userList = self.memberMap[channel] {
            for i in userList where i.0.userId == member.userId {
                return
            }
            UserInfoManager.share.queryUserInfo(userId: member.userId, loadCache: true) { userInfo, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if let userInfo = userInfo {
                    self.memberMap[channel]?.append((member, userInfo))
                    if let indexPath = self.index(channelId: channel) {
                        self.tableView.performBatchUpdates {
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                        }
                    }
                }
            }
        }
    }
    
    private func removeMembers(channel: String, members: [String]) {
        if let memberList = self.memberMap[channel] {
            let newList = memberList.filter { member in
                for i in members where member.0.userId == i {
                    return false
                }
                return true
            }
            self.memberMap[channel] = newList
            if let indexPath = self.index(channelId: channel) {
                self.tableView.performBatchUpdates {
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
    
    private func updateThreadName(threadId: String, name: String) {
        var channelId: String?
        for (key, value) in self.threadMap {
            if channelId != nil {
                break
            }
            if let list = value.list {
                for thread in list where thread.threadId == threadId {
                    thread.threadName = name
                    channelId = key
                    break
                }
            }
        }
        if let channelId = channelId {
            self.reloadChannel(channelId: channelId)
        }
    }
    
    private func removeThread(threadId: String) {
        var channelId: String?
        for (key, value) in self.threadMap {
            if channelId != nil {
                break
            }
            if let list = value.list {
                for i in 0..<list.count where list[i].threadId == threadId {
                    value.list?.remove(at: i)
                    channelId = key
                    break
                }
            }
        }
        if let channelId = channelId {
            self.reloadChannel(channelId: channelId)
        }
    }
    
    private func updateCategoryName(categoryId: String, name: String) {
        if let list = self.categorys?.list {
            for i in 0..<list.count where list[i].categoryId == categoryId {
                list[i].name = name
                self.tableView.performBatchUpdates {
                    self.tableView.reloadSections([i], with: .fade)
                }
                break
            }
        }
    }
    
    private func removeCategory(categoryId: String) {
        if let list = self.categorys?.list {
            for i in 0..<list.count where list[i].categoryId == categoryId {
                self.categorys?.list?.remove(at: i)
                self.tableView.performBatchUpdates {
                    self.tableView.deleteSections([i], with: .fade)
                }
                break
            }
        }
    }
    
    private func transferCategoryChannel(channelId: String, from: String, to: String) {
        if let channel = self.removeChannel(channelId: channelId) {
            channel.categoryId = to
            self.addChannel(channel)
        }
    }
    
    @objc private func didUpdateServerNotification(_ notification: Notification) {
        if let server = notification.object as? EMCircleServer, server.serverId == self.serverId {
            self.nameLabel.text = server.name
            self.tagListView.setTags(server.tags, itemHeight: self.tagListView.bounds.size.height, showType: .simple)
            self.descLabel.text = server.desc
            self.bgImageView.setImage(withUrl: server.background, placeholder: "message_server_bg")
        }
    }
    
    @objc private func didCreateChannelNotification(_ notification: Notification) {
        if let channel = notification.object as? EMCircleChannel {
            self.addChannel(channel)
        }
    }
    
    @objc private func didDestroyChannelNotification(_ notification: Notification) {
        if let data = notification.object as? (String, String) {
            if data.0 == self.serverId {
                self.removeChannel(channelId: data.1)
            }
        }
    }
    
    @objc private func didUpdateChannelNotification(_ notification: Notification) {
        guard let channel = notification.object as? EMCircleChannel else {
            return
        }
        self.updateChannel(channel)
    }
    
    @objc private func didJoinChannelNotification(_ notification: Notification) {
        guard let channel = notification.object as? EMCircleChannel else {
            return
        }
        if channel.type == .private {
            self.addChannel(channel)
        }
        if let currentUsername = EMClient.shared().currentUsername {
            ServerRoleManager.shared.queryServerRole(serverId: channel.serverId) { role in
                let user = EMCircleUser(userId: currentUsername, role: role)
                self.addMember(channel: channel.channelId, member: user)
            }
        }
    }
    
    @objc private func didCreateCategoryNotification(_ notification: Notification) {
        if let category = notification.object as? EMCircleChannelCategory, category.serverId == self.serverId {
            self.addCategory(category)
        }
    }
    
    @objc private func didDestroyCategoryNotification(_ notification: Notification) {
        if let obj = notification.object as? (String, String), obj.0 == self.serverId {
            self.removeCategory(categoryId: obj.1)
        }
    }
    
    @objc private func didUpdateCategoryNotification(_ notification: Notification) {
        guard let category = notification.object as? EMCircleChannelCategory, category.serverId == self.serverId, let categorys = self.categorys?.list else {
            return
        }
        for i in 0..<categorys.count where categorys[i].categoryId == category.categoryId {
            categorys[i].name = category.name
            self.tableView.performBatchUpdates {
                self.tableView.reloadSections([i], with: .fade)
            }
            break
        }
    }
    
    @objc private func didTransferChannelCategoryNotification(_ notification: Notification) {
        if let obj = notification.object as? (String, String, String, String), obj.0 == self.serverId {
            self.transferCategoryChannel(channelId: obj.3, from: obj.1, to: obj.2)
        }
    }
    
    @objc private func didServerMessageUnreadCountChangeNotification(_ notification: Notification) {
        if let serverId = notification.object as? String, serverId == self.serverId {
            self.tableView.reloadData()
        }
    }
    
    @objc private func didLeftChannelNotification(_ notification: Notification) {
        if let data = notification.object as? (String, String), data.0 == self.serverId, let channel = self.channel(channelId: data.1) {
            if channel.type == .private {
                ServerRoleManager.shared.queryServerRole(serverId: channel.serverId) { role in
                    if channel.serverId == self.serverId && role == .user {
                        self.removeChannel(channelId: data.1)
                    } else {
                        if let currentUsername = EMClient.shared().currentUsername {
                            self.removeMembers(channel: data.1, members: [currentUsername])
                        }
                    }
                }
            } else {
                if let currentUsername = EMClient.shared().currentUsername {
                    self.removeMembers(channel: data.1, members: [currentUsername])
                }
            }
        }
    }
    
    @objc private func didDestroyThreadNotification(_ notification: Notification) {
        if let threadId = notification.object as? String {
            self.removeThread(threadId: threadId)
        }
    }
    
    private func updateChannel(_ channel: EMCircleChannel) {
        if channel.serverId != self.serverId {
            return
        }
        var section: Int?
        for i in 0..<(self.categorys?.list?.count ?? 0) where self.categorys?.list?[i].categoryId == channel.categoryId {
            section = i
            break
        }
        
        if let section = section, let result = self.channelMap[channel.categoryId] {
            if let publicList = result.publicResult?.list {
                for i in 0..<publicList.count where publicList[i].channelId == channel.channelId {
                    result.publicResult?.list?[i] = channel
                    self.tableView.performBatchUpdates {
                        self.tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .fade)
                    }
                    return
                }
            }
            if let privateList = result.privateResult?.list {
                for i in 0..<privateList.count where privateList[i].channelId == channel.channelId {
                    result.privateResult?.list?[i] = channel
                    self.tableView.performBatchUpdates {
                        self.tableView.reloadRows(at: [IndexPath(row: i + (result.publicResult?.list?.count ?? 0), section: section)], with: .fade)
                    }
                    return
                }
            }
        }
    }
    
    deinit {
        EMClient.shared().circleManager?.remove(channelDelegate: self)
        EMClient.shared().remove(self)
        EMClient.shared().chatManager?.remove(self)
        EMClient.shared().threadManager?.remove(self)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: UITableViewDataSource
extension MessageServerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let category = self.categorys?.list?[section]
        if category?.isDefault == true {
            return 1
        }
        return 36
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let category = self.categorys?.list?[section], !category.isDefault else {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        if let view = view as? MessageServerChannelHeader {
            view.name = category.name
            view.isFold = !self.unfoldCategorySet.contains(category.categoryId)
            view.createEnable = self.server?.owner == EMClient.shared().currentUsername
            view.createHandle = { [unowned self] in
                let vc = ChannelCreateViewController(serverId: self.serverId, categoryId: category.categoryId)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            view.foldHandle = { [unowned self, view] in
                view.isFold = !view.isFold
                if view.isFold {
                    self.unfoldCategorySet.remove(category.categoryId)
                    self.tableView.performBatchUpdates {
                        self.tableView.reloadSections([section], with: .fade)
                    }
                } else {
                    self.unfoldCategorySet.insert(category.categoryId)
                    if self.channelMap[category.categoryId] == nil {
                        self.loadChannlsData(categoryId: category.categoryId)
                    } else {
                        self.tableView.performBatchUpdates {
                            self.tableView.reloadSections([section], with: .fade)
                        }
                    }
                }
            }
            view.longPressHandle = { [unowned self] in
                ServerRoleManager.shared.queryServerRole(serverId: self.serverId) { role in
                    if role == .owner {
                        let vc = CategorySettingViewController(category: category, fromViewController: self)
                        self.present(vc, animated: true)
                    }
                }
            }
        }
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.categorys?.list?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let categoryId = self.categorys?.list?[section].categoryId {
            if self.unfoldCategorySet.contains(categoryId), let channels = self.channelMap[categoryId] {
                return (channels.publicResult?.list?.count ?? 0) + (channels.privateResult?.list?.count ?? 0)
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? MessageServerChannelCell {
            let item = self.channel(index: indexPath)
            if let item = item {
                cell.channel = item
                if VoiceChatManager.shared.currentChannel?.channelId == item.channelId {
                    cell.speakSet = self.speakSet
                    cell.muteSet = self.muteSet
                } else {
                    cell.speakSet = nil
                    cell.muteSet = nil
                }
                if self.unfoldChannelSet.contains(item.channelId) {
                    cell.isFold = false
                    if item.mode == .chat {
                        if let value = self.threadMap[item.channelId], let list = value.list {
                            cell.setThreads(threads: list, hasNoMoreData: value.cursor?.count ?? 0 <= 0)
                        }
                    } else if item.mode == .voice {
                        if let value = self.memberMap[item.channelId] {
                            cell.setMembers(value)
                        }
                    }
                } else {
                    cell.isFold = true
                }
            }
            cell.channelClickHandle = { [unowned self] channel in
                self.channelClickAction(channel: channel, indexPath: indexPath)
            }
            cell.memberClickHandle = { [unowned self] channel, member in
                self.memberClickAction(channel: channel, member: member)
            }
            cell.foldClickHandle = { [unowned self, unowned cell] channel in
                self.foldClickAction(channel: channel, cell: cell, indexPath: indexPath)
            }
            cell.threadClickHandle = { [unowned self] thread in
                self.threadClickAction(thread: thread, channel: item)
            }
            cell.moreClickHandle = { [unowned self] channel in
                self.moreClickAction(channel: channel, indexPath: indexPath)
            }
            cell.channelLongPressHandle = { [unowned self] channel in
                let vc = ChannelSettingViewController(serverId: channel.serverId, channelId: channel.channelId, fromViewController: self)
                self.present(vc, animated: true)
            }
        }
        return cell
    }

    private func channelClickAction(channel: EMCircleChannel, indexPath: IndexPath) {
        if channel.mode == .chat {
            EMClient.shared().circleManager?.checkSelfIsInChannel(serverId: channel.serverId, channelId: channel.channelId) { isJoined, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if isJoined {
                    let vc = ChatViewController(chatType: .channel(serverId: channel.serverId, channelId: channel.channelId))
                    self.navigationController?.pushViewController(vc, animated: true)
                    NotificationCenter.default.post(name: EMCircleServerMessageUnreadCountChange, object: self.serverId)
                } else {
                    self.showChatChannelJoinAlert(serverId: channel.serverId, channelId: channel.channelId)
                }
            }
        } else if channel.mode == .voice {
            if let server = self.server {
                let vc = VoiceChannelViewController(showType: .detail(server: server, channel: channel), fromViewController: self)
                self.present(vc, animated: true)
            }
        }
    }
    
    private func memberClickAction(channel: EMCircleChannel, member: (EMCircleUser, EMUserInfo)) {
        if member.0.userId == EMClient.shared().currentUsername {
            return
        }
        ServerRoleManager.shared.queryServerRole(serverId: channel.serverId) { role in
            EMClient.shared().presenceManager?.fetchPresenceStatus([member.0.userId], completion: { presences, _ in
                var state: UserStatusView.Status = .offline
                if let presences = presences {
                    for i in presences where i.publisher == member.0.userId {
                        state = i.userStatus
                        break
                    }
                }
                DispatchQueue.main.async {
                    let vc = ServerUserMenuViewController(userId: member.0.userId, showType: .channel(serverId: channel.serverId, channelId: channel.channelId), role: role, targetRole: member.0.role, onlineState: state, isMute: false)
                    vc.didKickHandle = { userId in
                        self.removeMembers(channel: channel.channelId, members: [userId])
                    }
                    self.present(vc, animated: true)
                }
            })
        }
    }

    private func foldClickAction(channel: EMCircleChannel, cell: MessageServerChannelCell, indexPath: IndexPath) {
        if self.unfoldChannelSet.contains(channel.channelId) {
            self.unfoldChannelSet.remove(channel.channelId)
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            cell.isFold = true
            return
        }
        if channel.mode == .chat {
            EMClient.shared().circleManager?.checkSelfIsInChannel(serverId: channel.serverId, channelId: channel.channelId) { isJoined, error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else if isJoined {
                    self.unfoldChannelSet.insert(channel.channelId)
                    cell.isFold = false
                    if self.threadMap[channel.channelId] != nil {
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                    } else {
                        HUD.show(.progress, onView: self.view)
                        EMClient.shared().threadManager?.getChatThreadsFromServer(withParentId: channel.channelId, cursor: nil, pageSize: 20) { result, error in
                            HUD.hide()
                            if let error = error {
                                Toast.show(error.errorDescription, duration: 2)
                                return
                            }
                            if let result = result, let list = result.list {
                                if list.count < 20 {
                                    result.cursor = nil
                                }
                                self.threadMap[channel.channelId] = result
                                self.tableView.reloadRows(at: [indexPath], with: .fade)
                            }
                        }
                    }
                } else {
                    self.showChatChannelJoinAlert(serverId: channel.serverId, channelId: channel.channelId)
                }
            }
        } else if channel.mode == .voice {
            self.unfoldChannelSet.insert(channel.channelId)
            cell.isFold = false
            if self.memberMap[channel.channelId] != nil {
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            } else {
                HUD.show(.progress, onView: self.view)
                EMClient.shared().circleManager?.fetchChannelMembers(channel.serverId, channelId: channel.channelId, limit: 20, cursor: nil, completion: { result, error in
                    HUD.hide()
                    if let error = error {
                        Toast.show(error.errorDescription, duration: 2)
                        return
                    }
                    if let result = result, let list = result.list {
                        var userIds: [String] = []
                        for i in list {
                            userIds.append(i.userId)
                        }
                        UserInfoManager.share.queryUserInfo(userIds: userIds) {
                            var userInfos: [(EMCircleUser, EMUserInfo)] = []
                            for i in list {
                                if let userInfo = UserInfoManager.share.userInfo(userId: i.userId) {
                                    userInfos.append((i, userInfo))
                                }
                            }
                            self.memberMap[channel.channelId] = userInfos
                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                        }
                    }
                })
            }
        }
    }
    
    private func showChatChannelJoinAlert(serverId: String, channelId: String) {
        let vc = ServerJoinAlertViewController(showType: .joinChannel(serverId: serverId, channelId: channelId, joinHandle: { channel in
            if channel.mode == .chat {
                let chatVc = ChatViewController(chatType: .channel(serverId: channel.serverId, channelId: channel.channelId))
                self.navigationController?.pushViewController(chatVc, animated: true)
            }
        }))
        self.present(vc, animated: true)
    }
    
    private func threadClickAction(thread: EMChatThread, channel: EMCircleChannel?) {
        let threadId: String? = thread.threadId
        if let threadId = threadId {
            EMClient.shared().threadManager?.joinChatThread(threadId) { [weak self] _, error in
                guard let self = self else {
                    return
                }
                if let error = error, error.code != .userAlreadyExist {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    if let channel = channel {
                        let vc = ChatViewController(chatType: .thread(threadId: ChannelThreadId(serverId: self.serverId, channelId: channel.channelId, threadId: threadId)))
                        vc.subtitle = "# \(channel.name)"
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }
    }
    
    private func moreClickAction(channel: EMCircleChannel, indexPath: IndexPath) {
        if self.unfoldChannelSet.contains(channel.channelId), let oldResult = self.threadMap[channel.channelId] {
            HUD.show(.progress, onView: self.view)
            EMClient.shared().threadManager?.getChatThreadsFromServer(withParentId: channel.channelId, cursor: oldResult.cursor, pageSize: 20) { result, error in
                HUD.hide()
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                    return
                }
                if let result = result, let list = result.list {
                    if list.count < 20 {
                        result.cursor = nil
                    }
                    oldResult.append(result)
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
}

extension MessageServerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let channel = self.channel(index: indexPath)
        let channelId = channel?.channelId
        if let channelId = channelId, self.unfoldChannelSet.contains(channelId) {
            if channel?.mode == .chat, let result = self.threadMap[channelId] {
                if let cursor = result.cursor, cursor.count > 0 {
                    return CGFloat(76 + 40 + result.count * 40)
                } else {
                    return CGFloat(76 + result.count * 40)
                }
            } else if channel?.mode == .voice, let members = self.memberMap[channelId] {
                return CGFloat(76 + members.count * 40)
            }
        }
        return 76
    }
}

extension MessageServerViewController: EMCircleManagerServerDelegate {
    func onServerUpdated(_ event: EMCircleServerEvent) {
        if event.serverId == self.serverId {
            self.nameLabel.text = event.serverName
            self.descLabel.text = event.serverDesc
        }
    }
}

extension MessageServerViewController: EMCircleManagerChannelDelegate {
    func onChannelCreated(_ serverId: String, channelId: String, creator: String) {
        EMClient.shared().circleManager?.fetchChannelDetail(serverId, channelId: channelId) { channel, _ in
            if let channel = channel, channel.serverId == self.serverId {
                self.addChannel(channel)
            }
        }
    }
    
    func onChannelDestroyed(_ serverId: String, channelId: String, initiator: String) {
        if serverId != self.serverId {
            return
        }
        self.removeChannel(channelId: channelId)
    }
    
    func onChannelUpdated(_ serverId: String, channelId: String, name: String, desc: String, initiator: String) {
        if serverId != self.serverId {
            return
        }
        if let channel = self.channel(channelId: channelId) {
            channel.name = name
            channel.desc = desc
            self.reloadChannel(channelId: channelId)
        }
    }
    
    func onMemberJoinedChannel(_ serverId: String, channelId: String, member: EMCircleUser) {
        if serverId == self.serverId {
            self.addMember(channel: channelId, member: member)
        }
    }
    
    func onMemberLeftChannel(_ serverId: String, channelId: String, member: String) {
        if serverId == self.serverId {
            self.removeMembers(channel: channelId, members: [member])
        }
    }
    
    func onMemberRemoved(fromChannel serverId: String, channelId: String, member: String, initiator: String) {
        if serverId == self.serverId {
            self.removeMembers(channel: channelId, members: [member])
            if member == EMClient.shared().currentUsername, let channel = self.channel(channelId: channelId), channel.type == .private {
                ServerRoleManager.shared.queryServerRole(serverId: channel.serverId) { role in
                    if channel.serverId == self.serverId && role == .user {
                        self.removeChannel(channelId: channelId)
                    }
                }
            }
        }
    }
}

// MARK: - EMCircleManagerCategoryDelegate
extension MessageServerViewController: EMCircleManagerCategoryDelegate {
    func onCategoryCreated(_ serverId: String, categoryId: String, categoryName: String) {
        if serverId != self.serverId {
            return
        }
        let category = EMCircleChannelCategory()
        category.serverId = serverId
        category.categoryId = categoryId
        category.name = categoryName
        self.addCategory(category)
    }
    
    func onCategoryDestroyed(_ serverId: String, categoryId: String, initiator: String) {
        if serverId != self.serverId {
            return
        }
        self.removeCategory(categoryId: categoryId)
    }
    
    func onCategoryUpdated(_ serverId: String, categoryId: String, categoryName: String, initiator: String) {
        if serverId != self.serverId {
            return
        }
        self.updateCategoryName(categoryId: categoryId, name: categoryName)
    }
    
    func onCategoryTransferredChannel(_ serverId: String, from fromCategoryId: String, to toCategoryId: String, channelId: String, initiator: String) {
        if serverId != self.serverId {
            return
        }
        self.transferCategoryChannel(channelId: channelId, from: fromCategoryId, to: toCategoryId)
    }
}

// MARK: - EMChatManagerDelegate
extension MessageServerViewController: EMChatManagerDelegate {
    func conversationListDidUpdate(_ aConversationList: [EMConversation]) {
        self.tableView.reloadData()
    }
    
    func onConversationRead(_ from: String, to: String) {
        self.tableView.reloadData()
    }
    
    func messagesDidReceive(_ aMessages: [EMChatMessage]) {
        self.tableView.reloadData()
    }
}

// MARK: - EMThreadManagerDelegate
extension MessageServerViewController: EMThreadManagerDelegate {
    func onChatThreadCreate(_ event: EMChatThreadEvent) {
        if let thread = event.chatThread {
            self.addThread(thread)
        }
    }
    
    func onChatThreadUpdate(_ event: EMChatThreadEvent) {
        if event.type == .update, let threadId = event.chatThread.threadId, let name = event.chatThread.threadName {
            self.updateThreadName(threadId: threadId, name: name)
        }
    }
    
    func onChatThreadDestroy(_ event: EMChatThreadEvent) {
        if event.type == .delete, let threadId = event.chatThread.threadId {
            self.removeThread(threadId: threadId)
        }
    }
}

// MARK: - EMMultiDevicesDelegate
extension MessageServerViewController: EMMultiDevicesDelegate {
    func multiDevicesCircleServerEventDidReceive(_ aEvent: EMMultiDevicesEvent, serverId: String, ext aExt: Any?) {
        if serverId != self.serverId {
            return
        }
        switch aEvent {
        case .circleServerUpdate:
            self.updateServerDetail(refresh: true)
        default:
            break
        }
    }
    
    func multiDevicesCircleCategoryEventDidReceive(_ aEvent: EMMultiDevicesEvent, serverId aServerId: String, categoryId: String, channelId aChannelId: String, ext aExt: Any?) {
        if serverId != self.serverId {
            return
        }
        switch aEvent {
        case .circleCategoryCreate:
            if let name = (aExt as? [String])?.first {
                let category = EMCircleChannelCategory()
                category.serverId = serverId
                category.categoryId = categoryId
                category.name = name
                self.addCategory(category)
            }
        case .circleCategoryDestroy:
            self.removeCategory(categoryId: categoryId)
        case .circleCategoryUpdate:
            if let name = (aExt as? [String])?.first {
                self.updateCategoryName(categoryId: categoryId, name: name)
            }
        case .circleCategoryTransferChannel:
            self.transferCategoryChannel(channelId: aChannelId, from: "", to: categoryId)
        default:
            break
        }
    }
    
    func multiDevicesCircleChannelEventDidReceive(_ aEvent: EMMultiDevicesEvent, channelId: String, ext aExt: Any?) {
        switch aEvent {
        case .circleChannelDestroy:
            self.removeChannel(channelId: channelId)
        case .circleChannelUpdate:
            if let channel = self.channel(channelId: channelId) {
                EMClient.shared().circleManager?.fetchChannelDetail(channel.serverId, channelId: channelId, completion: { channel, _ in
                    if let channel = channel {
                        self.updateChannel(channel)
                    }
                })
            }
        case .circleChannelCreate, .circleChannelJoin:
            EMClient.shared().circleManager?.fetchChannelDetail(self.serverId, channelId: channelId, completion: { channel, _ in
                if let channel = channel {
                    self.addChannel(channel)
                }
            })
        case .circleChannelExit:
            if let channel = self.channel(channelId: channelId), channel.type == .private {
                ServerRoleManager.shared.queryServerRole(serverId: channel.serverId) { role in
                    if channel.serverId == self.serverId && role == .user {
                        self.removeChannel(channelId: channelId)
                    }
                }
            }
        case .circleChannelRemoveUser:
            if let channel = self.channel(channelId: channelId), channel.mode == .voice, let members = aExt as? [String] {
                self.removeMembers(channel: channelId, members: members)
            }
        default:
            break
        }
    }
}

// MARK: - VoiceChatManagerDelegate
extension MessageServerViewController: VoiceChatManagerDelegate {
    func voiceManagerDidJoinChannel(channel: String) {
        self.reloadChannel(channelId: channel)
    }
    
    func voiceManagerDidLeaveChannel(channel: String) {
        self.reloadChannel(channelId: channel)
    }
    
    func voiceManagerDidAudioMuted(channel: String, username: String, muted: Bool) {
        if muted {
            self.muteSet.insert(username)
        } else {
            self.muteSet.remove(username)
        }
        self.cell(for: channel)?.muteSet = self.muteSet
    }
    
    func voiceManagerDidUserSpeak(channel: String, usernames: [String]) {
        for username in usernames {
            self.speakSet.insert(username)
        }
        self.cell(for: channel)?.speakSet = self.speakSet
    }
    
    func voiceManagerDidUserSpeakEnd(channel: String, usernames: [String]) {
        for username in usernames {
            self.speakSet.remove(username)
        }
        self.cell(for: channel)?.speakSet = self.speakSet
    }
    
    private func cell(for channelId: String) -> MessageServerChannelCell? {
        if let indexPath = self.index(channelId: channelId), let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            for visiableIndexPath in indexPathsForVisibleRows where visiableIndexPath == indexPath {
                return self.tableView.cellForRow(at: indexPath) as? MessageServerChannelCell
            }
        }
        return nil
    }
}
