# Box for Root

[![ID](https://img.shields.io/badge/id-blue.svg?style=for-the-badge)](docs/index_id.md) [![EN](https://img.shields.io/badge/en-blue.svg?style=for-the-badge)](docs/index_en.md) [![ZH](https://img.shields.io/badge/zh-blue.svg?style=for-the-badge)](docs/index_zh.md)

<h1 align="center">
  <img src="https://github.com/taamarin/box_for_magisk/blob/master/docs/box.svg" alt="BOX" width="200">
  <br>BOX<br>
</h1>
<h4 align="center">Transparent Proxy for Android (Root)</h4>

<div align="center">
  <a href="https://github.com/taamarin/box_for_magisk/releases">
    <img src="https://img.shields.io/github/downloads/taamarin/box_for_magisk/total.svg?style=for-the-badge" alt="Releases">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  </a>
</div>

## Introduction
`Box for Root` (BFR) 是一个专为 [Magisk](https://github.com/topjohnwu/Magisk), [KernelSU](https://github.com/tiann/KernelSU), [APatch](https://github.com/bmax121/APatch) 优化的透明代理模块。

### 🌟 Sing-box 专用分支
当前分支是 **sing-box 专用优化版本**，专注于提供高性能的 `sing-box` 代理服务。该版本移除了其他代理工具支持，专门为sing-box进行了深度优化，提供更好的性能和稳定性。

📖 **[查看 Sing-box 分支详细说明 →](README-SINGBOX.md)**

### 分支对比
- **主分支** (`master`): 支持多种代理核心 (clash, xray, v2fly, hysteria, sing-box)
- **Sing-box 分支** (`sing-box`): 仅支持 sing-box，但提供更好的性能和专业功能

## Features

### 🎯 Sing-box 专用特性
- 🚀 **专为 sing-box 优化**：移除其他核心，专注性能提升
- 🎨 **Zashboard 集成**：专业的 Web 管理界面
- 🔧 **增强网络模式**：创新的 `enhance` 模式，结合 REDIRECT 和 TPROXY 优势
- ⚡ **性能优化**：cgroup 配置、CPU 绑定、内存管理
- 🤖 **完整自动化**：GitHub Actions 自动更新和构建系统
- 📱 **无缝集成**：完美支持 Magisk, KernelSU, 和 APatch
- 🛡️ **智能分流**：优化的规则管理和流量处理

### 🔄 分支切换指南
```bash
# 切换到 sing-box 专用分支
git checkout sing-box

# 切换回主分支
git checkout master
```

**推荐使用场景**：
- **Sing-box 分支**：追求高性能、稳定性，只使用 sing-box 核心
- **主分支**：需要多核心支持，兼容性优先

## Apk Manager
You can use the **BFR Manager** app (optional) to manage Box for Root on your device.
[Download BFR Manager](https://github.com/taamarin/box.manager)
> ⚠️ If you receive continuous notifications, open Magisk Manager, navigate to SuperUser, search for `BoxForRoot`, and disable logs and notifications.

## Module Directory
The core files of the module are stored in the following directories:
- `MODDIR=/data/adb/box`
- `MODLOG=/data/adb/box/run`
- `SETTINGS=/data/adb/box/settings.ini`
> ⚠️ Before editing the `settings.ini` file located at `/data/adb/box/settings.ini`, ensure that BFR is turned off to avoid configuration issues.

## Manage Service Start/Stop
The following core services are collectively referred to as **BFR**. By default, the BFR service auto-starts after a system boot. You can manage the service through Magisk/KernelSU Manager App, with the service start taking a few seconds, and stopping it taking effect immediately.

### To start the service:
```bash
su -c /data/adb/box/scripts/box.service start && su -c /data/adb/box/scripts/box.iptables enable
```
### To stop the service:
```bash
su -c /data/adb/box/scripts/box.iptables disable && su -c /data/adb/box/scripts/box.service stop
```

## Here are some additional instructions:
- When modifying any of the core configuration files, ensure that the tproxy-related configurations match the definitions in the **/data/adb/box/settings.ini** file.
- If your device has a public IP address, you can add that IP address to the internal network in the **/data/adb/box/scripts/box.iptables** file to prevent loopback traffic.
- The logs for the BFM service can be found in the directory **/data/adb/box/run**.
- Please note that modifying these files requires appropriate permissions. Make sure to carefully follow the instructions and validate any changes made to the configuration files.

You can run the following command to get other related operating instructions:
```bash
  su -c /data/adb/box/scripts/box.tool
  # usage: {check|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|all}
  su -c /data/adb/box/scripts/box.service
  # usage: $0 {start|stop|restart|status|cron|kcron}
  su -c /data/adb/box/scripts/box.iptables
  # usage: $0 {enable|disable|renew}
```

## 🤖 GitHub Actions 自动化系统

本项目配置了完整的GitHub Actions自动化系统，提供以下功能：

### 🔄 自动更新
- **sing-box核心自动更新**: 每天检查并更新sing-box到最新版本
- **Zashboard UI自动更新**: 自动更新Web管理界面到最新版本
- **多架构支持**: 自动下载amd64, arm64, armv7架构的二进制文件
- **智能版本管理**: 语义化版本控制和自动版本递增

### 📦 自动打包
- **自动构建**: 代码变更时自动构建Magisk模块
- **版本发布**: 自动创建GitHub Release和开发版本
- **文件校验**: 自动生成SHA256和MD5校验文件
- **详细日志**: 自动生成版本更新日志

### 🧪 持续集成
- **配置验证**: 自动验证JSON配置文件格式
- **脚本测试**: Shell脚本语法和功能检查
- **结构验证**: 模块结构完整性检查
- **集成测试**: 端到端功能测试

### 📊 监控和通知
- **构建状态**: 实时监控构建和测试状态
- **错误报告**: 自动生成故障报告和建议
- **性能监控**: 构建时间和资源使用监控

详细使用说明请参考 [GitHub Actions文档](.github/README.md)

## 🎨 Web管理界面

集成了Zashboard Web管理界面，提供直观的图形化管理：

- **访问地址**: `http://127.0.0.1:9090`
- **实时监控**: 连接状态、流量统计、性能指标
- **配置管理**: 可视化配置编辑和验证
- **日志查看**: 实时日志监控和分析
- **规则管理**: 分流规则可视化管理

### 配置文件
- **sing-box配置**: `/data/adb/box/sing-box/config.json`
- **Zashboard配置**: `/data/adb/box/sing-box/zashboard-config.json`
- **模块设置**: `/data/adb/box/settings.ini`

## Uninstall
Remove the module from `Magisk/KernelSU/APatch Manager` and run the following command to wipe the data:
```bash
su -c rm -rf /data/adb/box
su -c rm -rf /data/adb/service.d/box_service.sh
su -c rm -rf /data/adb/modules/box_for_root
```

## Credits
- [CHIZI-0618/box4magisk](https://github.com/CHIZI-0618/box4magisk) for the original Box for Magisk module.

## License
This project is licensed under the GPL-3.0 license - see the [LICENSE](https://github.com/taamarin/box_for_magisk/blob/master/LICENSE) file for details.
