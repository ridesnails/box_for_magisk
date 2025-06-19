#!/system/bin/sh

scripts_dir="${0%/*}"
source /data/adb/box/settings.ini

# user agent
user_agent="box_for_root"
# whether use ghproxy to accelerate github download
url_ghproxy="https://mirror.ghproxy.com"
use_ghproxy="false"
# to enable/disable download the stable mihomo kernel
mihomo_stable="enable"
singbox_stable="enable"

rev1="busybox wget --no-check-certificate -qO-"
if which curl > /dev/null 2>&1; then
  rev1="curl --insecure -sL"
fi

# Updating files from URLs
upfile() {
  file="$1"
  update_url="$2"
  file_bak="${file}.bak"
  if [ -f "${file}" ]; then
    mv "${file}" "${file_bak}" || return 1
  fi
  # Use ghproxy
  if [ "${use_ghproxy}" == true ] && [[ "${update_url}" == @(https://github.com/*|https://raw.githubusercontent.com/*|https://gist.github.com/*|https://gist.githubusercontent.com/*) ]]; then
    update_url="${url_ghproxy}/${update_url}"
  fi
  # request
  if which curl > /dev/null 2>&1; then
    # curl="$(which curl || echo /data/adb/box/bin/curl)"
    request="curl"
    request+=" -L"
    request+=" --insecure"
    request+=" --user-agent ${user_agent}"
    request+=" -o ${file}"
    request+=" ${update_url}"
    echo "${yellow}${request}${normal}"
  else
    request="busybox wget"
    request+=" --no-check-certificate"
    request+=" --user-agent ${user_agent}"
    request+=" -O ${file}"
    request+=" ${update_url}"
    echo "${yellow}${request}${normal}"
  fi
  ${request} >&2 || {
    if [ -f "${file_bak}" ]; then
      mv "${file_bak}" "${file}" || true
    fi
    log Error "Download ${request} ${orange}failed${normal}"
    return 1
  }
  return 0
}

# Restart the binary, after stopping and running again
restart_box() {
  "${scripts_dir}/box.service" restart
  # PIDS=("clash" "xray" "sing-box" "v2fly" "hysteria")
  PIDS=(${bin_name})
  PID=""
  i=0
  while [ -z "$PID" ] && [ "$i" -lt "${#PIDS[@]}" ]; do
    PID=$(busybox pidof "${PIDS[$i]}")
    i=$((i+1))
  done

  if [ -n "$PID" ]; then
    log Debug "${bin_name} Restart complete [$(date +"%F %R")]"
  else
    log Error "Failed to restart ${bin_name}."
    ${scripts_dir}/box.iptables disable >/dev/null 2>&1
  fi
}

# Check Configuration
check() {
  # su -c /data/adb/box/scripts/box.tool rconf
  case "${bin_name}" in
    sing-box)
      if ${bin_path} check -D "${box_dir}/${bin_name}" --config-directory "${box_dir}/sing-box" > "${box_run}/${bin_name}_report.log" 2>&1; then
        log Info "${sing_config} passed"
      else
        log Debug "${sing_config}"
        log Error "$(<"${box_run}/${bin_name}_report.log")" >&2
      fi
      ;;
    *)
      log Error "<${bin_name}> unknown binary. Only sing-box is supported."
      exit 1
      ;;
  esac
}

# reload base config
reload() {
  curl_command="curl"
  if ! command -v curl >/dev/null 2>&1; then
    if [ ! -e "${bin_dir}/curl" ]; then
      log Debug "$bin_dir/curl file not found, unable to reload configuration"
      log Debug "start to download from github"
      upcurl || exit 1
    fi
    curl_command="${bin_dir}/curl"
  fi

  check

  case "${bin_name}" in
    "sing-box")
      endpoint="http://${ip_port}/configs?force=true"
      if ${curl_command} -X PUT -H "Authorization: Bearer ${secret}" "${endpoint}" -d '{"path": "", "payload": ""}' 2>&1; then
        log Info "${bin_name} config reload success."
        return 0
      else
        log Error "${bin_name} config reload failed !"
        return 1
      fi
      ;;
    *)
      log warning "${bin_name} not supported using API to reload config. Only sing-box is supported."
      return 1
      ;;
  esac
}

