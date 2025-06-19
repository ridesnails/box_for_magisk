#!/system/bin/sh

# Box for Magisk - probe_user_group 调试脚本
# 用于诊断 "Failed to check BOX user group" 错误

scripts_dir="${0%/*}"
source /data/adb/box/settings.ini

log_debug() {
    echo "[DEBUG $(date '+%H:%M:%S')] $1" | tee -a "/data/adb/box/run/debug_probe.log"
}

log_error() {
    echo "[ERROR $(date '+%H:%M:%S')] $1" | tee -a "/data/adb/box/run/debug_probe.log"
}

log_info() {
    echo "[INFO $(date '+%H:%M:%S')] $1" | tee -a "/data/adb/box/run/debug_probe.log"
}

# 清理旧的调试日志
echo "=== Box for Magisk - probe_user_group 调试开始 ===" > "/data/adb/box/run/debug_probe.log"
echo "调试时间: $(date)" >> "/data/adb/box/run/debug_probe.log"
echo "" >> "/data/adb/box/run/debug_probe.log"

log_info "开始环境变量和权限检查..."

# 1. 检查关键环境变量
log_info "=== 1. 环境变量检查 ==="
log_debug "当前脚本路径: $0"
log_debug "scripts_dir: ${scripts_dir}"
log_debug "settings.ini 路径: /data/adb/box/settings.ini"

# 检查 settings.ini 是否存在和可读
if [ -f "/data/adb/box/settings.ini" ]; then
    log_info "✓ settings.ini 文件存在"
    if [ -r "/data/adb/box/settings.ini" ]; then
        log_info "✓ settings.ini 文件可读"
    else
        log_error "✗ settings.ini 文件不可读"
        ls -la "/data/adb/box/settings.ini" | while read line; do log_debug "文件权限: $line"; done
    fi
else
    log_error "✗ settings.ini 文件不存在"
    ls -la "/data/adb/box/" | while read line; do log_debug "box目录内容: $line"; done
fi

# 检查关键变量是否正确设置
log_debug "bin_name: '${bin_name}'"
log_debug "bin_path: '${bin_path}'"
log_debug "box_user_group: '${box_user_group}'"
log_debug "box_pid: '${box_pid}'"
log_debug "box_dir: '${box_dir}'"

if [ -z "${bin_name}" ]; then
    log_error "✗ bin_name 变量未设置或为空"
else
    log_info "✓ bin_name 已设置: ${bin_name}"
fi

if [ -z "${box_user_group}" ]; then
    log_error "✗ box_user_group 变量未设置或为空"
else
    log_info "✓ box_user_group 已设置: ${box_user_group}"
    # 解析用户组
    IFS=':' read -r expected_user expected_group <<< "${box_user_group}"
    log_debug "期望的用户: ${expected_user}"
    log_debug "期望的组: ${expected_group}"
fi

# 2. 检查 busybox 可用性
log_info "=== 2. busybox 可用性检查 ==="

# 检查 busybox 是否在 PATH 中
if command -v busybox >/dev/null 2>&1; then
    busybox_path=$(command -v busybox)
    log_info "✓ busybox 在 PATH 中找到: ${busybox_path}"
    
    # 检查 busybox 是否可执行
    if [ -x "${busybox_path}" ]; then
        log_info "✓ busybox 可执行"
        
        # 获取 busybox 版本
        busybox_version=$(busybox --help 2>&1 | head -1)
        log_debug "busybox 版本: ${busybox_version}"
    else
        log_error "✗ busybox 不可执行"
        ls -la "${busybox_path}" | while read line; do log_debug "busybox 权限: $line"; done
    fi
else
    log_error "✗ busybox 未在 PATH 中找到"
    log_debug "当前 PATH: ${PATH}"
    
    # 检查常见的 busybox 位置
    for busybox_location in "/data/adb/magisk/busybox" "/data/adb/ksu/bin/busybox" "/data/adb/ap/bin/busybox" "/system/bin/busybox" "/system/xbin/busybox"; do
        if [ -f "${busybox_location}" ]; then
            log_debug "发现 busybox: ${busybox_location}"
            if [ -x "${busybox_location}" ]; then
                log_debug "  - 可执行: 是"
            else
                log_debug "  - 可执行: 否"
            fi
        fi
    done
fi

# 3. 检查 pidof 命令可用性
log_info "=== 3. pidof 命令检查 ==="

# 测试 busybox pidof
if command -v busybox >/dev/null 2>&1; then
    log_debug "测试 'busybox pidof' 命令..."
    
    # 测试 pidof 帮助
    if busybox pidof --help >/dev/null 2>&1; then
        log_info "✓ busybox pidof 命令可用"
    else
        log_error "✗ busybox pidof 命令不可用或不支持"
        busybox 2>&1 | grep -i pidof | while read line; do log_debug "busybox 支持: $line"; done
    fi
    
    # 测试 pidof 查找一个肯定存在的进程
    test_pid=$(busybox pidof init 2>&1)
    if [ $? -eq 0 ] && [ -n "${test_pid}" ]; then
        log_info "✓ pidof 功能正常 (init PID: ${test_pid})"
    else
        log_error "✗ pidof 功能异常"
        log_debug "pidof init 输出: ${test_pid}"
    fi
