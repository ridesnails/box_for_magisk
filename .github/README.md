# 🤖 GitHub Actions 自动化系统

这个文档说明了为sing-box专用分支设置的完整GitHub Actions自动化系统。

## 📋 工作流概述

### 🔄 自动更新工作流

#### 1. `update-singbox.yml` - sing-box核心自动更新
- **触发条件**：
  - 定时执行：每天 02:00 和 14:00 UTC
  - 手动触发：支持强制更新和Beta版本选择
- **主要功能**：
  - 检查sing-box新版本（包括Beta版本）
  - 自动下载多架构二进制文件（amd64, arm64, armv7）
  - 更新版本信息和配置文件
  - 自动创建Pull Request
  - GitHub API限制处理和重试机制

#### 2. `update-zashboard.yml` - Zashboard UI自动更新
- **触发条件**：
  - 定时执行：每天 04:00 和 16:00 UTC（错开sing-box更新时间）
  - 手动触发：支持强制更新和指定版本
- **主要功能**：
  - 监控Zashboard仓库新版本
  - 自动下载和部署UI文件
  - 更新配置文件和API端点
  - 保持配置兼容性
  - 支持回滚机制

### 📦 构建和测试工作流

#### 3. `build-module.yml` - 模块自动打包
- **触发条件**：
  - 代码推送到主分支
  - Pull Request合并
  - 手动触发创建发布版本
- **主要功能**：
  - 自动计算版本号（语义化版本控制）
  - 构建Magisk模块压缩包
  - 生成SHA256和MD5校验文件
  - 创建GitHub Release或开发版本
  - 自动生成详细的更新日志

#### 4. `test-integration.yml` - 集成测试
- **触发条件**：
  - 代码推送和Pull Request
  - 定时执行：每天凌晨3点
  - 手动触发
- **测试内容**：
  - JSON配置文件格式验证
  - Shell脚本语法和功能检查
  - Web界面结构验证
  - 模块结构完整性检查
  - 配置兼容性测试

## 🔧 配置要求

### GitHub Secrets

确保在仓库设置中配置以下Secrets：

```
GITHUB_TOKEN - GitHub访问令牌（自动提供）
```

### 分支保护

建议为主分支设置以下保护规则：
- 要求Pull Request审查
- 要求状态检查通过
- 要求分支为最新状态

## 📊 版本管理

### 自动版本计算

#### 发布版本（手动触发）
- **Major**: 主要版本更新（重大变更）
- **Minor**: 次要版本更新（新功能）
- **Patch**: 补丁版本更新（错误修复）

#### 开发版本（自动生成）
- 格式：`{current_version}-dev.{build_number}`
- 例如：`1.8.0-dev.0123`

### 版本文件更新

自动更新以下文件：
- `module.prop` - 模块属性
- `update.json` - 更新信息
- `CHANGELOG.md` - 更新日志

## 🚀 使用指南

### 手动触发更新

#### sing-box核心更新
1. 进入Actions页面
2. 选择"Update sing-box Core"工作流
3. 点击"Run workflow"
4. 选择是否强制更新和包含Beta版本

#### Zashboard UI更新
1. 进入Actions页面
2. 选择"Update Zashboard UI"工作流
3. 点击"Run workflow"
4. 可选择特定版本或使用最新版本

#### 创建发布版本
1. 进入Actions页面
2. 选择"Build Magisk Module"工作流
3. 点击"Run workflow"
4. 选择"创建新版本发布"
5. 选择版本类型（patch/minor/major）

### 监控工作流状态

#### 成功指标
- ✅ 所有检查通过
- ✅ Pull Request自动创建
- ✅ 文件正确更新
- ✅ 版本号递增

#### 失败处理
- 查看工作流日志
- 检查API限制状态
- 验证网络连接
- 检查配置文件格式

## 📋 最佳实践

### 定时更新策略
- sing-box更新：工作时间检查，避免频繁触发
- Zashboard更新：错开时间，减少API调用冲突
- 测试执行：凌晨执行，不影响开发工作

### API限制管理
- 检查剩余调用次数
- 实现退避策略
- 使用缓存减少重复请求

### 安全考虑
- 使用最小权限原则
- 定期轮换访问令牌
- 验证下载文件完整性

## 🔍 故障排除

### 常见问题

#### 1. sing-box更新失败
```bash
# 检查原因
- GitHub API限制
- 下载链接失效
- 架构不匹配
- 网络连接问题
```

#### 2. Zashboard更新失败
```bash
# 检查原因
- 构建失败
- 依赖缺失
- 配置错误
- 权限问题
```

#### 3. 模块构建失败
```bash
# 检查原因
- 文件缺失
- 语法错误
- 压缩失败
- 版本计算错误
```

#### 4. 测试失败
```bash
# 检查原因
- 配置格式错误
- 脚本语法问题
- 依赖缺失
- 权限不足
```

### 调试步骤

1. **查看工作流日志**
   ```
   Actions -> 选择失败的工作流 -> 查看详细日志
   ```

2. **本地验证**
   ```bash
   # 验证JSON格式
   jq empty box/sing-box/config.json
   
   # 检查脚本语法
   bash -n customize.sh
   
   # 测试模块结构
   zip -T module.zip
   ```

3. **手动重试**
   ```
   Re-run failed jobs -> Re-run all jobs
   ```

## 📈 性能优化

### 缓存策略
- Node.js依赖缓存
- 构建产物缓存
- Docker镜像缓存

### 并行执行
- 独立任务并行运行
- 依赖任务串行执行
- 资源共享优化

### 资源使用
- 选择合适的运行器规格
- 优化下载和上传
- 减少网络传输

## 🔒 安全措施

### 权限控制
- 最小化仓库权限
- 使用只读令牌
- 定期审查访问权限

### 代码扫描
- 依赖漏洞检查
- 静态代码分析
- 安全配置验证

### 数据保护
- 敏感信息使用Secrets
- 日志中屏蔽敏感数据
- 安全的文件传输

## 📞 支持与反馈

如果遇到问题或有改进建议，请：

1. 创建Issue描述问题
2. 提供详细的错误日志
3. 说明复现步骤
4. 建议解决方案

---

*此文档由GitHub Actions自动化系统维护，最后更新：$(date +"%Y-%m-%d")*