# Get latest curl
upcurl() {
  local arch
  case $(uname -m) in
    "aarch64") arch="aarch64" ;;
    "armv7l"|"armv8l") arch="armv7" ;;
    "i686") arch="i686" ;;
    "x86_64") arch="amd64" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac

  mkdir -p "${bin_dir}/backup"
  [ -f "${bin_dir}/curl" ] && cp "${bin_dir}/curl" "${bin_dir}/backup/curl.bak" >/dev/null 2>&1

  local latest_version=$($rev1 "https://api.github.com/repos/stunnel/static-curl/releases" | grep "tag_name" | busybox grep -oE "[0-9.]*" | head -1)

  local download_link="https://github.com/stunnel/static-curl/releases/download/${latest_version}/curl-linux-${arch}-glibc-${latest_version}.tar.xz"

  log Debug "Download ${download_link}"
  upfile "${bin_dir}/curl.tar.xz" "${download_link}"

  if ! busybox tar -xJf "${bin_dir}/curl.tar.xz" -C "${bin_dir}" >&2; then
    log Error "Failed to extract ${bin_dir}/curl.tar.xz" >&2
    cp "${bin_dir}/backup/curl.bak" "${bin_dir}/curl" >/dev/null 2>&1 && log Info "Restored curl" || return 1
  fi

  chown "${box_user_group}" "${box_dir}/bin/curl"
  chmod 0700 "${bin_dir}/curl"

  rm -r "${bin_dir}/curl.tar.xz"
}

# Get latest yq
upyq() {
  local arch platform
  case $(uname -m) in
    "aarch64") arch="arm64"; platform="android" ;;
    "armv7l"|"armv8l") arch="arm"; platform="android" ;;
    "i686") arch="386"; platform="android" ;;
    "x86_64") arch="amd64"; platform="android" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac

  local download_link="https://github.com/taamarin/yq/releases/download/prerelease/yq_${platform}_${arch}"

  log Debug "Download ${download_link}"
  upfile "${box_dir}/bin/yq" "${download_link}"

  chown "${box_user_group}" "${box_dir}/bin/yq"
  chmod 0700 "${box_dir}/bin/yq"
}

# Check and update geoip and geosite
upgeox() {
  # su -c /data/adb/box/scripts/box.tool geox
  geodata_mode=$(busybox awk '!/^ *#/ && /geodata-mode:*./{print $2}' "${clash_config}")
  [ -z "${geodata_mode}" ] && geodata_mode=false
  case "${bin_name}" in
    sing-box)
      geoip_file="${box_dir}/sing-box/geoip.db"
      geoip_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip-lite.db"
      geosite_file="${box_dir}/sing-box/geosite.db"
      geosite_url="https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.db"
      ;;
    *)
      log Error "Only sing-box is supported for geo data updates."
      return 1
      ;;
  esac
  if [ "${update_geo}" = "true" ] && { log Info "daily updates geox" && log Debug "Downloading ${geoip_url}"; } && upfile "${geoip_file}" "${geoip_url}" && { log Debug "Downloading ${geosite_url}" && upfile "${geosite_file}" "${geosite_url}"; }; then

    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.db.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.dat.bak" -delete
    find "${box_dir}/${bin_name}" -maxdepth 1 -type f -name "*.mmdb.bak" -delete

    log Debug "update geox $(date "+%F %R")"
    return 0
  else
   return 1
  fi
}

