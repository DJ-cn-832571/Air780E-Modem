# Air780E Modem 0.9.3 发布说明

发布版本号：0.9.3（非 Beta 标签）。这是独立开发的社区软件，不是合宙官方产品。版本标签不等同于 Apple 公证或所有设备通过验证。

## 安装包适用范围

Apple Silicon Mac、macOS 26+、Air780EHV_A11 / EC718HM。Intel Mac 和其他 Air780 系列不在支持范围。普通使用无需安装 Python 或 Homebrew。
当前包只有 ad-hoc 签名，没有 Developer ID 签名或 Apple 公证；正式面向大量普通用户推广前建议完成签名和公证，按 docs/PUBLISH.md 执行。

## 更新内容

- 显示系统 AirM2M 网络服务、网卡链路和 IP 状态，不以模块 ECM 开关代替实际系统服务状态。
- 停用时提供“激活网卡”：只启用匹配 USB 接口的服务，随后重新核对。当前权限不允许操作时提供打开系统网络设置入口，让用户手动启用，不索要或保存管理员密码。
- 激活网卡不修改 Wi-Fi、DNS、VPN、默认路由或运营商 APN；仍需按需点击启动上网开启模块 ECM，启用不等于互联网已经可达。
- 保留五格信号、短信输入、回复、失败记录重发、已删除清空和最多三个邮箱转发。
- 新增关于窗口、脱敏诊断复制和单实例保护。
- 公开源码、安装包均不包含短信数据库、私人测试号码、邮箱密码、设备日志或专有核心固件。

## 已核验与未核验

已核验：离线单元测试、本机原生界面、系统 AirM2M 服务 Disabled 检测、之前本设备 ECM 绑定请求和短中文短信提交、列表显示/回复/重发确认，以及清理短信后空列表和模块空缓存。
“激活网卡”写入流程通过模拟测试，不在打包时强制撤销当前系统停用设置；需要用户实际点击后验证当前账户权限，权限不足可手工启用。
SMTP 真实投递、钥匙串实际保存、长短信/跨运营商、其他 Mac 系统仍未完整验证；不能写“所有功能全面实测”或“所有 Air780E 均支持”。

## 安全与费用

发送短信可能计费，长短信可能按多条计费；短信中心接受不代表手机送达。
邮箱转发默认关闭，启用后仅转发新同步短信；验证码等敏感内容可能被转发，请只设置可信邮箱。
清空已删除短信不可恢复，不是 SIM 清理或磁盘安全擦除。发布包始终为空，不需要清空本机才能发布。
固件安装覆盖模块核心与应用，无原固件自动备份；首次从官方 HTTPS 来源下载并校验，需要另一条可用网络。

## GitHub Release 附件

上传 dist/0.9.3/ 中的 DMG、app ZIP、源码 ZIP 和 SHA256SUMS.txt，不上传父工作区、build、.build-venv、短信目录或应用备份。
GitHub 发布地址：https://github.com/DJ-cn-832571/Air780E-Modem/releases/tag/v0.9.3

## English — Air780E Modem 0.9.3

Independent community software, not an official LuatOS product. The non-Beta version label is not notarization or universal validation.

Requires Apple Silicon/macOS 26+ and Air780EHV_A11/EC718HM. Intel/other models unsupported. Python/Homebrew not required for use. Ad-hoc signed only, not Developer ID signed/notarized; complete signing before broad distribution.

Updates: matched system AirM2M service/link/IP state rather than ECM-only state; Enable adapter for the verified USB service with recheck and manual Network settings fallback on permission failure. Wi-Fi/DNS/VPN/default routes/APN are unchanged. Service activation is not guaranteed Internet access. Five-bar signal, SMS entry/reply/failed resend/Deleted clearing and up to three forwarding addresses remain. About, sanitized diagnostics, single-instance protection and privacy docs are added. Public archives exclude personal data, passwords, logs and proprietary core firmware.

Verified: offline tests/native UI, Disabled-state detection, prior bound ECM HTTPS and short Chinese SMS submission, list/reply/resend confirmations and empty local/module cache after authorized cleanup. Adapter mutation was mocked, not forced during packaging. Real SMTP/Keychain persistence, long/cross-carrier SMS and other Macs were not fully validated.

SMS may incur charges; acceptance is not delivery. Forwarding defaults off and sends only newly synced messages to trusted addresses, possibly including sensitive codes. Emptying Deleted is irreversible local deletion, not SIM clearing or secure erasure. Flashing overwrites core/scripts, has no original backup and first downloads verified official assets over another working connection.

Release attachments: DMG, app ZIP, source ZIP, SHA256SUMS. Historical 0.9.3 binaries do not include later UI/language/sent-delete features. [Download 0.9.3](https://github.com/DJ-cn-832571/Air780E-Modem/releases/tag/v0.9.3).
