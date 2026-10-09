import Cocoa
import Security

final class SignalBars: NSView {
    var level = 0 { didSet { needsDisplay = true } }
    override func draw(_ dirtyRect: NSRect) {
        for i in 0..<5 {
            (i < level ? ModemTheme.green : ModemTheme.border).setFill()
            NSBezierPath(roundedRect:NSRect(x:i*13,y:0,width:9,height:6+i*4),xRadius:2,yRadius:2).fill()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate {
    var window: NSWindow!
    let output = NSTextView(), detail = NSTextView(), content = NSTextView()
    let number = NSTextField(), syncStatus = NSTextField(labelWithString: L("尚未同步"))
    let tabs = NSSegmentedControl(labels: [L("收件箱"), L("已发送"), L("已删除")], trackingMode: .selectOne, target: nil, action: nil)
    let table = NSTableView()
    let networkStatus = NSTextField(labelWithString:L("设备状态：未知 ｜ 上网状态：等待设备确认"))
    var clearTrashButton: NSButton!
    var inspectingNetwork = false
    var networkCheckedAt = 0.0
    var activateButton: NSButton!
    var activatingNetwork = false
    let signalBars = SignalBars(), signalText = NSTextField(labelWithString:L("信号未知"))
    let mailStatus = NSTextField(labelWithString:L("邮件转发：未启用"))
    var mailBusy = false
    var rows: [[String: Any]] = []
    var buttons: [NSButton] = []
    var busy = false, confirming = false
    var sendPending = false
    var signalDetail: NSTextField!, smsHeadline: NSTextField!, simLabel: NSTextField!, networkHeadline: NSTextField!
    var listHeading: NSTextField!, emptyLabel: NSTextField!, countLabel: NSTextField!
    var deleteButton: NSButton!, sendButton: NSButton!
    let activity = NSProgressIndicator()
    var checkedSentIDs = Set<String>()
    var selectAllButton: NSButton!, batchDeleteButton: NSButton!, selectedCount: NSTextField!
    var kind: String { ["inbox", "sent", "trash"][max(0,tabs.selectedSegment)] }

    func textArea(_ text: NSTextView, _ frame: NSRect, editable: Bool = false) {
        let scroll = NSScrollView(frame:frame); scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder; scroll.wantsLayer = true
        scroll.layer?.cornerRadius = 7; scroll.layer?.masksToBounds = true
        if editable { scroll.layer?.borderWidth = 1; scroll.layer?.borderColor = ModemTheme.border.cgColor }
        text.frame = NSRect(origin:.zero,size:scroll.contentSize)
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false
        text.textContainer?.widthTracksTextView = true
        text.minSize = NSSize(width:0,height:scroll.contentSize.height)
        text.maxSize = NSSize(width:CGFloat.greatestFiniteMagnitude,height:CGFloat.greatestFiniteMagnitude)
        text.drawsBackground = true; text.backgroundColor = .white; text.textColor = ModemTheme.ink
        text.isEditable = editable; text.isRichText = false; text.font = .systemFont(ofSize:14)
        text.textContainerInset = NSSize(width:8,height:8); text.autoresizingMask = [.width]
        scroll.documentView = text; window.contentView!.addSubview(scroll)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let identifier = Bundle.main.bundleIdentifier,
           let existing = NSRunningApplication.runningApplications(withBundleIdentifier:identifier).first(where:{ $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            existing.activate(options:[]); NSApp.terminate(nil); return
        }
        let menu = NSMenu()
        let appItem = NSMenuItem(); let appMenu = NSMenu()
        appMenu.addItem(withTitle:L("关于 Air780E Modem"),action:#selector(aboutProduct),keyEquivalent:"")
        appMenu.addItem(withTitle:L("复制脱敏诊断信息"),action:#selector(copyDiagnostics),keyEquivalent:"")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle:L("退出 Air780E Modem"),action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")
        appItem.submenu = appMenu; menu.addItem(appItem)
        let editItem = NSMenuItem(); editItem.title = L("编辑"); let editMenu = NSMenu(title:L("编辑"))
        editMenu.addItem(withTitle:L("剪切"),action:#selector(NSText.cut(_:)),keyEquivalent:"x")
        editMenu.addItem(withTitle:L("复制"),action:#selector(NSText.copy(_:)),keyEquivalent:"c")
        editMenu.addItem(withTitle:L("粘贴"),action:#selector(NSText.paste(_:)),keyEquivalent:"v")
        editMenu.addItem(withTitle:L("全选"),action:#selector(NSText.selectAll(_:)),keyEquivalent:"a")
        editItem.submenu = editMenu; menu.addItem(editItem); NSApp.mainMenu = menu
        window = NSWindow(contentRect:NSRect(x:0,y:0,width:1180,height:900),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        window.title = "Air780E Modem — 0.9.6"
        buildCommercialInterface()
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
        reloadLocal(); run("status"); forwardEmail()
        refreshNetworkStatus()
        Timer.scheduledTimer(withTimeInterval:5,repeats:true) { _ in self.refreshNetworkStatus() }
        Timer.scheduledTimer(withTimeInterval:15,repeats:true) { _ in if !self.busy && !self.confirming { self.run("sync_json",background:true) } }
    }
    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }
    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let field = NSTextField(labelWithString:"")
        field.font = .systemFont(ofSize:12); field.textColor = ModemTheme.ink
        let key = column!.identifier.rawValue
        if key == "selected" {
            let checkbox = NSButton(checkboxWithTitle:"",target:self,action:#selector(toggleSentRow(_:)))
            checkbox.tag = row; checkbox.state = checkedSentIDs.contains(rows[row]["id"] as? String ?? "") ? .on : .off
            checkbox.isEnabled = !busy && rows[row]["state"] as? String != "sending"
            checkbox.setAccessibilityLabel(L("选择发送记录 \(row+1)")); return checkbox
        }
        var value = rows[row][key] as? String ?? ""
        if key == "state" { value = ["sending":L("发送中"),"accepted":L("中心已接受"),"failed":L("发送失败"),"unknown":L("结果不确定")][value] ?? (kind == "inbox" ? L("已接收") : L("已删除")) }
        field.stringValue = value.replacingOccurrences(of:"\n",with:" "); field.lineBreakMode = .byTruncatingTail
        if key == "state" && kind == "sent" {
            var views: [NSView] = [field]
            if rows[row]["state"] as? String == "failed" {
                let retry = ModemButton(title:L("重新发送"),target:self,action:#selector(resendRow(_:)))
                retry.tag = row; retry.isBordered = false; retry.isEnabled = !busy
                retry.widthAnchor.constraint(equalToConstant:76).isActive = true
                retry.heightAnchor.constraint(equalToConstant:30).isActive = true; views.append(retry)
            }
            let remove = ModemButton(title:L("删除"),target:self,action:#selector(deleteSentRow(_:)))
            remove.tag = row; remove.isBordered = false; remove.destructive = true
            remove.isEnabled = !busy && rows[row]["state"] as? String != "sending"
            remove.widthAnchor.constraint(equalToConstant:58).isActive = true
            remove.heightAnchor.constraint(equalToConstant:30).isActive = true; views.append(remove)
            let stack = NSStackView(views:views); stack.orientation = .horizontal; stack.spacing = 6; return stack
        }
        if key == "state" && kind == "inbox" {
            let action = ModemButton(title:kind == "inbox" ? L("回复短信") : L("重新发送"),target:self,action:kind == "inbox" ? #selector(replyRow(_:)) : #selector(resendRow(_:)))
            action.tag = row; action.isBordered = false
            action.widthAnchor.constraint(equalToConstant:90).isActive = true
            action.heightAnchor.constraint(equalToConstant:30).isActive = true
            let stack = NSStackView(views:[field,action]); stack.orientation = .horizontal; stack.spacing = 10
            return stack
        }
        return field
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateListPresentation()
        guard table.selectedRow >= 0 && table.selectedRow < rows.count else { detail.string = ""; return }
        let row = rows[table.selectedRow]
        detail.string = "\(row["number"] ?? "")  \(row["received"] ?? "")\n\(row["message"] ?? "")\n\(row["error"] ?? "")"
    }
    @objc func tabChanged() { checkedSentIDs.removeAll(); rows = []; table.deselectAll(nil); table.reloadData(); detail.string = ""; updateListPresentation(); reloadLocal() }
    @objc func openMakerWebsite() {
        if let url = URL(string:"https://www.DJ.cn") { NSWorkspace.shared.open(url) }
    }
    @objc func aboutProduct() {
        let alert = NSAlert(); alert.messageText = "Air780E Modem 0.9.6"
        alert.informativeText = L("制作方：点击网络 · 股票代码：832571 · www.DJ.cn\n联系方式：cailiwen@dj.cn · 蔡立文\nApple Silicon · macOS 26+ · Air780EHV_A11\n非合宙官方软件；当前安装包为 ad-hoc 签名，未 Apple 公证。\n邮件真实投递、长短信及跨运营商仍需验证。")
        alert.addButton(withTitle:L("确定")); alert.runModal()
    }
    @objc func copyDiagnostics() {
        DispatchQueue.global().async {
            let (text,code) = self.backend("diagnostics",[])
            DispatchQueue.main.async {
                if code == 0 {
                    NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text,forType:.string)
                    self.syncStatus.stringValue = L("脱敏诊断信息已复制，不含短信、号码或邮箱密码。")
                } else { self.output.string = L(text) }
            }
        }
    }
    @objc func clearTrashClicked() {
        guard kind == "trash", !busy else { output.string = L("请等待当前操作完成后再清空。"); return }
        confirming = true
        let alert = NSAlert(); alert.alertStyle = .warning
        alert.messageText = L("永久清空已删除的全部短信？")
        alert.informativeText = L("清除 Mac 已删除列表中的所有内容（包括未显示在当前页的记录），不可恢复。不会删除收件箱、已发送记录或修改模块网络状态。此操作不是 SIM 存储清理或安全擦除磁盘。")
        alert.addButton(withTitle:L("永久清空")); alert.addButton(withTitle:L("取消"))
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
            let alert = NSAlert(); alert.messageText = L("用回复短信替换当前草稿？")
            alert.addButton(withTitle:L("替换草稿")); alert.addButton(withTitle:L("取消"))
            confirming = true; let answer = alert.runModal(); confirming = false
            guard answer == .alertFirstButtonReturn else { return }
        }
        number.stringValue = replyNumber
        content.string = ""; updateDraftCount(); window.makeFirstResponder(content)
    }
    @objc func resendRow(_ sender: NSButton) {
        guard !busy else { output.string = L("设备忙，请完成后重新点击重发。"); return }
        guard kind == "sent", rows.indices.contains(sender.tag), rows[sender.tag]["state"] as? String == "failed" else { return }
        number.stringValue = rows[sender.tag]["number"] as? String ?? ""
        content.string = rows[sender.tag]["message"] as? String ?? ""
        updateDraftCount()
        sendClicked()
    }
    func updateSignal(_ state: [String:Any]) {
        if let level = state["signalBars"] as? Int {
            signalBars.level = level; signalText.stringValue = L("\(level) / 5 格")
            signalDetail.stringValue = L("RSRP \(state["rsrp"] ?? L("未知")) dBm · 近似分级")
            signalBars.toolTip = L("LTE RSRP：\(state["rsrp"] ?? L("未知")) dBm（近似分级）")
        } else { signalBars.level = 0; signalText.stringValue = L("信号未知"); signalDetail.stringValue = L("RSRP 等待设备确认") }
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
                        self.networkHeadline.stringValue = L("网卡已停用")
                        self.networkStatus.stringValue = L("\(service)：已停用 ｜ 上网状态：已停止上网")
                        self.networkStatus.textColor = .secondaryLabelColor
                    } else if state?["connected"] as? Bool == true {
                        self.networkHeadline.stringValue = L("网卡已连接")
                        self.networkStatus.stringValue = L("\(service)：已激活 ｜ 上网状态：已启动上网（互联网未验证）")
                        self.networkStatus.textColor = .systemGreen
                    } else {
                        self.networkHeadline.stringValue = L("网卡未连接")
                        self.networkStatus.stringValue = L("\(service)：已激活 ｜ 上网状态：未连接／未取得 IP")
                        self.networkStatus.textColor = .systemOrange
                    }
                } else {
                    self.networkHeadline.stringValue = L("状态未知")
                    self.networkStatus.stringValue = L("AirM2M 系统网络状态：未知（未找到匹配服务或读取失败）")
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
            output.string = L("请手动打开系统设置 → 网络 → AirM2M Compo → 启用。")
        }
    }
    @objc func activateNetwork() {
        guard !activatingNetwork else { return }
        activatingNetwork = true; activateButton.isEnabled = false
        output.string = L("正在启用匹配的 AirM2M 系统网络服务，不修改 Wi-Fi、DNS 或 VPN……")
        DispatchQueue.global().async {
            let (text,code) = self.backend("activate_network",[])
            DispatchQueue.main.async {
                self.activatingNetwork = false
                if code == 0 {
                    self.output.string = L("AirM2M 系统网卡已启用。请查看下方连接状态；模块 ECM 未开启时，还需点击启动上网。")
                } else {
                    self.output.string = L(text)
                    let alert = NSAlert(); alert.messageText = L("请在系统网络设置中启用 AirM2M Compo")
                    alert.informativeText = L(text); alert.addButton(withTitle:L("打开网络设置")); alert.addButton(withTitle:L("取消"))
                    if alert.runModal() == .alertFirstButtonReturn { self.openNetworkSettings() }
                }
                self.refreshNetworkStatus()
            }
        }
    }
    @objc func installFirmware() {
        guard !busy else { output.string = L("正在执行设备操作，请完成后重试安装固件。"); return }
        confirming = true
        let alert = NSAlert(); alert.messageText = L("安装 Air780EHV 配套固件？")
        alert.informativeText = L("仅支持 Air780EHV_A11。核对模块丝印并输入 Air780EHV 确认，其他型号禁止烧录。首次联网下载官方固件和工具并校验。会覆盖核心和脚本并断网；未同步短信可能丢失，没有原固件自动备份。请勿拔线。")
        let model = NSTextField(frame:NSRect(x:0,y:0,width:300,height:26))
        model.placeholderString = L("输入 Air780EHV 确认型号")
        alert.accessoryView = model
        alert.addButton(withTitle:L("安装固件")); alert.addButton(withTitle:L("取消"))
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        confirming = false
        if confirmed && model.stringValue == "Air780EHV" { run("install_firmware",arguments:["Air780EHV_A11"]) }
        else if confirmed { output.string = L("型号确认不匹配，已取消烧录。") }
    }
    @objc func sendClicked() {
        guard !busy else { sendPending = true; output.string = L("已收到发送操作，当前同步完成后会弹出发送确认；尚未发送短信。"); return }
        let phone = number.stringValue.trimmingCharacters(in:.whitespacesAndNewlines), body = content.string
        guard !phone.isEmpty && !body.isEmpty && body.count <= 500 else { output.string = L("请填写号码与 1–500 字符的短信内容。"); return }
        confirming = true
        let alert = NSAlert(); alert.messageText = L("发送短信至 \(phone)？")
        alert.informativeText = L("短信可能计费；长短信可能按多条计费。"); alert.addButton(withTitle:L("发送")); alert.addButton(withTitle:L("取消"))
        let confirmed = alert.runModal() == .alertFirstButtonReturn
        confirming = false
        if confirmed { run("send_sms",arguments:[phone,body]) }
    }
    @objc func deleteClicked() {
        guard kind != "sent" else { output.string = L("已发送记录保留用于核对发送结果；请在收件箱或已删除列表操作。"); return }
        let ids = table.selectedRowIndexes.compactMap { $0 < rows.count ? rows[$0]["id"] as? String : nil }
        guard !ids.isEmpty else { output.string = L("请先选择短信。"); return }
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
                    let progress = String(data:data,encoding:.utf8) ?? L("正在安装……")
                    DispatchQueue.main.async {
                        self.output.string = L(progress)
                        self.output.scrollRangeToVisible(NSRange(location:self.output.string.utf16.count,length:0))
                    }
                }
            }
            p.waitUntilExit(); return (String(data:data,encoding:.utf8) ?? L("响应编码错误"),p.terminationStatus)
        }
        catch { return (L("无法启动控制程序：\(error.localizedDescription)"),2) }
    }
    func reloadLocal() {
        let selectedKind = kind
        DispatchQueue.global().async {
            let (text,code) = self.backend("list_json",[selectedKind])
            let data = text.data(using:.utf8) ?? Data()
            let result = (try? JSONSerialization.jsonObject(with:data)) as? [[String:Any]]
            DispatchQueue.main.async {
                guard self.kind == selectedKind else { return }
                if code == 0, let result = result {
                    self.rows = result
                    self.checkedSentIDs.formIntersection(Set(result.filter { $0["state"] as? String != "sending" }.compactMap { $0["id"] as? String }))
                    self.table.reloadData(); self.detail.string = ""; self.updateListPresentation()
                }
                else { self.syncStatus.stringValue = L("读取列表失败：") + text }
            }
        }
    }
    func run(_ action: String, arguments: [String] = [], background: Bool = false) {
        guard !busy else { if !background { output.string = L("正在执行其他操作，请稍后重试。") }; return }
        busy = true; buttons.forEach { $0.isEnabled = $0.title == L("发送短信") && action != "send_sms" && action != "install_firmware" }
        activity.startAnimation(nil)
        updateSentSelection(); table.reloadData()
        clearTrashButton.isEnabled = false
        if ["start","stop","install_firmware"].contains(action) { updateSignal([:]) }
        if !background { output.string = action == "send_sms" ? L("正在发送短信……等待设备最终结果，最长约 65 秒。请勿重复发送。") : (action == "install_firmware" ? L("正在安装配套固件（约 1–3 分钟），请勿拔线。详细结果会显示在这里。") : L("正在执行，请稍候……")) }
        if action == "sync_json" { syncStatus.stringValue = L("正在同步设备短信……") }
        DispatchQueue.global().async {
            let (text,code) = self.backend(action,arguments)
            DispatchQueue.main.async {
                self.busy = false; self.buttons.forEach { $0.isEnabled = true }
                self.activity.stopAnimation(nil)
                self.clearTrashButton.isEnabled = true
                if action == "sync_json" {
                    if code == 0, let data = text.data(using:.utf8), let result = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any], let state = result["status"] as? [String:Any] { self.updateDeviceCards(state) }
                    else if code != 0 { self.updateSignal([:]); self.smsHeadline.stringValue = L("读取失败"); self.simLabel.stringValue = L("SIM 手机号：本次未读取") }
                    self.syncStatus.stringValue = code == 0 ? L("同步成功 · 列表已刷新 · 每 15 秒自动同步") : L("同步失败 · 请检查 USB 连接，详情见任务与诊断")
                    self.syncStatus.toolTip = code == 0 ? nil : text
                    if !background || code != 0 { self.output.string = code == 0 ? self.syncStatus.stringValue : text }
                } else if !background {
                    if action == "status", let data = text.data(using:.utf8), let state = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] {
                        self.updateDeviceCards(state)
                        let simNumber = (state["phoneNumber"] as? String ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
                        self.output.string = L("模块 USB ECM：\((state["usbEnabled"] as? Bool == true) ? L("开启（系统上网状态见下方）") : L("关闭"))\nSIM 本机号码：\(simNumber.isEmpty ? L("未读取到（SIM 可能未存储本机号码）") : simNumber)\n短信：\((state["smsReady"] as? Bool == true) ? L("已就绪") : L("等待网络注册"))\n设备固件：\(state["version"] ?? L("未知"))")
                    } else { self.output.string = L(text); if action == "status" { self.updateSignal([:]); self.smsHeadline.stringValue = L("读取失败"); self.simLabel.stringValue = L("SIM 手机号：本次未读取") } }
                }
                if action == "send_sms" { self.tabs.selectedSegment = 1 }
                self.updateListPresentation()
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
        if CommandLine.arguments.contains("--self-test-localization") { localizationSelfTest(); return }
        let app = NSApplication.shared, delegate = AppDelegate()
        app.delegate = delegate; app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}
