#!/bin/bash

# Box for Magisk 工作流生成器
# 作者: Box for Root Team
# 版本: 1.0
# 描述: 自动化生成和推送 Box for Magisk 模块包的完整工作流

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检测运行环境
if [ "$GITHUB_ACTIONS" = "true" ]; then
    # GitHub Actions 环境
    BOX_DIR="${SCRIPT_DIR}/mock_box"
    MODULE_DIR="${SCRIPT_DIR}/mock_module"
    TEMP_DIR="/tmp/box_workflow"
    BUILD_DIR="${SCRIPT_DIR}/build"
    IS_GITHUB_ACTIONS=true
else
    # Android 设备环境
    BOX_DIR="/data/adb/box"
    MODULE_DIR="/data/adb/modules/box_for_root"
    TEMP_DIR="/tmp/box_workflow"
    BUILD_DIR="${SCRIPT_DIR}/build"
    IS_GITHUB_ACTIONS=false
fi

# 默认配置
DEFAULT_BIN_NAME="sing-box"
DEFAULT_NETWORK_MODE="enhance"
DEFAULT_PROXY_MODE="blacklist"
DEFAULT_UI="zashboard"

# Telegram Bot 配置 (需要用户设置环境变量)
TELEGRAM_API_ID="${API_ID}"
TELEGRAM_API_HASH="${API_HASH}"
TELEGRAM_BOT_TOKEN="${BOT_TOKEN}"
TELEGRAM_CHAT_ID="${CHAT_ID:-"-1001597117128"}"
TELEGRAM_MESSAGE_THREAD_ID="${MESSAGE_THREAD_ID:-"282263"}"

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" ;;
        *)       echo -e "${timestamp} - $message" ;;
    esac
}

# 输出环境检测结果
if [ "$IS_GITHUB_ACTIONS" = "true" ]; then
    log "INFO" "检测到 GitHub Actions 环境，使用模拟路径"
    log "DEBUG" "BOX_DIR: $BOX_DIR"
    log "DEBUG" "MODULE_DIR: $MODULE_DIR"
fi

# 检查依赖
check_dependencies() {
    log "INFO" "检查系统依赖..."
    
    local deps=("curl" "unzip" "zip" "python3")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR" "缺少依赖: ${missing_deps[*]}"
        log "INFO" "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log "INFO" "依赖检查完成"
}

# 初始化工作目录
init_workspace() {
    log "INFO" "初始化工作空间..."
    
    # 创建必要的目录
    mkdir -p "${TEMP_DIR}"
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${BOX_DIR}/bin"
    mkdir -p "${BOX_DIR}/clash/dashboard"
    mkdir -p "${BOX_DIR}/sing-box/dashboard"
    
    log "INFO" "工作空间初始化完成"
}

# 配置默认设置
configure_default_settings() {
    log "INFO" "配置默认运行模式..."

    if [ "$GITHUB_ACTIONS" = "true" ]; then
        # GitHub Actions 环境：创建模拟配置文件
        log "INFO" "GitHub Actions 环境：创建模拟配置文件"

        local settings_file="${BOX_DIR}/settings.ini"
        cat > "$settings_file" << EOF
#!/system/bin/sh
bin_name="${DEFAULT_BIN_NAME}"
network_mode="${DEFAULT_NETWORK_MODE}"
ipv6="false"
box_user_group="root:net_admin"
tproxy_port="9898"
redir_port="9797"
EOF

        local pkg_config="${BOX_DIR}/package.list.cfg"
        cat > "$pkg_config" << EOF
mode:${DEFAULT_PROXY_MODE}
# GitHub Actions 模拟配置
EOF

    else
        # Android 设备环境：修改现有配置
        # 备份原始配置
        if [ -f "${BOX_DIR}/settings.ini" ]; then
            cp "${BOX_DIR}/settings.ini" "${BOX_DIR}/settings.ini.bak"
            log "INFO" "已备份原始配置文件"
        fi

        # 更新 settings.ini 配置
        local settings_file="${BOX_DIR}/settings.ini"

        # 设置默认核心为 sing-box
        sed -i "s/^bin_name=.*/bin_name=\"${DEFAULT_BIN_NAME}\"/" "$settings_file"

        # 设置网络模式为 enhance (增强模式)
        sed -i "s/^network_mode=.*/network_mode=\"${DEFAULT_NETWORK_MODE}\"/" "$settings_file"

        # 设置透明代理规则为黑名单模式
        local pkg_config="${BOX_DIR}/package.list.cfg"
        sed -i "s/^mode:.*/mode:${DEFAULT_PROXY_MODE}/" "$pkg_config"
    fi

    log "INFO" "默认配置设置完成: 核心=${DEFAULT_BIN_NAME}, 网络模式=${DEFAULT_NETWORK_MODE}, 代理模式=${DEFAULT_PROXY_MODE}"
}

