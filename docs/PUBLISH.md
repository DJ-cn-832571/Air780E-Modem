# GitHub 发布指南

只发布这个 Air780E-Modem 目录，不要上传其父目录、原始私人开发目录或 Library 中的短信数据库。

1. 在 GitHub 新建空仓库，推荐名称 Air780E-Modem。
2. 在本目录执行下面的命令，把 YOUR_ACCOUNT 改成自己的用户名：

```sh
git init
git add src firmware scripts docs LICENSES .github README.md LICENSE CHANGELOG.md SECURITY.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md requirements-build.txt .gitignore
git commit -m "Release 0.9.3"
git branch -M main
git remote add origin https://github.com/YOUR_ACCOUNT/Air780E-Modem.git
git push -u origin main
```

3. 准备 Release，标签 v0.9.3。上传 dist/0.9.3/ 下两个安装包、源码 ZIP 和 SHA256SUMS.txt，并使用 docs/RELEASE-0.9.3.md 作为说明。版本号不再带 Beta；如仍未完成 Developer ID、公证或面向目标用户的验收，建议先标记 Pre-release，完成后再转正式，而不是隐瞒限制。
4. Release 说明必须注明：Apple Silicon、macOS 26+、仅 Air780EHV_A11、首次烧录需联网、覆盖原固件、不含原固件备份、尚未公证，以及已核验和未核验范围。
5. 不要把 .build-venv、build、dist、*.soc、*.sqlite、设备日志或实际手机号加入源码仓库。自动测试仅执行模拟用例。

## 正式签名与 Apple 公证

本次 beta 使用 ad-hoc 签名，不能假称已公证。正式对外发布建议用自己的 Developer ID Application 证书，对内嵌后端及其动态库从内向外签名，启用 hardened runtime；Python 所需 entitlements 必须评估而非盲目复制。最后签主应用，并执行 codesign --verify --deep --strict。

把已正确签名的应用压缩后用 xcrun notarytool submit 提交（使用自己钥匙串中的凭据），等待 Accepted 后对应用 stapler staple，再重新生成安装包和校验清单。当前脚本的 SIGN_IDENTITY 仅支持基础签名，不是完整公证流程。不要发布 Apple 密码、证书私钥或 CI secret。

GitHub Actions 工作流只运行离线测试，不自动创建 Release、烧录设备或发短信。
