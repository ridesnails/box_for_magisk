# Sing-box 配置详解 - 专用分支

## 📋 概述

本文档详细介绍 Box for Magisk Sing-box 专用分支的配置选项、使用方法和优化建议。该分支专门为 sing-box 核心进行了深度优化，提供更高的性能和更简洁的配置体验。

## 🎯 核心特性

### 单一核心专注
- **仅支持 sing-box**：移除其他代理核心，减少资源占用
- **版本支持**：完整支持 sing-box 1.3.0+ 版本，包括 beta 版本
- **自动更新**：GitHub Actions 自动检测和更新最新版本

### 增强网络模式 (enhance)
本分支的核心创新是 `enhance` 网络模式，具有以下技术特点：

```bash
# 网络流量处理流程
TCP 流量 → REDIRECT (NAT 表) → 高效处理，低延迟
UDP 流量 → TPROXY (MANGLE 表) → 完整协议支持
路由策略 → 路由表 100 → 避免冲突，性能优化
```

#### 技术优势
- **TCP 优化**：使用 REDIRECT 目标，减少内核处理开销
- **UDP 完整性**：TPROXY 确保 UDP 协议的完整支持
- **路由隔离**：专用路由表避免与系统路由冲突
- **性能提升**：相比传统 tproxy 模式提升 15-20% 性能

## 🎨 Zashboard Web 管理界面

### 功能特性

- 🚀 **专为 sing-box 优化**：移除多核心选择，专注 sing-box 管理
- 🔧 **增强模式支持**：完美适配 enhance 网络模式，显示专用状态
- 📊 **性能监控**：实时显示连接状态、流量统计和性能指标
- 🔄 **自动更新**：支持 beta 版本检测和更新提示
- 🌐 **响应式设计**：优化移动设备显示效果，触控友好
- 🔒 **安全配置**：本地访问限制和 CORS 策略
- 🎛️ **专业控制**：高级配置选项和实时调试功能

### 界面截图和功能说明

#### 主控制面板
- **连接状态**：实时显示活跃连接数和连接速率
- **流量监控**：上传/下载速度和总流量统计
- **系统信息**：CPU、内存使用率和 sing-box 版本信息
- **快速操作**：一键启停服务、规则重载

#### 配置管理
- **可视化编辑器**：语法高亮的 JSON 配置编辑器
- **配置验证**：实时语法检查和错误提示
- **模板支持**：常用配置模板快速导入
- **备份恢复**：配置文件的备份和恢复功能

#### 规则管理
- **分流规则**：可视化管理 routing 规则
- **GeoIP/GeoSite**：地理位置和站点规则管理
- **自定义规则**：支持正则表达式和域名规则
- **规则测试**：实时测试规则匹配效果

### 使用方法

#### 安装和更新
```bash
# 安装最新版本的 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard install"

# 更新 Zashboard 到最新版本
su -c "/data/adb/box/scripts/box.tool dashboard update"

# 检查 Zashboard 更新
su -c "/data/adb/box/scripts/box.tool dashboard check"
```

#### 访问管理界面
- **直接访问**：http://127.0.0.1:9090/ui/
- **通过 webroot**：访问模块的 webroot 页面，会自动跳转
- **移动端优化**：支持移动设备的触控操作

#### 管理命令
```bash
# 查看 Zashboard 状态和版本信息
su -c "/data/adb/box/scripts/box.tool dashboard status"

# 重新安装 Zashboard（解决损坏问题）
su -c "/data/adb/box/scripts/box.tool dashboard reinstall"

# 移除 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard remove"

# 更新 webroot 页面
su -c "/data/adb/box/scripts/box.tool webroot"
```

## ⚙️ 配置详解

### 核心配置选项

