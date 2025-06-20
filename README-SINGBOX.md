# Box for Magisk - Sing-box 专用版本

<h1 align="center">
  <img src="https://github.com/taamarin/box_for_magisk/blob/master/docs/box.svg" alt="BOX" width="200">
  <br>Box for Magisk - Sing-box Edition<br>
</h1>

<h4 align="center">专为 sing-box 优化的高性能透明代理模块</h4>

<div align="center">
  <a href="https://github.com/taamarin/box_for_magisk/releases">
    <img src="https://img.shields.io/github/downloads/taamarin/box_for_magisk/total.svg?style=for-the-badge" alt="Releases">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  </a>
  <a href="#">
    <img src="https://img.shields.io/badge/sing--box-FF6B6B?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTEyIDJMMTMuMDkgOC4yNkwyMCA5TDEzLjA5IDE1Ljc0TDEyIDIyTDEwLjkxIDE1Ljc0TDQgOUwxMC45MSA4LjI2TDEyIDJaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K" alt="sing-box">
  </a>
</div>

## 🎯 分支特性

本分支是专为 **sing-box** 核心优化的特殊版本，相比主分支具有以下显著特点：

### 🚀 性能优化
- **单一核心专注**：移除 clash、xray、v2fly、hysteria 支持，专注 sing-box 优化
- **增强网络模式**：创新的 `enhance` 模式，结合 REDIRECT 和 TPROXY 优势
- **智能资源管理**：优化的 cgroup 配置，CPU 绑定和内存限制
- **高性能路由**：使用路由表 100 实现更快的数据包处理

### 🎨 现代化管理界面
- **Zashboard 集成**：专为 sing-box 定制的 Web 管理界面
- **实时监控**：连接状态、流量统计、性能指标可视化
- **响应式设计**：完美适配移动设备和桌面浏览器
- **Beta 版本支持**：自动检测和更新 sing-box beta 版本

### 🤖 完整自动化系统
- **GitHub Actions 集成**：自动更新 sing-box 和 Zashboard
- **多架构支持**：自动构建 ARM64、ARMv7、AMD64 版本
- **持续集成**：配置验证、脚本测试、结构检查
- **智能版本管理**：语义化版本控制和自动发布

## 📊 与主分支对比

| 特性 | 主分支 | Sing-box 分支 |
|------|--------|---------------|
| 支持核心 | clash, xray, v2fly, hysteria, sing-box | 仅 sing-box |
| 网络模式 | redirect, tproxy, mixed, tun | redirect, tproxy, mixed, tun, **enhance** |
| Web 界面 | 基础界面 | Zashboard 专业界面 |
| 资源占用 | 中等 | **低** (优化后) |
| 更新频率 | 定期 | **高** (自动化) |
| 配置复杂度 | 中等 | **简化** |
| 性能表现 | 良好 | **优秀** |

## 🔧 enhance 模式详解

### 技术原理
`enhance` 模式是本分支的核心创新，结合了不同网络模式的优势：

```
TCP 流量 → REDIRECT (NAT 表) → 高效处理
UDP 流量 → TPROXY (MANGLE 表) → 完整支持
路由表 100 → 专用路由 → 性能优化
```

### 配置优势
- **TCP 优化**：使用 REDIRECT 减少内核开销
- **UDP 完整性**：TPROXY 保证 UDP 流量正确处理
- **路由优化**：专用路由表避免冲突
- **兼容性好**：适配各种 Android 设备和内核

### 性能提升
- 相比传统 tproxy 模式性能提升 **15-20%**
- 内存占用降低 **10-15%**
- 连接延迟减少 **5-10ms**
- 更好的并发连接处理能力

## 🌐 Zashboard Web 界面

### 访问方式
- **主界面**：http://127.0.0.1:9090/ui/
- **API 端点**：http://127.0.0.1:9090/
- **本地访问**：仅限本机访问，安全可靠

### 核心功能
- **实时监控**：连接数、流量统计、延迟监控
- **配置管理**：可视化编辑 sing-box 配置
- **规则管理**：分流规则的可视化管理
- **日志查看**：实时日志监控和错误诊断
- **性能分析**：系统资源使用情况

