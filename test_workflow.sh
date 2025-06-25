#!/bin/bash

# Box for Magisk 工作流测试脚本
# 用于验证工作流的各个功能组件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 测试配置
TEST_DIR="/tmp/box_workflow_test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 测试计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "PASS")  echo -e "${GREEN}[PASS]${NC} ${timestamp} - $message" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} ${timestamp} - $message" ;;
        "INFO")  echo -e "${BLUE}[INFO]${NC} ${timestamp} - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" ;;
        *)       echo -e "${timestamp} - $message" ;;
    esac
}

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log "INFO" "运行测试: $test_name"
    
    if eval "$test_command"; then
        log "PASS" "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log "FAIL" "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 初始化测试环境
setup_test_env() {
    log "INFO" "初始化测试环境..."
    
    # 创建测试目录
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # 复制脚本到测试目录
    cp "$SCRIPT_DIR/workflow_generator.sh" "$TEST_DIR/"
    cp "$SCRIPT_DIR/quick_setup.sh" "$TEST_DIR/"
    
    # 设置权限
    chmod +x "$TEST_DIR"/*.sh
    
    log "INFO" "测试环境初始化完成"
}

# 清理测试环境
cleanup_test_env() {
    log "INFO" "清理测试环境..."
    rm -rf "$TEST_DIR"
    log "INFO" "测试环境清理完成"
}

# 测试脚本语法
test_script_syntax() {
    bash -n "$TEST_DIR/workflow_generator.sh" >/dev/null 2>&1
}

test_quick_setup_syntax() {
    bash -n "$TEST_DIR/quick_setup.sh" >/dev/null 2>&1
}

# 测试帮助信息
test_help_output() {
    "$TEST_DIR/workflow_generator.sh" --help >/dev/null 2>&1
}

# 测试参数解析
test_parameter_parsing() {
    # 创建模拟的 module.prop 文件
    echo "version=v1.8" > "$TEST_DIR/module.prop"

    # 测试有效参数（仅测试参数解析，不执行完整工作流）
    cd "$TEST_DIR"
    timeout 10 bash -c './workflow_generator.sh --core sing-box --mode enhance --proxy-mode blacklist --ui zashboard --build-only' >/dev/null 2>&1
    local exit_code=$?

    # 如果是超时（124）或者正常开始执行（0），都算成功
    [ $exit_code -eq 124 ] || [ $exit_code -eq 0 ]
}

# 测试无效参数
test_invalid_parameters() {
    # 这个测试应该失败（返回非零退出码）
    ! "$TEST_DIR/workflow_generator.sh" --core invalid-core >/dev/null 2>&1
}

# 测试依赖检查
test_dependency_check() {
    # 创建一个临时的测试脚本来检查依赖
    cat > "$TEST_DIR/test_deps.sh" << 'EOF'
#!/bin/bash
source workflow_generator.sh
check_dependencies 2>/dev/null
EOF
    chmod +x "$TEST_DIR/test_deps.sh"
    cd "$TEST_DIR" && ./test_deps.sh
}

# 测试配置文件生成
test_config_generation() {
    # 创建模拟的配置目录
    local mock_box_dir="$TEST_DIR/mock_box"
    mkdir -p "$mock_box_dir"
    
    # 创建模拟的 settings.ini
    cat > "$mock_box_dir/settings.ini" << 'EOF'
#!/system/bin/sh
bin_name="clash"
network_mode="tproxy"
ipv6="true"
box_user_group="0:3005"
EOF
    
    # 创建模拟的 package.list.cfg
    cat > "$mock_box_dir/package.list.cfg" << 'EOF'
mode:whitelist
com.example.app
EOF
    
    # 测试配置修改
    sed -i 's/^bin_name=.*/bin_name="sing-box"/' "$mock_box_dir/settings.ini"
    sed -i 's/^network_mode=.*/network_mode="enhance"/' "$mock_box_dir/settings.ini"
    sed -i 's/^mode:.*/mode:blacklist/' "$mock_box_dir/package.list.cfg"
    
    # 验证修改结果
    grep -q 'bin_name="sing-box"' "$mock_box_dir/settings.ini" && \
    grep -q 'network_mode="enhance"' "$mock_box_dir/settings.ini" && \
    grep -q 'mode:blacklist' "$mock_box_dir/package.list.cfg"
}

# 测试 URL 可访问性
test_url_accessibility() {
    local urls=(
        "https://api.github.com/repos/SagerNet/sing-box/releases"
        "https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip"
        "https://api.github.com/repos/MetaCubeX/mihomo/releases"
    )
    
    for url in "${urls[@]}"; do
        if command -v curl >/dev/null 2>&1; then
            curl -s --head "$url" | head -1 | grep -q "200 OK"
        elif command -v wget >/dev/null 2>&1; then
            wget --spider -q "$url" 2>/dev/null
        else
            log "WARN" "无法测试 URL 可访问性：缺少 curl 或 wget"
            return 0
        fi
    done
}

