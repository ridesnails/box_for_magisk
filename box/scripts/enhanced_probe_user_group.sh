#!/system/bin/sh

# 增强版 probe_user_group 函数 - 带详细调试日志
# 用于替换 box.iptables 中的原函数以进行故障排除

scripts_dir="${0%/*}"
source /data/adb/box/settings.ini

# 增强版 probe_user_group 函数
probe_user_group_enhanced() {
    log Debug "=== probe_user_group_enhanced 开始 ==="
    log Debug "bin_name: '${bin_name}'"
    log Debug "box_user_group 配置: '${box_user_group}'"
    
    # 检查必要的变量
    if [ -z "${bin_name}" ]; then
        log Error "bin_name 变量未设置或为空"
        return 1
    fi
    
    # 检查 busybox 可用性
    if ! command -v busybox >/dev/null 2>&1; then
        log Error "busybox 命令不可用"
        log Debug "当前 PATH: ${PATH}"
        # 尝试从配置获取用户组
        IFS=':' read -r box_user box_group <<< "${box_user_group}"
        log Warning "busybox 不可用，使用配置中的用户组: ${box_user}:${box_group}"
        return 1
    fi
    
    log Debug "busybox 路径: $(command -v busybox)"
    
    # 检查 pidof 命令是否可用
    if ! busybox pidof --help >/dev/null 2>&1; then
        log Error "busybox pidof 命令不支持"
        # 显示 busybox 支持的命令
        log Debug "busybox 支持的命令: $(busybox 2>&1 | head -5)"
        IFS=':' read -r box_user box_group <<< "${box_user_group}"
        log Warning "pidof 不可用，使用配置中的用户组: ${box_user}:${box_group}"
        return 1
    fi
    
    log Debug "执行命令: busybox pidof ${bin_name}"
    
    # 执行 pidof 命令并捕获输出
    pidof_output=$(busybox pidof ${bin_name} 2>&1)
    pidof_exit_code=$?
    
    log Debug "pidof 退出码: ${pidof_exit_code}"
    log Debug "pidof 输出: '${pidof_output}'"
    
    if [ ${pidof_exit_code} -eq 0 ] && [ -n "${pidof_output}" ]; then
        # pidof 成功找到进程
        PID="${pidof_output}"
        log Info "找到 ${bin_name} 进程: PID ${PID}"
        
        # 验证 PID 的有效性
        valid_pids=""
        for pid in ${PID}; do
            log Debug "验证 PID: ${pid}"
            
            if [ -d "/proc/${pid}" ]; then
                log Debug "✓ /proc/${pid} 目录存在"
                
                # 检查进程名称是否匹配
                if [ -r "/proc/${pid}/cmdline" ]; then
                    cmdline=$(cat "/proc/${pid}/cmdline" 2>/dev/null | tr '\0' ' ')
                    log Debug "PID ${pid} 命令行: ${cmdline}"
                    
                    if echo "${cmdline}" | grep -q "${bin_name}"; then
                        log Debug "✓ PID ${pid} 确实是 ${bin_name} 进程"
                        valid_pids="${valid_pids} ${pid}"
                    else
                        log Warning "PID ${pid} 不是 ${bin_name} 进程，跳过"
                    fi
                else
                    log Warning "无法读取 /proc/${pid}/cmdline"
                fi
            else
                log Warning "/proc/${pid} 目录不存在，PID 可能已失效"
            fi
        done
        
        if [ -n "${valid_pids}" ]; then
            # 使用第一个有效的 PID
            first_valid_pid=$(echo ${valid_pids} | awk '{print $1}')
            log Debug "使用 PID: ${first_valid_pid}"
            
            # 尝试获取进程的用户和组
            log Debug "尝试获取 PID ${first_valid_pid} 的用户信息"
            
            if box_user=$(stat -c %U /proc/${first_valid_pid} 2>&1); then
                log Debug "✓ 获取用户成功: ${box_user}"
            else
                log Error "获取用户失败: ${box_user}"
                log Debug "尝试备用方法获取用户信息"
                
                # 备用方法：从 status 文件获取 UID 然后查找用户名
                if [ -r "/proc/${first_valid_pid}/status" ]; then
                    uid=$(grep '^Uid:' "/proc/${first_valid_pid}/status" 2>/dev/null | awk '{print $2}')
                    log Debug "从 status 获取 UID: ${uid}"
                    
                    # 简单的 UID 到用户名映射
                    case "${uid}" in
                        0) box_user="root" ;;
                        *) box_user="user_${uid}" ;;
                    esac
                    log Debug "映射得到用户: ${box_user}"
                fi
            fi
            
            log Debug "尝试获取 PID ${first_valid_pid} 的组信息"
            
            if box_group=$(stat -c %G /proc/${first_valid_pid} 2>&1); then
                log Debug "✓ 获取组成功: ${box_group}"
            else
                log Error "获取组失败: ${box_group}"
                log Debug "尝试备用方法获取组信息"
                
                # 备用方法：从 status 文件获取 GID 然后查找组名
                if [ -r "/proc/${first_valid_pid}/status" ]; then
                    gid=$(grep '^Gid:' "/proc/${first_valid_pid}/status" 2>/dev/null | awk '{print $2}')
                    log Debug "从 status 获取 GID: ${gid}"
                    
                    # 简单的 GID 到组名映射
                    case "${gid}" in
                        0) box_group="root" ;;
                        3005) box_group="net_admin" ;;
                        *) box_group="group_${gid}" ;;
                    esac
                    log Debug "映射得到组: ${box_group}"
                fi
            fi
            
            if [ -n "${box_user}" ] && [ -n "${box_group}" ]; then
                log Info "✓ 成功获取进程用户组: ${box_user}:${box_group}"
                log Debug "与配置对比 - 配置: ${box_user_group}, 实际: ${box_user}:${box_group}"
                
                # 验证是否与配置匹配
                expected_user_group="${box_user}:${box_group}"
                if [ "${expected_user_group}" = "${box_user_group}" ]; then
                    log Info "✓ 用户组匹配配置"
                else
                    log Warning "用户组与配置不匹配 - 配置: ${box_user_group}, 实际: ${expected_user_group}"
                fi
                
                log Debug "=== probe_user_group_enhanced 成功结束 ==="
                return 0
            else
                log Error "无法获取完整的用户组信息"
            fi
        else
            log Error "没有找到有效的 ${bin_name} 进程"
        fi
    else
        log Error "busybox pidof ${bin_name} 失败"
        log Debug "可能的原因:"
        log Debug "1. ${bin_name} 进程未启动"
        log Debug "2. pidof 命令权限不足"
        log Debug "3. 进程名称不匹配"
        
        # 使用备用方法搜索进程
        log Debug "尝试使用 ps 命令搜索进程"
        ps_result=$(ps | grep "${bin_name}" | grep -v grep 2>/dev/null)
        if [ -n "${ps_result}" ]; then
            log Info "ps 命令找到相关进程:"
            echo "${ps_result}" | while read line; do
                log Debug "  ${line}"
            done
        else
            log Error "ps 命令也未找到 ${bin_name} 进程"
        fi
        
        # 列出所有包含关键字的进程
        log Debug "搜索包含 'sing' 的所有进程:"
        ps | grep -i sing | grep -v grep | while read line; do
            log Debug "  ${line}"
        done
    fi
    
    # 回退到配置中的用户组
    log Warning "回退到配置中的用户组"
    IFS=':' read -r box_user box_group <<< "${box_user_group}"
    log Info "使用配置的用户组: ${box_user}:${box_group}"
    
    log Debug "=== probe_user_group_enhanced 失败结束 ==="
    return 1
}

# 如果脚本被直接执行，运行测试
if [ "$(basename "$0")" = "enhanced_probe_user_group.sh" ]; then
    echo "运行增强版 probe_user_group 测试..."
    echo ""
    
    # 设置测试环境
    mkdir -p "/data/adb/box/run"
    
    # 运行测试
    probe_user_group_enhanced
    exit_code=$?
    
    echo ""
    echo "测试完成，退出码: ${exit_code}"
    echo "详细日志请查看: /data/adb/box/run/runs.log"
    
    exit ${exit_code}
fi