# 隐私说明

应用默认把短信存到当前 Mac 的 ~/Library/Application Support/Air780E Modem/。
SQLite 内容含号码、短信正文、时间、发送结果及可选邮箱投递记录。目录和数据库权限受本地账户保护，但应用没有额外加密数据库；建议开启 FileVault。

没有遥测、账户注册或默认云端备份。邮箱转发默认关闭；用户启用后，新同步短信的号码、时间和正文会发给最多三个指定邮箱。SMTP 密码或授权码存入 macOS 钥匙串，经匿名管道传给本地后端，不写到配置、命令行或日志。
启用转发不发送历史短信。未知投递结果不自动重试，认证失败暂停尝试。

首次安装固件下载访问官方 LuatOS CDN 与 GitHub，并验证固定 SHA-256。上网验证使用绑定模块接口的 HTTPS 请求；用户点击制作方网站才打开 www.DJ.cn。
激活网卡只更改所匹配系统 USB 服务的启用状态，不开启其他服务或关闭系统安全保护。

复制脱敏诊断信息包含应用版本、macOS 版本、处理器架构、USB 接口名与系统启用/链路状态，不含短信、电话号码、SIM 标识、邮箱、密码或用户名。本机文件路径不写入诊断输出。提交前仍请自行检查截图和说明。

删除短信为软删除；清空已删除为不可恢复的应用层删除。清空全部本地记录不会擦除系统备份、APFS 快照、运营商记录或对方已收到的短信。无正文的消息 ID 可能保留，用来避免设备缓存重放已清除消息。
卸载应用不自动删除本地数据库、设置或钥匙串项目；请在理解后果后自行管理。邮箱转发记录不会因仅清空已删除页而全部清除。

公开发行包不包含个人数据；正式发布不要添加真实短信截图。制作方公开联系方式 cailiwen@dj.cn · 蔡立文按发布者要求保留。

## English — Privacy

The app stores SMS in `~/Library/Application Support/Air780E Modem/` on the current Mac. SQLite includes numbers, bodies, times, send results and optional email-delivery history. Account permissions protect it, but the app does not encrypt the database; consider FileVault.

There is no telemetry, account registration or default cloud backup. Email forwarding defaults to off. Enabling sends newly synced numbers/times/bodies to up to three addresses. SMTP passwords/app passwords use Keychain and reach the local backend via an anonymous pipe, never configuration, arguments or logs. Historical SMS are not automatically forwarded. Unknown submission results are not retried; authentication failure pauses attempts.

First-time firmware setup contacts official LuatOS CDN and GitHub and verifies pinned SHA-256. Connectivity checks bind HTTPS to the module interface. The maker website opens only on request. Adapter activation changes only the matched USB service; no other services or security protections are changed.

Sanitized diagnostics includes app/macOS versions, architecture, interface names and system/link state; excludes SMS, numbers, SIM identifiers, email addresses, passwords, usernames and file paths. Still review any material before sharing. Raw task views may contain personal content.

Received-message deletion is recoverable; emptying Deleted is irreversible at app level. Sent-record deletion is permanent after confirmation and cannot recall SMS. Clearing data does not erase backups, APFS snapshots, carrier records or recipient messages. Opaque IDs may remain to prevent replay. Uninstalling does not delete data/settings/Keychain. Emptying Deleted does not clear all forwarding history.

Public packages contain no user data. Never publish real SMS screenshots. Publisher-approved maker contact remains public: cailiwen@dj.cn, Cai Liwen (蔡立文). Language is a local preference; switching never sends SMS or changes message content.