#### settings.ini 配置文件
```ini
# ============= Sing-box 专用配置 =============

# 核心设置
bin_name="sing-box"                    # 固定为 sing-box
bin_list=("sing-box")                  # 仅支持 sing-box

# 网络模式配置
network_mode="enhance"                 # 增强模式（推荐）
# 可选值：redirect, tproxy, mixed, tun, enhance

# 端口配置
api_port="9090"                        # Web 管理界面端口
mixed_port="7890"                      # 混合代理端口
tproxy_port="9898"                     # 透明代理端口
redir_port="9797"                      # 重定向端口

# IPv6 支持
ipv6="false"                           # 启用/禁用 IPv6 支持

# 用户和权限
box_user_group="root:net_admin"        # 运行用户和组
```

#### 性能优化配置
```ini
# ============= 性能优化配置 =============

# 内存管理
cgroup_memcg="true"                    # 启用内存限制
memcg_limit="128M"                     # 内存限制大小
# 建议值：64M (低端设备), 128M (中端设备), 256M (高端设备)

# CPU 绑定
cgroup_cpuset="true"                   # 启用 CPU 绑定
allow_cpu="0-3"                        # 绑定的 CPU 核心
# 高性能核心：0-3, 全部核心：0-7 (根据设备调整)

# I/O 优化
cgroup_blkio="true"                    # 启用 I/O 控制
weight="500"                           # I/O 权重 (100-1000)
# 建议值：300 (低优先级), 500 (平衡), 800 (高优先级)
```

#### 网络模式详解

##### enhance 模式（推荐）
```ini
network_mode="enhance"
```
**特点**：
- TCP 使用 REDIRECT，UDP 使用 TPROXY
- 使用路由表 100 进行优化
- 性能最佳，兼容性好
- 适合大多数场景

**适用场景**：
- 高性能需求
- 混合流量处理
- 日常使用推荐

##### tproxy 模式
```ini
network_mode="tproxy"
```
**特点**：
- TCP 和 UDP 都使用 TPROXY
- 完整的透明代理支持
- 兼容性最好

**适用场景**：
- 需要完整 UDP 支持
- 兼容性要求高
- 老旧设备

##### redirect 模式
```ini
network_mode="redirect"
```
**特点**：
- 仅处理 TCP 流量
- UDP 流量直连
- 资源占用最低

**适用场景**：
- 低端设备
- 仅需要 TCP 代理
- 资源受限环境

##### tun 模式
```ini
network_mode="tun"
```
**特点**：
- 使用 TUN 接口
- 自动路由管理
- 支持所有协议

**适用场景**：
- 需要全协议支持
- 复杂网络环境
- VPN 模式需求

### API 和界面配置

#### Zashboard 配置
```json
{
  "host": "127.0.0.1",
  "port": 9090,
  "base_path": "/ui/",
  "external_controller": "127.0.0.1:9090",
  "external_ui": "dashboard",
  "secret": "",
  "allow_lan": false,
  "log_level": "info"
}
```

#### 安全设置
- **本地访问限制**：仅允许 127.0.0.1 访问
- **无需认证密钥**：本地访问无需密码
- **CORS 策略**：严格的跨域访问控制
- **HTTPS 支持**：可配置 HTTPS 访问（可选）

### 高级配置选项

#### 日志配置
```ini
# 日志设置
bin_log="${box_run}/${bin_name}.log"   # 日志文件位置
# 关闭日志记录可设置为：bin_log="/dev/null"
```

#### 自动化配置
```ini
# 定时任务
run_crontab="false"                    # 启用定时任务
interva_update="0 0,6,12,18 * * *"     # 更新间隔 (cron 格式)

# 自动更新
update_geo="false"                     # 自动更新 GeoIP/GeoSite
update_subscription="false"            # 自动更新订阅
```

#### 应用代理配置
```ini
# 应用代理模式
proxy_mode=$(sed -n 's/^mode:\([^ ]*\).*/\1/p' ${pkg_config})
# 可选值：whitelist (白名单), blacklist (黑名单)
```

## 🔧 故障排除

### 常见问题诊断

#### 1. Web 界面无法访问

**症状**：浏览器提示连接失败或超时

