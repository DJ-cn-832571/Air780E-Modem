# 0.9.4 界面预览

本地界面更新；GitHub 的 v0.9.3 保持不变。不是电话功能版本，没有新增拨打或接听电话。

参考用户指定的 Air780E Modem for Router V1.3 页面：白底圆角卡片、深绿色主按钮、三张状态卡、短信列表与发送区左右分栏。保留原生 macOS 文本编辑、键盘操作及辅助功能标签。

- 状态卡：蜂窝五格信号、RSRP、短信就绪、本机号码、系统网卡状态。没有设备时显示未知／读取失败，不以历史值冒充实时状态。
- 原有启停上网、激活网卡、打开系统网络设置、安装／修复固件功能保留，未修改固件协议。
- 短信分类显示记录数与空列表说明；删除页显示恢复操作与清空按钮；空列表禁用清空，永久清空仍确认。
- 右侧固定发送表单，实时字数计数，超过 500 字红色提示；发送仍需要确认，未知结果不自动重发。
- 保留回复、失败重发、三个邮箱及 SMTP 设置；任务详情和脱敏诊断分开，避免把含私人信息的任务日志当作脱敏信息公开。
- 后台任务显示进度指示。同步失败显示简明提示，可查看完整任务详情。

验证：42 个离线后端测试通过、Swift 编译、安装包签名结构与内嵌后端自检通过。真实 UI 已检查空收件箱、已删除空状态、输入 10 个字符时的计数及清除测试草稿。当前 Mac 未发现配套 USB 设备，未在这次界面改版中重新验证蜂窝上网、短信、SMTP 或固件烧录。未发送短信、未更改路由器设置。

仍然是 ad-hoc 签名，未 Apple 公证。适用范围仍是 Apple Silicon、macOS 26+、Air780EHV_A11。使用同一个本机数据目录，升级不清空记录或邮箱设置。

## English — 0.9.4 UI preview

Local UI update inspired by the user's Router V1.3 page: white rounded cards, dark-green actions, three status cards and side-by-side SMS list/composer. Native text editing, keyboard behavior and accessibility labels are retained. This is not the phone-call release and did not alter historical GitHub 0.9.3.

Cards show five-bar RSRP, SMS readiness, own number and actual system adapter state. Missing devices show unknown/read failure, not stale live claims. Existing networking/activation/firmware behavior remains. Folder counts/empty states, restore labeling, empty-trash disabling, a live 500-character counter, send confirmations, reply/resend, three-mailbox SMTP, progress and separate raw task/sanitized diagnostics remain.

42 offline tests, Swift compile, backend self-test and signature structure passed. Native checks covered empty folders, a ten-character draft and clearing that test draft. No matching USB device was available on the Mac for this UI update; actual cellular/SMS/SMTP/flashing were not re-tested. No SMS was sent and router settings were unchanged. Ad-hoc/non-notarized; Apple Silicon/macOS 26+/Air780EHV_A11; same local data directory, no automatic data clearing.