else
    log_error "✗ 无法测试 pidof，busybox 不可用"
fi

# 4. 检查 sing-box 进程状态
log_info "=== 4. sing-box 进程状态检查 ==="

if [ -n "${bin_name}" ]; then
    log_debug "搜索进程: ${bin_name}"
    
    # 使用 busybox pidof 搜索
    if command -v busybox >/dev/null 2>&1; then
        pidof_result=$(busybox pidof "${bin_name}" 2>&1)
        pidof_exit_code=$?
        
        log_debug "busybox pidof ${bin_name} 退出码: ${pidof_exit_code}"
        log_debug "busybox pidof ${bin_name} 输出: '${pidof_result}'"
        
        if [ ${pidof_exit_code} -eq 0 ] && [ -n "${pidof_result}" ]; then
            log_info "✓ 找到 ${bin_name} 进程: PID ${pidof_result}"
            
            # 检查进程详细信息
            for pid in ${pidof_result}; do
                if [ -d "/proc/${pid}" ]; then
                    log_debug "PID ${pid} 进程信息:"
                    if [ -r "/proc/${pid}/cmdline" ]; then
                        cmdline=$(cat "/proc/${pid}/cmdline" 2>/dev/null | tr '\0' ' ')
                        log_debug "  命令行: ${cmdline}"
                    fi
                    if [ -r "/proc/${pid}/status" ]; then
                        log_debug "  用户: $(grep '^Uid:' /proc/${pid}/status 2>/dev/null)"
                        log_debug "  组: $(grep '^Gid:' /proc/${pid}/status 2>/dev/null)"
                    fi
                else
                    log_error "  进程目录 /proc/${pid} 不存在"
                fi
            done
        else
            log_error "✗ 未找到 ${bin_name} 进程"
        fi
    fi
    
    # 使用 ps 命令作为备选
    log_debug "使用 ps 命令搜索 ${bin_name}..."
    ps_result=$(ps | grep "${bin_name}" | grep -v grep 2>/dev/null)
    if [ -n "${ps_result}" ]; then
        log_info "✓ ps 命令找到 ${bin_name} 进程:"
        echo "${ps_result}" | while read line; do log_debug "  ${line}"; done
    else
        log_error "✗ ps 命令未找到 ${bin_name} 进程"
    fi
    
    # 检查所有进程
    log_debug "所有包含 'sing' 的进程:"
    ps | grep -i sing | grep -v grep | while read line; do log_debug "  ${line}"; done
else
    log_error "✗ bin_name 未设置，无法搜索进程"
fi

# 5. 检查 PID 文件状态
log_info "=== 5. PID 文件检查 ==="

if [ -n "${box_pid}" ]; then
    log_debug "检查 PID 文件: ${box_pid}"
    
    if [ -f "${box_pid}" ]; then
        log_info "✓ PID 文件存在"
        
        if [ -r "${box_pid}" ]; then
            log_info "✓ PID 文件可读"
            
            stored_pid=$(cat "${box_pid}" 2>/dev/null)
            log_debug "存储的 PID: '${stored_pid}'"
            
            if [ -n "${stored_pid}" ] && [ "${stored_pid}" -gt 0 ] 2>/dev/null; then
                log_info "✓ PID 文件包含有效 PID: ${stored_pid}"
                
                # 检查该 PID 是否存在
                if [ -d "/proc/${stored_pid}" ]; then
                    log_info "✓ PID ${stored_pid} 对应的进程存在"
                    
                    # 检查进程名称是否匹配
                    if [ -r "/proc/${stored_pid}/cmdline" ]; then
                        cmdline=$(cat "/proc/${stored_pid}/cmdline" 2>/dev/null | tr '\0' ' ')
                        log_debug "PID ${stored_pid} 命令行: ${cmdline}"
                        
                        if echo "${cmdline}" | grep -q "${bin_name}"; then
                            log_info "✓ PID ${stored_pid} 确实是 ${bin_name} 进程"
                        else
                            log_error "✗ PID ${stored_pid} 不是 ${bin_name} 进程"
                        fi
                    fi
                else
                    log_error "✗ PID ${stored_pid} 对应的进程不存在"
                fi
            else
                log_error "✗ PID 文件包含无效 PID: '${stored_pid}'"
            fi
        else
            log_error "✗ PID 文件不可读"
            ls -la "${box_pid}" | while read line; do log_debug "PID 文件权限: $line"; done
        fi
    else
        log_error "✗ PID 文件不存在: ${box_pid}"
        
        # 检查 run 目录
        run_dir="${box_pid%/*}"
        if [ -d "${run_dir}" ]; then
            log_debug "run 目录存在: ${run_dir}"
            ls -la "${run_dir}" | while read line; do log_debug "run 目录内容: $line"; done
        else
            log_error "run 目录不存在: ${run_dir}"
        fi
    fi
