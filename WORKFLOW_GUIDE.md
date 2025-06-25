# Box for Magisk 工作流详细指南

## 概述

本工作流提供了一个完整的自动化解决方案，用于生成和推送 Box for Magisk 模块包。工作流包含以下主要功能：

1. **默认运行模式配置** - 使用 sing-box 核心，enhance 网络模式，黑名单透明代理
2. **自动核心管理** - 检测本地核心，如不存在则下载 sing-box beta 版本
3. **UI 集成** - 默认使用 zashboard UI 替代 yacd
4. **模块包生成** - 自动打包生成 Magisk 模块
5. **Telegram Bot 推送** - 自动推送到指定的 Telegram 频道

## 默认运行模式详解

### 1. 核心配置
- **默认核心**: sing-box
- **版本选择**: beta 版本（功能更新，稳定性良好）
- **安装位置**: `/data/adb/box/bin/sing-box`
- **权限设置**: 6755 (setuid + setgid + 执行权限)
- **用户组**: root:net_admin

### 2. 网络模式配置
- **默认模式**: enhance（增强模式）
- **工作原理**: 
  - TCP 流量使用 redirect 模式
  - UDP 流量使用 tproxy 模式
  - 提供最佳的兼容性和性能平衡

### 3. 透明代理规则
- **默认模式**: blacklist（黑名单模式）
- **配置文件**: `/data/adb/box/package.list.cfg`
- **工作原理**: 
  - 默认所有应用都通过代理
  - 可在配置文件中添加例外应用
  - 支持包名和 GID 两种方式

### 4. UI 界面配置
- **默认 UI**: zashboard
- **下载源**: https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
- **安装位置**: `/data/adb/box/sing-box/dashboard`
- **访问地址**: http://127.0.0.1:9090/ui/

## 工作流执行步骤

### 步骤 1: 环境检查
```bash
# 检查系统依赖
- curl: 用于下载文件
- unzip: 用于解压缩
- zip: 用于打包模块
- python3: 用于 Telegram 推送
```

### 步骤 2: 工作空间初始化
```bash
# 创建必要目录
/tmp/box_workflow/          # 临时工作目录
./build/                    # 构建输出目录
/data/adb/box/bin/         # 核心文件目录
/data/adb/box/*/dashboard/ # UI 文件目录
```

### 步骤 3: 默认配置设置
```bash
# 修改 settings.ini
bin_name="sing-box"
network_mode="enhance"

# 修改 package.list.cfg
mode:blacklist
```

### 步骤 4: 核心下载与安装
```bash
# 检测架构
aarch64 -> arm64
armv7l/armv8l -> armv7
x86_64 -> amd64
i386 -> 386

# 下载最新 beta 版本
curl -s "https://api.github.com/repos/SagerNet/sing-box/releases"
# 解压并安装到指定位置
```

### 步骤 5: UI 下载与配置
```bash
# 下载 zashboard
curl -L "https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip"
# 解压到 dashboard 目录
# 更新 webroot 重定向页面
```

### 步骤 6: 模块包生成
```bash
# 更新版本代码
versionCode=$(date +%Y%m%d)
# 打包模块文件
zip -r box_for_root-${version}.zip
```

### 步骤 7: Telegram 推送
```bash
# 设置环境变量
export API_ID BOT_TOKEN API_HASH
# 使用 telethon 库推送文件
python3 .github/taamarinbot.py
```

## 使用方法

### 基本使用
```bash
# 使用默认配置
./workflow_generator.sh

# 显示帮助信息
./workflow_generator.sh --help
```

### 高级配置
```bash
# 指定不同的核心
./workflow_generator.sh --core clash

# 指定网络模式
./workflow_generator.sh --mode tproxy

# 指定代理模式
./workflow_generator.sh --proxy-mode whitelist

# 指定 UI 界面
./workflow_generator.sh --ui yacd
```

### 跳过特定步骤
```bash
# 跳过核心下载
./workflow_generator.sh --skip-core

# 跳过 UI 下载
./workflow_generator.sh --skip-ui

# 跳过 Telegram 推送
./workflow_generator.sh --skip-telegram

# 仅生成模块包
./workflow_generator.sh --build-only
```

## 环境变量配置

### Telegram Bot 配置
```bash
export API_ID="your_api_id"
export API_HASH="your_api_hash"
export BOT_TOKEN="your_bot_token"
export CHAT_ID="-1001597117128"  # 可选，默认值
export MESSAGE_THREAD_ID="282263"  # 可选，默认值
```

### 获取 Telegram 配置
1. **API_ID 和 API_HASH**: 
   - 访问 https://my.telegram.org/apps
   - 创建应用获取 API credentials

2. **BOT_TOKEN**:
   - 与 @BotFather 对话创建 bot
   - 获取 bot token

3. **CHAT_ID**:
   - 将 bot 添加到目标群组
   - 使用 bot API 获取 chat ID

## 配置文件说明

### settings.ini 关键配置
```ini
# 核心选择
bin_name="sing-box"

# 网络模式
network_mode="enhance"  # redirect|tproxy|mixed|enhance|tun

# 端口配置
tproxy_port="9898"
redir_port="9797"

# IPv6 支持
ipv6="false"

# 用户组设置
box_user_group="root:net_admin"
```

### package.list.cfg 配置
```ini
# 代理模式
mode:blacklist  # whitelist|blacklist

# 应用包名示例
# com.android.chrome
# com.tencent.mm

# GID 示例
# 10086 com.example.app
```

### ap.list.cfg 网络接口配置
```ini
# 允许的网络接口
allow ap+
allow wlan+
allow rndis+
allow swlan+
allow ncm+
allow eth+

# 忽略的网络接口
# ignore wlan0
# ignore swlan0
```

## 故障排除

### 常见问题

1. **核心下载失败**
   - 检查网络连接
   - 确认 GitHub 访问正常
   - 尝试使用代理

2. **UI 下载失败**
   - 检查 GitHub 访问
   - 确认解压工具可用
   - 检查磁盘空间

3. **Telegram 推送失败**
   - 验证环境变量设置
   - 检查 bot 权限
   - 确认网络连接

4. **模块包生成失败**
   - 检查文件权限
   - 确认磁盘空间
   - 验证 zip 工具可用

### 日志查看
```bash
# 工作流执行日志会实时显示
# 错误信息会以红色显示
# 警告信息会以黄色显示
# 调试信息会以蓝色显示
```

## 自定义扩展

### 添加新的核心支持
1. 在 `download_*_core()` 函数中添加下载逻辑
2. 更新参数验证部分
3. 在主工作流中添加调用

### 添加新的 UI 支持
1. 创建 `download_*_ui()` 函数
2. 更新 UI 选择逻辑
3. 配置相应的访问路径

### 自定义推送目标
1. 修改 Telegram 配置变量
2. 更新推送脚本逻辑
3. 添加其他推送方式支持

## 最佳实践

1. **定期更新**: 建议定期运行工作流以获取最新版本
2. **备份配置**: 在运行前备份重要配置文件
3. **测试环境**: 在生产环境前先在测试环境验证
4. **监控日志**: 关注工作流执行日志，及时发现问题
5. **网络环境**: 确保稳定的网络连接，特别是访问 GitHub

## 版本历史

- **v1.0**: 初始版本，支持基本的工作流功能
  - sing-box 核心支持
  - zashboard UI 集成
  - Telegram Bot 推送
  - 模块包自动生成
