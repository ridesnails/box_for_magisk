# sing-box RuleSet 错误修复方案

## 🔍 问题分析

### 错误信息
```
marshal object: json: error calling MarshalJSON for type option.RuleSet: 
expected json object start, but starts with nil
```

### 问题特征
- ✅ 直接运行 `sing-box run -c config.json` 正常工作
- ❌ 作为模块运行时出现 RuleSet 相关错误
- 🎯 问题不在 config.json 文件本身

### 根本原因分析
这个问题通常由以下原因导致：

1. **动态配置生成**: 模块运行时可能会动态修改配置文件
2. **环境差异**: 模块运行环境与直接运行环境不同
3. **RuleSet 引用问题**: 配置中引用了 null 或不存在的 RuleSet
4. **JSON 序列化问题**: 某些 RuleSet 对象在序列化时为 nil

## ✅ 解决方案

### 在工作流中添加配置文件修复步骤

我在第四步"应用默认配置修改"中添加了第5个子步骤：

#### 5. 修复 sing-box 配置文件中的 RuleSet 问题

```yaml
# 5. 修复 sing-box 配置文件中的 RuleSet 问题
echo "🔧 检查并修复 sing-box 配置文件..."
CONFIG_FILE="box/sing-box/config.json"

if [ -f "$CONFIG_FILE" ]; then
  # 备份原始配置文件
  cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
  
  # 使用 Python 脚本修复 JSON 配置
  python3 << 'EOF'
  # Python 修复脚本
  EOF
fi
```

### 修复逻辑详解

#### 1. 检查并修复 route.rule_set
```python
if 'route' in config and 'rule_set' in config['route']:
    rule_sets = config['route']['rule_set']
    if rule_sets is None:
        config['route']['rule_set'] = []  # null -> 空数组
    elif isinstance(rule_sets, list):
        # 过滤掉 null 元素
        config['route']['rule_set'] = [rs for rs in rule_sets if rs is not None]
```

#### 2. 检查并修复 route.rules 中的 rule_set 引用
```python
for rule in config['route']['rules']:
    if isinstance(rule, dict) and 'rule_set' in rule:
        if rule['rule_set'] is None:
            rule['rule_set'] = []  # null -> 空数组
        elif isinstance(rule['rule_set'], list):
            # 清理无效引用
            rule['rule_set'] = [rs for rs in rule['rule_set'] if rs is not None and rs != ""]
```

#### 3. 错误处理和恢复
```python
except Exception as e:
    print(f"❌ 配置文件修复失败: {e}")
    # 恢复备份
    shutil.copy('box/sing-box/config.json.backup', 'box/sing-box/config.json')
```

## 🎯 修复的具体问题

### 常见的 RuleSet 配置问题

#### 问题 1: null RuleSet 数组
```json
{
  "route": {
    "rule_set": null  // ❌ 这会导致序列化错误
  }
}
```

**修复后**:
```json
{
  "route": {
    "rule_set": []  // ✅ 空数组
  }
}
```

#### 问题 2: 数组中的 null 元素
```json
{
  "route": {
    "rule_set": [
      "geosite-cn",
      null,  // ❌ null 元素
      "geoip-cn"
    ]
  }
}
```

**修复后**:
```json
{
  "route": {
    "rule_set": [
      "geosite-cn",
      "geoip-cn"  // ✅ 移除 null 元素
    ]
  }
}
```

#### 问题 3: 规则中的 null rule_set 引用
```json
{
  "route": {
    "rules": [
      {
        "rule_set": null,  // ❌ null 引用
        "outbound": "direct"
      }
    ]
  }
}
```

**修复后**:
```json
{
  "route": {
    "rules": [
      {
        "rule_set": [],  // ✅ 空数组
        "outbound": "direct"
      }
    ]
  }
}
```

## 🚀 工作流执行示例

### 成功修复的日志
```bash
🔧 检查并修复 sing-box 配置文件...
📋 检查配置文件: box/sing-box/config.json
🔍 发现 rule_set 配置，进行修复...
🔧 修复 route.rule_set: null -> []
🔧 移除了 2 个 null RuleSet 元素
🔧 清理了 route.rules[3].rule_set 中的无效引用
✅ 配置文件修复完成
✅ 配置文件检查完成
```

### 无需修复的日志
```bash
🔧 检查并修复 sing-box 配置文件...
📋 检查配置文件: box/sing-box/config.json
ℹ️ 配置文件中未发现 rule_set 配置
✅ 配置文件检查完成
```

## 🔒 安全措施

### 1. 备份机制
- 修复前自动备份原始配置文件
- 修复失败时自动恢复备份

### 2. 错误处理
- 捕获所有可能的异常
- 提供详细的错误信息
- 确保工作流不会因配置修复失败而中断

### 3. 验证机制
- 修复后验证 JSON 格式正确性
- 确保必要的配置项存在

## 📋 预防措施

### 1. 配置文件模板
建议在项目中维护一个标准的 config.json 模板，确保：
- 所有 RuleSet 相关字段都有合理的默认值
- 不包含 null 值
- 格式正确且完整

### 2. 配置验证
在模块脚本中添加配置文件验证逻辑：
```bash
# 验证配置文件
if ! sing-box check -c config.json; then
    echo "配置文件验证失败，使用默认配置"
    cp config.json.template config.json
fi
```

### 3. 动态配置生成
如果需要动态生成配置，确保：
- 使用可靠的 JSON 库
- 验证生成的配置文件
- 提供降级方案

## 🎉 总结

通过在工作流中添加配置文件修复步骤，我们可以：

- ✅ **预防性修复**: 在打包前修复潜在的 RuleSet 问题
- ✅ **自动化处理**: 无需手动干预，自动检测和修复
- ✅ **安全可靠**: 有备份和恢复机制
- ✅ **兼容性好**: 不影响正常的配置文件

这样生成的模块包应该能够避免 RuleSet 相关的运行时错误！🎊
