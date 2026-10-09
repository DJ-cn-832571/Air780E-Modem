import Cocoa
import Security

final class SignalBars: NSView {
    var level = 0 { didSet { needsDisplay = true } }
    override func draw(_ dirtyRect: NSRect) {
        for i in 0..<5 {
            (i < level ? NSColor.systemGreen : NSColor.separatorColor).setFill()
            NSBezierPath(roundedRect:NSRect(x:i*13,y:0,width:9,height:6+i*4),xRadius:2,yRadius:2).fill()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var window: NSWindow!
    let output = NSTextView(), detail = NSTextView(), content = NSTextView()
    let number = NSTextField(), syncStatus = NSTextField(labelWithString: "尚未同步")
    let tabs = NSSegmentedControl(labels: ["收件箱", "已发送", "已删除"], trackingMode: .selectOne, target: nil, action: nil)
    let table = NSTableView()
    let networkStatus = NSTextField(labelWithString:"设备状态：未知 ｜ 上网状态：等待设备确认")
    var clearTrashButton: NSButton!
    var inspectingNetwork = false
    var networkCheckedAt = 0.0
    var activateButton: NSButton!
    var activatingNetwork = false
    let signalBars = SignalBars(), signalText = NSTextField(labelWithString:"信号未知")
    let mailStatus = NSTextField(labelWithString:"邮件转发：未启用")
    var mailBusy = false
    var rows: [[String: Any]] = []
    var buttons: [NSButton] = []
    var busy = false, confirming = false
    var sendPending = false
    var kind: String { ["inbox", "sent", "trash"][max(0,tabs.selectedSegment)] }

    func button(_ title: String, _ x: Int, _ y: Int, _ tag: Int, _ action: Selector) {
        let b = NSButton(title: title, target: self, action: action)
        b.tag = tag; b.bezelStyle = .rounded; b.frame = NSRect(x:x,y:y,width:140,height:32)
        window.contentView!.addSubview(b); buttons.append(b)
    }
    func textArea(_ text: NSTextView, _ frame: NSRect, editable: Bool = false) {
        let scroll = NSScrollView(frame:frame); scroll.hasVerticalScroller = true
        scroll.borderType = editable ? .bezelBorder : .noBorder
        text.frame = NSRect(origin:.zero,size:scroll.contentSize)
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false
        text.textContainer?.widthTracksTextView = true
        text.minSize = NSSize(width:0,height:scroll.contentSize.height)
        text.maxSize = NSSize(width:CGFloat.greatestFiniteMagnitude,height:CGFloat.greatestFiniteMagnitude)
        text.drawsBackground = true; text.backgroundColor = .textBackgroundColor
        text.isEditable = editable; text.isRichText = false; text.font = .systemFont(ofSize:14)
        text.textContainerInset = NSSize(width:8,height:8); text.autoresizingMask = [.width]
        scroll.documentView = text; window.contentView!.addSubview(scroll)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let identifier = Bundle.main.bundleIdentifier,
           let existing = NSRunningApplication.runningApplications(withBundleIdentifier:identifier).first(where:{ $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            existing.activate(options:[.activateIgnoringOtherApps]); NSApp.terminate(nil); return
        }
        let menu = NSMenu()
        let appItem = NSMenuItem(); let appMenu = NSMenu()
        appMenu.addItem(withTitle:"关于 Air780E Modem",action:#selector(aboutProduct),keyEquivalent:"")
        appMenu.addItem(withTitle:"复制脱敏诊断信息",action:#selector(copyDiagnostics),keyEquivalent:"")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle:"退出 Air780E Modem",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")
        appItem.submenu = appMenu; menu.addItem(appItem)
        let editItem = NSMenuItem(); editItem.title = "编辑"; let editMenu = NSMenu(title:"编辑")
        editMenu.addItem(withTitle:"剪切",action:#selector(NSText.cut(_:)),keyEquivalent:"x")
        editMenu.addItem(withTitle:"复制",action:#selector(NSText.copy(_:)),keyEquivalent:"c")
        editMenu.addItem(withTitle:"粘贴",action:#selector(NSText.paste(_:)),keyEquivalent:"v")
        editMenu.addItem(withTitle:"全选",action:#selector(NSText.selectAll(_:)),keyEquivalent:"a")
        editItem.submenu = editMenu; menu.addItem(editItem); NSApp.mainMenu = menu
        window = NSWindow(contentRect:NSRect(x:0,y:0,width:900,height:800),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        window.title = "Air780E Modem — 0.9.3"
        let title = NSTextField(labelWithString:"USB 上网与短信")
        title.font = .boldSystemFont(ofSize:24); title.frame = NSRect(x:24,y:748,width:500,height:32)
        window.contentView!.addSubview(title)
        for (i,label) in ["启动上网","停止上网","设备状态"].enumerated() { button(label,24+i*155,706,i,#selector(network(_:))) }
        button("安装／修复固件",725,706,0,#selector(installFirmware))
        button("邮件转发设置",489,706,0,#selector(emailSettings))
        signalBars.frame = NSRect(x:625,y:752,width:70,height:28)
        signalText.frame = NSRect(x:700,y:749,width:180,height:30)
        window.contentView!.addSubview(signalBars); window.contentView!.addSubview(signalText)
        textArea(output,NSRect(x:24,y:613,width:852,height:80))
        networkStatus.frame = NSRect(x:24,y:588,width:588,height:20)
        networkStatus.font = .boldSystemFont(ofSize:12)
        window.contentView!.addSubview(networkStatus)
        activateButton = NSButton(title:"激活网卡",target:self,action:#selector(activateNetwork))
        activateButton.bezelStyle = .rounded; activateButton.frame = NSRect(x:620,y:584,width:110,height:28)
        activateButton.isEnabled = false; window.contentView!.addSubview(activateButton)
        let networkSettings = NSButton(title:"打开网络设置",target:self,action:#selector(openNetworkSettings))
        networkSettings.bezelStyle = .rounded; networkSettings.frame = NSRect(x:738,y:584,width:138,height:28)
        window.contentView!.addSubview(networkSettings)
        tabs.selectedSegment = 0; tabs.target = self; tabs.action = #selector(tabChanged)
        tabs.frame = NSRect(x:24,y:555,width:400,height:30); window.contentView!.addSubview(tabs)
        clearTrashButton = NSButton(title:"清空",target:self,action:#selector(clearTrashClicked))
        clearTrashButton.bezelStyle = .rounded; clearTrashButton.frame = NSRect(x:440,y:555,width:110,height:30)
        clearTrashButton.isHidden = true; window.contentView!.addSubview(clearTrashButton)
        button("同步短信",570,555,0,#selector(syncClicked))
        button("删除／恢复所选",725,555,0,#selector(deleteClicked))
        for (id,label,width) in [("received","时间",145.0),("number","号码",145.0),("message","内容",265.0),("state","状态／操作",240.0)] {
            let c = NSTableColumn(identifier:NSUserInterfaceItemIdentifier(id)); c.title = label; c.width = width; table.addTableColumn(c)
        }
        table.delegate = self; table.dataSource = self; table.allowsMultipleSelection = true
        table.rowHeight = 28
        let scroll = NSScrollView(frame:NSRect(x:24,y:330,width:852,height:210))
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.documentView = table
        window.contentView!.addSubview(scroll)
        textArea(detail,NSRect(x:24,y:234,width:852,height:82))
        number.placeholderString = "收件人：中国手机号或 + 国家代码号码"
        number.frame = NSRect(x:24,y:185,width:600,height:30); window.contentView!.addSubview(number)
        button("发送短信",735,184,0,#selector(sendClicked))
        let recipientLabel = NSTextField(labelWithString:"发送短信 — 收件人号码")
        recipientLabel.font = .boldSystemFont(ofSize:14)
        recipientLabel.frame = NSRect(x:24,y:216,width:600,height:18)
        window.contentView!.addSubview(recipientLabel)
        let contentLabel = NSTextField(labelWithString:"短信内容（在下方输入，支持多行中文，最多 500 字符）")
        contentLabel.font = .boldSystemFont(ofSize:13)
        contentLabel.frame = NSRect(x:24,y:160,width:852,height:20)
        window.contentView!.addSubview(contentLabel)
        textArea(content,NSRect(x:24,y:70,width:852,height:88),editable:true)
        syncStatus.frame = NSRect(x:24,y:33,width:445,height:30); window.contentView!.addSubview(syncStatus)
        mailStatus.frame = NSRect(x:24,y:8,width:445,height:24); window.contentView!.addSubview(mailStatus)
        let maker = NSButton(title:"制作方：点击网络  www.DJ.cn",target:self,action:#selector(openMakerWebsite))
        maker.isBordered = false; maker.contentTintColor = .linkColor
        maker.alignment = .right; maker.frame = NSRect(x:480,y:35,width:396,height:24)
        window.contentView!.addSubview(maker)
        let contact = NSTextField(labelWithString:"联系方式：cailiwen@dj.cn  ·  蔡立文")
        contact.isSelectable = true; contact.alignment = .right
        contact.frame = NSRect(x:480,y:8,width:396,height:24); window.contentView!.addSubview(contact)
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
        reloadLocal(); run("status"); forwardEmail()
        refreshNetworkStatus()
        Timer.scheduledTimer(withTimeInterval:5,repeats:true) { _ in self.refreshNetworkStatus() }
        Timer.scheduledTimer(withTimeInterval:15,repeats:true) { _ in if !self.busy && !self.confirming { self.run("sync_json",background:true) } }
    }
    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let field = NSTextField(labelWithString:"")
        let key = column!.identifier.rawValue
        var value = rows[row][key] as? String ?? ""
        if key == "state" { value = ["sending":"发送中","accepted":"中心已接受","failed":"发送失败","unknown":"结果不确定"][value] ?? (kind == "inbox" ? "已接收" : "已删除") }
        field.stringValue = value.replacingOccurrences(of:"\n",with:" "); field.lineBreakMode = .byTruncatingTail
        if key == "state" && (kind == "inbox" || (kind == "sent" && rows[row]["state"] as? String == "failed")) {
            let action = NSButton(title:kind == "inbox" ? "回复短信" : "重新发送",target:self,action:kind == "inbox" ? #selector(replyRow(_:)) : #selector(resendRow(_:)))
            action.tag = row; action.bezelStyle = .rounded
            let stack = NSStackView(views:[field,action]); stack.orientation = .horizontal; stack.spacing = 10
            return stack
        }
        return field
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard table.selectedRow >= 0 && table.selectedRow < rows.count else { detail.string = ""; return }
        let row = rows[table.selectedRow]
        detail.string = "\(row["number"] ?? "")  \(row["received"] ?? "")\n\(row["message"] ?? "")\n\(row["error"] ?? "")"
    }
    @objc func tabChanged() { clearTrashButton.isHidden = kind != "trash"; reloadLocal() }
    @objc func openMakerWebsite() {
        if let url = URL(string:"https://www.DJ.cn") { NSWorkspace.shared.open(url) }
    }
    @objc func aboutProduct() {
        let alert = NSAlert(); alert.messageText = "Air780E Modem 0.9.3"
        alert.informativeText = "制作方：点击网络 www.DJ.cn\n联系方式：cailiwen@dj.cn · 蔡立文\nApple Silicon · macOS 26+ · Air780EHV_A11\n非合宙官方软件；当前安装包为 ad-hoc 签名，未 Apple 公证。\n邮件真实投递、长短信及跨运营商仍需验证。"
        alert.addButton(withTitle:"确定"); alert.runModal()
    }
    @objc func copyDiagnostics() {
        DispatchQueue.global().async {
            let (text,code) = self.backend("diagnostics",[])
            DispatchQueue.main.async {
                if code == 0 {
                    NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text,forType:.string)
                    self.syncStatus.stringValue = "脱敏诊断信息已复制，不含短信、号码或邮箱密码。"
                } else { self.output.string = text }
            }
        }
    }
    @objc func clearTrashClicked() {
        guard kind == "trash", !busy else { output.string = "请等待当前操作完成后再清空。"; return }
        confirming = true
        let alert = NSAlert(); alert.alertStyle = .warning
        alert.messageText = "永久清空已删除的全部短信？"
        alert.informativeText = "清除 Mac 已删除列表中的所有内容（包括未显示在当前页的记录），不可恢复。不会删除收件箱、已发送记录或修改模块网络状态。此操作不是 SIM 存储清理或安全擦除磁盘。"
        alert.addButton(withTitle:"永久清空"); alert.addButton(withTitle:"取消")
        alert.buttons[0].keyEquivalent = ""; alert.buttons[1].keyEquivalent = "\r"
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        confirming = false
        if confirmed { run("clear_trash",arguments:["--confirm-permanent"]) }
    }
    @objc func network(_ b: NSButton) { run(["start","stop","status"][b.tag]) }
    @objc func syncClicked() { run("sync_json") }
    @objc func replyRow(_ sender: NSButton) {
        guard kind == "inbox", rows.indices.contains(sender.tag) else { return }
        let replyNumber = rows[sender.tag]["number"] as? String ?? ""
        if !content.string.isEmpty {
            let alert = NSAlert(); alert.messageText = "用回复短信替换当前草稿？"
            alert.addButton(withTitle:"替换草稿"); alert.addButton(withTitle:"取消")
            confirming = true; let answer = alert.runModal(); confirming = false
            guard answer == .alertFirstButtonReturn else { return }
        }
        number.stringValue = replyNumber
        content.string = ""; window.makeFirstResponder(content)
    }
    @objc func resendRow(_ sender: NSButton) {
        guard !busy else { output.string = "设备忙，请完成后重新点击重发。"; return }
        guard kind == "sent", rows.indices.contains(sender.tag), rows[sender.tag]["state"] as? String == "failed" else { return }
        number.stringValue = rows[sender.tag]["number"] as? String ?? ""
        content.string = rows[sender.tag]["message"] as? String ?? ""
        sendClicked()
    }
    func updateSignal(_ state: [String:Any]) {
        if let level = state["signalBars"] as? Int {
            signalBars.level = level; signalText.stringValue = "\(level)/5 格"
            signalBars.toolTip = "LTE RSRP：\(state["rsrp"] ?? "未知") dBm（近似分级）"
        } else { signalBars.level = 0; signalText.stringValue = "信号未知" }
    }
    func refreshNetworkStatus() {
        guard !inspectingNetwork else { return }
        inspectingNetwork = true
        DispatchQueue.global().async {
            let (text,code) = self.backend("system_network",[])
            let state = text.data(using:.utf8).flatMap { try? JSONSerialization.jsonObject(with:$0) } as? [String:Any]
            DispatchQueue.main.async {
                self.inspectingNetwork = false
                let checked = state?["checkedAt"] as? Double ?? Date().timeIntervalSince1970
                guard checked >= self.networkCheckedAt else { return }
                self.networkCheckedAt = checked
                let service = state?["service"] as? String ?? "AirM2M Compo"
                if code == 0, let enabled = state?["serviceEnabled"] as? Bool {
                    if !enabled {
                        self.networkStatus.stringValue = "\(service)：已停用 ｜ 上网状态：已停止上网"
                        self.networkStatus.textColor = .secondaryLabelColor
                    } else if state?["connected"] as? Bool == true {
                        self.networkStatus.stringValue = "\(service)：已激活 ｜ 上网状态：已启动上网（互联网未验证）"
                        self.networkStatus.textColor = .systemGreen
                    } else {
                        self.networkStatus.stringValue = "\(service)：已激活 ｜ 上网状态：未连接／未取得 IP"
                        self.networkStatus.textColor = .systemOrange
                    }
                } else {
                    self.networkStatus.stringValue = "AirM2M 系统网络状态：未知（未找到匹配服务或读取失败）"
                    self.networkStatus.textColor = .secondaryLabelColor
                }
                self.networkStatus.toolTip = state?["detail"] as? String
                self.activateButton.isEnabled = code == 0 && state?["serviceEnabled"] as? Bool == false && !self.activatingNetwork
            }
        }
    }
    @objc func openNetworkSettings() {
        if let url = URL(string:"x-apple.systempreferences:com.apple.Network-Settings.extension"), NSWorkspace.shared.open(url) { return }
        if !NSWorkspace.shared.open(URL(fileURLWithPath:"/System/Library/PreferencePanes/Network.prefPane")) {
            output.string = "请手动打开系统设置 → 网络 → AirM2M Compo → 启用。"
        }
    }
    @objc func activateNetwork() {
        guard !activatingNetwork else { return }
        activatingNetwork = true; activateButton.isEnabled = false
        output.string = "正在启用匹配的 AirM2M 系统网络服务，不修改 Wi-Fi、DNS 或 VPN……"
        DispatchQueue.global().async {
            let (text,code) = self.backend("activate_network",[])
            DispatchQueue.main.async {
                self.activatingNetwork = false
                if code == 0 {
                    self.output.string = "AirM2M 系统网卡已启用。请查看下方连接状态；模块 ECM 未开启时，还需点击启动上网。"
                } else {
                    self.output.string = text
                    let alert = NSAlert(); alert.messageText = "请在系统网络设置中启用 AirM2M Compo"
                    alert.informativeText = text; alert.addButton(withTitle:"打开网络设置"); alert.addButton(withTitle:"取消")
                    if alert.runModal() == .alertFirstButtonReturn { self.openNetworkSettings() }
                }
                self.refreshNetworkStatus()
            }
        }
    }
    @objc func installFirmware() {
        guard !busy else { output.string = "正在执行设备操作，请完成后重试安装固件。"; return }
        confirming = true
        let alert = NSAlert(); alert.messageText = "安装 Air780EHV 配套固件？"
        alert.informativeText = "仅支持 Air780EHV_A11。核对模块丝印并输入 Air780EHV 确认，其他型号禁止烧录。首次联网下载官方固件和工具并校验。会覆盖核心和脚本并断网；未同步短信可能丢失，没有原固件自动备份。请勿拔线。"
        let model = NSTextField(frame:NSRect(x:0,y:0,width:300,height:26))
        model.placeholderString = "输入 Air780EHV 确认型号"
        alert.accessoryView = model
        alert.addButton(withTitle:"安装固件"); alert.addButton(withTitle:"取消")
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        confirming = false
        if confirmed && model.stringValue == "Air780EHV" { run("install_firmware",arguments:["Air780EHV_A11"]) }
        else if confirmed { output.string = "型号确认不匹配，已取消烧录。" }
    }
    @objc func sendClicked() {
        guard !busy else { sendPending = true; output.string = "已收到发送操作，当前同步完成后会弹出发送确认；尚未发送短信。"; return }
        let phone = number.stringValue.trimmingCharacters(in:.whitespacesAndNewlines), body = content.string
        guard !phone.isEmpty && !body.isEmpty && body.count <= 500 else { output.string = "请填写号码与 1–500 字符的短信内容。"; return }
        confirming = true
        let alert = NSAlert(); alert.messageText = "发送短信至 \(phone)？"
        alert.informativeText = "短信可能计费；长短信可能按多条计费。"; alert.addButton(withTitle:"发送"); alert.addButton(withTitle:"取消")
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        confirming = false
        if confirmed { run("send_sms",arguments:[phone,body]) }
    }
    @objc func deleteClicked() {
        guard kind != "sent" else { output.string = "已发送记录保留用于核对发送结果；请在收件箱或已删除列表操作。"; return }
        let ids = table.selectedRowIndexes.compactMap { $0 < rows.count ? rows[$0]["id"] as? String : nil }
        guard !ids.isEmpty else { output.string = "请先选择短信。"; return }
        run(kind == "trash" ? "restore_sms" : "delete_sms",arguments:ids)
    }
    func backend(_ action: String, _ arguments: [String], input: Data? = nil) -> (String,Int32) {
        let p = Process(), pipe = Pipe()
        p.executableURL = Bundle.main.resourceURL!.appendingPathComponent("backend/modem-backend")
        p.arguments = [action] + arguments
        p.standardOutput = pipe; p.standardError = pipe
        let inputPipe = Pipe()
        if input != nil { p.standardInput = inputPipe }
        do {
            try p.run()
            if let input = input { inputPipe.fileHandleForWriting.write(input); try? inputPipe.fileHandleForWriting.close() }
            var data = Data()
            while true {
                let chunk = pipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                data.append(chunk)
                if action == "install_firmware" {
                    let progress = String(data:data,encoding:.utf8) ?? "正在安装……"
                    DispatchQueue.main.async {
                        self.output.string = progress
                        self.output.scrollRangeToVisible(NSRange(location:self.output.string.utf16.count,length:0))
                    }
                }
            }
            p.waitUntilExit(); return (String(data:data,encoding:.utf8) ?? "响应编码错误",p.terminationStatus)
        }
        catch { return ("无法启动控制程序：\(error.localizedDescription)",2) }
    }
    func reloadLocal() {
        let selectedKind = kind
        DispatchQueue.global().async {
            let (text,code) = self.backend("list_json",[selectedKind])
            let data = text.data(using:.utf8) ?? Data()
            let result = (try? JSONSerialization.jsonObject(with:data)) as? [[String:Any]]
            DispatchQueue.main.async {
                guard self.kind == selectedKind else { return }
                if code == 0, let result = result { self.rows = result; self.table.reloadData(); self.detail.string = "" }
                else { self.syncStatus.stringValue = "读取列表失败：" + text }
            }
        }
    }
    func run(_ action: String, arguments: [String] = [], background: Bool = false) {
        guard !busy else { if !background { output.string = "正在执行其他操作，请稍后重试。" }; return }
        busy = true; buttons.forEach { $0.isEnabled = $0.title == "发送短信" && action != "send_sms" && action != "install_firmware" }
        clearTrashButton.isEnabled = false
        if ["start","stop","install_firmware"].contains(action) { updateSignal([:]) }
        if !background { output.string = action == "send_sms" ? "正在发送短信……等待设备最终结果，最长约 65 秒。请勿重复发送。" : (action == "install_firmware" ? "正在安装配套固件（约 1–3 分钟），请勿拔线。详细结果会显示在这里。" : "正在执行，请稍候……") }
        if action == "sync_json" { syncStatus.stringValue = "正在同步设备短信……" }
        DispatchQueue.global().async {
            let (text,code) = self.backend(action,arguments)
            DispatchQueue.main.async {
                self.busy = false; self.buttons.forEach { $0.isEnabled = true }
                self.clearTrashButton.isEnabled = true
                if action == "sync_json" {
                    if code == 0, let data = text.data(using:.utf8), let result = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any], let state = result["status"] as? [String:Any] { self.updateSignal(state) }
                    else if code != 0 { self.updateSignal([:]) }
                    self.syncStatus.stringValue = code == 0 ? "同步成功；接收列表会自动刷新。" : "同步失败：" + text
                    if !background { self.output.string = self.syncStatus.stringValue }
                } else if !background {
                    if action == "status", let data = text.data(using:.utf8), let state = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] {
                        self.updateSignal(state)
                        let simNumber = (state["phoneNumber"] as? String ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
                        self.output.string = "模块 USB ECM：\((state["usbEnabled"] as? Bool == true) ? "开启（系统上网状态见下方）" : "关闭")\nSIM 本机号码：\(simNumber.isEmpty ? "未读取到（SIM 可能未存储本机号码）" : simNumber)\n短信：\((state["smsReady"] as? Bool == true) ? "已就绪" : "等待网络注册")\n设备固件：\(state["version"] ?? "未知")"
                    } else { self.output.string = text; if action == "status" { self.updateSignal([:]) } }
                }
                if action == "send_sms" { self.tabs.selectedSegment = 1 }
                self.reloadLocal()
                self.refreshNetworkStatus()
                if action == "sync_json" { self.forwardEmail() }
                if self.sendPending { self.sendPending = false; self.sendClicked() }
            }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
@main struct ModemApplication {
    static func main() {
        let app = NSApplication.shared, delegate = AppDelegate()
        app.delegate = delegate; app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}
