# GitHub Actions 工作流显示问题排查

## 🔍 问题分析

### 可能的原因

1. **路径过滤器过于严格**
   - 原工作流使用了 `paths` 过滤器
   - 只有特定文件变化时才触发
   - 可能导致工作流不显示在 Actions 页面

2. **YAML 语法错误**
   - 语法错误会导致工作流无法解析
   - GitHub 不会显示有语法错误的工作流

3. **分支问题**
   - 工作流文件需要在默认分支或当前分支上
   - 分支名称配置错误

4. **文件路径问题**
   - 必须在 `.github/workflows/` 目录下
   - 文件扩展名必须是 `.yml` 或 `.yaml`

## ✅ 已修复的问题

### 1. 移除严格的路径过滤器

**修复前**:
```yaml
push:
  branches:
    - simple
  paths:
    - 'box/bin/sing-box'
    - 'box/sing-box/**'
    - 'box/scripts/**'
    - 'box_service.sh'
    - 'customize.sh'
    - 'module.prop'
```

**修复后**:
```yaml
push:
  branches:
    - simple
```

### 2. 添加测试工作流

创建了 `test-display.yml` 来验证工作流显示：
```yaml
name: Test Display

on:
  workflow_dispatch:
  push:
    branches:
      - simple

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Test step
      run: echo "✅ 工作流显示测试"
```

## 🚀 现在应该可以看到的工作流

推送后，您应该能在 GitHub Actions 页面看到：

1. **"📦 构建并推送模块包"** - 主要的构建工作流
2. **"Test Display"** - 简单的测试工作流

## 🔧 验证步骤

### 1. 检查 Actions 页面
- 进入 GitHub 仓库
- 点击 "Actions" 标签
- 查看是否显示工作流

### 2. 手动触发测试
- 点击 "Test Display" 工作流
- 点击 "Run workflow"
- 选择 `simple` 分支
- 点击绿色的 "Run workflow" 按钮

### 3. 验证主工作流
- 点击 "📦 构建并推送模块包" 工作流
- 点击 "Run workflow"
- 验证是否可以手动触发

## 🎯 工作流功能

### 主工作流功能
1. **自动版本管理**: 基于日期和提交生成版本号
2. **模块信息更新**: 自动更新 `module.prop`
3. **语法检查**: 使用 shellcheck 检查脚本
4. **默认配置应用**: 
   - sing-box 核心
   - enhance 网络模式
   - 黑名单代理规则
   - zashboard UI
5. **模块打包**: 生成 ZIP 文件
6. **GitHub Release**: 自动创建预发布版本
7. **Telegram 推送**: 推送到 Bot（需要设置 Secrets）

### 触发条件
- **手动触发**: 在 Actions 页面手动运行
- **自动触发**: 推送到 `simple` 分支

## 📱 Telegram 推送设置

如果要启用 Telegram 推送，需要在 GitHub Secrets 中设置：

| Secret 名称 | 描述 | 示例 |
|------------|------|------|
| `BOT_TOKEN` | Telegram Bot Token | `123456789:ABCdef...` |
| `CHAT_ID` | 目标 Chat ID | `123456789` 或 `-1001234567890` |

### 设置步骤
1. 进入仓库 Settings
2. 点击 Secrets and variables → Actions
3. 点击 New repository secret
4. 添加 `BOT_TOKEN` 和 `CHAT_ID`

## 🔍 故障排除

### 工作流仍然不显示
1. **刷新页面**: 有时需要等待几分钟
2. **检查分支**: 确保在 `simple` 分支上
3. **检查文件路径**: 确认文件在 `.github/workflows/` 目录
4. **检查语法**: 使用在线 YAML 验证器

### 工作流显示但无法运行
1. **检查权限**: 确保有 Actions 权限
2. **检查语法**: 查看工作流文件是否有错误
3. **查看日志**: 点击失败的运行查看详细日志

### Telegram 推送失败
1. **检查 Secrets**: 确认 BOT_TOKEN 和 CHAT_ID 设置正确
2. **验证 Bot**: 确认 Bot 可以发送消息到目标 Chat
3. **检查网络**: 确认 GitHub Actions 可以访问 Telegram API

## 📊 工作流状态

### 成功运行的标志
- ✅ 版本号生成成功
- ✅ module.prop 更新完成
- ✅ 语法检查通过
- ✅ 默认配置应用成功
- ✅ 模块打包完成
- ✅ GitHub Release 创建成功
- ✅ Telegram 推送完成（如果配置了）

### 常见错误
- ❌ 语法检查失败: 修复脚本语法错误
- ❌ 打包失败: 检查文件权限和路径
- ❌ Telegram 推送失败: 检查 Secrets 配置

## 🎉 总结

通过移除严格的路径过滤器和添加测试工作流，现在应该能够：

1. ✅ 在 Actions 页面看到工作流
2. ✅ 手动触发工作流运行
3. ✅ 自动触发构建（推送到 simple 分支）
4. ✅ 生成包含默认配置的模块包
5. ✅ 推送到 Telegram Bot（如果配置了）

如果仍然有问题，请检查上述故障排除步骤或查看 GitHub Actions 的详细日志。