else
    log_error "✗ box_pid 变量未设置"
fi

# 6. 检查权限和 /proc 访问
log_info "=== 6. 权限和 /proc 访问检查 ==="

log_debug "当前用户 ID: $(id -u)"
log_debug "当前组 ID: $(id -g)"
log_debug "当前用户: $(id -un 2>/dev/null || echo 'unknown')"
log_debug "当前组: $(id -gn 2>/dev/null || echo 'unknown')"

# 检查 /proc 目录访问
if [ -d "/proc" ]; then
    log_info "✓ /proc 目录存在"
    
    if [ -r "/proc" ]; then
        log_info "✓ /proc 目录可读"
        
        # 测试读取一些 /proc 下的文件
        if [ -r "/proc/version" ]; then
            log_info "✓ 可以读取 /proc/version"
            log_debug "内核版本: $(cat /proc/version 2>/dev/null | head -1)"
        else
            log_error "✗ 无法读取 /proc/version"
        fi
        
        # 检查是否可以列出 /proc 下的进程目录
        proc_count=$(ls -1 /proc/ 2>/dev/null | grep -c '^[0-9]*$' 2>/dev/null || echo 0)
        if [ "${proc_count}" -gt 0 ]; then
            log_info "✓ 可以访问 /proc 下的进程目录 (${proc_count} 个)"
        else
            log_error "✗ 无法访问 /proc 下的进程目录"
        fi
    else
        log_error "✗ /proc 目录不可读"
    fi
else
    log_error "✗ /proc 目录不存在"
fi

# 7. 模拟 probe_user_group 函数
log_info "=== 7. 模拟 probe_user_group 函数 ==="

probe_user_group_debug() {
    log_debug "开始模拟 probe_user_group 函数..."
    
    if [ -z "${bin_name}" ]; then
        log_error "bin_name 未设置，无法执行"
        return 1
    fi
    
    log_debug "执行: busybox pidof ${bin_name}"
    
    if PID=$(busybox pidof ${bin_name} 2>&1); then
        log_info "✓ busybox pidof 成功，PID: ${PID}"
        
        # 尝试获取用户和组信息
        for pid in ${PID}; do
            log_debug "处理 PID: ${pid}"
            
            if [ -f "/proc/${pid}/status" ]; then
                log_debug "检查 /proc/${pid}/status"
                
                # 使用 stat 命令获取用户和组
                if box_user=$(stat -c %U /proc/${pid} 2>&1); then
                    log_info "✓ 获取用户成功: ${box_user}"
                else
                    log_error "✗ 获取用户失败: ${box_user}"
                fi
                
                if box_group=$(stat -c %G /proc/${pid} 2>&1); then
                    log_info "✓ 获取组成功: ${box_group}"
                else
                    log_error "✗ 获取组失败: ${box_group}"
                fi
                
                if [ -n "${box_user}" ] && [ -n "${box_group}" ]; then
                    log_info "✓ probe_user_group 模拟成功: ${box_user}:${box_group}"
                    return 0
                fi
            else
                log_error "✗ /proc/${pid}/status 不存在"
            fi
        done
        
        log_error "✗ 无法获取完整的用户组信息"
        return 1
    else
        log_error "✗ busybox pidof 失败: ${PID}"
        
        # 作为回退，尝试从配置中获取
        log_debug "尝试从配置获取用户组信息"
        if [ -n "${box_user_group}" ]; then
            IFS=':' read -r box_user box_group <<< "${box_user_group}"
            log_info "从配置获取用户组: ${box_user}:${box_group}"
            return 1
        else
            log_error "配置中的用户组信息也不可用"
            return 1
        fi
    fi
}

# 执行模拟测试
probe_user_group_debug

# 8. 生成总结报告
log_info "=== 8. 调试总结 ==="

echo ""
echo "调试完成！请查看详细日志: /data/adb/box/run/debug_probe.log"
echo ""
echo "快速诊断结果:"

# 检查关键问题
critical_issues=0

if [ -z "${bin_name}" ]; then
    echo "❌ 关键问题: bin_name 变量未设置"
    critical_issues=$((critical_issues + 1))
fi

if ! command -v busybox >/dev/null 2>&1; then
    echo "❌ 关键问题: busybox 命令不可用"
    critical_issues=$((critical_issues + 1))
fi

if [ -n "${bin_name}" ] && command -v busybox >/dev/null 2>&1; then
    if ! busybox pidof "${bin_name}" >/dev/null 2>&1; then
        echo "❌ 主要问题: ${bin_name} 进程未运行或 pidof 无法找到"
        critical_issues=$((critical_issues + 1))
    fi
fi

if [ ${critical_issues} -eq 0 ]; then
    echo "✅ 未发现关键问题，错误可能是时序相关"
else
    echo "❌ 发现 ${critical_issues} 个关键问题"
fi

echo ""
echo "请将此调试日志发送给开发者以获得进一步帮助。"