import Cocoa

enum AppLanguage: String, CaseIterable {
    case simplified = "zh-Hans", english = "en", traditional = "zh-Hant"
}
enum Localizer {
    static var language = AppLanguage(rawValue:UserDefaults.standard.string(forKey:"interfaceLanguage") ?? "zh-Hans") ?? .simplified
    static let catalog: [String:String] = {
        let lines = """
        USB 移动网络与短信工作台|USB Internet & SMS Workspace
        股票代码：832571|Stock code: 832571
        点击网络|DJ Network
        蔡立文|Cai Liwen
        联系方式：|Contact: 
        制作方：|Made by: 
        立即同步|Sync now
        复制诊断|Diagnostics
        关于|About
        蜂窝信号|Cellular signal
        短信服务|SMS service
        USB 上网|USB Internet
        启动上网|Start Internet
        停止上网|Stop Internet
        设备状态|Device status
        激活网卡|Enable adapter
        打开网络设置|Network settings
        安装／修复固件|Install / repair firmware
        收件箱|Inbox
        已发送|Sent
        已删除|Deleted
        邮件转发|Email forwarding
        任务与诊断|Tasks & diagnostics
        删除所选|Delete selected
        恢复所选|Restore selected
        清空|Empty
        短信分类|SMS folders
        全选当前列表的已发送记录|Select all sent records in this list
        选择发送记录|Select sent record
        号码|Number
        内容|Content
        时间|Time
        状态／操作|Status / actions
        短信详情|Message details
        批量删除|Delete selected
        重新发送|Resend
        回复短信|Reply
        发送短信|Send SMS
        收件人号码|Recipient number
        中国手机号或 + 国家代码号码|Chinese mobile number or + country code
        短信内容|Message
        字符|characters
        发送前需要确认。长短信可能按多条计费；中心接受不代表送达。未知结果不会自动重发。|Confirmation required. Long SMS may cost more. Acceptance is not delivery. Unknown results are never retried automatically.
        独立社区软件 · MIT 开源 · Air780EHV_A11 · 未 Apple 公证|Independent community app · MIT · Air780EHV_A11 · Not Apple notarized
        发送中|Sending
        中心已接受|Accepted
        发送失败|Failed
        结果不确定|Unknown result
        已接收|Received
        删除记录|Delete records
        删除|Delete
        取消|Cancel
        确定|OK
        关闭|Close
        保存并测试 SMTP|Save & test SMTP
        查看转发记录|Forwarding history
        保存|Save
        关于 Air780E Modem|About Air780E Modem
        复制脱敏诊断信息|Copy sanitized diagnostics
        退出 Air780E Modem|Quit Air780E Modem
        编辑|Edit
        剪切|Cut
        复制|Copy
        粘贴|Paste
        全选|Select all
        短信就绪|SMS ready
        等待网络注册|Waiting for registration
        等待设备|Waiting for device
        等待确认|Checking
        RSRP 等待设备确认|Waiting for RSRP
        信号未知|Signal unknown
        近似分级|approximate scale
        未知|unknown
        SIM 手机号：等待读取|SIM number: checking
        SIM 手机号：本次未读取|SIM number: unavailable
        SIM 手机号：|SIM number: 
        未读取到（SIM 可能未存储）|Unavailable (not stored on SIM)
        SIM 未存储本机号码时无法自动读取；不会猜测号码。|A SIM without its own number cannot provide it. The app never guesses.
        网卡已停用|Adapter disabled
        网卡已连接|Adapter connected
        网卡未连接|Adapter disconnected
        状态未知|Status unknown
        已停用 ｜ 上网状态：已停止上网|Disabled | Internet stopped
        已激活 ｜ 上网状态：已启动上网（互联网未验证）|Enabled | Link connected (Internet not verified)
        已激活 ｜ 上网状态：未连接／未取得 IP|Enabled | No link / no IP
        AirM2M 系统网络状态：未知（未找到匹配服务或读取失败）|AirM2M status unknown (service not found or check failed)
        设备状态：未知 ｜ 上网状态：等待设备确认|Device unknown | Waiting for confirmation
        暂无短信|No messages
        收到的短信会在同步后显示在这里|Received messages appear after syncing
        暂无发送记录|No sent records
        发送结果会显示在这里|Send results appear here
        已删除列表为空|Deleted folder is empty
        删除的短信可在这里恢复或清空|Restore deleted messages or empty this folder
        已选 |Selected 
         条 · 全选仅针对当前加载列表（最多 500 条）；发送中不可删除| records · Current list only (up to 500); active sends are protected
         条发送记录？| sent records?
         条| records
         格| bars
        仅永久删除这台 Mac 的所选发送记录，不可恢复，不会撤回已发短信、发送新短信或删除收件箱。发送中的记录不能删除；未知结果也不代表发送失败。|Permanently delete only the selected local sent records. This cannot be undone or recall sent SMS. Inbox and device are unchanged. Active sends are protected; an unknown result does not mean failure.
        当前任务详情可能含本机号码或短信内容。对外反馈请使用“复制脱敏诊断”，不要公开此窗口。|Task details may contain numbers or messages. Share sanitized diagnostics instead; do not publish this window.
        尚未同步|Not synced yet
        邮件转发：未启用|Email forwarding: off
        读取失败|Read failed
        脱敏诊断信息已复制，不含短信、号码或邮箱密码。|Sanitized diagnostics copied; no SMS, phone numbers or email passwords.
        永久清空已删除的全部短信？|Permanently empty the Deleted folder?
        清除 Mac 已删除列表中的所有内容（包括未显示在当前页的记录），不可恢复。不会删除收件箱、已发送记录或修改模块网络状态。此操作不是 SIM 存储清理或安全擦除磁盘。|Remove every local Deleted message, including records outside this page. This cannot be undone. Inbox, Sent and network settings are unchanged. This is not SIM clearing or secure disk erasure.
        永久清空|Empty permanently
        请等待当前操作完成后再清空。|Wait for the current task before emptying.
        用回复短信替换当前草稿？|Replace the current draft with a reply?
        替换草稿|Replace draft
        设备忙，请完成后重新点击重发。|Device busy. Wait before resending.
        请手动打开系统设置 → 网络 → AirM2M Compo → 启用。|Open System Settings → Network → AirM2M Compo and enable it.
        正在启用匹配的 AirM2M 系统网络服务，不修改 Wi-Fi、DNS 或 VPN……|Enabling the matched AirM2M service; Wi-Fi, DNS and VPN remain unchanged…
        AirM2M 系统网卡已启用。请查看下方连接状态；模块 ECM 未开启时，还需点击启动上网。|AirM2M enabled. Check its connection state; start Internet if module ECM is off.
        请在系统网络设置中启用 AirM2M Compo|Enable AirM2M Compo in Network settings
        正在执行设备操作，请完成后重试安装固件。|A device task is running. Wait before installing firmware.
        安装 Air780EHV 配套固件？|Install the matching Air780EHV firmware?
        仅支持 Air780EHV_A11。核对模块丝印并输入 Air780EHV 确认，其他型号禁止烧录。首次联网下载官方固件和工具并校验。会覆盖核心和脚本并断网；未同步短信可能丢失，没有原固件自动备份。请勿拔线。|Air780EHV_A11 only. Check the module marking and type Air780EHV. Never flash other models. Official assets are downloaded and verified. Flashing overwrites the core and scripts, disconnects networking and may lose unsynced SMS. No original firmware backup. Do not unplug.
        输入 Air780EHV 确认型号|Type Air780EHV to confirm
        安装固件|Install firmware
        型号确认不匹配，已取消烧录。|Model confirmation does not match; flashing cancelled.
        已收到发送操作，当前同步完成后会弹出发送确认；尚未发送短信。|Send requested. Confirmation will appear after the current task. No SMS sent yet.
        请填写号码与 1–500 字符的短信内容。|Enter a recipient and a message of 1–500 characters.
        发送短信至 |Send SMS to 
        短信可能计费；长短信可能按多条计费。|SMS may incur charges; long messages may be billed as multiple SMS.
        发送|Send
        已发送记录保留用于核对发送结果；请在收件箱或已删除列表操作。|Use the delete buttons in Sent; use Inbox or Deleted for received messages.
        请先选择短信。|Select a message first.
        正在安装……|Installing…
        响应编码错误|Response encoding error
        无法启动控制程序：|Cannot start backend: 
        读取列表失败：|Cannot load list: 
        正在执行其他操作，请稍后重试。|Another task is running. Try again later.
        正在发送短信……等待设备最终结果，最长约 65 秒。请勿重复发送。|Sending SMS… Waiting up to 65 seconds for a result. Do not send again.
        正在安装配套固件（约 1–3 分钟），请勿拔线。详细结果会显示在这里。|Installing firmware (about 1–3 minutes). Do not unplug. Details appear here.
        正在执行，请稍候……|Working, please wait…
        正在同步设备短信……|Syncing device messages…
        同步成功 · 列表已刷新 · 每 15 秒自动同步|Synced · List refreshed · Auto-sync every 15 seconds
        同步失败 · 请检查 USB 连接，详情见任务与诊断|Sync failed · Check USB · See Tasks & diagnostics
        模块 USB ECM：|Module USB ECM: 
        ECM 已关闭|ECM off
        开启（系统上网状态见下方）|On (see system link state)
        SIM 本机号码：|SIM own number: 
        未读取到（SIM 可能未存储本机号码）|Unavailable (the SIM may not store its own number)
        短信：|SMS: 
        已就绪|Ready
        设备固件：|Device firmware: 
        非合宙官方软件；当前安装包为 ad-hoc 签名，未 Apple 公证。|Not an official LuatOS app. Ad-hoc signed; not Apple notarized.
        邮件真实投递、长短信及跨运营商仍需验证。|Real email delivery, long SMS and cross-carrier use still require validation.
        无法读取钥匙串，请允许本应用访问 SMTP 密码。|Cannot read Keychain. Allow this app to access the SMTP password.
        无法保存 SMTP 密码至钥匙串（|Cannot save SMTP password to Keychain (
        ），设置没有保存。|); settings were not saved.
        邮件任务正在执行，请完成后再修改设置。|An email task is running. Wait before editing settings.
        短信邮件转发（最多 3 个邮箱）|SMS email forwarding (up to 3 addresses)
        启用后，新同步的短信及发送号码会发送给所填邮箱；应用必须保持运行。密码/授权码存入 macOS 钥匙串，留空保留原密码。仅支持验证证书的 SSL / STARTTLS。|When enabled, newly synced SMS and sender numbers go to the chosen addresses. Keep the app running. Passwords/app passwords use Keychain; leave blank to keep the old value. Only certificate-verified SSL / STARTTLS is supported.
        启用收到短信自动转发|Enable forwarding for new incoming SMS
        SMTP 服务器|SMTP server
        SMTP 端口|SMTP port
        SMTP 用户名|SMTP username
        发件邮箱|Sender address
        密码／授权码|Password / app password
        留空保留；多数邮箱须使用 SMTP 授权码|Leave blank to keep; most providers require an app password
        收件邮箱 |Recipient email 
        加密方式|Encryption
        启用转发前，请输入 SMTP 密码或授权码。|Enter an SMTP password or app password before enabling forwarding.
        邮件转发已启用：只转发此后新同步短信。|Forwarding enabled for newly synced SMS only.
        邮件转发已关闭。|Forwarding disabled.
        邮件设置提示|Email settings
        无法读取邮件设置。|Cannot read email settings.
        未保存 SMTP 密码，请打开邮件设置。|No SMTP password saved. Open email settings.
        正在测试 SMTP 加密登录……|Testing encrypted SMTP login…
        正在检查短信邮件转发……|Checking SMS forwarding…
        就绪。网络状态以 macOS 的 AirM2M 服务为准；不会修改 Wi-Fi 或 VPN。|Ready. Status follows the macOS AirM2M service; Wi-Fi and VPN stay unchanged.
        操作失败：|Operation failed: 
        未收到配套设备协议。可能正在重启、USB 未连接或固件未正常启动。请重试设备状态，仍失败可点击‘安装／修复固件’。本次未发短信；不能仅凭此提示判断设备固件版本。|No matching device protocol received. The device may be restarting, disconnected or not running the expected firmware. Check Device status before considering firmware repair. No SMS sent; this alone does not identify the installed firmware.
        关|Off
        ？|?
        ：|: 
        """
        return Dictionary(uniqueKeysWithValues:lines.split(separator:"\n").compactMap { line in
            let parts = line.split(separator:"|",maxSplits:1,omittingEmptySubsequences:false)
            guard parts.count == 2 else { return nil }; return (String(parts[0]),String(parts[1]))
        })
    }()
    static func traditional(_ source:String) -> String { source.applyingTransform(StringTransform("Hans-Hant"),reverse:false) ?? source }
    static func text(_ source:String) -> String {
        if language == .simplified { return source }
        if language == .traditional { return traditional(source) }
        if let exact = catalog[source] { return exact }
        var result = source
        // Long phrases first; one pass never translates user-entered fields or SMS bodies.
        for key in catalog.keys.sorted(by:{ $0.count > $1.count }) { result = result.replacingOccurrences(of:key,with:catalog[key]!) }
        return result
    }
    static func retranslate(_ source:String,from old:AppLanguage) -> String {
        if old == .simplified { return text(source) }
        if old == .traditional { return text(source.applyingTransform(StringTransform("Hant-Hans"),reverse:false) ?? source) }
        var raw = source
        for pair in catalog.sorted(by:{ $0.value.count > $1.value.count }) where pair.value.count > 2 {
            raw = raw.replacingOccurrences(of:pair.value,with:pair.key)
        }
        return text(raw)
    }
}
func L(_ source:String) -> String { Localizer.text(source) }

