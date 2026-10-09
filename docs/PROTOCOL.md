# 架构与协议

Cocoa GUI → 独立 modem-backend → macOS 原生串口 → uart.VUART_0 → LuatOS Lua → mobile / sms。

USB 发现使用 IORegistry：运行态 VID 19d1、PID 0001；下载态 VID 17d1、PID 0001。这些 ID 只能帮助识别设备类别，不能证明模块型号。烧录必须手工核对 Air780EHV_A11。
运行态接口 7 为用户协议数据口，接口 3 为 SOC 控制数据口；无法获得匹配接口时安全拒绝操作，不猜测任意串口。

协议为 UTF-8 JSON + 换行：app=AIR780E_DEMO，protocol=1，request_id 为 UUID。主机被动读取设备身份后才下发命令。
actions：status、start、stop、inbox、send_sms。事件包括 status、network、sms_received、sms_sent、error。
send_sms 包含 number、message；sms_sent.success=true 表示提交成功。每个请求按 request_id 关联，发送最长等候约 65 秒。未知结果不自动重试，以免重复计费。

上网状态持久化到 fskv；USB 配置切换期间不能在 USB 关闭时插入会让出执行权的等待。
中国 +86 号码使用 sms.sendLong(number,message,true).wait()；其余号码使用 false。沿用已实机验证的调用方式。
本地 SQLite 存储收件箱、软删除标记、已发送状态。多个进程共享 flock 锁，禁止并发占用设备。

官方资产 URL 和 SHA-256 固定于 src/assets.py。当前核心 V2052 Air780EHV_1，工具 v1.11.0 aarch64-apple-darwin。每次使用核心检查哈希；CLI 从已校验归档重新提取，不使用未经检查的缓存可执行文件。更改版本必须重新核验型号、来源、许可、哈希及实机测试。

脚本版本 0.2.3；GUI 发布版本 0.9.6。新增功能不需要重新烧录。

sync_json 返回 messages 和 status；status.signalBars 为近似 RSRP 格数或 null。邮件模块独立于设备锁，使用 email.lock 防止并发转发。SMTP 密码由原生 UI 钥匙串读取并经标准输入管道传给后端，配置文件没有密码。TLS 信任根读取 macOS 系统证书，不依赖 Homebrew 证书路径。

## English — Architecture and protocol

Cocoa GUI → bundled modem-backend → native macOS serial → uart.VUART_0 → LuatOS Lua → mobile / sms.

Discovery uses IORegistry: runtime VID 19d1/PID 0001; download VID 17d1/PID 0001. IDs identify a family, not a model; physically confirm Air780EHV_A11 before flashing. Runtime interface 7 is the user protocol port; interface 3 is SOC control. Missing ownership causes safe refusal, not guessing.

Protocol is newline-delimited UTF-8 JSON: app=AIR780E_DEMO, protocol=1, UUID request_id. Identity is passively read before commands. Device actions: status, start, stop, inbox, send_sms. Events: status, network, sms_received, sms_sent, error. Send includes number/message; success means submission accepted, not delivery. Requests correlate by ID and may wait about 65 seconds. Unknown outcomes are never automatically retried.

ECM state persists via fskv; avoid yielding while USB is disabled during reconfiguration. Chinese +86 numbers use sms.sendLong(number,message,true).wait(), others false, matching prior hardware validation. SQLite tracks received/soft-deleted messages and durable sent results. flock prevents concurrent device access. Local delete_sent requires explicit confirmation and never opens a device port; it atomically rejects batches containing active sends.

Assets/pinned SHA-256 are in src/assets.py: V2052 Air780EHV_1 core, v1.11.0 aarch64-apple-darwin CLI. Core hashes are rechecked; CLI is re-extracted from a verified archive. Version changes require model/source/license/hash/hardware validation.

Lua is 0.2.3; GUI is 0.9.6. This UI/local-history update does not require reflashing. sync_json returns messages/status; signalBars is approximate RSRP or null. Email has its own lock. Keychain secrets reach the backend via stdin. Trust roots use macOS, not a Homebrew certificate path. Localization is host UI only; protocol, identifiers and SMS bodies are unchanged.
