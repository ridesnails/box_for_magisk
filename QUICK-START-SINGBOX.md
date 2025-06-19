# 快速开始指南 - Sing-box 专用分支

## 🚀 5分钟快速部署

本指南将帮助您在5分钟内完成 Box for Magisk Sing-box 专用版本的安装和基本配置。

## 📋 准备工作

### 系统要求
- **Android 版本**：Android 7.0+ (API 24+)
- **Root 框架**：Magisk 20.4+ / KernelSU 0.5.0+ / APatch 10.0+
- **架构支持**：ARM64 / ARMv7
- **存储空间**：至少 50MB 可用空间

### 检查环境
```bash
# 检查 Android 版本
getprop ro.build.version.release

# 检查架构
getprop ro.product.cpu.abi

# 检查 Root 权限
su -c "echo 'Root 权限正常'"
```

## 📦 安装步骤

### 第1步：下载模块

1. **从 GitHub 下载**：
   - 访问 [Releases 页面](https://github.com/taamarin/box_for_magisk/releases)
   - 下载最新的 `box_for_magisk-v*.*.*-singbox.zip`

2. **验证文件**：
   ```bash
   # 检查文件完整性（可选）
   md5sum box_for_magisk-v*.*.*-singbox.zip
   ```

### 第2步：安装模块

#### Magisk Manager
1. 打开 Magisk Manager
2. 点击 "模块" 标签
3. 点击 "从存储安装"
4. 选择下载的 ZIP 文件
5. 等待安装完成

#### KernelSU Manager
1. 打开 KernelSU Manager
2. 点击 "模块" 标签
3. 点击 "+" 按钮
4. 选择 ZIP 文件并安装

#### APatch Manager
1. 打开 APatch Manager
2. 进入 "模块" 页面
3. 点击 "安装模块"
4. 选择文件并确认安装

### 第3步：重启设备
```bash
# 重启设备以激活模块
su -c "reboot"
```

## ⚙️ 基本配置

### 第1步：验证安装
```bash
# 检查模块状态
su -c "ls -la /data/adb/box/"

# 检查服务状态
su -c "/data/adb/box/scripts/box.service status"
```

### 第2步：配置代理

#### 方式1：使用 Web 界面（推荐）
1. 确保设备连接到网络
2. 打开浏览器访问：http://127.0.0.1:9090/ui/
3. 在界面中配置您的代理服务器信息

#### 方式2：手动编辑配置
```bash
# 编辑配置文件
su -c "nano /data/adb/box/sing-box/config.json"
```

### 第3步：启动服务
```bash
# 启动代理服务
su -c "/data/adb/box/scripts/box.service start"
su -c "/data/adb/box/scripts/box.iptables enable"

# 检查启动状态
su -c "/data/adb/box/scripts/box.service status"
```

## 🎯 基本配置示例

### 最简配置模板
```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "8.8.8.8"
      }
    ]
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 7890
    },
    {
      "type": "tproxy",
      "tag": "tproxy-in",
      "listen": "0.0.0.0",
      "listen_port": 9898,
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "inbound": "tproxy-in",
        "outbound": "direct"
      }
    ]
  }
}
```

### 代理服务器配置示例

#### VLESS 配置
```json
{
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "your-server.com",
      "server_port": 443,
      "uuid": "your-uuid-here",
      "tls": {
        "enabled": true,
        "server_name": "your-server.com"
      }
    }
  ]
}
```

#### Shadowsocks 配置
```json
{
  "outbounds": [
    {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": "your-server.com",
      "server_port": 8388,
      "method": "aes-256-gcm",
      "password": "your-password"
    }
  ]
}
```

#### Trojan 配置
```json
{
  "outbounds": [
    {
      "type": "trojan",
      "tag": "proxy",
      "server": "your-server.com",
      "server_port": 443,
      "password": "your-password",
      "tls": {
        "enabled": true,
        "server_name": "your-server.com"
      }
    }
  ]
}
```

## 🌐 Web 界面快速上手

### 访问界面
1. **确保服务运行**：
   ```bash
   su -c "/data/adb/box/scripts/box.service status"
   ```

2. **打开浏览器**：
   - 访问：http://127.0.0.1:9090/ui/
   - 或点击系统通知中的链接

### 界面导航
- **概览页面**：查看连接状态和流量统计
- **代理页面**：管理代理服务器和规则
- **连接页面**：查看实时连接信息
- **日志页面**：查看运行日志和错误信息
- **设置页面**：配置界面和系统选项

### 常用操作
1. **添加代理服务器**：
   - 点击 "代理" 标签
   - 点击 "+" 添加新的代理
   - 输入服务器信息并保存

2. **测试连接**：
   - 选择代理服务器
   - 点击 "测试" 按钮
   - 查看延迟和连通性

3. **启用代理**：
   - 在概览页面点击 "启动"
   - 或使用命令行启动服务

## 🔧 常用命令参考

### 服务管理
```bash
# 查看服务状态
su -c "/data/adb/box/scripts/box.service status"

# 启动服务
su -c "/data/adb/box/scripts/box.service start"

# 停止服务
su -c "/data/adb/box/scripts/box.service stop"

# 重启服务
su -c "/data/adb/box/scripts/box.service restart"
```

### 网络规则管理
```bash
# 启用网络规则
su -c "/data/adb/box/scripts/box.iptables enable"

# 禁用网络规则
su -c "/data/adb/box/scripts/box.iptables disable"

# 重新加载规则
su -c "/data/adb/box/scripts/box.iptables renew"
```

### 工具命令
```bash
# 检查配置
su -c "/data/adb/box/scripts/box.tool check"

# 更新 sing-box
su -c "/data/adb/box/scripts/box.tool upkernel"

# 安装 Web 界面
su -c "/data/adb/box/scripts/box.tool dashboard install"

# 查看帮助
su -c "/data/adb/box/scripts/box.tool"
```

## 📱 应用代理配置

### 配置应用白名单/黑名单
```bash
# 编辑应用列表
su -c "nano /data/adb/box/package.list.cfg"
```

#### 白名单模式示例
```ini
# 白名单模式：仅列表中的应用使用代理
mode:whitelist

# 应用包名
com.android.chrome
com.google.android.youtube
com.twitter.android
com.facebook.katana

# 用户ID
10450 alook
```

#### 黑名单模式示例
```ini
# 黑名单模式：列表中的应用不使用代理
mode:blacklist

# 系统应用
com.android.vending
com.google.android.gms
android

# 银行应用
com.eg.android.AlipayGphone
```

### 重新加载应用规则
```bash
# 应用配置更改后重启服务
su -c "/data/adb/box/scripts/box.service restart"
```

## 🚨 快速问题解决

### 问题1：无法访问 Web 界面
```bash
# 检查服务状态
su -c "/data/adb/box/scripts/box.service status"

# 检查端口监听
su -c "netstat -tlnp | grep 9090"

# 重新安装界面
su -c "/data/adb/box/scripts/box.tool dashboard reinstall"
```

### 问题2：网络无法连接
```bash
# 检查网络规则
su -c "/data/adb/box/scripts/box.iptables status"

# 重置网络规则
su -c "/data/adb/box/scripts/box.iptables disable"
su -c "/data/adb/box/scripts/box.iptables enable"

# 尝试不同网络模式
# 编辑 /data/adb/box/settings.ini
# 修改 network_mode="tproxy"
```

### 问题3：配置文件错误
```bash
# 验证配置语法
su -c "/data/adb/box/bin/sing-box check -c /data/adb/box/sing-box/config.json"

# 查看错误日志
su -c "tail -50 /data/adb/box/run/sing-box.log"

# 恢复默认配置
su -c "cp /data/adb/box/sing-box/config.json.bak /data/adb/box/sing-box/config.json"
```

### 问题4：性能问题
```bash
# 检查资源使用
su -c "top | head -20"

# 优化网络模式
# 在 settings.ini 中设置：
network_mode="enhance"

# 调整内存限制
memcg_limit="256M"
```

## 🎯 性能优化建议

### 基本优化
1. **使用 enhance 模式**：
   ```ini
   network_mode="enhance"
   ```

2. **调整内存限制**：
   ```ini
   memcg_limit="128M"  # 根据设备调整
   ```

3. **绑定高性能核心**：
   ```ini
   allow_cpu="0-3"     # 绑定前4个核心
   ```

### 高级优化
1. **调整 I/O 权重**：
   ```ini
   weight="800"        # 提高I/O优先级
   ```

2. **优化 DNS 配置**：
   ```json
   {
     "dns": {
       "servers": [
         {
           "tag": "cloudflare",
           "address": "1.1.1.1"
         }
       ],
       "strategy": "prefer_ipv4"
     }
   }
   ```

3. **使用更快的加密方法**：
   - 推荐：aes-128-gcm, chacha20-poly1305
   - 避免：aes-256-cfb, rc4-md5

## 📚 下一步学习

### 进阶配置
- [详细配置说明](box/sing-box/README.md)
- [网络模式详解](README-SINGBOX.md#enhance-模式详解)
- [性能优化指南](README-SINGBOX.md#性能优化)

### 故障排除
- [常见问题解答](README-SINGBOX.md#故障排除)
- [调试工具使用](box/sing-box/README.md#高级调试工具)
- [日志分析方法](box/sing-box/README.md#日志分析)

### 社区支持
- [GitHub Issues](https://github.com/taamarin/box_for_magisk/issues)
- [讨论区](https://github.com/taamarin/box_for_magisk/discussions)
- [Telegram 群组](https://t.me/boxformmagisk)

## ✅ 完成检查清单

安装完成后，请确认以下项目：

- [ ] 模块已成功安装并重启设备
- [ ] 服务状态显示正常运行
- [ ] Web 界面可以正常访问
- [ ] 代理配置已正确设置
- [ ] 网络连接测试通过
- [ ] 应用代理规则已配置
- [ ] 性能表现符合预期

**🎉 恭喜！您已成功完成 Box for Magisk Sing-box 专用版本的快速部署。**

---

> **提示**：如果在安装过程中遇到问题，请参考 [详细文档](README-SINGBOX.md) 或在 [GitHub Issues](https://github.com/taamarin/box_for_magisk/issues) 中寻求帮助。