#!/bin/bash

# Box for Magisk 快速设置脚本
# 用于快速配置默认运行模式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置路径
BOX_DIR="/data/adb/box"
SETTINGS_FILE="${BOX_DIR}/settings.ini"
PACKAGE_CONFIG="${BOX_DIR}/package.list.cfg"
AP_CONFIG="${BOX_DIR}/ap.list.cfg"

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

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "ERROR" "此脚本需要 root 权限运行"
        log "INFO" "请使用: su -c '$0' 或 sudo $0"
        exit 1
    fi
}

# 检查 Box 目录
check_box_directory() {
    if [ ! -d "$BOX_DIR" ]; then
        log "ERROR" "Box for Root 未安装或目录不存在: $BOX_DIR"
        log "INFO" "请先安装 Box for Magisk 模块"
        exit 1
    fi
    
    log "INFO" "检测到 Box for Root 安装目录: $BOX_DIR"
}

# 备份配置文件
backup_configs() {
    local backup_dir="${BOX_DIR}/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    for file in "$SETTINGS_FILE" "$PACKAGE_CONFIG" "$AP_CONFIG"; do
        if [ -f "$file" ]; then
            cp "$file" "$backup_dir/"
            log "INFO" "已备份: $(basename "$file")"
        fi
    done
    
    log "INFO" "配置文件备份到: $backup_dir"
}

# 配置默认设置
configure_default_settings() {
    log "INFO" "配置默认运行模式..."
    
    # 确保配置文件存在
    if [ ! -f "$SETTINGS_FILE" ]; then
        log "ERROR" "配置文件不存在: $SETTINGS_FILE"
        exit 1
    fi
    
    # 设置 sing-box 为默认核心
    sed -i 's/^bin_name=.*/bin_name="sing-box"/' "$SETTINGS_FILE"
    log "INFO" "✓ 设置默认核心: sing-box"
    
    # 设置 enhance 网络模式
    sed -i 's/^network_mode=.*/network_mode="enhance"/' "$SETTINGS_FILE"
    log "INFO" "✓ 设置网络模式: enhance (增强模式)"
    
    # 确保 IPv6 关闭 (提高兼容性)
    sed -i 's/^ipv6=.*/ipv6="false"/' "$SETTINGS_FILE"
    log "INFO" "✓ 禁用 IPv6 (提高兼容性)"
    
    # 设置用户组
    sed -i 's/^box_user_group=.*/box_user_group="root:net_admin"/' "$SETTINGS_FILE"
    log "INFO" "✓ 设置用户组: root:net_admin"
}

# 配置透明代理规则
configure_proxy_rules() {
    log "INFO" "配置透明代理规则..."
    
    # 设置黑名单模式
    if [ -f "$PACKAGE_CONFIG" ]; then
        sed -i 's/^mode:.*/mode:blacklist/' "$PACKAGE_CONFIG"
        log "INFO" "✓ 设置代理模式: blacklist (黑名单模式)"
        
        # 添加一些常见的系统应用到黑名单示例
        if ! grep -q "# 系统应用示例" "$PACKAGE_CONFIG"; then
            cat >> "$PACKAGE_CONFIG" << 'EOF'

# 系统应用示例 (取消注释以排除代理)
# com.android.vending
# com.google.android.gms
# com.android.providers.downloads

# 常用应用示例
# com.tencent.mm
# com.tencent.mobileqq
# com.alibaba.android.rimet
EOF
            log "INFO" "✓ 添加应用配置示例"
        fi
    else
        log "WARN" "包配置文件不存在: $PACKAGE_CONFIG"
    fi
}

# 配置网络接口
configure_network_interfaces() {
    log "INFO" "配置网络接口..."
    
    if [ -f "$AP_CONFIG" ]; then
        # 确保热点和 WiFi 接口被允许
        if ! grep -q "allow ap+" "$AP_CONFIG"; then
            echo "allow ap+" >> "$AP_CONFIG"
        fi
        if ! grep -q "allow wlan+" "$AP_CONFIG"; then
            echo "allow wlan+" >> "$AP_CONFIG"
        fi
        log "INFO" "✓ 配置网络接口: 允许 WiFi 和热点"
    else
        log "WARN" "网络接口配置文件不存在: $AP_CONFIG"
    fi
}

# 下载 sing-box 核心
download_singbox() {
    local bin_path="${BOX_DIR}/bin/sing-box"
    
    if [ -f "$bin_path" ]; then
        log "INFO" "sing-box 核心已存在，跳过下载"
        return 0
    fi
    
    log "INFO" "下载 sing-box 核心..."
    
    # 使用现有的下载工具
    if [ -f "${BOX_DIR}/scripts/box.tool" ]; then
        # 临时设置 bin_name 为 sing-box
        local original_bin_name=$(grep '^bin_name=' "$SETTINGS_FILE" | cut -d'"' -f2)
        sed -i 's/^bin_name=.*/bin_name="sing-box"/' "$SETTINGS_FILE"
        
        # 执行下载
        "${BOX_DIR}/scripts/box.tool" upkernel
        
        if [ -f "$bin_path" ]; then
            log "INFO" "✓ sing-box 核心下载完成"
        else
            log "ERROR" "sing-box 核心下载失败"
            return 1
        fi
    else
        log "ERROR" "找不到 box.tool 脚本"
        return 1
    fi
}

