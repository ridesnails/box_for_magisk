# Sing-box 规则集文件说明

本目录包含用于 sing-box 路由规则的规则集文件，用于解决运行时可能出现的 `no such file or directory` 错误。

## 📋 文件列表

| 文件名 | 用途 | 描述 |
|--------|------|------|
| `direct.json` | 直连规则 | 包含需要直接连接的域名和IP段 |
| `proxy.json` | 代理规则 | 包含需要通过代理访问的国外网站 |
| `reject.json` | 拒绝规则 | 包含广告、追踪和恶意网站 |
| `cn.json` | 中国大陆规则 | 专门针对中国大陆网站的规则集 |
| `streaming.json` | 流媒体规则 | 包含 Netflix、YouTube 等流媒体平台 |

## 🔧 使用方法

这些规则集文件已自动配置在 `config.json` 中，无需手动配置。sing-box 会自动加载和使用这些规则。

### 规则优先级
1. **reject-list** - 最高优先级，阻止广告和恶意内容
2. **direct-list/cn-list** - 直连规则，中国大陆网站
3. **proxy-list/streaming-list** - 代理规则，国外网站和流媒体

## 📝 自定义规则

### 添加直连网站
编辑 `direct.json`，在相应的数组中添加域名：

```json
{
  "version": 2,
  "rules": [
    {
      "domain_suffix": [
        "example.com",  // 添加你的域名
        "your-site.org"
      ]
    }
  ]
}
```

### 添加代理网站
编辑 `proxy.json`，添加需要代理的域名。

### 添加广告屏蔽
编辑 `reject.json`，添加需要屏蔽的广告域名。

## 🛠️ 故障排除

### 常见错误
- `open /data/adb/box/sing-box/source/direct.json: no such file or directory`

**解决方案：**
1. 检查文件是否存在：`ls -la /data/adb/box/sing-box/source/`
2. 重新安装模块
3. 检查文件权限：`chmod 644 /data/adb/box/sing-box/source/*.json`

### 验证规则集
```bash
# 使用 sing-box 验证配置
/data/adb/box/bin/sing-box check -c /data/adb/box/sing-box/config.json
```

## 📚 规则集格式

所有规则集文件都遵循 sing-box 的标准格式：

```json
{
  "version": 2,
  "rules": [
    {
      "domain_suffix": ["example.com"],
      "domain_keyword": ["keyword"],
      "domain_regex": ["regex_pattern"],
      "ip_cidr": ["10.0.0.0/8"],
      "port": [80, 443],
      "port_range": ["1000:2000"]
    }
  ]
}
```

## 🔄 更新规则集

规则集文件支持热更新，修改后重启 sing-box 服务即可生效：

```bash
su -c "/data/adb/box/scripts/box.service restart"
```

---

> **提示**：这些规则集文件是为了确保 sing-box 的正常运行而创建的。如果您有自定义的规则集文件，建议备份后再进行修改。