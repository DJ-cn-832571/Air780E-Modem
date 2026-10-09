import Cocoa

enum ModemTheme {
    static let green = NSColor(srgbRed:0.18,green:0.36,blue:0.30,alpha:1)
    static let ink = NSColor(srgbRed:0.15,green:0.19,blue:0.18,alpha:1)
    static let muted = NSColor(srgbRed:0.40,green:0.45,blue:0.43,alpha:1)
    static let surface = NSColor(srgbRed:0.96,green:0.975,blue:0.965,alpha:1)
    static let border = NSColor(srgbRed:0.84,green:0.87,blue:0.85,alpha:1)
}

/// Native NSButton keeps keyboard and accessibility actions while drawing our palette.
final class ModemButton: NSButton {
    var primary = false { didSet { needsDisplay = true } }
    var destructive = false { didSet { needsDisplay = true } }
    private var hovering = false
    override var isEnabled: Bool { didSet { needsDisplay = true } }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect:bounds,options:[.mouseEnteredAndExited,.activeInKeyWindow,.inVisibleRect],owner:self))
    }
    override func mouseEntered(with event: NSEvent) { hovering = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovering = false; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx:1,dy:1)
        let path = NSBezierPath(roundedRect:rect,xRadius:7,yRadius:7)
        let tint = destructive ? NSColor.systemRed : ModemTheme.green
        let fill = primary ? tint : (hovering ? NSColor(srgbRed:0.91,green:0.945,blue:0.925,alpha:1) : ModemTheme.surface)
        (isEnabled ? fill : ModemTheme.surface).setFill(); path.fill()
        (primary && isEnabled ? tint : ModemTheme.border).setStroke(); path.lineWidth = 1; path.stroke()
        let foreground = !isEnabled ? ModemTheme.muted.withAlphaComponent(0.5) : (primary ? .white : (destructive ? .systemRed : ModemTheme.ink))
        let text = NSAttributedString(string:title,attributes:[.font:NSFont.systemFont(ofSize:13,weight:primary ? .semibold : .medium),.foregroundColor:foreground])
        let size = text.size()
        text.draw(at:NSPoint(x:(bounds.width-size.width)/2,y:(bounds.height-size.height)/2))
        if cell?.isHighlighted == true { NSColor.black.withAlphaComponent(0.08).setFill(); path.fill() }
        if window?.firstResponder === self { NSFocusRingPlacement.only.set(); path.fill() }
    }
}

