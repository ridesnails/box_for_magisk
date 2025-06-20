#!/system/bin/sh

# Zashboard 集成测试脚本
# 用于验证 Zashboard Web 管理界面的完整集成

echo "=== Zashboard 集成测试 ==="
echo "测试时间: $(date)"
echo ""

# 设置变量
SCRIPT_DIR="/data/adb/box/scripts"
BOX_TOOL="${SCRIPT_DIR}/box.tool"
API_PORT="9090"
API_HOST="127.0.0.1"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试函数
test_step() {
    echo -e "${BLUE}[测试]${NC} $1"
}

test_pass() {
    echo -e "${GREEN}[通过]${NC} $1"
}

test_fail() {
    echo -e "${RED}[失败]${NC} $1"
}

test_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# 1. 检查基础环境
test_step "检查基础环境..."

if [ ! -f "$BOX_TOOL" ]; then
    test_fail "box.tool 脚本不存在"
    exit 1
else
    test_pass "box.tool 脚本存在"
fi

if [ ! -f "/data/adb/box/settings.ini" ]; then
    test_fail "settings.ini 配置文件不存在"
    exit 1
else
    test_pass "settings.ini 配置文件存在"
fi

# 2. 检查 sing-box 配置
test_step "检查 sing-box 配置..."

if [ ! -f "/data/adb/box/sing-box/config.json" ]; then
    test_fail "sing-box 配置文件不存在"
    exit 1
else
    test_pass "sing-box 配置文件存在"
fi

# 检查 API 配置
if grep -q "external_controller.*9090" "/data/adb/box/sing-box/config.json"; then
    test_pass "API 端口配置正确 (9090)"
else
    test_fail "API 端口配置错误"
fi

# 3. 测试 Zashboard 安装
test_step "测试 Zashboard 安装..."

echo "执行: $BOX_TOOL dashboard install"
if su -c "$BOX_TOOL dashboard install" 2>/dev/null; then
    test_pass "Zashboard 安装成功"
else
    test_fail "Zashboard 安装失败"
fi

# 4. 检查 dashboard 目录
test_step "检查 dashboard 目录..."

DASHBOARD_DIR="/data/adb/box/sing-box/dashboard"
if [ -d "$DASHBOARD_DIR" ]; then
    test_pass "Dashboard 目录存在"
    
    # 检查文件数量
    file_count=$(find "$DASHBOARD_DIR" -type f | wc -l)
    if [ "$file_count" -gt 0 ]; then
        test_pass "Dashboard 文件已下载 ($file_count 个文件)"
    else
        test_fail "Dashboard 目录为空"
    fi
else
    test_fail "Dashboard 目录不存在"
fi

# 5. 检查版本信息
test_step "检查版本信息..."

if [ -f "${DASHBOARD_DIR}/.version" ]; then
    test_pass "版本信息文件存在"
    echo "版本信息:"
    cat "${DASHBOARD_DIR}/.version" | sed 's/^/  /'
else
    test_warn "版本信息文件不存在"
fi

# 6. 测试 webroot 配置
test_step "测试 webroot 配置..."

echo "执行: $BOX_TOOL webroot"
if su -c "$BOX_TOOL webroot" 2>/dev/null; then
    test_pass "Webroot 配置成功"
else
    test_fail "Webroot 配置失败"
fi

WEBROOT_FILE="/data/adb/modules/box_for_root/webroot/index.html"
if [ -f "$WEBROOT_FILE" ]; then
    test_pass "Webroot HTML 文件存在"
    
    # 检查是否包含 Zashboard 相关内容
    if grep -q "Zashboard" "$WEBROOT_FILE"; then
        test_pass "Webroot 包含 Zashboard 内容"
    else
        test_fail "Webroot 不包含 Zashboard 内容"
    fi
else
    test_fail "Webroot HTML 文件不存在"
fi

# 7. 测试命令行工具
test_step "测试命令行工具..."

# 测试 dashboard status
echo "执行: $BOX_TOOL dashboard status"
if su -c "$BOX_TOOL dashboard status" 2>/dev/null; then
    test_pass "dashboard status 命令正常"
else
    test_warn "dashboard status 命令执行失败"
fi

# 8. 检查文件权限
test_step "检查文件权限..."

if [ -d "$DASHBOARD_DIR" ]; then
    # 检查目录权限
    dir_perm=$(stat -c %a "$DASHBOARD_DIR" 2>/dev/null)
    if [ "$dir_perm" = "755" ]; then
        test_pass "Dashboard 目录权限正确 (755)"
    else
        test_warn "Dashboard 目录权限: $dir_perm (期望: 755)"
    fi
fi

# 9. 网络连接测试（如果 sing-box 正在运行）
test_step "网络连接测试..."

# 检查 sing-box 是否运行
if pgrep sing-box >/dev/null; then
    test_pass "sing-box 进程正在运行"
    
    # 测试 API 连接
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 5 "http://${API_HOST}:${API_PORT}/" >/dev/null 2>&1; then
            test_pass "API 端点可访问"
        else
            test_fail "API 端点不可访问"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=5 --tries=1 "http://${API_HOST}:${API_PORT}/" -O /dev/null 2>/dev/null; then
            test_pass "API 端点可访问"
        else
            test_fail "API 端点不可访问"
        fi
    else
        test_warn "无法测试 API 连接（curl/wget 不可用）"
    fi
else
    test_warn "sing-box 进程未运行，跳过网络测试"
fi

# 10. 配置文件验证
test_step "配置文件验证..."

ZASHBOARD_CONFIG="/data/adb/box/zashboard/config.json"
if [ -f "$ZASHBOARD_CONFIG" ]; then
    test_pass "Zashboard 配置文件存在"
else
    test_warn "Zashboard 配置文件不存在"
fi

# 输出总结
echo ""
echo "=== 测试总结 ==="
echo "Zashboard 集成测试完成"
echo ""
echo "访问方式："
echo "  1. 直接访问: http://127.0.0.1:9090/ui/"
echo "  2. Webroot: 访问模块 webroot 页面"
echo ""
echo "管理命令："
echo "  - 安装/更新: su -c '$BOX_TOOL dashboard install'"
echo "  - 查看状态: su -c '$BOX_TOOL dashboard status'"
echo "  - 移除: su -c '$BOX_TOOL dashboard remove'"
echo ""
echo "如有问题，请检查："
echo "  1. sing-box 服务是否正常运行"
echo "  2. 端口 9090 是否被占用"
echo "  3. 网络连接是否正常"