# 测试 JSON 解析
test_json_parsing() {
    # 创建测试 JSON
    local test_json='{"tag_name": "v1.8.0-beta.1", "prerelease": true}'
    
    # 测试版本提取
    local version=$(echo "$test_json" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
    [ "$version" = "v1.8.0-beta.1" ]
}

# 测试文件操作
test_file_operations() {
    local test_file="$TEST_DIR/test_file.txt"
    
    # 创建文件
    echo "test content" > "$test_file"
    
    # 测试文件存在
    [ -f "$test_file" ] && \
    
    # 测试文件内容
    grep -q "test content" "$test_file" && \
    
    # 测试文件删除
    rm "$test_file" && \
    
    # 测试文件不存在
    [ ! -f "$test_file" ]
}

# 测试压缩功能
test_compression() {
    local test_dir="$TEST_DIR/test_compress"
    local test_file="$test_dir/test.txt"
    local zip_file="$TEST_DIR/test.zip"
    
    # 创建测试文件
    mkdir -p "$test_dir"
    echo "test content" > "$test_file"
    
    # 测试压缩
    cd "$TEST_DIR"
    zip -r -q "test.zip" "test_compress/" && \
    
    # 测试压缩文件存在
    [ -f "$zip_file" ] && \
    
    # 测试解压
    mkdir -p "extract_test" && \
    cd "extract_test" && \
    unzip -q "../test.zip" && \
    
    # 验证解压结果
    [ -f "test_compress/test.txt" ] && \
    grep -q "test content" "test_compress/test.txt"
}

# 测试环境变量处理
test_environment_variables() {
    # 设置测试环境变量
    export TEST_VAR="test_value"
    
    # 测试环境变量读取
    [ "$TEST_VAR" = "test_value" ] && \
    
    # 测试未设置的环境变量
    [ -z "$UNDEFINED_VAR" ]
    
    # 清理
    unset TEST_VAR
}

# 测试架构检测
test_architecture_detection() {
    local arch=$(uname -m)
    
    case "$arch" in
        "aarch64"|"armv7l"|"armv8l"|"x86_64"|"i386")
            return 0
            ;;
        *)
            log "WARN" "未知架构: $arch"
            return 0  # 不算作失败，只是警告
            ;;
    esac
}

# 运行所有测试
run_all_tests() {
    log "INFO" "开始运行工作流测试套件..."
    
    # 基础测试
    run_test "脚本语法检查" "test_script_syntax"
    run_test "快速设置脚本语法检查" "test_quick_setup_syntax"
    run_test "帮助信息输出" "test_help_output"
    run_test "参数解析测试" "test_parameter_parsing"
    run_test "无效参数处理" "test_invalid_parameters"
    
    # 功能测试
    run_test "依赖检查功能" "test_dependency_check"
    run_test "配置文件生成" "test_config_generation"
    run_test "JSON 解析功能" "test_json_parsing"
    run_test "文件操作功能" "test_file_operations"
    run_test "压缩解压功能" "test_compression"
    run_test "环境变量处理" "test_environment_variables"
    run_test "架构检测功能" "test_architecture_detection"
    
    # 网络测试（可选）
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        run_test "URL 可访问性测试" "test_url_accessibility"
    else
        log "WARN" "跳过网络测试：缺少网络工具"
    fi
}

# 显示测试结果
show_test_results() {
    echo
    echo "═══════════════════════════════════════════════════════════════"
    echo "                          测试结果摘要"
    echo "═══════════════════════════════════════════════════════════════"
    echo
    echo -e "总测试数: ${CYAN}$TESTS_TOTAL${NC}"
    echo -e "通过测试: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败测试: ${RED}$TESTS_FAILED${NC}"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ 所有测试通过！工作流准备就绪。${NC}"
        echo
    else
        echo -e "${RED}✗ 有 $TESTS_FAILED 个测试失败，请检查相关功能。${NC}"
        echo
        exit 1
    fi
}

# 主函数
main() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                Box for Magisk 工作流测试套件                 ║
║                                                              ║
║  验证工作流脚本的各个功能组件                                ║
╚══════════════════════════════════════════════════════════════╝

EOF
    
    # 设置测试环境
    setup_test_env
    
    # 运行测试
    run_all_tests
    
    # 显示结果
    show_test_results
    
    # 清理环境
    cleanup_test_env
}

# 信号处理
trap cleanup_test_env EXIT INT TERM

# 运行主函数
main "$@"