# Check and update subscription
upsubs() {
  enhanced=false
  update_file_name="${clash_config}"
  if [ "${renew}" != "true" ]; then
    yq="yq"
    if ! command -v yq &>/dev/null; then
      if [ ! -e "${box_dir}/bin/yq" ]; then
        log Debug "yq file not found, start to download from github"
        ${scripts_dir}/box.tool upyq
      fi
      yq="${box_dir}/bin/yq"
    fi
    enhanced=true
    update_file_name="${update_file_name}.subscription"
  fi

  case "${bin_name}" in
    "sing-box")
      log Warning "${bin_name} does not support subscriptions."
      return 1
      ;;
    *)
      log Error "<${bin_name}> unknown binary. Only sing-box is supported."
      return 1
      ;;
  esac
}

upkernel() {
  # su -c /data/adb/box/scripts/box.tool upkernel
  mkdir -p "${bin_dir}/backup"
  if [ -f "${bin_dir}/${bin_name}" ]; then
    cp "${bin_dir}/${bin_name}" "${bin_dir}/backup/${bin_name}.bak" >/dev/null 2>&1
  fi
  case $(uname -m) in
    "aarch64") if [ "${bin_name}" = "clash" ]; then arch="arm64-v8"; else arch="arm64"; fi; platform="android" ;;
    "armv7l"|"armv8l") arch="armv7"; platform="linux" ;;
    "i686") arch="386"; platform="linux" ;;
    "x86_64") arch="amd64"; platform="linux" ;;
    *) log Warning "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
  # Do anything else below
  file_kernel="${bin_name}-${arch}"
  case "${bin_name}" in
    "sing-box")
      api_url="https://api.github.com/repos/SagerNet/sing-box/releases"
      url_down="https://github.com/SagerNet/sing-box/releases"

      if [ "${singbox_stable}" = "disable" ]; then
        # Pre-release
        log Debug "download ${bin_name} Pre-release"
        latest_version=$($rev1 "${api_url}" | grep "tag_name" | busybox grep -oE "v[0-9].*" | head -1 | cut -d'"' -f1)
      else
        # Latest
        log Debug "download ${bin_name} Latest-stable"
        latest_version=$($rev1 "${api_url}/latest" | grep "tag_name" | busybox grep -oE "v[0-9.]*" | head -1)
      fi

      if [ -z "$latest_version" ]; then
        log Error "Failed to get latest stable/beta/alpha version of sing-box"
        return 1
      fi

      download_link="${url_down}/download/${latest_version}/sing-box-${latest_version#v}-${platform}-${arch}.tar.gz"
      log Debug "download ${download_link}"
      upfile "${box_dir}/${file_kernel}.tar.gz" "${download_link}" && xkernel
      ;;
    *)
      log Error "<${bin_name}> unknown binary. Only sing-box is supported."
      exit 1
      ;;
  esac
}

# Check and update kernel
xkernel() {
  case "${bin_name}" in
    "sing-box")
      tar_command="tar"
      if ! command -v tar >/dev/null 2>&1; then
        tar_command="busybox tar"
      fi
      if ${tar_command} -xf "${box_dir}/${file_kernel}.tar.gz" -C "${bin_dir}" >&2; then
        mv "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}/sing-box" "${bin_dir}/${bin_name}"
        if [ -f "${box_pid}" ]; then
          rm -rf /data/adb/box/sing-box/cache.db
          restart_box
        else
          log Debug "${bin_name} does not need to be restarted."
        fi
      else
        log Error "Failed to extract ${box_dir}/${file_kernel}.tar.gz."
      fi
      [ -d "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}" ] && \
        rm -r "${bin_dir}/sing-box-${latest_version#v}-${platform}-${arch}"
      ;;
    *)
      log Error "<${bin_name}> unknown binary. Only sing-box is supported."
      exit 1
      ;;
  esac

  find "${box_dir}" -maxdepth 1 -type f -name "${file_kernel}.*" -delete
  chown ${box_user_group} ${bin_path}
  chmod 6755 ${bin_path}
}

