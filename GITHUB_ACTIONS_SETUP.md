# GitHub Actions 自动化构建和推送设置指南

## 🚀 功能概述

这个 GitHub Actions 工作流提供以下功能：

- ✅ 自动构建 Box for Magisk 模块包
- ✅ 支持多种配置选项（核心、网络模式、UI）
- ✅ 自动推送到 Telegram Bot
- ✅ 创建 GitHub Release（标签推送时）
- ✅ 上传构建产物
- ✅ 详细的构建摘要

## 📋 必需的 GitHub Secrets

在您的 GitHub 仓库中设置以下 Secrets：

### Telegram Bot 配置（必需）

| Secret 名称 | 描述 | 获取方法 |
|------------|------|----------|
| `BOT_TOKEN` | Telegram Bot Token | 与 @BotFather 对话创建 Bot |
| `CHAT_ID` | 目标 Chat ID | Bot 私聊或群组 ID |

## 🔧 设置步骤

### 1. 创建 Telegram Bot

1. 在 Telegram 中搜索 @BotFather
2. 发送 `/newbot` 命令
3. 按提示设置 Bot 名称和用户名
4. 获取 Bot Token

### 2. 获取 Chat ID

#### 方法一：Bot 私聊
1. 在 Telegram 中搜索您的 Bot
2. 发送 `/start` 命令
3. 访问：`https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`
4. 在返回的 JSON 中找到 `chat.id`（正数）

#### 方法二：群组聊天
1. 将 Bot 添加到目标群组
2. 在群组中发送任意消息
3. 访问：`https://api.telegram.org/bot<BOT_TOKEN>/getUpdates`
4. 在返回的 JSON 中找到 `chat.id`（负数）

### 3. 设置 GitHub Secrets

1. 进入您的 GitHub 仓库
2. 点击 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret`
4. 添加以下 Secrets：

```
BOT_TOKEN: 您的 Bot Token
CHAT_ID: 目标 Chat ID（私聊为正数，群组为负数）
```

## 🎯 触发方式

### 自动触发

- **推送到主分支**: 自动构建并推送
- **创建标签**: 创建 Release 并推送
- **Pull Request**: 仅构建测试

### 手动触发

1. 进入 `Actions` 页面
2. 选择 `Build and Push to Telegram` 工作流
3. 点击 `Run workflow`
4. 选择配置选项：
   - **代理核心**: sing-box, clash, xray, v2fly, hysteria
   - **网络模式**: enhance, tproxy, redirect, mixed, tun
   - **UI 界面**: zashboard, yacd, metacubexd
   - **跳过推送**: 是否跳过 Telegram 推送

## 📦 构建产物

### 文件命名格式
```
box_for_root-{version}-{core}-{network_mode}.zip
```

示例：
```
box_for_root-v1.8.1-sing-box-enhance.zip
box_for_root-v20241225-clash-tproxy.zip
```

### 存储位置
- **GitHub Artifacts**: 保存 30 天
- **GitHub Releases**: 永久保存（标签推送时）
- **Telegram**: 推送到指定群组/频道

## 🔍 工作流配置

### 默认配置
```yaml
core: sing-box          # 代理核心
network_mode: enhance   # 网络模式
ui: zashboard          # UI 界面
proxy_mode: blacklist  # 代理规则（固定）
```

### 自定义配置示例

#### 游戏优化配置
```yaml
core: hysteria
network_mode: tun
ui: yacd
```

#### 企业稳定配置
```yaml
core: xray
network_mode: redirect
ui: metacubexd
```

#### 轻量级配置
```yaml
core: v2fly
network_mode: mixed
ui: yacd
```

## 📱 Telegram 推送格式

推送消息包含以下信息：

```
v1.8.1-20241225-abcd123

— 最新提交信息1
— 最新提交信息2
— 最新提交信息3

🔗 GitHub
📦 Releases

#BoxForRoot #Magisk #KernelSU #APatch #module
```

## 🛠️ 故障排除

### 常见问题

#### 1. Telegram 推送失败
```
❌ 错误: 缺少必需的环境变量 BOT_TOKEN
```
**解决方案**: 检查 GitHub Secrets 设置

#### 2. Chat ID 错误
```
❌ 发送失败: Chat not found
```
**解决方案**: 
- 确认 Chat ID 正确
- 确认 Bot 已添加到目标群组
- 确认 Bot 有发送消息权限

#### 3. API 凭据错误
```
❌ 发送失败: Invalid api_id/api_hash combination
```
**解决方案**: 重新获取 API_ID 和 API_HASH

#### 4. 构建失败
```
❌ 错误: 缺少依赖: unzip zip
```
**解决方案**: 工作流会自动安装依赖，如果仍然失败请检查网络连接

### 调试方法

#### 1. 查看工作流日志
1. 进入 `Actions` 页面
2. 点击失败的工作流
3. 查看详细日志

#### 2. 测试 Telegram 配置
```bash
# 本地测试（需要安装 telethon）
export BOT_TOKEN="your_token"
export CHAT_ID="your_chat_id"
export API_ID="your_api_id"
export API_HASH="your_api_hash"

python3 .github/telegram_push.py test_file.txt
```

#### 3. 跳过 Telegram 推送测试
手动触发工作流时勾选 "跳过 Telegram 推送" 选项

## 🔒 安全注意事项

1. **保护 Secrets**: 不要在代码中硬编码敏感信息
2. **权限控制**: Bot 只给予必要的权限
3. **定期更新**: 定期更换 Bot Token
4. **访问限制**: 限制仓库访问权限

## 📈 高级配置

### 自定义推送消息
编辑 `.github/telegram_push.py` 中的 `get_caption()` 函数

### 添加更多触发条件
编辑 `.github/workflows/build-and-push.yml` 中的 `on` 部分

### 自定义构建步骤
在工作流中添加自定义步骤

## 🎉 完成设置

设置完成后，您的仓库将具备：

- ✅ 自动化构建能力
- ✅ 多配置支持
- ✅ Telegram 自动推送
- ✅ Release 管理
- ✅ 构建产物存储

现在您可以：
1. 推送代码自动触发构建
2. 创建标签发布新版本
3. 手动触发自定义构建
4. 在 Telegram 中接收构建通知

享受自动化的便利！🚀
