#!/bin/bash

# Telegram 推送功能测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" ;;
        *)       echo -e "${timestamp} - $message" ;;
    esac
}

# 检查环境变量
check_env_vars() {
    log "INFO" "检查环境变量..."

    local required_vars=("BOT_TOKEN" "CHAT_ID")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -ne 0 ]; then
        log "ERROR" "缺少以下环境变量:"
        for var in "${missing_vars[@]}"; do
            log "ERROR" "  - $var"
        done
        log "INFO" "请设置这些环境变量后重试"
        return 1
    fi

    log "INFO" "环境变量检查通过"
    log "DEBUG" "BOT_TOKEN: ${BOT_TOKEN:0:10}..."
    log "DEBUG" "CHAT_ID: $CHAT_ID"
    return 0
}

# 检查 Python 依赖
check_python_deps() {
    log "INFO" "检查 Python 依赖..."

    if ! command -v python3 &> /dev/null; then
        log "ERROR" "未找到 python3"
        return 1
    fi

    if ! python3 -c "import requests" 2>/dev/null; then
        log "WARN" "未安装 requests 库"
        log "INFO" "正在安装 requests..."
        pip3 install requests
    fi

    log "INFO" "Python 依赖检查通过"
    return 0
}

# 创建测试文件
create_test_file() {
    log "INFO" "创建测试文件..."
    
    local test_file="test_module.zip"
    local test_content="这是一个测试模块包"
    
    # 创建一个简单的测试文件
    echo "$test_content" > test_file.txt
    zip -q "$test_file" test_file.txt
    rm test_file.txt
    
    if [ -f "$test_file" ]; then
        log "INFO" "测试文件创建成功: $test_file"
        echo "$test_file"
    else
        log "ERROR" "测试文件创建失败"
        return 1
    fi
}

# 测试 Telegram 推送
test_telegram_push() {
    local test_file="$1"
    
    log "INFO" "测试 Telegram 推送..."
    
    # 设置测试环境变量
    export VERSION="test-$(date +%Y%m%d-%H%M%S)"
    export COMMIT="— 测试推送功能"
    
    # 检查推送脚本
    if [ -f ".github/telegram_push.py" ]; then
        log "INFO" "使用新的推送脚本"
        python3 .github/telegram_push.py "$test_file"
    elif [ -f ".github/taamarinbot.py" ]; then
        log "INFO" "使用原有推送脚本"
        python3 .github/taamarinbot.py "$test_file"
    else
        log "ERROR" "未找到推送脚本"
        return 1
    fi
    
    log "INFO" "Telegram 推送测试完成"
}

# 清理测试文件
cleanup() {
    log "INFO" "清理测试文件..."
    rm -f test_module.zip
    rm -f .github/bot.session*
    log "INFO" "清理完成"
}

# 显示帮助信息
show_help() {
    cat << EOF
Telegram 推送功能测试脚本

用法: $0 [选项]

选项:
    -h, --help          显示此帮助信息
    -f, --file FILE     指定要推送的文件（可选）
    --skip-deps         跳过依赖检查
    --no-cleanup        不清理测试文件

环境变量:
    BOT_TOKEN           Telegram Bot Token (必需)
    CHAT_ID             目标 Chat ID (必需)

示例:
    # 基本测试
    export BOT_TOKEN="123456789:ABCdef..."
    export CHAT_ID="123456789"  # 或者 "-1001234567890" 用于群组
    $0

    # 推送指定文件
    $0 --file my_module.zip

    # 跳过依赖检查
    $0 --skip-deps

EOF
}

# 主函数
main() {
    local test_file=""
    local skip_deps=false
    local no_cleanup=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--file)
                test_file="$2"
                shift 2
                ;;
            --skip-deps)
                skip_deps=true
                shift
                ;;
            --no-cleanup)
                no_cleanup=true
                shift
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                  Telegram 推送功能测试                       ║
║                                                              ║
║  测试 Box for Magisk 的 Telegram Bot 推送功能               ║
╚══════════════════════════════════════════════════════════════╝

EOF
    
    # 检查环境变量
    if ! check_env_vars; then
        exit 1
    fi
    
    # 检查 Python 依赖
    if [ "$skip_deps" != "true" ]; then
        if ! check_python_deps; then
            exit 1
        fi
    fi
    
    # 准备测试文件
    if [ -n "$test_file" ]; then
        if [ ! -f "$test_file" ]; then
            log "ERROR" "指定的文件不存在: $test_file"
            exit 1
        fi
        log "INFO" "使用指定文件: $test_file"
    else
        test_file=$(create_test_file)
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
    
    # 执行推送测试
    if test_telegram_push "$test_file"; then
        log "INFO" "✅ Telegram 推送测试成功!"
    else
        log "ERROR" "❌ Telegram 推送测试失败!"
        exit 1
    fi
    
    # 清理
    if [ "$no_cleanup" != "true" ] && [ -z "$test_file" ]; then
        cleanup
    fi
    
    log "INFO" "测试完成!"
}

# 信号处理
trap cleanup EXIT INT TERM

# 运行主函数
main "$@"