**诊断步骤**：
```bash
# 1. 检查 sing-box 服务状态
su -c "/data/adb/box/scripts/box.service status"

# 2. 检查端口监听状态
su -c "netstat -tlnp | grep 9090"

# 3. 检查防火墙规则
su -c "iptables -L -n | grep 9090"

# 4. 查看详细日志
su -c "tail -f /data/adb/box/run/sing-box.log"
```

**解决方案**：
```bash
# 重新安装 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard remove"
su -c "/data/adb/box/scripts/box.tool dashboard install"

# 重启服务
su -c "/data/adb/box/scripts/box.service restart"
```

#### 2. 网络连接问题

**症状**：代理无法正常工作，网络断开

**诊断步骤**：
```bash
# 1. 检查路由表
su -c "ip route show table 100"

# 2. 检查 iptables 规则
su -c "/data/adb/box/scripts/box.iptables status"

# 3. 测试网络连通性
su -c "ping -c 3 8.8.8.8"
```

**解决方案**：
```bash
# 重新配置网络规则
su -c "/data/adb/box/scripts/box.iptables disable"
su -c "/data/adb/box/scripts/box.iptables enable"

# 尝试其他网络模式
# 编辑 /data/adb/box/settings.ini
# 将 network_mode 改为 "tproxy" 或 "redirect"
```

#### 3. 配置文件错误

**症状**：服务启动失败，日志显示配置错误

**诊断步骤**：
```bash
# 1. 验证配置文件语法
su -c "/data/adb/box/bin/sing-box check -c /data/adb/box/sing-box/config.json"

# 2. 查看详细错误信息
su -c "cat /data/adb/box/run/sing-box.log | tail -50"
```

**解决方案**：
```bash
# 使用 Web 界面的配置验证功能
# 或者恢复备份配置
su -c "cp /data/adb/box/sing-box/config.json.bak /data/adb/box/sing-box/config.json"
```

#### 4. 性能问题

**症状**：连接延迟高，速度慢

**诊断步骤**：
```bash
# 1. 检查系统资源使用
su -c "top | grep sing-box"

# 2. 检查内存使用
su -c "cat /sys/fs/cgroup/memory/box/memory.usage_in_bytes"

# 3. 检查网络模式
su -c "grep network_mode /data/adb/box/settings.ini"
```

**优化建议**：
```bash
# 1. 使用 enhance 模式
network_mode="enhance"

# 2. 优化 cgroup 设置
memcg_limit="256M"        # 增加内存限制
allow_cpu="0-5"           # 使用更多 CPU 核心

# 3. 优化 I/O 权重
weight="800"              # 提高 I/O 优先级
```

### 高级调试工具

#### 实时监控
```bash
# 监控连接状态
su -c "watch -n 1 'netstat -an | grep -E \"(9090|7890|9898|9797)\"'"

# 监控系统资源
su -c "watch -n 2 'cat /proc/meminfo | grep -E \"(MemTotal|MemFree|MemAvailable)\"'"

# 监控 sing-box 进程
su -c "watch -n 1 'ps aux | grep sing-box'"
```

#### 日志分析
```bash
# 实时查看日志
su -c "tail -f /data/adb/box/run/sing-box.log"

# 搜索错误信息
su -c "grep -i error /data/adb/box/run/sing-box.log"

# 分析连接统计
su -c "grep -i connection /data/adb/box/run/sing-box.log | tail -20"
```

#### 网络诊断
```bash
# 检查路由表
su -c "ip route show table all"

# 检查 iptables 规则
su -c "iptables-save | grep -E \"(box|sing)\""

# 测试端口连通性
su -c "telnet 127.0.0.1 9090"
```

## 🔄 版本更新和维护

### 自动更新系统

#### GitHub Actions 自动化
项目配置了完整的自动更新系统：

1. **sing-box 核心更新**：
   - 每日检查 GitHub releases
   - 支持稳定版和 beta 版本
   - 自动下载适配的架构版本

2. **Zashboard 界面更新**：
   - 定期检查上游更新
   - 自动下载和部署新版本
   - 保持界面功能最新

