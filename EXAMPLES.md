# Box for Magisk 工作流使用示例

## 🎯 使用场景示例

### 场景 1: 开发者完整工作流

**需求**: 开发者需要生成一个完整的模块包并推送到 Telegram 频道

```bash
# 1. 设置 Telegram Bot 环境变量
export API_ID="12345678"
export API_HASH="abcdef1234567890abcdef1234567890"
export BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"

# 2. 运行完整工作流
./workflow_generator.sh

# 输出示例:
# [INFO] 开始 Box for Magisk 工作流...
# [INFO] 配置信息:
# [INFO]   - 代理核心: sing-box
# [INFO]   - 网络模式: enhance
# [INFO]   - 代理模式: blacklist
# [INFO]   - UI 界面: zashboard
# [INFO] 检查系统依赖...
# [INFO] 依赖检查完成
# [INFO] 初始化工作空间...
# [INFO] 下载 sing-box 核心...
# [INFO] 下载并配置 zashboard UI...
# [INFO] 生成 Magisk 模块包...
# [INFO] 推送模块包到 Telegram Bot...
# [INFO] 工作流完成!
```

### 场景 2: 自定义配置构建

**需求**: 使用 clash 核心 + tproxy 模式 + 白名单代理

```bash
./workflow_generator.sh \
    --core clash \
    --mode tproxy \
    --proxy-mode whitelist \
    --ui yacd

# 这将生成一个使用以下配置的模块包:
# - 核心: clash (mihomo)
# - 网络模式: tproxy (纯透明代理)
# - 代理规则: whitelist (仅代理指定应用)
# - UI: yacd (经典界面)
```

### 场景 3: 仅构建不推送

**需求**: 生成模块包但不推送到 Telegram

```bash
./workflow_generator.sh --build-only

# 输出:
# [INFO] 模块包已保存到: ./build/box_for_root-v1.8.zip
# [INFO] 您可以手动安装或分发此模块包
```

### 场景 4: 跳过下载使用现有文件

**需求**: 使用已有的核心和 UI 文件，仅重新打包

```bash
./workflow_generator.sh --skip-core --skip-ui --build-only

# 适用于:
# - 已经下载过核心和 UI
# - 仅需要重新打包配置更改
# - 网络环境不佳的情况
```

### 场景 5: 设备端快速配置

**需求**: 在已安装 Box for Magisk 的 Android 设备上快速配置

```bash
# 1. 将脚本推送到设备
adb push quick_setup.sh /sdcard/

# 2. 在设备上执行
adb shell
su
cd /sdcard
chmod +x quick_setup.sh
./quick_setup.sh

# 交互式配置过程:
# 是否下载 sing-box 核心? (y/N): y
# 是否下载 zashboard UI? (y/N): y  
# 是否重启 Box 服务以应用配置? (y/N): y
```

## 🔧 高级配置示例

### 示例 1: 企业环境配置

```bash
# 企业网络环境，需要稳定性优先
./workflow_generator.sh \
    --core xray \
    --mode redirect \
    --proxy-mode whitelist \
    --ui metacubexd
```

**配置说明**:
- `xray`: 企业级稳定性
- `redirect`: 兼容性最佳
- `whitelist`: 精确控制代理应用
- `metacubexd`: 功能丰富的管理界面

### 示例 2: 游戏优化配置

```bash
# 游戏环境，需要低延迟
./workflow_generator.sh \
    --core hysteria \
    --mode tun \
    --proxy-mode blacklist
```

**配置说明**:
- `hysteria`: 专为高速传输优化
- `tun`: 系统级代理，延迟最低
- `blacklist`: 默认代理，排除游戏应用

### 示例 3: 开发测试配置

```bash
# 开发环境，需要灵活性
./workflow_generator.sh \
    --core sing-box \
    --mode mixed \
    --proxy-mode blacklist \
    --ui zashboard
```

**配置说明**:
- `sing-box`: 功能最新最全
- `mixed`: TCP redirect + UDP tun，平衡性能
- `blacklist`: 灵活的应用控制
- `zashboard`: 现代化调试界面

## 📱 实际部署示例

### 部署到测试设备

```bash
# 1. 生成测试版本
./workflow_generator.sh --build-only

# 2. 推送到设备
adb push ./build/box_for_root-*.zip /sdcard/

# 3. 通过 Magisk Manager 安装
# 4. 重启设备
# 5. 验证功能
adb shell su -c '/data/adb/box/scripts/box.service status'
```

