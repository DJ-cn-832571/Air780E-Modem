# 发布前核验：0.7.0-beta.1

## 0.8.0-beta.1 更新核验

- 27 项离线测试通过：增加信号阈值、三邮箱单次分发、历史短信不转发、未知结果不重复发送、TLS 在认证前启用、配置不保存密码及认证失败暂停测试。
- 新版 Cocoa 界面已打开：核对真实设备信号约 2–3 格，模块仍显示 USB 上网已开启、固件 0.2.3。
- 用已有收件记录核对“回复短信”自动填号，已有失败记录核对重发费用确认及原文恢复；测试取消发送，没有新增真实短信发送。
- SMTP 设置界面显示三个邮箱、服务器、端口、用户名、发件地址和安全密码框；核对 macOS 158 个系统信任根可供 TLS 使用。
- 本次没有输入真实邮箱凭据、保存钥匙串密码、发送真实邮件或重新烧录。邮件真实投递和钥匙串保存/读取仍需使用者提供自己的账户后验证，不能宣称已真实投递成功。
- 旧版安装应用已完整备份到工作区；备份、用户短信和邮箱配置不加入发布包。

## 0.7 历史核验

2026-10-08，本机 macOS 27 / Apple Silicon：

- 16 项离线单元测试通过，包括短信结果、列表软删除/恢复、协议解析、USB 接口归属和型号限制。
- Swift GUI 编译成功，独立后端运行 SQLite / TLS / Lua 资源自检成功。
- 内嵌运行库最低系统要求检查：最高为 macOS 26；安装包没有外部 Homebrew 动态库依赖。
- codesign --verify --deep --strict 通过，仅 ad-hoc 签名，未 Apple 公证。
- 已连接设备只读枚举核对：发现一台匹配设备，控制/日志/用户接口为 3/5/7。
- 发布源码与 app 中检查了本机用户名、已知私人号码和私人设备标识，未发现匹配项；没有打包数据库、日志、SSH 密钥或专有核心固件。

本次打包没有重新烧录、启动/停止上网或发送真实短信。此前原硬件版曾实机验证 ECM 上网和短中文短信提交成功；新公开包尚未完成全流程实机回归，真实入站短信、长短信、跨运营商及其他 Mac 系统仍未验证。因此必须按 beta 发布，不能宣称通用兼容或已全面验证。

## English — Verification history

These historical checks are not a claim of full compatibility. On 2026-10-08, Apple Silicon/macOS 27: 16 offline tests covered send outcomes, archive/restore, protocol parsing, interface ownership and model restrictions; Swift compiled; backend SQLite/TLS/Lua self-test passed. Highest bundled runtime minimum was macOS 26, without external Homebrew library dependencies. Deep strict ad-hoc signature verification passed, not notarization. Read-only enumeration found one device with interfaces 3/5/7. Public archives were checked for known personal markers and excluded databases/logs/keys/proprietary core.

0.8 checks: 27 offline tests added signal thresholds, three-address forwarding, no historical forwarding, no resend of unknown outcomes, TLS-before-auth, secret-free configuration and authentication pause. Native UI showed signal around 2–3 bars and firmware 0.2.3/ECM enabled. Existing records tested reply/resend confirmation; sending was cancelled. SMTP showed three addresses and secure input; macOS trust roots were available. No real mailbox secrets, email delivery, Keychain saving or reflashing were performed in those checks.

0.9.3 used 42 offline tests and native/system-state checks; 0.9.5 used 47 tests plus isolated synthetic records to check sent deletion selection and cancellation. None of these UI tests sent SMS or deleted actual user records. Prior hardware tests demonstrated ECM and short Chinese SMS submission, not delivery receipts or a complete release regression. Real SMTP, long/cross-carrier SMS and other Macs need validation. Private app backups are excluded from release archives.