# 下载 sing-box 核心
download_singbox_core() {
    log "INFO" "检查并下载 sing-box 核心..."

    local bin_path="${BOX_DIR}/bin/sing-box"

    # 检查核心是否存在
    if [ -f "$bin_path" ]; then
        log "INFO" "sing-box 核心已存在，跳过下载"
        return 0
    fi

    if [ "$GITHUB_ACTIONS" = "true" ]; then
        # GitHub Actions 环境：创建模拟核心文件
        log "INFO" "GitHub Actions 环境：创建模拟 sing-box 核心文件"
        echo "#!/bin/bash" > "$bin_path"
        echo "echo 'sing-box mock version for GitHub Actions'" >> "$bin_path"
        chmod +x "$bin_path"
        log "INFO" "模拟 sing-box 核心创建完成"
        return 0
    fi

    log "INFO" "本地未找到 sing-box 核心，开始下载 beta 版本..."
    
    # 获取系统架构
    local arch
    case $(uname -m) in
        "aarch64") arch="arm64" ;;
        "armv7l"|"armv8l") arch="armv7" ;;
        "x86_64") arch="amd64" ;;
        "i386") arch="386" ;;
        *) log "ERROR" "不支持的架构: $(uname -m)"; exit 1 ;;
    esac
    
    # 获取最新 beta 版本
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | \
                    grep -E '"tag_name".*"v.*-beta\.' | head -1 | \
                    sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
    
    if [ -z "$latest_version" ]; then
        log "ERROR" "无法获取 sing-box 最新版本信息"
        exit 1
    fi
    
    log "INFO" "下载 sing-box ${latest_version} for linux-${arch}..."
    
    local download_url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/sing-box-${latest_version#v}-linux-${arch}.tar.gz"
    local temp_file="${TEMP_DIR}/sing-box.tar.gz"
    
    if curl -L -o "$temp_file" "$download_url"; then
        # 解压并安装
        tar -xzf "$temp_file" -C "${TEMP_DIR}"
        local extracted_dir=$(find "${TEMP_DIR}" -name "sing-box-*" -type d | head -1)
        
        if [ -d "$extracted_dir" ]; then
            cp "${extracted_dir}/sing-box" "$bin_path"
            chmod 6755 "$bin_path"
            chown root:net_admin "$bin_path"
            log "INFO" "sing-box 核心安装完成"
        else
            log "ERROR" "解压 sing-box 失败"
            exit 1
        fi
    else
        log "ERROR" "下载 sing-box 失败"
        exit 1
    fi
}

