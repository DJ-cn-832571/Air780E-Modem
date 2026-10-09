# Third-party notices

- 项目自有 Swift/Python/Lua 业务代码：根目录 MIT License。
- firmware/lua/sys.lua 来源 openLuat/LuatOS，MIT，Copyright 2019–2026 openLuat & AirM2M。完整许可在 LICENSES/LuatOS-MIT.txt。sysplus.lua 为本项目兼容入口。
- luatos-cli：Wendal Chen，MIT，LICENSES/luatos-cli-MIT.txt。运行时按固定版本从上游下载，本仓库与安装包不包含工具或其内置厂商 boot 二进制。工具包含的第三方组件各自受上游许可约束。
- LuatOS V2052 Air780EHV_1 蜂窝核心：厂商资产，不随本项目再分发，也不授予 MIT 权利。用户从官方 CDN 下载使用，须遵守厂商相关许可。
- 安装包包含 CPython 及其构建所用第三方动态库，许可随包放在 LICENSES。
- 构建工具 PyInstaller：GPL-2.0-or-later，并有允许生成独立应用再分发的 bootloader exception，完整许可随包附带。构建依赖许可不得误认为均是本项目 MIT。

上游：https://github.com/openLuat/LuatOS ，https://github.com/wendal/luatos-cli ，https://pyinstaller.org/ ，https://www.python.org/ 。

