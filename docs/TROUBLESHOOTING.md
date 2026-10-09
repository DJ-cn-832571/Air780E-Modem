# 排障

- 未发现配套固件：USB 已连接不代表已运行本项目 Lua 协议。核对型号后从 GUI 安装；只有通用 USB ID 而没有型号证据时不要烧录。
- 无法安全识别控制口：只接一台模块，重插并检查线材/供电。保留日志，不要随意选择其他串口、短接脚位或刷不同型号。
- 下载失败：首次烧录需要其他可用网络，可能无法访问 GitHub/CDN；软件不会跳过 TLS 和 SHA 校验。
- 短信未就绪：检查天线、SIM 注册状态和运营商短信业务。先等待，不要不停重复发送。
- 发送失败：查看已发送列表详情。若结果未知，先核实是否收到，避免重复计费；本软件不会自动重发。
- 收不到短信：保持应用打开并刷新，SIM 必须支持短信。真实入站流程仍属于 beta 验证范围；删除仅改变 Mac 列表。
- 能启动 ECM 但浏览器不走模块：检查系统网络服务优先级和 VPN；应用没有修改默认路由。
- 无手机号：SIM 未保存本机号码时属于正常限制，不代表 SIM 无效。
- macOS 安全拦截：核对来源和发布校验清单，按系统单应用批准流程处理；不要关闭 Gatekeeper。
- 烧录写入完成但校验失败：保留完整日志，重插后点击设备状态；不要立即反复烧录。

## English — Troubleshooting

- No matching firmware protocol: USB presence alone is not proof that the project's Lua protocol is running. Check model/cable/power and Device status. Do not flash based only on generic USB IDs.
- Control port cannot be identified safely: connect one module, reconnect and inspect power/cable. Keep logs; do not guess another port, short pins or flash a different model.
- Download fails: first flashing needs another working network and access to GitHub/CDN. TLS and SHA checks are never bypassed.
- SMS not ready: check antenna, SIM registration and carrier SMS service. Wait rather than repeatedly sending.
- Send fails: inspect Sent details. Unknown is not failure; verify reception before retrying to avoid charges. No automatic resend.
- No incoming SMS: keep the app running and sync; the SIM must support SMS. Deletion changes the local list, not SIM storage. Incoming behavior across hardware/carriers still needs regression testing.
- ECM starts but browser traffic uses another connection: inspect service priority and VPN. The app does not rewrite default routes.
- No own phone number: a SIM may not store it; this does not make the SIM invalid.
- macOS blocks the app: verify source/checksums and use per-app approval; do not disable Gatekeeper.
- Flash writes but verification fails: keep complete logs, reconnect, check Device status; do not repeatedly reflash without diagnosis.
- Sent delete/select-all unavailable: active sends are protected; wait. Select-all covers only the loaded list (up to 500). Deleted sent records cannot be restored.
- Switch language at the top; changes are blocked during tasks or confirmations. Technical/vendor logs and user content retain their original language.
