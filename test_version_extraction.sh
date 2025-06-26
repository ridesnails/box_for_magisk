#!/bin/bash

# 测试版本提取脚本

echo "🧪 测试 sing-box 版本提取..."

# 测试用例
test_commits=(
    "Update sing-box binary to v1.12.0-beta.28-reF1nd (Android ARM64)"
    "Update sing-box binary to v1.11.0-beta.15 (Android ARM64)"
    "Update sing-box binary to v1.10.5 (Android ARM64)"
    "Fix some bugs"
    "Add new features"
)

echo "📋 测试用例:"
for i in "${!test_commits[@]}"; do
    commit="${test_commits[$i]}"
    echo "  $((i+1)). $commit"
    
    if echo "$commit" | grep -q "Update sing-box binary to v"; then
        version=$(echo "$commit" | sed -n 's/.*Update sing-box binary to v\([^ ]*\).*/\1/p')
        echo "     ✅ 提取版本: $version"
    else
        echo "     ❌ 未找到版本信息"
    fi
    echo
done

echo "🎯 正则表达式说明:"
echo "  模式: 's/.*Update sing-box binary to v\([^ ]*\).*/\1/p'"
echo "  匹配: 'Update sing-box binary to v' + 版本号 + 空格或其他字符"
echo "  提取: 版本号部分（不包含空格的连续字符）"
