# Changelog

## 0.9.6

- 制作方增加股票代码 832571；三语言界面，首次简体中文，切换保留草稿并记住选择。
- 全部公开说明补充英文；历史 0.9.3 附件不变，补充双语发布说明。
- Adds maker stock code 832571 and Simplified Chinese (default), English and Traditional Chinese UI; preserves drafts and saves language choice.
- Adds English to all public explanatory documents and historical release notes, without replacing 0.9.3 binaries.

## 0.9.5（本地，未发布 GitHub）

- 已发送每行增加删除按钮，失败重发保留。
- 号码／内容前增加选择框与表头全选，选择以记录 ID 保存，后台刷新不误选其他记录。
- 列表底部批量删除，确认后仅永久删除当前所选本机发送记录，不撤回短信，不操作设备。
- 当前加载列表最多 500 条；全选不包含列表外记录，发送中记录不可选择或删除。

## 0.9.4 界面预览（本地，未发布 GitHub）

- 参考 Router V1.3：三张状态卡、深绿圆角按钮、短信列表与发送表单左右分栏。
- 原生辅助功能、字数计数、空列表、分类记录数、进度指示、任务详情及脱敏诊断入口。
- 分类切换先清除旧选择，删除页明确显示“恢复所选”；空列表禁用清空按钮。
- 原有上网、短信、邮件和烧录协议保持不变；不增加电话功能、不自动清空本机数据。

## 0.9.3

- 状态后增加激活网卡按钮，只启用已匹配的 AirM2M 系统服务并重新检查；权限不足可打开系统网络设置手工启用。
- 关于窗口、脱敏诊断复制、单实例保护、隐私说明、GitHub Issue 模板和自动发布审计。
- 公开发布包不含用户短信、号码、邮箱配置或密码；制作方公开信息保留。
- 版本号去掉 Beta 标签，不代表 Apple 公证或全面实机验证，详见发布说明。

## 0.9.1-beta.1

- 修正将模块 USB ECM 开关误显示为 macOS 实际上网状态的问题。
- 按 USB 归属的 en 接口匹配系统网络服务，读取 service enabled、网卡 UP/link 及 IP，每 5 秒刷新。
- 系统停用 AirM2M Compo 时显示“已停用／已停止上网”，不修改用户网络配置；无法确认时显示未知。
- 区分模块 ECM、系统网卡连接、互联网验证，不再混为同一状态。

## 0.9.0-beta.1

- 软件底部加入制作方“点击网络”、网站入口及蔡立文的公开联系方式。

- USB 验证信息下方独立显示设备已激活／已停用和上网已启动／已停止，依据最新设备回报；未知时等待确认。
- 已删除页新增清空按钮与永久删除确认；清除全部记录，不限于界面 500 条，不影响收件箱和已发送列表。
- 保留无正文的短信 ID 防止模块缓存同步后重新出现；此操作不是 SIM 清理或磁盘安全擦除。
- 清空后新短信序号继续递增，保持邮件转发的新消息过滤正确。
- 31 项离线测试通过；更新不烧录、不切换上网或清空真实短信。

## 0.8.0-beta.1

- 顶部五格 LTE 信号指示，未知信号不显示满格，约 15 秒刷新。
- 失败短信行增加“重新发送”（费用确认，保留原记录）；收件箱行增加“回复短信”。
- 可选的收到短信邮件转发：一个 SMTP 发件账户、最多三个接收邮箱、SSL/STARTTLS、钥匙串保存密码。
- SMTP 登录自检、转发记录、只转发新同步短信，结果未知不自动重复发送。
- 27 项离线自动测试通过，未使用真实 SMTP 凭据或发送实际测试邮件；连接失败采用退避重试，认证失败暂停尝试直到重新保存设置。

## 0.7.0-beta.1

- 独立打包 Python 后端，保留原生短信输入框、收件箱、软删除/恢复和发送记录。
- 端口发现按 USB 设备及接口归属，不再绑定某台机器的设备路径。
- 固件安装增加型号确认，固定官方下载版本和 SHA-256 校验。
- 仓库及安装包不含专有蜂窝核心、个人号码、短信数据库和私人日志。
- 16 项离线测试；沿用固件脚本 0.2.3。公开版未新增真实短信/烧录测试。

## English — Previous changes

- **0.9.5:** per-row Sent Delete, failed Resend retained, row/header checkboxes, stable ID selection, bottom batch deletion with confirmation; current loaded list only (up to 500), active sends protected. Initially local-only, included in 0.9.6.
- **0.9.4:** Router V1.3-style cards/dark-green buttons and two-column SMS; native accessibility, counters, empty states, folder counts, progress/tasks/diagnostics; reset stale selections on folder change; no new phone feature or data clearing. Initially a local preview.
- **0.9.3:** matched AirM2M activation and manual-settings fallback; About, sanitized diagnostics, single-instance protection, privacy/issue templates/source audit. Removes Beta from the version label but does not claim notarization or full hardware validation.
- **0.9.1-beta.1:** fixes ECM-versus-system-status confusion, checks owned interface/service/link/IP every 5 seconds, respects disabled services and shows unknown when unverified. Separates ECM, link and Internet verification.
- **0.9.0-beta.1:** maker website/contact; distinct activation/Internet status; confirmed permanent Deleted clearing including unloaded records, without touching Inbox/Sent/network. Opaque IDs prevent replay; monotonically increasing SMS indices keep new-email filters correct. 31 offline tests; no real SMS, flashing or data clearing by builds.
- **0.8.0-beta.1:** five-bar RSRP/unknown state, failed resend with confirmation, reply prefilling, optional one-sender/three-recipient SMTP with TLS/Keychain, login check/history/new-only forwarding and no unknown-result retry. 27 mocked tests; no real SMTP secrets or actual test email. Connection backoff and authentication pause.
- **0.7.0-beta.1:** initial independently packaged native GUI and backend with offline validation; hardware compatibility and signing limits documented.
