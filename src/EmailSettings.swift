import Cocoa
import Security

extension AppDelegate {
    var smtpKey: [String:Any] {
        [kSecClass as String:kSecClassGenericPassword,
         kSecAttrService as String:"io.github.air780e.modem.smtp",
         kSecAttrAccount as String:"primary"]
    }
    func smtpPassword() throws -> String {
        var query = smtpKey
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary,&value)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = value as? Data, let secret = String(data:data,encoding:.utf8) else {
            throw NSError(domain:"Keychain",code:Int(status),userInfo:[NSLocalizedDescriptionKey:"无法读取钥匙串，请允许本应用访问 SMTP 密码。"])
        }
        return secret
    }
    func saveSMTPPassword(_ secret: String) throws {
        let attributes = [kSecValueData as String:Data(secret.utf8)]
        var status = SecItemUpdate(smtpKey as CFDictionary,attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = smtpKey; item[kSecValueData as String] = Data(secret.utf8)
            status = SecItemAdd(item as CFDictionary,nil)
        }
        guard status == errSecSuccess else {
            throw NSError(domain:"Keychain",code:Int(status),userInfo:[NSLocalizedDescriptionKey:"无法保存 SMTP 密码至钥匙串（\(status)），设置没有保存。"])
        }
    }
    @objc func emailSettings() {
        guard !mailBusy else { mailStatus.stringValue = "邮件任务正在执行，请完成后再修改设置。"; return }
        confirming = true
        defer { confirming = false }
        let (text,code) = backend("email_config",[])
        guard code == 0, let data = text.data(using:.utf8), let config = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else { output.string = text; return }
        let alert = NSAlert(); alert.messageText = "短信邮件转发（最多 3 个邮箱）"
        alert.informativeText = "启用后，新同步的短信及发送号码会发送给所填邮箱；应用必须保持运行。密码/授权码存入 macOS 钥匙串，留空保留原密码。仅支持验证证书的 SSL / STARTTLS。"
        alert.addButton(withTitle:"保存")
        alert.addButton(withTitle:"取消")
        alert.addButton(withTitle:"保存并测试 SMTP")
        alert.addButton(withTitle:"查看转发记录")
        let panel = NSView(frame:NSRect(x:0,y:0,width:460,height:355))
        let enabled = NSButton(checkboxWithTitle:"启用收到短信自动转发",target:nil,action:nil)
        enabled.state = config["enabled"] as? Bool == true ? .on : .off
        enabled.frame = NSRect(x:0,y:322,width:450,height:25); panel.addSubview(enabled)
        func field(_ title:String,_ y:Int,_ value:String,secure:Bool = false) -> NSTextField {
            let label = NSTextField(labelWithString:title); label.frame = NSRect(x:0,y:y+3,width:125,height:24); panel.addSubview(label)
            let input: NSTextField = secure ? NSSecureTextField() : NSTextField()
            input.frame = NSRect(x:130,y:y,width:325,height:26); input.stringValue = value; panel.addSubview(input)
            return input
        }
        let host = field("SMTP 服务器",288,config["host"] as? String ?? "")
        let port = field("SMTP 端口",256,"\(config["port"] ?? 465)")
        let user = field("SMTP 用户名",224,config["username"] as? String ?? "")
        let sender = field("发件邮箱",192,config["sender"] as? String ?? "")
        let password = field("密码／授权码",160,"",secure:true)
        password.placeholderString = "留空保留；多数邮箱须使用 SMTP 授权码"
        let recipients = config["recipients"] as? [String] ?? []
        let targets = (0..<3).map { field("收件邮箱 \($0+1)",128-$0*32,$0 < recipients.count ? recipients[$0] : "") }
        let security = NSPopUpButton(frame:NSRect(x:130,y:28,width:325,height:26),pullsDown:false)
        security.addItems(withTitles:["SSL","STARTTLS"]); security.selectItem(withTitle:config["tls"] as? String ?? "SSL")
        let label = NSTextField(labelWithString:"加密方式"); label.frame = NSRect(x:0,y:31,width:125,height:24)
        panel.addSubview(label); panel.addSubview(security); alert.accessoryView = panel
        while true {
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn { return }
            if answer.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue+3 {
                output.string = backend("email_history",[]).0; return
            }
            let settings: [String:Any] = ["enabled":enabled.state == .on,"host":host.stringValue,
                "port":Int(port.stringValue) ?? 0,"tls":security.titleOfSelectedItem ?? "SSL",
                "username":user.stringValue,"sender":sender.stringValue,
                "recipients":targets.map { $0.stringValue.trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !$0.isEmpty }]
            guard let payload = try? JSONSerialization.data(withJSONObject:settings) else { return }
            let validation = backend("email_validate",[],input:payload)
            if validation.1 != 0 { showMailError(validation.0); continue }
            do {
                if !password.stringValue.isEmpty { try saveSMTPPassword(password.stringValue) }
                if enabled.state == .on {
                    if try smtpPassword().isEmpty { showMailError("启用转发前，请输入 SMTP 密码或授权码。"); continue }
                }
            } catch { showMailError(error.localizedDescription); continue }
            let result = backend("email_save",[],input:payload)
            if result.1 != 0 { showMailError(result.0); continue }
            password.stringValue = ""
            mailStatus.stringValue = enabled.state == .on ? "邮件转发已启用：只转发此后新同步短信。" : "邮件转发已关闭。"
            if answer.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue+2 { forwardEmail(test:true) }
            return
        }
    }
    func showMailError(_ message:String) {
        let alert = NSAlert(); alert.messageText = "邮件设置提示"; alert.informativeText = message; alert.runModal()
    }
    func forwardEmail(test:Bool = false) {
        guard !mailBusy else { return }
        mailBusy = true
        DispatchQueue.global().async {
            let result = self.backend("email_config",[])
            DispatchQueue.main.async {
                guard result.1 == 0, let data = result.0.data(using:.utf8),
                      let config = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else {
                    self.mailBusy = false; self.mailStatus.stringValue = "无法读取邮件设置。"; return
                }
                guard config["enabled"] as? Bool == true else {
                    self.mailBusy = false; self.mailStatus.stringValue = "邮件转发：未启用"; return
                }
                do {
                    let password = try self.smtpPassword()
                    guard !password.isEmpty else { throw NSError(domain:"SMTP",code:1,userInfo:[NSLocalizedDescriptionKey:"未保存 SMTP 密码，请打开邮件设置。"]) }
                    let input = try JSONSerialization.data(withJSONObject:["password":password])
                    self.mailStatus.stringValue = test ? "正在测试 SMTP 加密登录……" : "正在检查短信邮件转发……"
                    DispatchQueue.global().async {
                        let (text,_) = self.backend(test ? "email_test" : "email_forward",[],input:input)
                        DispatchQueue.main.async { self.mailBusy = false; self.mailStatus.stringValue = text.trimmingCharacters(in:.whitespacesAndNewlines) }
                    }
                } catch { self.mailBusy = false; self.mailStatus.stringValue = error.localizedDescription }
            }
        }
    }
}
