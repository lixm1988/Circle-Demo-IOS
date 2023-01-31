//
//  ServerEditViewController.swift
//  discord-ios
//
//  Created by 冯钊 on 2022/11/23.
//

import UIKit
import HyphenateChat
import TZImagePickerController
import PKHUD

class ServerEditViewController: BaseViewController {

    private let serverId: String
    
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    init(serverId: String) {
        self.serverId = serverId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "编辑社区"
        
        ServerInfoManager.shared.getServerInfo(serverId: self.serverId, refresh: false) { server, _ in
            self.avatarImageView.setImage(withUrl: server?.icon, placeholder: "server_head_placeholder")
            self.bgImageView.setImage(withUrl: server?.background, placeholder: "message_server_bg")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func bgAction() {
        PHPhotoLibrary.request {
            if let vc = TZImagePickerController(maxImagesCount: 1, delegate: nil) {
                let width: CGFloat = 400
                vc.allowPickingOriginalPhoto = false
                vc.allowPickingVideo = false
                vc.photoWidth = width
                vc.didFinishPickingPhotosHandle = { images, _, _ in
                    guard let image = images?.first else {
                        return
                    }
                    let height: CGFloat = image.size.height / image.size.width * 400
                    UIGraphicsBeginImageContext(CGSize(width: width, height: height))
                    image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    guard let newImage = newImage else {
                        return
                    }
                    self.avatarImageView.image = newImage
                    HUD.show(.progress, onView: self.view)
                    HTTP.uploadImage(image: newImage) { path, error in
                        if let error = error {
                            HUD.hide(animated: true)
                            Toast.show(error.localizedDescription, duration: 2)
                        } else if let path = path {
                            let attribute = EMCircleServerAttribute()
                            attribute.background = path
                            EMClient.shared().circleManager?.updateServer(self.serverId, attribute: attribute) { server, error in
                                HUD.hide()
                                if let error = error {
                                    Toast.show(error.errorDescription, duration: 2)
                                } else {
                                    Toast.show("修改成功", duration: 2)
                                    if let server = server {
                                        ServerInfoManager.shared.saveServerInfo(servers: [server])
                                        self.bgImageView.image = newImage
                                        NotificationCenter.default.post(name: EMCircleDidUpdateServer, object: server)
                                    }
                                }
                            }
                        } else {
                            HUD.hide(animated: true)
                            Toast.show("图片上传失败", duration: 2)
                        }
                    }
                }
                self.present(vc, animated: true)
            }
        }
    }
    
    @IBAction func iconAction() {
        PHPhotoLibrary.request {
            if let vc = TZImagePickerController(maxImagesCount: 1, delegate: nil) {
                vc.allowPickingOriginalPhoto = false
                vc.allowPickingVideo = false
                vc.allowCrop = true
                vc.photoWidth = 200
                vc.didFinishPickingPhotosHandle = { images, _, _ in
                    guard let image = images?.first else {
                        return
                    }
                    UIGraphicsBeginImageContext(CGSize(width: 200, height: 200))
                    image.draw(in: CGRect(x: 0, y: 0, width: 200, height: 200))
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    guard let newImage = newImage else {
                        return
                    }
                    self.avatarImageView.image = newImage
                    HUD.show(.progress, onView: self.view)
                    HTTP.uploadImage(image: newImage) { path, error in
                        if let error = error {
                            HUD.hide(animated: true)
                            Toast.show(error.localizedDescription, duration: 2)
                        } else if let path = path {
                            let attribute = EMCircleServerAttribute()
                            attribute.icon = path
                            EMClient.shared().circleManager?.updateServer(self.serverId, attribute: attribute) { server, error in
                                HUD.hide()
                                if let error = error {
                                    Toast.show(error.errorDescription, duration: 2)
                                } else {
                                    Toast.show("修改成功", duration: 2)
                                    if let server = server {
                                        ServerInfoManager.shared.saveServerInfo(servers: [server])
                                        self.avatarImageView.image = newImage
                                        NotificationCenter.default.post(name: EMCircleDidUpdateServer, object: server)
                                    }
                                }
                            }
                        } else {
                            HUD.hide(animated: true)
                            Toast.show("图片上传失败", duration: 2)
                        }
                    }
                }
                self.present(vc, animated: true)
            }
        }
    }
    
    @IBAction func infoAction() {
        let vc = ServerInfoEditViewController(serverId: self.serverId)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func settingAction() {
        let vc = ServerPermissionSettingViewController(showType: .server(serverId: self.serverId))
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func destroyAction() {
        let serverName = ServerInfoManager.shared.getServerInfo(serverId: self.serverId)?.name ?? ""
        let vc = UIAlertController(title: "解散社区", message: "确认解散社区\(serverName)？本操作不可撤销。", preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "取消", style: .default))
        vc.addAction(UIAlertAction(title: "确认", style: .default, handler: { _ in
            EMClient.shared().circleManager?.destroyServer(self.serverId) { error in
                if let error = error {
                    Toast.show(error.errorDescription, duration: 2)
                } else {
                    Toast.show("解散成功", duration: 2)
                    ServerInfoManager.shared.remove(serverId: self.serverId)
                    NotificationCenter.default.post(name: EMCircleDidDestroyServer, object: self.serverId)
                    self.dismiss(animated: true)
                }
            }
        }))
        self.present(vc, animated: true)
    }
}
