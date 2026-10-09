# 安全说明

不要在公开 Issue 中提交真实短信、手机号、IMEI、IMSI、ICCID、数据库或证书。安全问题可私下联系 cailiwen@dj.cn（蔡立文）；仓库发布者建议同时启用 GitHub Private vulnerability reporting。请勿发送密码或完整短信数据库。

固件安装会覆盖原固件，不提供原固件备份。只允许已确认型号。下载固定 HTTPS 来源并验证 SHA-256，不支持跳过校验。

短信数据库只有本地权限保护，没有应用层加密。发送短信可能计费。未知发送结果不会自动重试。本项目不是紧急通信设备。

邮箱转发默认关闭；开启后会将新同步短信、发送号码及时间发送给指定邮箱，可能包括验证码等敏感信息。请确认最多三个接收邮箱的所有者和邮箱安全。密码/SMTP 授权码只存入 macOS 钥匙串，后端通过匿名标准输入管道接收，不出现在进程参数或配置文件。仅允许验证证书的 SSL/STARTTLS，不支持关闭 TLS 校验。SMTP 认证失败暂停尝试，未知投递结果不自动重发。

## English — Security

Do not post real SMS, phone numbers, IMEI/IMSI/ICCID, databases, passwords, certificates or keys in public Issues. Contact cailiwen@dj.cn (Cai Liwen) privately for security reports. The publisher should also enable GitHub private vulnerability reporting; do not send passwords or full databases.

Flashing overwrites firmware with no original backup. Physically confirm the model. Assets use pinned HTTPS sources and SHA-256; bypasses are unsupported. Local SMS has account permissions but no app-layer encryption. SMS may cost money; unknown results are not automatically retried. This is not an emergency communication device.

Forwarding defaults off. When enabled, numbers/times/bodies—including verification codes—go to up to three trusted email addresses. Passwords/app passwords use Keychain and anonymous stdin, never arguments/config. Only certificate-verified SSL/STARTTLS is allowed. Authentication failure pauses attempts; unknown delivery is not retried. Raw task logs may contain personal content; prefer sanitized diagnostics.
