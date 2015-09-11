//
//  CertifyViewController.swift
//  BITWebCertify
//
//  Created by Hunter on 15/9/10.
//  Copyright (c) 2015年 BIT. All rights reserved.
//

import Cocoa
import SwiftHTTP

class State {
    var logInState: String = ""
    var logOutState: String = ""
}

class CertifyViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        defaultInfo.synchronize()
        if let defaultName = defaultInfo.stringForKey("defaultName") {
            self.nameForWebCertify.stringValue = defaultName
        }
        if let defaultPassword = defaultInfo.stringForKey("defaultPassword") {
            self.passwordForWebCertify.stringValue = defaultPassword
        }
    }
    
    let defaultInfo = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var nameForWebCertify: NSTextField!
    @IBOutlet weak var passwordForWebCertify: NSSecureTextField!
    
    @IBOutlet weak var webConnectionState: NSTextField!
    
    
    @IBAction func logInWeb(sender: NSButton) {
        self.logIn()
        
    }
    
    @IBAction func logOutWeb(sender: NSButton) {
        self.logOut()
    }
    
    @IBAction func QuitApp(sender: NSButton) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
    
    var state = State()

    
    func logIn() -> String {
        
        let name = self.nameForWebCertify.stringValue
        
        let passwordWithOutMD5 = self.passwordForWebCertify.stringValue
        
        
        defaultInfo.setValue(name, forKey: "defaultName")
        defaultInfo.setValue(passwordWithOutMD5, forKey: "defaultPassword")
        
        let passwordWithMD5 = passwordWithOutMD5.md5
        
        let range = passwordWithMD5.startIndex.advancedBy(8) ..< passwordWithMD5.endIndex.advancedBy(-8)
        
        var password: String = ""
        
        for index in range {
            password.append(passwordWithMD5[index])
        }
        
        
        let request = HTTPTask()
        let logInURL = "http://10.0.0.55/cgi-bin/do_login"
        let params: Dictionary<String,AnyObject> = [
            "username": name,
            "password": password,
            "drop": 0,
            "type": 1,
            "n": 100
        ]
        

        
        request.POST(logInURL, parameters: params, completionHandler: {(response:HTTPResponse) -> Void in
            if response.responseObject != nil{
                let data = response.responseObject as! NSData
                let str = NSString(data: data, encoding: NSUTF8StringEncoding)
                self.state.logInState = str as! String
                self.webConnectionState.stringValue = self.state.logInState
                if (Int(self.state.logInState) != nil) {
                    self.webConnectionState.stringValue = "已连接"
                } else if(self.state.logInState != "") {
                    self.webConnectionState.stringValue = self.logInInfo(self.state.logInState)
                } else {
                    self.webConnectionState.stringValue = "找不到认证服务器"
                }
            }
            }
        )
        
        return self.state.logInState
        
    }
    
    func logOut() ->String {
        
        let request = HTTPTask()
        request.GET("http://10.0.0.55/cgi-bin/do_logout", parameters: nil, completionHandler: {(response: HTTPResponse) in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                return //also notify app of failure as needed
            }
            if let data = response.responseObject as? NSData {
                let str = NSString(data: data, encoding: NSUTF8StringEncoding)
                self.state.logOutState = str as! String
                self.webConnectionState.stringValue = self.state.logOutState
            }
        })
        
        
        return self.state.logOutState
    }
    
    func logInInfo(key: String) -> String {
        var infoArray = [String: String]()
        infoArray["user_tab_error"] = "认证程序未启动"
        infoArray["username_error"] = "用户名错误"
        infoArray["non_auth_error"] = "您无须认证，可直接上网"
        infoArray["password_error"] = "密码错误"
        infoArray["status_error"] = "用户已欠费，请尽快充值。"
        infoArray["available_error"] = "用户已禁用"
        infoArray["ip_exist_error"] = "您的IP尚未下线，请等待2分钟再试"
        infoArray["usernum_error"] = "用户数已达上限"
        infoArray["online_num_error"] = "该帐号的登录人数已超过限额"
        infoArray["flux_error"] = "您的流量已超支"
        infoArray["minutes_error"] = "您的时长已超支"
        infoArray["ip_error"] = "您的IP地址不合法"
        infoArray["mac_error"] = "您的MAC地址不合法"
        infoArray["sync_error"] = "您的资料已修改，正在等待同步，请2分钟后再试"
        infoArray["time_policy_error"] = "当前时段不允许连接"
        infoArray["mode_error"] = "系统已禁止WEB方式登录，请使用客户端"
        return infoArray[key]!
    }
    
    
}