# 下载并配置 zashboard UI
download_zashboard_ui() {
    log "INFO" "下载并配置 zashboard UI..."

    local ui_dir="${BOX_DIR}/${DEFAULT_BIN_NAME}/dashboard"
    local temp_ui_file="${TEMP_DIR}/zashboard.zip"
    local zashboard_url="https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip"

    # 清理旧的 UI 文件
    if [ -d "$ui_dir" ]; then
        rm -rf "${ui_dir:?}"/*
        log "INFO" "已清理旧的 UI 文件"
    fi

    mkdir -p "$ui_dir"

    if [ "$GITHUB_ACTIONS" = "true" ]; then
        # GitHub Actions 环境：创建模拟 UI 文件
        log "INFO" "GitHub Actions 环境：创建模拟 zashboard UI"
        echo "<html><body><h1>Mock Zashboard UI for GitHub Actions</h1></body></html>" > "$ui_dir/index.html"
        log "INFO" "模拟 zashboard UI 创建完成"
        return 0
    fi

    # 下载 zashboard
    log "INFO" "从 GitHub 下载 zashboard..."
    if curl -L -o "$temp_ui_file" "$zashboard_url"; then
        # 解压 UI 文件
        unzip -q "$temp_ui_file" -d "${TEMP_DIR}/ui_extract"
        local extracted_ui_dir="${TEMP_DIR}/ui_extract/zashboard-gh-pages"

        if [ -d "$extracted_ui_dir" ]; then
            cp -r "${extracted_ui_dir}"/* "$ui_dir/"
            log "INFO" "zashboard UI 安装完成"
        else
            log "ERROR" "解压 zashboard UI 失败"
            exit 1
        fi
    else
        log "ERROR" "下载 zashboard UI 失败"
        exit 1
    fi
}

# 更新 webroot 配置
update_webroot_config() {
    log "INFO" "更新 webroot 配置..."

    if [ "$GITHUB_ACTIONS" = "true" ]; then
        # GitHub Actions 环境：使用相对路径
        local webroot_file="webroot/index.html"
    else
        # Android 设备环境：使用绝对路径
        local webroot_file="${MODULE_DIR}/webroot/index.html"
    fi

    mkdir -p "$(dirname "$webroot_file")"

    # 创建重定向到 dashboard 的 HTML 文件
    cat > "$webroot_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Box for Root Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            margin-bottom: 20px;
            font-size: 2.5em;
        }
        .redirect-info {
            margin: 20px 0;
            font-size: 1.2em;
        }
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: #fff;
            animation: spin 1s ease-in-out infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Box for Root</h1>
        <div class="redirect-info">
            <div class="loading"></div>
            <p>正在跳转到控制面板...</p>
        </div>
    </div>
    <script>
        setTimeout(function() {
            document.location = 'http://127.0.0.1:9090/ui/';
        }, 2000);
    </script>
</body>
</html>
EOF

    log "INFO" "webroot 配置更新完成"
}

# 生成 Magisk 模块包
build_module_package() {
    log "INFO" "生成 Magisk 模块包..."

    # 获取版本信息
    local version=$(grep '^version=' module.prop | cut -d'=' -f2)
    local version_code=$(date +%Y%m%d)

    # 更新版本代码
    sed -i "s/^versionCode=.*/versionCode=${version_code}/" module.prop

    # 创建构建目录
    local build_output="${BUILD_DIR}/box_for_root-${version}.zip"

    log "INFO" "打包模块文件..."

    # 使用改进的打包命令
    zip -r -9 -q "$build_output" \
        ./ \
        -x '.git/*' \
        -x 'CHANGELOG.md' \
        -x 'update.json' \
        -x 'build.sh' \
        -x '.github/*' \
        -x 'docs/*' \
        -x "${TEMP_DIR}/*" \
        -x "${BUILD_DIR}/*" \
        -x '*.log' \
        -x '*.tmp'

    if [ -f "$build_output" ]; then
        log "INFO" "模块包生成成功: $build_output"
        echo "$build_output"
    else
        log "ERROR" "模块包生成失败"
        exit 1
    fi
}