# Check and update yacd
upxui() {
  # su -c /data/adb/box/scripts/box.tool upxui
  xdashboard="${bin_name}/dashboard"
  if [[ "${bin_name}" == "sing-box" ]]; then
    file_dashboard="${box_dir}/${xdashboard}.zip"
    url="https://github.com/CHIZI-0618/yacd/archive/refs/heads/gh-pages.zip"
    if [ "$use_ghproxy" == true ]; then
      url="${url_ghproxy}/${url}"
    fi
    dir_name="yacd-gh-pages"
    log Debug "Download ${url}"

    if which curl > /dev/null 2>&1; then
      rev2="curl -L --insecure ${url} -o"
    else
      rev2="busybox wget --no-check-certificate ${url} -O"
    fi

    if $rev2 "${file_dashboard}" >&2; then
      if [ ! -d "${box_dir}/${xdashboard}" ]; then
        log Info "dashboard folder not exist, creating it"
        mkdir "${box_dir}/${xdashboard}"
      else
        rm -rf "${box_dir}/${xdashboard}/"*
      fi
      if command -v unzip >/dev/null 2>&1; then
        unzip_command="unzip"
      else
        unzip_command="busybox unzip"
      fi
      "${unzip_command}" -o "${file_dashboard}" "${dir_name}/*" -d "${box_dir}/${xdashboard}" >&2
      mv -f "${box_dir}/${xdashboard}/$dir_name"/* "${box_dir}/${xdashboard}/"
      rm -f "${file_dashboard}"
      rm -rf "${box_dir}/${xdashboard}/${dir_name}"
    else
      log Error "Failed to download dashboard" >&2
      return 1
    fi
    return 0
  else
    log Debug "${bin_name} does not support dashboards"
    return 1
  fi
}

cgroup_blkio() {
  local pid_file="$1"
  local fallback_weight="${2:-900}"  # default weight jika pakai 'box'

  if [ -z "$pid_file" ] || [ ! -f "$pid_file" ]; then
    log Warning "PID file missing or invalid: $pid_file"
    return 1
  fi

  local PID=$(<"$pid_file" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" 2>/dev/null; then
    log Warning "Invalid or dead PID: $PID"
    return 1
  fi

  # Temukan blkio path
  if [ -z "$blkio_path" ]; then
    blkio_path=$(mount | busybox awk '/blkio/ {print $3}' | head -1)
    if [ -z "$blkio_path" ] || [ ! -d "$blkio_path" ]; then
      log Warning "blkio_path not found"
      return 1
    fi
  fi

  # Pilih target group: foreground jika ada, jika tidak buat box
  local target
  if [ -d "${blkio_path}/foreground" ]; then
    target="${blkio_path}/foreground"
    log Info "Using existing blkio group: foreground"
  else
    target="${blkio_path}/box"
    mkdir -p "$target"
    echo "$fallback_weight" > "${target}/blkio.weight"
    log Info "Created blkio group: box with weight $fallback_weight"
  fi

  echo "$PID" > "${target}/cgroup.procs" \
    && log Info "Assigned PID $PID to $target"

  return 0
}

cgroup_memcg() {
  local pid_file="$1"
  local raw_limit="$2"

  if [ -z "$pid_file" ] || [ ! -f "$pid_file" ]; then
    log Warning "PID file missing or invalid: $pid_file"
    return 1
  fi

  if [ -z "$raw_limit" ]; then
    log Warning "memcg limit not specified"
    return 1
  fi

  local limit
  case "$raw_limit" in
    *[Mm])
      limit=$(( ${raw_limit%[Mm]} * 1024 * 1024 ))
      ;;
    *[Gg])
      limit=$(( ${raw_limit%[Gg]} * 1024 * 1024 * 1024 ))
      ;;
    *[Kk])
      limit=$(( ${raw_limit%[Kk]} * 1024 ))
      ;;
    *[0-9])
      limit=$raw_limit  # assume raw bytes
      ;;
    *)
      log Warning "Invalid memcg limit format: $raw_limit"
      return 1
      ;;
  esac

  local PID
  PID=$(<"$pid_file" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" 2>/dev/null; then
    log Warning "Invalid or dead PID: $PID"
    return 1
  fi

  # Deteksi memcg_path jika belum diset
  if [ -z "$memcg_path" ]; then
    memcg_path=$(mount | grep cgroup | busybox awk '/memory/{print $3}' | head -1)
    if [ -z "$memcg_path" ] || [ ! -d "$memcg_path" ]; then
      log Warning "memcg path could not be determined"
      return 1
    fi
  fi

  # Gunakan bin_name jika tersedia, default ke 'app'
  local name="${bin_name:-app}"
  local target="${memcg_path}/${name}"
  mkdir -p "$target"

  echo "$limit" > "${target}/memory.limit_in_bytes" \
    && log Info "Set memory limit for $name: ${limit} bytes"

  echo "$PID" > "${target}/cgroup.procs" \
    && log Info "Assigned PID $PID to ${target}"

  return 0
}

cgroup_cpuset() {
  local pid_file="${1}"
  local cores="${2}"

  if [ -z "${pid_file}" ] || [ ! -f "${pid_file}" ]; then
    log Warning "Missing or invalid PID file: ${pid_file}"
    return 1
  fi

  local PID
  PID=$(<"${pid_file}" 2>/dev/null)
  if [ -z "$PID" ] || ! kill -0 "$PID" 2>/dev/null; then
    log Warning "PID $PID from ${pid_file} is not valid or not running"
    return 1
  fi

  # Deteksi jumlah core jika cores belum ditentukan
  if [ -z "${cores}" ]; then
    local total_core
    total_core=$(nproc --all 2>/dev/null)
    if [ -z "$total_core" ] || [ "$total_core" -le 0 ]; then
      log Warning "Failed to detect CPU cores"
      return 1
    fi
    cores="0-$((total_core - 1))"
  fi

  # Deteksi cpuset_path
  if [ -z "${cpuset_path}" ]; then
    cpuset_path=$(mount | grep cgroup | busybox awk '/cpuset/{print $3}' | head -1)
    if [ -z "${cpuset_path}" ] || [ ! -d "${cpuset_path}" ]; then
      log Warning "cpuset_path not found"
      return 1
    fi
  fi

  local cpuset_target="${cpuset_path}/top-app"
  if [ ! -d "${cpuset_target}" ]; then
    cpuset_target="${cpuset_path}/apps"
    [ ! -d "${cpuset_target}" ] && log Warning "cpuset target not found" && return 1
  fi

  echo "${cores}" > "${cpuset_target}/cpus"
  echo "0" > "${cpuset_target}/mems"

  echo "${PID}" > "${cpuset_target}/cgroup.procs" \
    && log Info "Assigned PID $PID to ${cpuset_target} with CPU cores [$cores]"

  return 0
}

ip_port=$(if [ "${bin_name}" = "clash" ]; then busybox awk '/external-controller:/ {print $2}' "${clash_config}"; else find /data/adb/box/sing-box/ -type f -name 'config.json' -exec busybox awk -F'[:,]' '/external_controller/ {print $2":"$3}' {} \; | sed 's/^[ \t]*//;s/"//g'; fi;)
secret=""

webroot() {
path_webroot="/data/adb/modules/box_for_root/webroot/index.html"
touch -n > $path_webroot
  if [[ "${bin_name}" = "sing-box" ]]; then
    echo -e '
  <!DOCTYPE html>
  <script>
      document.location = 'http://127.0.0.1:9090/ui/'
  </script>
  </html>
  ' > $path_webroot
    sed -i "s#document\.location =.*#document.location = 'http://$ip_port/ui/'#" $path_webroot
  else
   echo -e '
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Unsupported Dashboard</title>
      <style>
          body {
              font-family: Arial, sans-serif;
              text-align: center;
              padding: 50px;
          }
          h1 {
              color: red;
          }
      </style>
  </head>
  <body>
      <h1>Unsupported Dashboard</h1>
      <p>Sorry, xray/v2ray does not support the necessary Dashboard features.</p>
  </body>
  </html>' > $path_webroot
  fi
}

bond0() {
  # Menonaktifkan mode low latency untuk TCP
  sysctl -w net.ipv4.tcp_low_latency=0 >/dev/null 2>&1
  log Debug "tcp low latency: 0"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 3000 untuk semua interface wireless (wlan*)
  for dev in /sys/class/net/wlan*; do ip link set dev $(basename $dev) txqueuelen 3000; done
  log Debug "wlan* txqueuelen: 3000"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 1000 untuk semua interface rmnet_data*
  for txqueuelen in /sys/class/net/rmnet_data*; do txqueuelen_name=$(basename $txqueuelen); ip link set dev $txqueuelen_name txqueuelen 1000; done
  log Debug "rmnet_data* txqueuelen: 1000"

  # Mengatur MTU (Maximum Transmission Unit) menjadi 1500 untuk semua interface rmnet_data*
  for mtu in /sys/class/net/rmnet_data*; do mtu_name=$(basename $mtu); ip link set dev $mtu_name mtu 1500; done
  log Debug "rmnet_data* mtu: 1500"
}

bond1() {
  # Mengaktifkan mode low latency untuk TCP
  sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
  log Debug "tcp low latency: 1"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 4000 untuk semua interface wireless (wlan*)
  for dev in /sys/class/net/wlan*; do ip link set dev $(basename $dev) txqueuelen 4000; done
  log Debug "wlan* txqueuelen: 4000"

  # Mengatur panjang antrian transmisi (txqueuelen) menjadi 2000 untuk semua interface rmnet_data*
  for txqueuelen in /sys/class/net/rmnet_data*; do txqueuelen_name=$(basename $txqueuelen); ip link set dev $txqueuelen_name txqueuelen 2000; done
  log Debug "rmnet_data* txqueuelen: 2000"

  # Mengatur MTU (Maximum Transmission Unit) menjadi 9000 untuk semua interface rmnet_data*
  for mtu in /sys/class/net/rmnet_data*; do mtu_name=$(basename $mtu); ip link set dev $mtu_name mtu 9000; done
  log Debug "rmnet_data* mtu: 9000"
}

case "$1" in
  check)
    check
    ;;
  memcg|cpuset|blkio)
    # leave it blank by default, it will fill in auto,
    case "$1" in
      memcg)
        memcg_path=""
        cgroup_memcg "${box_pid}" ${memcg_limit}
        ;;
      cpuset)
        cpuset_path=""
        cgroup_cpuset "${box_pid}" ${allow_cpu}
        ;;
      blkio)
        blkio_path=""
        cgroup_blkio "${box_pid}" "${weight}"
        ;;
    esac
    ;;
  bond0|bond1)
    $1
    ;;
  geosub)
    upsubs
    upgeox
    if [ -f "${box_pid}" ]; then
      kill -0 "$(<"${box_pid}" 2>/dev/null)" && reload
    fi
    ;;
  geox|subs)
    if [ "$1" = "geox" ]; then
      upgeox
    else
      upsubs
      [ "${bin_name}" != "sing-box" ] && exit 1
    fi
    if [ -f "${box_pid}" ]; then
      kill -0 "$(<"${box_pid}" 2>/dev/null)" && reload
    fi
    ;;
  upkernel)
    upkernel
    ;;
  upxui)
    upxui
    ;;
  upyq|upcurl)
    $1
    ;;
  reload)
    reload
    ;;
  webroot)
    webroot
    ;;
  all)
    upyq
    upcurl
    for bin_name in "${bin_list[@]}"; do
      upkernel
      upgeox
      upsubs
      upxui
    done
    ;;
  *)
    echo "${red}$0 $1 no found${normal}"
    echo "${yellow}usage${normal}: ${green}$0${normal} {${yellow}check|memcg|cpuset|blkio|geosub|geox|subs|upkernel|upxui|upyq|upcurl|reload|webroot|bond0|bond1|all${normal}}"
    ;;
esac