### 批量部署脚本

```bash
#!/bin/bash
# batch_deploy.sh - 批量部署脚本

DEVICES=("device1" "device2" "device3")
MODULE_FILE="./build/box_for_root-v1.8.zip"

# 生成模块包
./workflow_generator.sh --build-only

# 部署到所有设备
for device in "${DEVICES[@]}"; do
    echo "部署到设备: $device"
    adb -s "$device" push "$MODULE_FILE" /sdcard/
    adb -s "$device" shell su -c "magisk --install-module /sdcard/$(basename $MODULE_FILE)"
done
```

## 🚀 CI/CD 集成示例

### GitHub Actions 工作流

```yaml
# .github/workflows/build-and-release.yml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup environment
      run: |
        chmod +x workflow_generator.sh
        sudo apt-get update
        sudo apt-get install -y curl unzip zip python3 python3-pip
    
    - name: Build module
      env:
        API_ID: ${{ secrets.API_ID }}
        API_HASH: ${{ secrets.API_HASH }}
        BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
      run: |
        ./workflow_generator.sh
    
    - name: Upload to releases
      uses: softprops/action-gh-release@v1
      with:
        files: ./build/*.zip
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        API_ID = credentials('telegram-api-id')
        API_HASH = credentials('telegram-api-hash')
        BOT_TOKEN = credentials('telegram-bot-token')
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'chmod +x workflow_generator.sh'
                sh './workflow_generator.sh'
            }
        }
        
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'build/*.zip', fingerprint: true
            }
        }
    }
}
```

## 🔍 调试和故障排除示例

### 调试模式运行

```bash
# 启用详细日志
set -x
./workflow_generator.sh --core sing-box --build-only
set +x
```

### 分步骤调试

```bash
# 1. 仅测试依赖
./test_workflow.sh

# 2. 仅测试配置生成
./workflow_generator.sh --skip-core --skip-ui --build-only

# 3. 仅测试核心下载
./workflow_generator.sh --skip-ui --build-only

# 4. 完整测试
./workflow_generator.sh --build-only
```

### 网络问题解决

```bash
# 使用代理下载
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
./workflow_generator.sh

# 或者使用 GitHub 镜像
sed -i 's|github.com|mirror.ghproxy.com/https://github.com|g' workflow_generator.sh
```

## 📊 性能优化示例

### 缓存优化

```bash
# 创建缓存目录
mkdir -p ~/.box_cache/{cores,ui}

# 修改脚本使用缓存
export CACHE_DIR="$HOME/.box_cache"
./workflow_generator.sh
```

### 并行下载

```bash
# 同时下载核心和 UI
{
    ./workflow_generator.sh --skip-ui --build-only &
    ./workflow_generator.sh --skip-core --build-only &
    wait
}
```

## 🎨 自定义扩展示例

### 添加自定义核心

```bash
# 在 workflow_generator.sh 中添加
download_custom_core() {
    log "INFO" "下载自定义核心..."
    # 自定义下载逻辑
}

# 在主工作流中调用
case "$DEFAULT_BIN_NAME" in
    "custom")
        download_custom_core
        ;;
esac
```

### 添加自定义 UI

```bash
# 添加新的 UI 选项
download_custom_ui() {
    log "INFO" "下载自定义 UI..."
    local ui_url="https://example.com/custom-ui.zip"
    # 下载和配置逻辑
}
```

### 添加自定义推送

```bash
# 添加 Discord 推送支持
push_to_discord() {
    local webhook_url="$DISCORD_WEBHOOK_URL"
    local module_file="$1"
    
    curl -X POST "$webhook_url" \
        -F "file=@$module_file" \
        -F "content=新的 Box for Magisk 模块包已生成"
}
```

## 📝 配置模板示例

### 最小配置模板

```ini
# settings.ini - 最小配置
bin_name="sing-box"
network_mode="enhance"
ipv6="false"
box_user_group="root:net_admin"
```

### 完整配置模板

```ini
# settings.ini - 完整配置
bin_name="sing-box"
network_mode="enhance"
tproxy_port="9898"
redir_port="9797"
ipv6="false"
box_user_group="root:net_admin"
cgroup_memcg="true"
memcg_limit="200M"
run_crontab="true"
update_geo="true"
update_subscription="true"
interva_update="0 6 * * *"
```

这些示例涵盖了工作流的各种使用场景，从基本使用到高级定制，从单设备部署到批量管理，帮助用户根据自己的需求选择合适的配置和使用方式。