# 推送到 Telegram Bot
push_to_telegram() {
    local module_file="$1"

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_API_ID" ] || [ -z "$TELEGRAM_API_HASH" ]; then
        log "WARN" "Telegram Bot 配置不完整，跳过推送"
        log "INFO" "请设置以下环境变量以启用 Telegram 推送:"
        log "INFO" "  - API_ID: Telegram API ID"
        log "INFO" "  - API_HASH: Telegram API Hash"
        log "INFO" "  - BOT_TOKEN: Telegram Bot Token"
        return 0
    fi

    log "INFO" "推送模块包到 Telegram Bot..."

    # 检查 Python 依赖
    if ! python3 -c "import telethon" 2>/dev/null; then
        log "INFO" "安装 Telegram 推送依赖..."
        pip3 install telethon==1.31.1
    fi

    # 设置环境变量
    export API_ID="$TELEGRAM_API_ID"
    export API_HASH="$TELEGRAM_API_HASH"
    export BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
    export CHAT_ID="$TELEGRAM_CHAT_ID"
    export MESSAGE_THREAD_ID="$TELEGRAM_MESSAGE_THREAD_ID"
    export VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    export COMMIT=$(git log --oneline -n 5 --no-decorate 2>/dev/null | sed 's/^[0-9a-f]* //' | sed 's/^/— /' || echo "— Manual build")

    # 使用现有的 Telegram 推送脚本
    if [ -f ".github/taamarinbot.py" ]; then
        python3 .github/taamarinbot.py "$module_file"
        log "INFO" "模块包推送完成"
    else
        log "ERROR" "找不到 Telegram 推送脚本"
        exit 1
    fi
}

# 清理临时文件
cleanup() {
    log "INFO" "清理临时文件..."
    rm -rf "$TEMP_DIR"
    log "INFO" "清理完成"
}

# 显示帮助信息
show_help() {
    cat << EOF
Box for Magisk 工作流生成器

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -c, --core CORE         指定代理核心 (默认: sing-box)
                           支持: clash, sing-box, xray, v2fly, hysteria
    -m, --mode MODE         指定网络模式 (默认: enhance)
                           支持: redirect, tproxy, mixed, enhance, tun
    -p, --proxy-mode MODE   指定透明代理模式 (默认: blacklist)
                           支持: whitelist, blacklist
    -u, --ui UI             指定 UI 界面 (默认: zashboard)
                           支持: yacd, zashboard, metacubexd
    --skip-core             跳过核心下载
    --skip-ui               跳过 UI 下载
    --skip-telegram         跳过 Telegram 推送
    --build-only            仅生成模块包，不推送
    --clean                 清理并退出

环境变量:
    API_ID                  Telegram API ID
    API_HASH                Telegram API Hash
    BOT_TOKEN               Telegram Bot Token
    CHAT_ID                 Telegram Chat ID (可选)
    MESSAGE_THREAD_ID       Telegram Message Thread ID (可选)

示例:
    # 使用默认配置生成模块包
    $0

    # 使用 clash 核心和 tproxy 模式
    $0 --core clash --mode tproxy

    # 仅生成模块包，不推送到 Telegram
    $0 --build-only

    # 跳过核心和 UI 下载
    $0 --skip-core --skip-ui

EOF
}