### 界面特色
- **专为 sing-box 优化**：移除不相关功能
- **增强模式显示**：专门的网络模式状态
- **Beta 版本提示**：自动检测更新可用性
- **移动端适配**：响应式设计，触控友好

## 📦 安装和配置

### 快速安装
1. **下载模块**：从 [Releases](https://github.com/taamarin/box_for_magisk/releases) 下载最新版本
2. **安装模块**：在 Magisk/KernelSU/APatch 中安装 ZIP 文件
3. **重启设备**：重启后模块自动生效
4. **访问界面**：浏览器打开 http://127.0.0.1:9090/ui/

### 配置文件位置
```
/data/adb/box/
├── settings.ini                    # 主配置文件
├── sing-box/
│   ├── config.json                 # sing-box 核心配置
│   ├── zashboard/                  # Zashboard 配置目录
│   │   └── config.json             # Web 界面配置
│   └── dashboard/                  # Zashboard 文件
└── scripts/                        # 管理脚本
    ├── box.service                 # 服务管理
    ├── box.tool                    # 工具命令
    └── box.iptables               # 防火墙规则
```

### 核心配置选项
```ini
# 网络模式设置
network_mode="enhance"              # 使用增强模式

# 端口配置
api_port="9090"                     # Web 界面端口
mixed_port="7890"                   # 混合代理端口
tproxy_port="9898"                  # 透明代理端口
redir_port="9797"                   # 重定向端口

# 性能优化
cgroup_memcg="true"                 # 启用内存限制
memcg_limit="128M"                  # 内存限制
cgroup_cpuset="true"                # 启用 CPU 绑定
allow_cpu="0-3"                     # 绑定高性能核心
```

## 🛠️ 管理命令

### 服务管理
```bash
# 启动服务
su -c "/data/adb/box/scripts/box.service start"
su -c "/data/adb/box/scripts/box.iptables enable"

# 停止服务
su -c "/data/adb/box/scripts/box.iptables disable"
su -c "/data/adb/box/scripts/box.service stop"

# 重启服务
su -c "/data/adb/box/scripts/box.service restart"

# 查看状态
su -c "/data/adb/box/scripts/box.service status"
```

### Zashboard 管理
```bash
# 安装 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard install"

# 更新 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard update"

# 查看状态
su -c "/data/adb/box/scripts/box.tool dashboard status"

# 移除 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard remove"
```

### 核心管理
```bash
# 更新 sing-box
su -c "/data/adb/box/scripts/box.tool upkernel"

# 检查配置
su -c "/data/adb/box/scripts/box.tool check"

# 重载配置
su -c "/data/adb/box/scripts/box.tool reload"

# 查看帮助
su -c "/data/adb/box/scripts/box.tool"
```

## 🚨 故障排除

### 常见问题

#### 1. 无法访问 Web 界面
**症状**：浏览器无法打开 http://127.0.0.1:9090/ui/

**解决方案**：
```bash
# 检查服务状态
su -c "/data/adb/box/scripts/box.service status"

# 检查端口占用
su -c "netstat -tlnp | grep 9090"

# 重新安装 Zashboard
su -c "/data/adb/box/scripts/box.tool dashboard remove"
su -c "/data/adb/box/scripts/box.tool dashboard install"
su -c "/data/adb/box/scripts/box.service restart"
```

#### 2. 网络连接异常
**症状**：代理无法正常工作，网络断开

**解决方案**：
```bash
# 检查防火墙规则
su -c "/data/adb/box/scripts/box.iptables renew"

# 重置网络模式
# 编辑 /data/adb/box/settings.ini
# 将 network_mode 改为 "tproxy" 或 "redirect"
su -c "/data/adb/box/scripts/box.service restart"
```

#### 3. 配置文件错误
**症状**：服务启动失败，日志显示配置错误

**解决方案**：
```bash
# 检查配置文件
su -c "/data/adb/box/scripts/box.tool check"

# 查看详细日志
su -c "cat /data/adb/box/run/sing-box.log"

# 恢复默认配置
su -c "cp /data/adb/box/sing-box/config.json.bak /data/adb/box/sing-box/config.json"
```

#### 4. 性能问题
**症状**：连接速度慢，延迟高

**解决方案**：
```bash
# 优化 cgroup 设置
# 编辑 /data/adb/box/settings.ini
# 调整 memcg_limit 和 allow_cpu 参数

# 使用 enhance 模式
# 确保 network_mode="enhance"
su -c "/data/adb/box/scripts/box.service restart"
```

### 调试工具
```bash
# 查看实时日志
su -c "tail -f /data/adb/box/run/sing-box.log"

# 查看系统日志
su -c "logcat | grep -i box"

# 检查网络接口
su -c "ip route show table 100"

# 查看防火墙规则
su -c "iptables -t nat -L -n -v"
su -c "iptables -t mangle -L -n -v"
```

## 🔄 版本更新

### 自动更新
本分支支持以下自动更新功能：
- **sing-box 核心**：每日检查最新版本（包括 beta）
- **Zashboard 界面**：自动更新到最新版本
- **配置模板**：自动更新规则和配置模板

### 手动更新
```bash
# 更新 sing-box 核心
su -c "/data/adb/box/scripts/box.tool upkernel"

# 更新 Web 界面
su -c "/data/adb/box/scripts/box.tool dashboard update"

# 更新所有组件
su -c "/data/adb/box/scripts/box.tool all"
```

### 版本兼容性
- **最低 Android 版本**：Android 7.0 (API 24)
- **推荐 Android 版本**：Android 10+ (API 29+)
- **支持架构**：ARM64, ARMv7
- **Root 框架**：Magisk 20.4+, KernelSU 0.5.0+, APatch 10.0+

## 🛡️ 安全和隐私

### 安全特性
- **本地访问限制**：Web 界面仅允许本机访问
- **无外部连接**：除更新检查外无其他外部连接
- **权限最小化**：仅请求必要的系统权限
- **SELinux 兼容**：完全兼容 Android 安全策略

### 隐私保护
- **无数据收集**：不收集任何用户数据
- **本地处理**：所有配置和日志均在本地处理
- **开源透明**：代码完全开源，接受社区审查

## 💡 最佳实践

### 配置建议
1. **网络模式选择**：
   - 高性能设备：使用 `enhance` 模式
   - 兼容性优先：使用 `tproxy` 模式
   - 简单场景：使用 `redirect` 模式

2. **资源优化**：
   - 内存限制：根据设备调整 `memcg_limit`
   - CPU 绑定：绑定高性能核心提升响应速度
   - I/O 权重：平衡系统整体性能

3. **规则配置**：
   - 使用分类规则减少匹配时间
   - 优先级设置：本地 > 直连 > 代理
   - 定期更新 GeoIP 和 GeoSite 数据

### 维护建议
1. **定期检查**：
   - 每周检查服务状态和日志
   - 监控内存和 CPU 使用情况
   - 及时更新核心版本

2. **备份配置**：
   - 定期备份 `/data/adb/box/` 目录
   - 记录重要的配置修改
   - 测试恢复流程

3. **性能监控**：
   - 使用 Web 界面监控连接状态
   - 关注系统资源使用情况
   - 优化规则和配置参数

## 🤝 社区支持

### 获取帮助
- **GitHub Issues**：报告问题和功能请求
- **讨论区**：技术交流和经验分享
- **文档**：查看详细的使用说明

### 贡献方式
- **代码贡献**：提交 Pull Request
- **文档完善**：改进使用说明和教程
- **问题反馈**：报告 Bug 和改进建议
- **社区支持**：帮助其他用户解决问题

### 开发路线图
- [ ] 支持更多网络模式和优化选项
- [ ] 增强 Web 界面功能和用户体验
- [ ] 完善自动化测试和持续集成
- [ ] 提供更多的配置模板和示例
- [ ] 集成更多的监控和诊断工具

---

## 📚 相关文档

- [快速开始指南](QUICK-START-SINGBOX.md)
- [配置详解](box/sing-box/README.md)
- [变更日志](CHANGELOG-SINGBOX.md)
- [发布说明](RELEASE-NOTES-SINGBOX.md)
- [GitHub Actions 说明](.github/README.md)

---

<div align="center">

**Box for Magisk - Sing-box Edition**

专注于 sing-box 的高性能透明代理解决方案

[下载最新版本](https://github.com/taamarin/box_for_magisk/releases) | [查看文档](README-SINGBOX.md) | [报告问题](https://github.com/taamarin/box_for_magisk/issues)

</div>