# 下载 zashboard UI
download_zashboard() {
    local ui_dir="${BOX_DIR}/sing-box/dashboard"
    
    if [ -d "$ui_dir" ] && [ "$(ls -A "$ui_dir" 2>/dev/null)" ]; then
        log "INFO" "UI 文件已存在，跳过下载"
        return 0
    fi
    
    log "INFO" "下载 zashboard UI..."
    
    mkdir -p "$ui_dir"
    local temp_file="/tmp/zashboard.zip"
    local zashboard_url="https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip"
    
    # 下载 UI
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$temp_file" "$zashboard_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$temp_file" "$zashboard_url"
    else
        log "ERROR" "未找到 curl 或 wget 命令"
        return 1
    fi
    
    # 解压 UI
    if [ -f "$temp_file" ]; then
        unzip -q "$temp_file" -d "/tmp/ui_extract"
        local extracted_dir="/tmp/ui_extract/zashboard-gh-pages"
        
        if [ -d "$extracted_dir" ]; then
            cp -r "$extracted_dir"/* "$ui_dir/"
            rm -rf "/tmp/ui_extract" "$temp_file"
            log "INFO" "✓ zashboard UI 下载完成"
        else
            log "ERROR" "解压 zashboard UI 失败"
            return 1
        fi
    else
        log "ERROR" "下载 zashboard UI 失败"
        return 1
    fi
}

# 重启服务
restart_service() {
    log "INFO" "重启 Box 服务..."
    
    if [ -f "${BOX_DIR}/scripts/box.service" ]; then
        "${BOX_DIR}/scripts/box.service" stop >/dev/null 2>&1 || true
        sleep 2
        "${BOX_DIR}/scripts/box.service" start >/dev/null 2>&1
        
        # 检查服务状态
        sleep 3
        if "${BOX_DIR}/scripts/box.service" status >/dev/null 2>&1; then
            log "INFO" "✓ Box 服务启动成功"
        else
            log "WARN" "Box 服务可能未正常启动，请检查配置"
        fi
    else
        log "WARN" "找不到服务脚本，请手动重启"
    fi
}

# 显示配置摘要
show_summary() {
    cat << EOF

${CYAN}╔══════════════════════════════════════════════════════════════╗
║                        配置完成摘要                          ║
╚══════════════════════════════════════════════════════════════╝${NC}

${GREEN}✓ 默认核心:${NC} sing-box
${GREEN}✓ 网络模式:${NC} enhance (增强模式)
${GREEN}✓ 代理规则:${NC} blacklist (黑名单模式)
${GREEN}✓ UI 界面:${NC} zashboard
${GREEN}✓ IPv6:${NC} 已禁用

${YELLOW}访问控制面板:${NC} http://127.0.0.1:9090/ui/

${YELLOW}常用命令:${NC}
  启动服务: su -c '${BOX_DIR}/scripts/box.service start'
  停止服务: su -c '${BOX_DIR}/scripts/box.service stop'
  查看状态: su -c '${BOX_DIR}/scripts/box.service status'
  更新核心: su -c '${BOX_DIR}/scripts/box.tool upkernel'
  更新 UI:  su -c '${BOX_DIR}/scripts/box.tool upxui'

${YELLOW}配置文件:${NC}
  主配置: ${SETTINGS_FILE}
  应用规则: ${PACKAGE_CONFIG}
  网络接口: ${AP_CONFIG}

EOF
}

# 主函数
main() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                  Box for Magisk 快速设置                    ║
║                                                              ║
║  自动配置默认运行模式:                                       ║
║  • sing-box 核心 + enhance 网络模式                         ║
║  • 黑名单透明代理 + zashboard UI                            ║
╚══════════════════════════════════════════════════════════════╝

EOF
    
    log "INFO" "开始快速设置..."
    
    # 执行设置步骤
    check_root
    check_box_directory
    backup_configs
    configure_default_settings
    configure_proxy_rules
    configure_network_interfaces
    
    # 询问是否下载核心和 UI
    echo
    read -p "是否下载 sing-box 核心? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        download_singbox
    fi
    
    echo
    read -p "是否下载 zashboard UI? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        download_zashboard
    fi
    
    # 询问是否重启服务
    echo
    read -p "是否重启 Box 服务以应用配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_service
    fi
    
    show_summary
    log "INFO" "快速设置完成!"
}

# 运行主函数
main "$@"