extension AppDelegate {
    @objc func languageChanged(_ sender:NSPopUpButton) {
        guard !busy, !confirming, !mailBusy else { sender.selectItem(at:AppLanguage.allCases.firstIndex(of:Localizer.language) ?? 0); return }
        let previous = Localizer.language
        let newLanguage = AppLanguage.allCases[sender.indexOfSelectedItem]
        guard newLanguage != previous else { return }
        let draft = content.string, recipient = number.stringValue, folder = tabs.selectedSegment, selected = checkedSentIDs
        let statusFields = [signalText,signalDetail,smsHeadline,simLabel,networkHeadline,networkStatus,syncStatus,mailStatus]
        let texts = statusFields.map { $0?.stringValue ?? "" }
        let task = output.string
        Localizer.language = newLanguage; UserDefaults.standard.set(newLanguage.rawValue,forKey:"interfaceLanguage")
        window.contentView!.subviews.forEach { $0.removeFromSuperview() }; buttons.removeAll()
        table.tableColumns.forEach { table.removeTableColumn($0) }
        buildCommercialInterface(); tabs.selectedSegment = folder; checkedSentIDs = selected
        number.stringValue = recipient; content.string = draft; updateDraftCount(); table.reloadData(); updateListPresentation()
        let fields = [signalText,signalDetail,smsHeadline,simLabel,networkHeadline,networkStatus,syncStatus,mailStatus]
        for (field,value) in zip(fields,texts) { field?.stringValue = Localizer.retranslate(value,from:previous) }
        // JSON history can contain SMS bodies: do not translate or reverse-map it.
        let trimmed = task.trimmingCharacters(in:.whitespacesAndNewlines)
        output.string = (trimmed.hasPrefix("[") || trimmed.hasPrefix("{")) ? task : Localizer.retranslate(task,from:previous)
        func translateMenu(_ menu:NSMenu) {
            menu.title = Localizer.retranslate(menu.title,from:previous)
            for item in menu.items { item.title = Localizer.retranslate(item.title,from:previous); if let child = item.submenu { translateMenu(child) } }
        }
        if let menu = NSApp.mainMenu { translateMenu(menu) }
        refreshNetworkStatus()
    }
}

func localizationSelfTest() {
    Localizer.language = .simplified
    precondition(L("发送短信") == "发送短信")
    Localizer.language = .english
    precondition(L("发送短信") == "Send SMS")
    precondition(L("删除 3 条发送记录？") == "Delete 3 sent records?")
    precondition(!L("点击网络 · 股票代码：832571 · www.DJ.cn").contains("股票"))
    precondition(L("已选 3 / 3 条 · 全选仅针对当前加载列表（最多 500 条）；发送中不可删除").hasPrefix("Selected 3 / 3"))
    Localizer.language = .traditional
    precondition(L("发送短信") == "發送短信")
    precondition(L("股票代码：832571").contains("股票代碼"))
    Localizer.language = .simplified
    precondition(Localizer.retranslate("Send SMS",from:.english) == "发送短信")
    print("Localization self-test: zh-Hans / en / zh-Hant OK")
}