# 主工作流函数
main_workflow() {
    log "INFO" "开始 Box for Magisk 工作流..."
    log "INFO" "配置信息:"
    log "INFO" "  - 代理核心: $DEFAULT_BIN_NAME"
    log "INFO" "  - 网络模式: $DEFAULT_NETWORK_MODE"
    log "INFO" "  - 代理模式: $DEFAULT_PROXY_MODE"
    log "INFO" "  - UI 界面: $DEFAULT_UI"

    # 执行工作流步骤
    check_dependencies
    init_workspace

    # 配置默认设置
    configure_default_settings

    # 下载核心 (如果需要)
    if [ "$SKIP_CORE" != "true" ]; then
        case "$DEFAULT_BIN_NAME" in
            "sing-box")
                download_singbox_core
                ;;
            "clash")
                if [ "$GITHUB_ACTIONS" = "true" ]; then
                    log "INFO" "GitHub Actions 环境：跳过 clash 核心下载"
                else
                    log "INFO" "使用现有的 clash 核心下载逻辑"
                    "${BOX_DIR}/scripts/box.tool" upkernel
                fi
                ;;
            *)
                if [ "$GITHUB_ACTIONS" = "true" ]; then
                    log "INFO" "GitHub Actions 环境：跳过通用核心下载"
                else
                    log "INFO" "使用通用核心下载逻辑"
                    "${BOX_DIR}/scripts/box.tool" upkernel
                fi
                ;;
        esac
    fi

    # 下载 UI (如果需要)
    if [ "$SKIP_UI" != "true" ]; then
        case "$DEFAULT_UI" in
            "zashboard")
                download_zashboard_ui
                ;;
            "yacd"|"metacubexd")
                if [ "$GITHUB_ACTIONS" = "true" ]; then
                    log "INFO" "GitHub Actions 环境：跳过 UI 下载"
                else
                    log "INFO" "使用现有的 UI 下载逻辑"
                    "${BOX_DIR}/scripts/box.tool" upxui
                fi
                ;;
        esac
    fi

    # 更新 webroot 配置
    update_webroot_config

    # 生成模块包
    local module_file
    module_file=$(build_module_package)

    # 推送到 Telegram (如果需要)
    if [ "$SKIP_TELEGRAM" != "true" ] && [ "$BUILD_ONLY" != "true" ]; then
        push_to_telegram "$module_file"
    fi

    # 清理临时文件
    cleanup

    log "INFO" "工作流完成!"
    log "INFO" "生成的模块包: $module_file"

    if [ "$BUILD_ONLY" = "true" ] || [ "$SKIP_TELEGRAM" = "true" ]; then
        log "INFO" "模块包已保存到: $module_file"
        log "INFO" "您可以手动安装或分发此模块包"
    fi
}

# 参数解析
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--core)
                DEFAULT_BIN_NAME="$2"
                shift 2
                ;;
            -m|--mode)
                DEFAULT_NETWORK_MODE="$2"
                shift 2
                ;;
            -p|--proxy-mode)
                DEFAULT_PROXY_MODE="$2"
                shift 2
                ;;
            -u|--ui)
                DEFAULT_UI="$2"
                shift 2
                ;;
            --skip-core)
                SKIP_CORE="true"
                shift
                ;;
            --skip-ui)
                SKIP_UI="true"
                shift
                ;;
            --skip-telegram)
                SKIP_TELEGRAM="true"
                shift
                ;;
            --build-only)
                BUILD_ONLY="true"
                shift
                ;;
            --clean)
                cleanup
                exit 0
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 验证参数
    case "$DEFAULT_BIN_NAME" in
        clash|sing-box|xray|v2fly|hysteria) ;;
        *) log "ERROR" "不支持的核心: $DEFAULT_BIN_NAME"; exit 1 ;;
    esac

    case "$DEFAULT_NETWORK_MODE" in
        redirect|tproxy|mixed|enhance|tun) ;;
        *) log "ERROR" "不支持的网络模式: $DEFAULT_NETWORK_MODE"; exit 1 ;;
    esac

    case "$DEFAULT_PROXY_MODE" in
        whitelist|blacklist) ;;
        *) log "ERROR" "不支持的代理模式: $DEFAULT_PROXY_MODE"; exit 1 ;;
    esac

    case "$DEFAULT_UI" in
        yacd|zashboard|metacubexd) ;;
        *) log "ERROR" "不支持的 UI: $DEFAULT_UI"; exit 1 ;;
    esac
}

# 信号处理
trap cleanup EXIT INT TERM

# 主程序入口
main() {
    # 显示横幅
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    Box for Magisk 工作流生成器                ║
║                                                              ║
║  自动化生成和推送 Box for Magisk 模块包的完整工作流           ║
║                                                              ║
║  作者: Box for Root Team                                     ║
║  版本: 1.0                                                   ║
╚══════════════════════════════════════════════════════════════╝

EOF

    # 解析命令行参数
    parse_arguments "$@"

    # 执行主工作流
    main_workflow
}

# 如果脚本被直接执行，则运行主程序
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