extension AppDelegate {
    @discardableResult
    func uiLabel(_ value:String,_ frame:NSRect,size:CGFloat = 13,weight:NSFont.Weight = .regular,color:NSColor = ModemTheme.ink) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString:value)
        label.frame = frame; label.font = .systemFont(ofSize:size,weight:weight); label.textColor = color
        window.contentView!.addSubview(label); return label
    }
    func card(_ frame:NSRect) {
        let view = NSView(frame:frame); view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.cornerRadius = 12; view.layer?.borderWidth = 1
        view.layer?.borderColor = ModemTheme.border.cgColor
        window.contentView!.addSubview(view)
    }
    @discardableResult
    func styledButton(_ title:String,_ frame:NSRect,_ action:Selector,primary:Bool = false,tracked:Bool = false) -> ModemButton {
        let b = ModemButton(title:title,target:self,action:action)
        b.isBordered = false; b.frame = frame; b.primary = primary
        b.setAccessibilityLabel(title)
        window.contentView!.addSubview(b)
        if tracked { buttons.append(b) }
        return b
    }
    func buildCommercialInterface() {
        window.contentView!.wantsLayer = true
        window.contentView!.layer?.backgroundColor = NSColor.white.cgColor
        window.appearance = NSAppearance(named:.aqua)
        uiLabel("Air780E Modem",NSRect(x:28,y:840,width:550,height:36),size:28,weight:.bold)
        uiLabel(L("USB 移动网络与短信工作台  ·  0.9.6"),NSRect(x:28,y:815,width:640,height:20),color:ModemTheme.muted)
        let languagePicker = NSPopUpButton(frame:NSRect(x:662,y:842,width:202,height:30),pullsDown:false)
        languagePicker.addItems(withTitles:["简体中文","English","繁體中文"])
        languagePicker.selectItem(at:AppLanguage.allCases.firstIndex(of:Localizer.language) ?? 0)
        languagePicker.target = self; languagePicker.action = #selector(languageChanged(_:))
        languagePicker.setAccessibilityLabel("Language / 语言 / 語言"); window.contentView!.addSubview(languagePicker)
        styledButton(L("立即同步"),NSRect(x:878,y:840,width:90,height:34),#selector(syncClicked),tracked:true)
        styledButton(L("复制诊断"),NSRect(x:978,y:840,width:90,height:34),#selector(copyDiagnostics))
        styledButton(L("关于"),NSRect(x:1078,y:840,width:74,height:34),#selector(aboutProduct))

        card(NSRect(x:28,y:690,width:360,height:108))
        card(NSRect(x:404,y:690,width:360,height:108))
        card(NSRect(x:780,y:690,width:372,height:108))
        uiLabel(L("蜂窝信号"),NSRect(x:46,y:765,width:310,height:20),color:ModemTheme.muted)
        signalText.frame = NSRect(x:46,y:732,width:230,height:30)
        signalText.font = .systemFont(ofSize:22,weight:.bold); signalText.textColor = ModemTheme.ink
        signalBars.frame = NSRect(x:46,y:703,width:70,height:27)
        window.contentView!.addSubview(signalText); window.contentView!.addSubview(signalBars)
        signalDetail = uiLabel(L("RSRP 等待设备确认"),NSRect(x:132,y:709,width:235,height:20),size:12,color:ModemTheme.muted)
        uiLabel(L("短信服务"),NSRect(x:422,y:765,width:310,height:20),color:ModemTheme.muted)
        smsHeadline = uiLabel(L("等待设备"),NSRect(x:422,y:732,width:310,height:30),size:22,weight:.bold)
        simLabel = uiLabel(L("SIM 手机号：等待读取"),NSRect(x:422,y:701,width:322,height:28),size:12,color:ModemTheme.muted)
        simLabel.isSelectable = true
        uiLabel(L("USB 上网"),NSRect(x:798,y:765,width:320,height:20),color:ModemTheme.muted)
        networkHeadline = uiLabel(L("等待确认"),NSRect(x:798,y:732,width:320,height:30),size:22,weight:.bold)
        networkStatus.frame = NSRect(x:798,y:695,width:332,height:36)
        networkStatus.font = .systemFont(ofSize:12); networkStatus.maximumNumberOfLines = 2
        networkStatus.lineBreakMode = .byWordWrapping; window.contentView!.addSubview(networkStatus)

        for (index,title) in [L("启动上网"),L("停止上网"),L("设备状态")].enumerated() {
            let b = styledButton(title,NSRect(x:28+index*110,y:639,width:100,height:36),#selector(network(_:)),primary:index == 0,tracked:true)
            b.tag = index
        }
        activateButton = styledButton(L("激活网卡"),NSRect(x:358,y:639,width:110,height:36),#selector(activateNetwork))
        activateButton.isEnabled = false
        styledButton(L("打开网络设置"),NSRect(x:478,y:639,width:128,height:36),#selector(openNetworkSettings))
        styledButton(L("安装／修复固件"),NSRect(x:616,y:639,width:190,height:36),#selector(installFirmware),tracked:true)
        activity.frame = NSRect(x:1118,y:647,width:20,height:20)
        activity.style = .spinning; activity.isDisplayedWhenStopped = false; window.contentView!.addSubview(activity)
        textArea(output,NSRect(x:28,y:558,width:1124,height:68))
        output.backgroundColor = ModemTheme.surface
        output.string = L("就绪。网络状态以 macOS 的 AirM2M 服务为准；不会修改 Wi-Fi 或 VPN。")

        tabs.selectedSegment = 0; tabs.target = self; tabs.action = #selector(tabChanged)
        for (index,label) in ["收件箱","已发送","已删除"].enumerated() { tabs.setLabel(L(label),forSegment:index) }
        tabs.segmentStyle = .rounded; tabs.frame = NSRect(x:28,y:513,width:330,height:32)
        tabs.setAccessibilityLabel(L("短信分类")); window.contentView!.addSubview(tabs)
        styledButton(L("邮件转发"),NSRect(x:370,y:513,width:140,height:32),#selector(emailSettings),tracked:true)
        styledButton(L("任务与诊断"),NSRect(x:520,y:513,width:156,height:32),#selector(showTaskDetails))

        card(NSRect(x:28,y:106,width:754,height:394))
        card(NSRect(x:798,y:106,width:354,height:394))
        listHeading = uiLabel(L("收件箱"),NSRect(x:46,y:458,width:430,height:28),size:19,weight:.semibold)
        deleteButton = styledButton(L("删除所选"),NSRect(x:526,y:455,width:114,height:32),#selector(deleteClicked),tracked:true)
        clearTrashButton = styledButton(L("清空"),NSRect(x:652,y:455,width:110,height:32),#selector(clearTrashClicked))
        (clearTrashButton as? ModemButton)?.destructive = true; clearTrashButton.isHidden = true
        for (id,label,width) in [("selected","",28.0),("number",L("号码"),105.0),("message",L("内容"),155.0),("received",L("时间"),135.0),("state",L("状态／操作"),240.0)] {
            let c = NSTableColumn(identifier:NSUserInterfaceItemIdentifier(id)); c.title = label; c.width = width; table.addTableColumn(c)
        }
        table.delegate = self; table.dataSource = self; table.allowsMultipleSelection = true
        table.rowHeight = 40; table.intercellSpacing = NSSize(width:8,height:4)
        table.usesAlternatingRowBackgroundColors = false; table.backgroundColor = .white
        let scroll = NSScrollView(frame:NSRect(x:46,y:250,width:716,height:193))
        scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.documentView = table
        window.contentView!.addSubview(scroll)
        emptyLabel = uiLabel(L("暂无短信\n收到的短信会在同步后显示在这里"),NSRect(x:188,y:303,width:420,height:55),size:14,color:ModemTheme.muted)
        emptyLabel.alignment = .center
        selectAllButton = NSButton(checkboxWithTitle:"",target:self,action:#selector(toggleAllSent(_:)))
        selectAllButton.allowsMixedState = true; selectAllButton.frame = NSRect(x:51,y:421,width:24,height:22)
        selectAllButton.setAccessibilityLabel(L("全选当前列表的已发送记录"))
        window.contentView!.addSubview(selectAllButton)
        uiLabel(L("短信详情"),NSRect(x:46,y:222,width:700,height:20),size:12,weight:.medium,color:ModemTheme.muted)
        textArea(detail,NSRect(x:46,y:166,width:716,height:52))
        detail.backgroundColor = ModemTheme.surface
        selectedCount = uiLabel("",NSRect(x:46,y:125,width:560,height:22),size:12,color:ModemTheme.muted)
        batchDeleteButton = styledButton(L("批量删除"),NSRect(x:632,y:120,width:130,height:34),#selector(deleteSelectedSent),tracked:true)
        (batchDeleteButton as? ModemButton)?.destructive = true

        uiLabel(L("发送短信"),NSRect(x:816,y:458,width:315,height:28),size:19,weight:.semibold)
        uiLabel(L("收件人号码"),NSRect(x:816,y:424,width:315,height:20))
        number.placeholderString = L("中国手机号或 + 国家代码号码")
        number.frame = NSRect(x:816,y:388,width:318,height:32)
        number.font = .systemFont(ofSize:14); number.setAccessibilityLabel(L("收件人号码"))
        window.contentView!.addSubview(number)
        uiLabel(L("短信内容"),NSRect(x:816,y:360,width:315,height:20))
        textArea(content,NSRect(x:816,y:238,width:318,height:118),editable:true)
        content.delegate = self; content.setAccessibilityLabel(L("短信内容"))
        countLabel = uiLabel(L("0 / 500 字符"),NSRect(x:816,y:216,width:315,height:18),size:12,color:ModemTheme.muted)
        uiLabel(L("发送前需要确认。长短信可能按多条计费；中心接受不代表送达。未知结果不会自动重发。"),NSRect(x:816,y:157,width:318,height:55),size:11,color:ModemTheme.muted)
        sendButton = styledButton(L("发送短信"),NSRect(x:816,y:117,width:124,height:34),#selector(sendClicked),primary:true,tracked:true)
        syncStatus.frame = NSRect(x:28,y:77,width:744,height:20); syncStatus.font = .systemFont(ofSize:12); syncStatus.textColor = ModemTheme.muted
        mailStatus.frame = NSRect(x:798,y:77,width:354,height:20); mailStatus.font = .systemFont(ofSize:12); mailStatus.textColor = ModemTheme.muted
        window.contentView!.addSubview(syncStatus); window.contentView!.addSubview(mailStatus)
        let maker = NSButton(title:L("点击网络 · 股票代码：832571 · www.DJ.cn"),target:self,action:#selector(openMakerWebsite))
        maker.isBordered = false; maker.contentTintColor = ModemTheme.green; maker.alignment = .left
        maker.frame = NSRect(x:24,y:39,width:400,height:24); window.contentView!.addSubview(maker)
        let contact = uiLabel(L("蔡立文 · cailiwen@dj.cn"),NSRect(x:440,y:40,width:450,height:20),size:12,color:ModemTheme.muted)
        contact.isSelectable = true
        uiLabel(L("独立社区软件 · MIT 开源 · Air780EHV_A11 · 未 Apple 公证"),NSRect(x:28,y:17,width:900,height:18),size:11,color:ModemTheme.muted)
    }
    func updateListPresentation() {
        listHeading.stringValue = L("\([L("收件箱"),L("已发送"),L("已删除")][tabs.selectedSegment]) · \(rows.count) 条")
        emptyLabel.isHidden = !rows.isEmpty
        emptyLabel.stringValue = kind == "sent" ? L("暂无发送记录\n发送结果会显示在这里") : (kind == "trash" ? L("已删除列表为空\n删除的短信可在这里恢复或清空") : L("暂无短信\n收到的短信会在同步后显示在这里"))
        deleteButton.title = kind == "trash" ? L("恢复所选") : L("删除所选")
        deleteButton.setAccessibilityLabel(deleteButton.title)
        deleteButton.isEnabled = !busy && kind != "sent" && !table.selectedRowIndexes.isEmpty
        clearTrashButton.isEnabled = !busy && !rows.isEmpty
        clearTrashButton.isHidden = kind != "trash"
        deleteButton.isHidden = kind == "sent"
        table.tableColumn(withIdentifier:NSUserInterfaceItemIdentifier("selected"))?.isHidden = kind != "sent"
        updateSentSelection()
    }
    func updateSentSelection() {
        guard selectAllButton != nil else { return }
        let eligible = Set(rows.filter { $0["state"] as? String != "sending" }.compactMap { $0["id"] as? String })
        checkedSentIDs.formIntersection(eligible)
        selectAllButton.isHidden = kind != "sent"; batchDeleteButton.isHidden = kind != "sent"
        selectedCount.isHidden = kind != "sent"
        selectAllButton.isEnabled = !busy && !eligible.isEmpty
        selectAllButton.state = checkedSentIDs.isEmpty ? .off : (checkedSentIDs == eligible ? .on : .mixed)
        batchDeleteButton.isEnabled = !busy && !checkedSentIDs.isEmpty
        selectedCount.stringValue = L("已选 \(checkedSentIDs.count) / \(eligible.count) 条 · 全选仅针对当前加载列表（最多 500 条）；发送中不可删除")
    }
    @objc func toggleSentRow(_ sender:NSButton) {
        guard kind == "sent", !busy, rows.indices.contains(sender.tag), let id = rows[sender.tag]["id"] as? String, rows[sender.tag]["state"] as? String != "sending" else { return }
        if sender.state == .on { checkedSentIDs.insert(id) } else { checkedSentIDs.remove(id) }
        updateSentSelection()
    }
    @objc func toggleAllSent(_ sender:NSButton) {
        guard kind == "sent", !busy else { return }
        let ids = Set(rows.filter { $0["state"] as? String != "sending" }.compactMap { $0["id"] as? String })
        checkedSentIDs = checkedSentIDs == ids ? [] : ids
        table.reloadData(); updateSentSelection()
    }
    @objc func deleteSentRow(_ sender:NSButton) {
        guard kind == "sent", rows.indices.contains(sender.tag), let id = rows[sender.tag]["id"] as? String else { return }
        confirmDeleteSent([id])
    }
    @objc func deleteSelectedSent() { confirmDeleteSent(Array(checkedSentIDs).sorted()) }
    func confirmDeleteSent(_ ids:[String]) {
        guard kind == "sent", !busy, !ids.isEmpty else { return }
        confirming = true
        let alert = NSAlert(); alert.alertStyle = .warning; alert.messageText = L("删除 \(ids.count) 条发送记录？")
        alert.informativeText = L("仅永久删除这台 Mac 的所选发送记录，不可恢复，不会撤回已发短信、发送新短信或删除收件箱。发送中的记录不能删除；未知结果也不代表发送失败。")
        alert.addButton(withTitle:L("删除记录")); alert.addButton(withTitle:L("取消"))
        alert.buttons[0].keyEquivalent = ""; alert.buttons[1].keyEquivalent = "\r"
        let confirmed = alert.runModal() == .alertFirstButtonReturn; confirming = false
        if confirmed { run("delete_sent",arguments:["--confirm-permanent"]+ids) }
    }
    func textDidChange(_ notification:Notification) {
        guard notification.object as? NSTextView === content else { return }
        updateDraftCount()
    }
    func updateDraftCount() {
        countLabel.stringValue = L("\(content.string.count) / 500 字符")
        countLabel.textColor = content.string.count > 500 ? .systemRed : ModemTheme.muted
    }
    @objc func showTaskDetails() {
        let alert = NSAlert(); alert.messageText = L("任务与诊断")
        alert.informativeText = L("当前任务详情可能含本机号码或短信内容。对外反馈请使用“复制脱敏诊断”，不要公开此窗口。")
        alert.addButton(withTitle:L("关闭"))
        let scroll = NSScrollView(frame:NSRect(x:0,y:0,width:640,height:280)); scroll.hasVerticalScroller = true
        let text = NSTextView(frame:NSRect(x:0,y:0,width:620,height:280)); text.isEditable = false; text.isRichText = false
        text.font = .monospacedSystemFont(ofSize:12,weight:.regular)
        text.string = output.string; text.textContainer?.widthTracksTextView = true; text.isVerticallyResizable = true
        scroll.documentView = text; alert.accessoryView = scroll
        confirming = true; alert.runModal(); confirming = false
    }
    func updateDeviceCards(_ state:[String:Any]) {
        updateSignal(state)
        smsHeadline.stringValue = state["smsReady"] as? Bool == true ? L("短信就绪") : L("等待网络注册")
        let phone = (state["phoneNumber"] as? String ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
        simLabel.stringValue = L("SIM 手机号：") + (phone.isEmpty ? L("未读取到（SIM 可能未存储）") : phone)
        simLabel.toolTip = L("SIM 未存储本机号码时无法自动读取；不会猜测号码。")
    }
}
