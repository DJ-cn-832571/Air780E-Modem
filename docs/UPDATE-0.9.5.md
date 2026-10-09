# 0.9.5 已发送管理

已发送操作栏每行提供删除，失败记录仍可重新发送。号码／内容前有行选择框与表头全选；部分选择时全选框为半选状态。批量删除位于列表最底部。

全选仅选择当前已加载列表（最多 500 条），不包含更多历史记录。后台刷新按照记录 ID 保留选择；切换分类清除选择。发送中记录禁止选择或删除，后端也会拒绝包含发送中记录的整个批次。

单条、批量删除均需明确确认。永久删除的是本机发送记录，不进入收件“已删除”分类、不能恢复、不能撤回已经提交的短信；结果未知不等于发送失败。收件箱、已删除列表、邮件配置及模块状态不受影响。

新增删除测试仅操作临时测试数据库，不删除用户真实记录、不发送短信。当前更新只在本地安装，GitHub 0.9.3 未修改。仍未 Apple 公证，兼容范围不变。

47 个离线测试通过。用独立临时数据库在真实窗口验证了三条模拟记录的单行删除按钮、全选计数、底部批量删除确认及取消保留；测试应用禁止所有设备命令，模拟数据未写入用户数据库或安装包。

## English — 0.9.5 sent-record management

Each Sent row offers Delete; failed rows retain Resend. Row checkboxes and header select-all precede Number/Content. Partial selection shows a mixed checkbox. Delete selected is at the list bottom.

Select-all covers only the loaded list (up to 500), not additional history. Selection follows record IDs during background refresh; changing folders clears it. Active sends cannot be selected/deleted and the backend rejects any batch containing one.

Single/batch deletion requires confirmation and permanently removes only local sent history. It does not enter the received-message Deleted folder, cannot be restored or recall an SMS, and does not change inbox, forwarding settings or module state. Unknown outcomes do not mean failure.

47 offline tests passed using temporary databases. An isolated native UI with three synthetic records verified row Delete, select-all counts and batch-confirmation cancellation. Device commands were blocked in the test app; synthetic data never entered the real database or releases. This version was initially local-only; later 0.9.6 includes it. Still not Apple notarized.
