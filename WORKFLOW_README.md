# Box for Magisk 自动化工作流

## 🚀 快速开始

这是一个完整的自动化工作流，用于生成和推送 Box for Magisk 模块包。工作流实现了以下默认配置：

- **默认核心**: sing-box (beta 版本)
- **网络模式**: enhance (增强模式)
- **透明代理**: blacklist (黑名单模式)  
- **默认UI**: zashboard
- **自动推送**: Telegram Bot

## 📁 文件结构

```
├── workflow_generator.sh    # 主工作流脚本
├── quick_setup.sh          # 快速设置脚本
├── WORKFLOW_GUIDE.md       # 详细使用指南
└── WORKFLOW_README.md      # 本文件
```

## ⚡ 快速使用

### 1. 基本使用（推荐）
```bash
# 使用默认配置生成模块包
chmod +x workflow_generator.sh
./workflow_generator.sh
```

### 2. 快速设置现有安装
```bash
# 在已安装 Box for Magisk 的设备上快速配置
chmod +x quick_setup.sh
su -c './quick_setup.sh'
```

## 🔧 默认运行模式详解

### 核心配置
- **sing-box**: 选择 beta 版本，功能更新且稳定性良好
- **自动检测**: 如果本地不存在核心，自动下载适合架构的版本
- **权限设置**: 自动设置正确的权限和用户组

### 网络模式 - enhance
```
TCP 流量 → redirect 模式
UDP 流量 → tproxy 模式
```
这种组合提供最佳的兼容性和性能平衡。

### 透明代理 - 黑名单模式
```
默认行为: 所有应用通过代理
例外处理: 在配置文件中指定不代理的应用
配置文件: /data/adb/box/package.list.cfg
```

### UI 界面 - zashboard
- **现代化界面**: 比 yacd 更美观和功能丰富
- **自动下载**: 从 GitHub 获取最新版本
- **访问地址**: http://127.0.0.1:9090/ui/

## 🛠️ 高级配置

### 自定义核心
```bash
# 使用 clash 核心
./workflow_generator.sh --core clash

# 使用 xray 核心  
./workflow_generator.sh --core xray
```

### 自定义网络模式
```bash
# 使用 tproxy 模式
./workflow_generator.sh --mode tproxy

# 使用 tun 模式
./workflow_generator.sh --mode tun
```

### 自定义代理规则
```bash
# 使用白名单模式
./workflow_generator.sh --proxy-mode whitelist
```

### 跳过特定步骤
```bash
# 跳过核心下载（使用现有核心）
./workflow_generator.sh --skip-core

# 跳过 UI 下载
./workflow_generator.sh --skip-ui

# 仅生成模块包，不推送
./workflow_generator.sh --build-only
```

## 📱 Telegram Bot 推送

### 环境变量配置
```bash
export API_ID="your_api_id"
export API_HASH="your_api_hash"  
export BOT_TOKEN="your_bot_token"
export CHAT_ID="-1001597117128"      # 可选
export MESSAGE_THREAD_ID="282263"    # 可选
```

### 获取配置信息
1. **API 凭据**: 访问 https://my.telegram.org/apps
2. **Bot Token**: 与 @BotFather 对话创建 bot
3. **Chat ID**: 将 bot 添加到群组并获取 ID

## 📋 配置文件说明

### settings.ini 关键配置
```ini
bin_name="sing-box"           # 核心选择
network_mode="enhance"        # 网络模式
tproxy_port="9898"           # 透明代理端口
redir_port="9797"            # 重定向端口
ipv6="false"                 # IPv6 支持
box_user_group="root:net_admin"  # 用户组
```

### package.list.cfg 应用规则
```ini
mode:blacklist               # 代理模式

# 应用包名示例（取消注释以排除代理）
# com.android.vending
# com.google.android.gms
# com.tencent.mm
```

### ap.list.cfg 网络接口
```ini
allow ap+                    # 允许热点
allow wlan+                  # 允许 WiFi
allow rndis+                 # 允许 USB 共享
# ignore wlan0               # 忽略特定接口
```

## 🔍 故障排除

### 常见问题

**核心下载失败**
```bash
# 检查网络连接
ping github.com

# 手动下载核心
su -c '/data/adb/box/scripts/box.tool upkernel'
```

**UI 访问失败**
```bash
# 检查服务状态
su -c '/data/adb/box/scripts/box.service status'

# 重启服务
su -c '/data/adb/box/scripts/box.service restart'
```

**Telegram 推送失败**
```bash
# 检查环境变量
echo $BOT_TOKEN

# 安装依赖
pip3 install telethon==1.31.1
```

### 日志查看
```bash
# 查看运行日志
tail -f /data/adb/box/run/runs.log

# 查看核心日志
tail -f /data/adb/box/run/sing-box.log
```

## 📚 详细文档

- **完整指南**: 查看 `WORKFLOW_GUIDE.md` 了解详细配置和使用方法
- **官方文档**: https://github.com/taamarin/box_for_magisk
- **问题反馈**: https://t.me/taamarin

## 🎯 使用场景

### 开发者
```bash
# 完整的开发工作流
./workflow_generator.sh --core sing-box --ui zashboard
```

### 普通用户
```bash
# 在设备上快速配置
su -c './quick_setup.sh'
```

### CI/CD 集成
```bash
# 自动化构建和推送
export BOT_TOKEN="xxx"
./workflow_generator.sh --build-only
```

## ⚠️ 注意事项

1. **Root 权限**: 设备配置需要 root 权限
2. **网络连接**: 确保能访问 GitHub 和相关资源
3. **存储空间**: 确保有足够的存储空间下载核心和 UI
4. **备份配置**: 运行前建议备份重要配置文件
5. **测试环境**: 建议先在测试环境验证配置

## 🔄 更新和维护

### 定期更新
```bash
# 更新核心
su -c '/data/adb/box/scripts/box.tool upkernel'

# 更新 UI
su -c '/data/adb/box/scripts/box.tool upxui'

# 更新所有组件
su -c '/data/adb/box/scripts/box.tool all'
```

### 配置维护
```bash
# 查看当前配置
cat /data/adb/box/settings.ini

# 重新运行快速设置
su -c './quick_setup.sh'
```

## 📄 许可证

本工作流基于 Box for Magisk 项目，遵循相同的开源许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工作流！

---

**享受自动化的便利！** 🎉
