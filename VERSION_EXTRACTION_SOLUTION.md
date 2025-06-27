# sing-box 版本提取解决方案

## 🎯 问题分析

### 核心问题
- `box/bin/sing-box` 是 Android ARM64 版本的二进制文件
- GitHub Actions 运行在 Linux x86_64 环境中
- 无法直接执行 Android 二进制文件获取版本信息

### 解决思路
从 Git commit 消息中提取 sing-box 版本信息，因为核心更新时 commit 会包含版本信息。

## ✅ 解决方案

### 版本提取逻辑

#### Commit 消息模式
```
Update sing-box binary to v1.12.0-beta.28-reF1nd (Android ARM64)
```

#### 提取步骤
1. 获取最新 commit 消息
2. 检查是否包含 "Update sing-box binary to v" 模式
3. 使用正则表达式提取版本号
4. 如果没有找到，使用 "unknown" 作为默认值

### 实现代码

```yaml
- name: "⚙️ 第二步：生成版本信息"
  run: |
    # 从 Git commit 消息中提取 sing-box 版本信息
    echo "ℹ️ 从 Git commit 消息中获取 sing-box 版本..."
    
    # 获取最新的 commit 消息
    LATEST_COMMIT=$(git log -1 --pretty=format:"%s")
    echo "📝 最新 commit: $LATEST_COMMIT"
    
    # 从 commit 消息中提取版本号
    if echo "$LATEST_COMMIT" | grep -q "Update sing-box binary to v"; then
      CORE_VERSION=$(echo "$LATEST_COMMIT" | sed -n 's/.*Update sing-box binary to v\([^ ]*\).*/\1/p')
      echo "✅ 从 commit 消息中提取到版本: $CORE_VERSION"
    else
      CORE_VERSION="unknown"
      echo "⚠️ 未在 commit 消息中找到版本信息，使用默认版本: $CORE_VERSION"
    fi
```

## 🧪 测试验证

### 测试用例
| Commit 消息 | 提取结果 |
|-------------|----------|
| `Update sing-box binary to v1.12.0-beta.28-reF1nd (Android ARM64)` | `1.12.0-beta.28-reF1nd` |
| `Update sing-box binary to v1.11.0-beta.15 (Android ARM64)` | `1.11.0-beta.15` |
| `Update sing-box binary to v1.10.5 (Android ARM64)` | `1.10.5` |
| `Fix some bugs` | `unknown` |
| `Add new features` | `unknown` |

### 正则表达式说明
```bash
sed -n 's/.*Update sing-box binary to v\([^ ]*\).*/\1/p'
```

- `.*Update sing-box binary to v` - 匹配前缀
- `\([^ ]*\)` - 捕获版本号（非空格字符）
- `.*` - 匹配后缀
- `\1` - 输出捕获的版本号
- `p` - 打印匹配的行

## 🚀 工作流执行示例

### 成功提取版本
```bash
ℹ️ 从 Git commit 消息中获取 sing-box 版本...
📝 最新 commit: Update sing-box binary to v1.12.0-beta.28-reF1nd (Android ARM64)
✅ 从 commit 消息中提取到版本: 1.12.0-beta.28-reF1nd

ℹ️ 获取 Git Commit Hash...
GIT_HASH: a1b2c3d

✅ 成功生成版本号: 1.12.0-beta.28-reF1nd+a1b2c3d
```

### 未找到版本信息
```bash
ℹ️ 从 Git commit 消息中获取 sing-box 版本...
📝 最新 commit: Fix workflow issues
⚠️ 未在 commit 消息中找到版本信息，使用默认版本: unknown

ℹ️ 获取 Git Commit Hash...
GIT_HASH: a1b2c3d

✅ 成功生成版本号: unknown+a1b2c3d
```

## 📋 优势分析

### 相比直接执行二进制文件
1. **✅ 跨平台兼容**: 不依赖特定架构的二进制文件
2. **✅ 执行效率**: 无需文件权限设置和二进制执行
3. **✅ 信息准确**: 直接从更新记录中获取版本信息
4. **✅ 错误处理**: 有明确的降级策略

### 相比硬编码版本
1. **✅ 自动更新**: 随 commit 消息自动获取最新版本
2. **✅ 历史追踪**: 可以追踪版本更新历史
3. **✅ 维护简单**: 无需手动更新配置文件

## 🔄 版本更新流程

### 标准流程
1. **更新 sing-box 核心**: 替换 `box/bin/sing-box` 文件
2. **提交更改**: 使用标准格式的 commit 消息
   ```
   Update sing-box binary to v[版本号] (Android ARM64)
   ```
3. **触发工作流**: 推送到 `simple` 分支
4. **自动构建**: 工作流自动提取版本并生成模块包

### Commit 消息格式
```
Update sing-box binary to v1.12.0-beta.28-reF1nd (Android ARM64)
```

**格式要求**:
- 必须包含 "Update sing-box binary to v"
- 版本号紧跟在 "v" 后面
- 版本号后面有空格或其他字符
- 建议包含架构信息 "(Android ARM64)"

## 🎉 总结

通过从 Git commit 消息中提取版本信息，我们解决了：

- ✅ **架构兼容性问题**: Android 二进制无法在 Linux 中执行
- ✅ **版本信息获取**: 准确提取 sing-box 版本号
- ✅ **自动化流程**: 无需手动配置版本信息
- ✅ **错误处理**: 有合理的降级策略

这种方案既解决了技术限制，又保持了工作流的自动化特性！🎊

## 📝 测试脚本

项目中包含 `test_version_extraction.sh` 脚本，可以本地测试版本提取逻辑：

```bash
bash test_version_extraction.sh
```

这个脚本会测试各种 commit 消息格式，验证版本提取的准确性。
