# 参与开发

提交前运行 python3 -m unittest discover -s src -p 'test_*.py'。测试必须模拟硬件，不可自动发送真实短信或烧录。新增型号须单独说明接口、核心固件、许可和实机证据，不要仅按 VID 推断兼容。提交前清理个人信息；修复发送逻辑时保留未知结果状态和禁止自动重发规则。

## English — Contributing

Run `python3 -m unittest discover -s src -p 'test_*.py'` before submitting. Tests must mock hardware and never automatically send real SMS or flash devices. New models require documented interfaces, matching core/license and hardware evidence; vendor IDs alone are insufficient. Remove personal data. Preserve unknown send outcomes and the no-automatic-resend rule. Keep Simplified/Traditional/English UI consistent; never translate identifiers, user SMS or protocol values. Update both documentation languages.
