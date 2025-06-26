# 默认配置修改总结

## 🎯 添加的默认配置修改

我已经在 GitHub Actions 工作流中添加了您要求的所有默认配置修改：

### 1. 默认网络模式 - enhance（增强模式）
```bash
# 修改 box/settings.ini 文件
sed -i 's/^network_mode=.*/network_mode="enhance"/' box/settings.ini
```
**效果**: TCP 使用 redirect 模式，UDP 使用 tproxy 模式，提供最佳兼容性和性能平衡

### 2. 默认代理核心 - sing-box
```bash
# 修改 box/settings.ini 文件  
sed -i 's/^bin_name=.*/bin_name="sing-box"/' box/settings.ini
```
**效果**: 使用 sing-box 作为默认代理核心，功能最新最全

### 3. 默认透明代理规则 - 黑名单模式
```bash
# 修改 box/package.list.cfg 文件
sed -i 's/^mode:.*/mode:blacklist/' box/package.list.cfg
```
**效果**: 默认所有应用通过代理，可在配置文件中指定例外应用

### 4. 默认 UI - zashboard
```bash
# 下载并安装 zashboard UI
ZASHBOARD_URL="https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip"
curl -L -o zashboard.zip "$ZASHBOARD_URL"
unzip -q zashboard.zip
cp -r zashboard-gh-pages/* box/sing-box/dashboard/
```
**效果**: 使用现代化的 zashboard UI 替代默认的 yacd

## 📋 工作流步骤详解

### 第四步：应用默认配置修改
```yaml
- name: "⚙️ 第四步：应用默认配置修改"
  run: |
    # 1. 设置网络模式为 enhance
    # 2. 设置代理核心为 sing-box  
    # 3. 设置透明代理为黑名单模式
    # 4. 下载并集成 zashboard UI
    # 5. 显示配置摘要
```

### 第八步：推送到 Telegram Bot
```yaml
- name: "📱 第八步：推送到 Telegram Bot"
  if: secrets.BOT_TOKEN != '' && secrets.CHAT_ID != ''
  env:
    BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
    CHAT_ID: ${{ secrets.CHAT_ID }}
```

## 🎨 Telegram 推送消息格式

推送的消息将包含默认配置信息：

```
v1.8.1-20241225-abcd123

— 最新提交信息1
— 最新提交信息2

🔧 默认配置:
• 代理核心: sing-box
• 网络模式: enhance (增强模式)
• 代理规则: blacklist (黑名单模式)  
• UI 界面: zashboard

🔗 GitHub
📦 Releases

#BoxForRoot #Magisk #KernelSU #APatch #singbox #enhance #zashboard
```

## 🔧 配置文件修改详情

### box/settings.ini 修改
```ini
# 修改前可能的值
bin_name="clash"
network_mode="tproxy"

# 修改后的值
bin_name="sing-box"
network_mode="enhance"
```

### box/package.list.cfg 修改
```ini
# 修改前可能的值
mode:whitelist

# 修改后的值
mode:blacklist
```

### UI 文件结构
```
box/sing-box/dashboard/
├── index.html
├── assets/
│   ├── css/
│   ├── js/
│   └── fonts/
└── ...（zashboard 的所有文件）
```

## ✅ 验证步骤

工作流会在配置修改后显示摘要：

```
📋 配置摘要：
  🎯 代理核心: sing-box
  📡 网络模式: enhance (增强模式)
  🚫 代理规则: blacklist (黑名单模式)
  🎨 UI 界面: zashboard
✅ 默认配置应用完成！
```

## 🚀 使用方法

### 自动触发
```bash
# 推送代码到 simple 分支
git push origin simple

# 创建标签
git tag v1.0.0
git push origin v1.0.0
```

### 手动触发
1. 进入 GitHub Actions 页面
2. 选择工作流
3. 点击 "Run workflow"

### 设置 Telegram 推送
在 GitHub Secrets 中设置：
- `BOT_TOKEN`: Telegram Bot Token
- `CHAT_ID`: 目标 Chat ID

## 🎯 最终效果

生成的模块包将具有以下默认配置：

1. **✅ sing-box 核心**: 最新功能，beta 版本支持
2. **✅ enhance 网络模式**: TCP redirect + UDP tproxy，最佳平衡
3. **✅ 黑名单代理**: 默认代理所有，灵活配置例外
4. **✅ zashboard UI**: 现代化界面，功能丰富
5. **✅ 自动推送**: 包含配置信息的 Telegram 通知

## 📱 安装后效果

用户安装模块后将获得：
- 开箱即用的最佳配置
- 现代化的 Web 管理界面
- 高性能的网络代理体验
- 灵活的应用代理控制

这些默认配置确保了用户获得最佳的开箱即用体验！🎉