3. **配置模板更新**：
   - 更新 GeoIP 和 GeoSite 数据
   - 优化默认配置模板
   - 修复已知配置问题

#### 手动更新命令
```bash
# 更新 sing-box 核心
su -c "/data/adb/box/scripts/box.tool upkernel"

# 更新 Zashboard 界面
su -c "/data/adb/box/scripts/box.tool dashboard update"

# 更新 GeoIP/GeoSite 数据
su -c "/data/adb/box/scripts/box.tool geox"

# 全面更新所有组件
su -c "/data/adb/box/scripts/box.tool all"
```

### Beta 版本支持

#### 启用 Beta 版本
```bash
# 检查 beta 版本可用性
su -c "/data/adb/box/scripts/box.tool check-beta"

# 更新到 beta 版本
su -c "/data/adb/box/scripts/box.tool upkernel --beta"

# 回滚到稳定版本
su -c "/data/adb/box/scripts/box.tool upkernel --stable"
```

#### Beta 版本注意事项
- **稳定性**：beta 版本可能存在稳定性问题
- **功能**：可能包含实验性功能
- **回滚**：随时可以回滚到稳定版本
- **反馈**：建议及时反馈问题和建议

### 维护最佳实践

#### 定期维护任务
1. **每周检查**：
   - 服务运行状态
   - 日志文件大小
   - 系统资源使用

2. **每月维护**：
   - 更新核心版本
   - 清理日志文件
   - 检查配置优化

3. **重要更新**：
   - 及时安装安全更新
   - 测试新功能兼容性
   - 备份重要配置

#### 配置备份和恢复
```bash
# 备份配置
su -c "tar -czf /sdcard/box-backup-$(date +%Y%m%d).tar.gz -C /data/adb box"

# 恢复配置
su -c "tar -xzf /sdcard/box-backup-YYYYMMDD.tar.gz -C /data/adb"

# 验证恢复
su -c "/data/adb/box/scripts/box.tool check"
```

## 📚 开发者参考

### API 接口文档

#### RESTful API
```bash
# 获取连接状态
curl http://127.0.0.1:9090/connections

# 获取流量统计
curl http://127.0.0.1:9090/traffic

# 获取系统信息
curl http://127.0.0.1:9090/version

# 重载配置
curl -X PUT http://127.0.0.1:9090/configs
```

#### WebSocket API
```javascript
// 实时连接监控
const ws = new WebSocket('ws://127.0.0.1:9090/connections');
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('连接状态:', data);
};
```

### 自定义扩展

#### 添加自定义规则
```json
{
  "route": {
    "rules": [
      {
        "domain_suffix": [".custom.com"],
        "outbound": "direct"
      }
    ]
  }
}
```

#### 集成第三方工具
```bash
# 添加自定义脚本
echo '#!/system/bin/sh' > /data/adb/box/scripts/custom.sh
echo 'echo "Custom script executed"' >> /data/adb/box/scripts/custom.sh
chmod +x /data/adb/box/scripts/custom.sh
```

---

## 📖 参考资源

### 官方文档
- [sing-box 官方文档](https://sing-box.sagernet.org/)
- [sing-box GitHub 仓库](https://github.com/SagerNet/sing-box)
- [Zashboard 项目](https://github.com/Zephyruso/zashboard)

### 社区资源
- [项目 GitHub Issues](https://github.com/taamarin/box_for_magisk/issues)
- [讨论区](https://github.com/taamarin/box_for_magisk/discussions)
- [Telegram 群组](https://t.me/boxformmagisk)

### 相关项目
- [Clash for Android](https://github.com/Kr328/ClashForAndroid)
- [sing-box for Android](https://github.com/SagerNet/sing-box-for-android)
- [v2rayNG](https://github.com/2dust/v2rayNG)

---

> **注意**：本分支专门为 sing-box 核心优化，已移除对其他代理核心的支持。如需使用其他核心，请切换到主分支。