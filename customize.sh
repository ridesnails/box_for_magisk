#!/system/bin/sh

# Script configuration variables
SKIPUNZIP=1
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true

# Check installation conditions
if [ "$BOOTMODE" != true ]; then
  abort "-----------------------------------------------------------"
  ui_print "! Please install in Magisk/KernelSU/APatch Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "-----------------------------------------------------------"
  ui_print "! Please update your KernelSU and KernelSU Manager"
  abort "-----------------------------------------------------------"
fi

service_dir="/data/adb/service.d"
if [ "$KSU" = "true" ]; then
  ui_print "- KernelSU version: $KSU_VER ($KSU_VER_CODE)"
  [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
  
  # Enhanced KernelSU integration optimizations
  ui_print "- Applying KernelSU specific optimizations"
  
  # Set KernelSU specific environment variables
  export KSU_MODULE_DIR="/data/adb/modules"
  export KSU_BIN_DIR="/data/adb/ksu/bin"
  
  # Optimize for KernelSU permission model
  if [ -d "/data/adb/ksu" ]; then
    ui_print "- Configuring KernelSU permission model"
    # Ensure proper KernelSU module loading mechanism
    mkdir -p "/data/adb/ksu/modules_update"
    # Set enhanced permissions for KernelSU environment
    chmod 755 "/data/adb/ksu" 2>/dev/null
  fi
  
elif [ "$APATCH" = "true" ]; then
  APATCH_VER=$(cat "/data/adb/ap/version")
  ui_print "- APatch version: $APATCH_VER"
  
  # APatch specific optimizations
  export AP_MODULE_DIR="/data/adb/modules"
  export AP_BIN_DIR="/data/adb/ap/bin"
  
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
  
  # Magisk specific optimizations
  export MAGISK_MODULE_DIR="/data/adb/modules"
  export MAGISK_BIN_DIR="/data/adb/magisk"
fi

# Set up service directory and clean old installations
mkdir -p "${service_dir}"
if [ -d "/data/adb/modules/box_for_magisk" ]; then
  rm -rf "/data/adb/modules/box_for_magisk"
  ui_print "- Old module deleted."
fi

# Extract files and configure directories
ui_print "- Installing Box for Magisk/KernelSU/APatch"
unzip -o "$ZIPFILE" -x 'META-INF/*' -x 'webroot/*' -d "$MODPATH" >&2
if [ -d "/data/adb/box" ]; then
  ui_print "- Backup existing box data"
  temp_bak=$(mktemp -d "/data/adb/box/box.XXXXXXXXXX")
  temp_dir="${temp_bak}"
  mv /data/adb/box/* "${temp_dir}/"
  mv "$MODPATH/box/"* /data/adb/box/
  backup_box="true"
else
  mv "$MODPATH/box" /data/adb/
fi

# Ensure rule-set source directory exists and has proper permissions
ui_print "- Setting up rule-set source files"
mkdir -p /data/adb/box/sing-box/source/
if [ -d "$MODPATH/box/sing-box/source" ]; then
  cp -rf "$MODPATH/box/sing-box/source/"* /data/adb/box/sing-box/source/ 2>/dev/null || true
fi

# Directory creation and file extraction
ui_print "- Create directories"
mkdir -p /data/adb/box/ /data/adb/box/run/ /data/adb/box/bin/xclash/
ui_print "- Extracting uninstall.sh skip_mount and box_service.sh"
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'skip_mount' -d "$MODPATH" >&2
unzip -j -o "$ZIPFILE" 'box_service.sh' -d "${service_dir}" >&2

# Set permissions with enhanced KernelSU/APatch compatibility
ui_print "- Setting permissions with enhanced compatibility"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive /data/adb/box/ 0 3005 0755 0644
set_perm_recursive /data/adb/box/scripts/ 0 3005 0755 0700
set_perm_recursive /data/adb/box/sing-box/source/ 0 3005 0755 0644
set_perm ${service_dir}/box_service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
chmod ugo+x ${service_dir}/box_service.sh $MODPATH/uninstall.sh /data/adb/box/scripts/*
chmod 644 /data/adb/box/sing-box/source/*.json 2>/dev/null || true

# Enhanced permission settings for different root solutions
if [ "$KSU" = "true" ]; then
  # KernelSU specific permission optimizations
  ui_print "- Applying KernelSU enhanced permissions"
  chown -R 0:3005 /data/adb/box/ 2>/dev/null
  chmod 755 /data/adb/box/bin/ 2>/dev/null
  # Set SELinux context for KernelSU compatibility
  if command -v chcon >/dev/null 2>&1; then
    chcon -R u:object_r:system_file:s0 /data/adb/box/bin/ 2>/dev/null
  fi
elif [ "$APATCH" = "true" ]; then
  # APatch specific permission optimizations
  ui_print "- Applying APatch enhanced permissions"
  chown -R 0:3005 /data/adb/box/ 2>/dev/null
else
  # Magisk specific permission optimizations
  ui_print "- Applying Magisk enhanced permissions"
  chown -R 0:3005 /data/adb/box/ 2>/dev/null
fi

# Download prompt for optional kernel components
ui_print "-----------------------------------------------------------"
ui_print "- Do you want to download Kernel(xray hysteria clash v2fly sing-box) and GeoX(geosite geoip mmdb)? size: ±100MB."
ui_print "- Ensure a good internet connection."
ui_print "- [ Vol UP(+): Yes ]"
ui_print "- [ Vol DOWN(-): No ]"

START_TIME=$(date +%s)
while true ; do
  NOW_TIME=$(date +%s)
  timeout 1 getevent -lc 1 2>&1 | grep KEY_VOLUME > "$TMPDIR/events"
  if [ $(( NOW_TIME - START_TIME )) -gt 9 ]; then
    ui_print "- No input detected after 10 seconds, skipping download."
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEUP); then
    ui_print "- Starting download..."
    /data/adb/box/scripts/box.tool all
    break
  elif $(cat $TMPDIR/events | grep -q KEY_VOLUMEDOWN); then
    ui_print "- Skipping download."
    break
  fi
done

# Restore backup configurations if present
if [ "${backup_box}" = "true" ]; then
  ui_print "- Restoring configurations (xray, hysteria, clash, sing-box, v2fly)"
  restore_config() {
    config_dir="$1"
    [ -d "${temp_dir}/${config_dir}" ] && cp -rf "${temp_dir}/${config_dir}/"* "/data/adb/box/${config_dir}/"
  }
  for dir in clash xray v2fly sing-box hysteria; do
    restore_config "$dir"
  done

  # Restore rule-set source files if they exist in backup but preserve new ones
  if [ -d "${temp_dir}/sing-box/source" ]; then
    ui_print "- Merging rule-set source files"
    # Keep existing rule-set files, only restore if missing
    for rule_file in "${temp_dir}/sing-box/source"/*.json; do
      [ -f "$rule_file" ] || continue
      rule_name=$(basename "$rule_file")
      if [ ! -f "/data/adb/box/sing-box/source/$rule_name" ]; then
        cp "$rule_file" "/data/adb/box/sing-box/source/"
      fi
    done
  fi

  restore_kernel() {
    kernel_name="$1"
    [ ! -f "/data/adb/box/bin/$kernel_name" ] && [ -f "${temp_dir}/bin/${kernel_name}" ] && cp -rf "${temp_dir}/bin/${kernel_name}" "/data/adb/box/bin/${kernel_name}"
  }
  for kernel in curl yq xray sing-box v2fly hysteria xclash/mihomo xclash/premium; do
    restore_kernel "$kernel"
  done

  ui_print "- Restoring logs, pid, and uid.list"
  cp "${temp_dir}/run/"* "/data/adb/box/run/"
fi

# create_resolv() {
  # # Check if the resolv.conf file exists
  # if [ ! -f /system/etc/resolv.conf ]; then
    # # Ensure the target directory exists before writing the file
    # mkdir -p "$MODPATH/system/etc/security/cacerts/"
    # # Create resolv.conf with the specified nameservers
    # cat > "$MODPATH/system/etc/resolv.conf" <<EOF
# # nameserver 8.8.8.8
# # nameserver 1.1.1.1
# # nameserver 114.114.114.114
# EOF
  # fi
  # ui_print "- create $MODPATH/system/etcresolv.conf"
# }
# create_resolv

# Update module description if no kernel binaries are found
[ -z "$(find /data/adb/box/bin -type f)" ] && sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ 😱 Module installed but manual Kernel download required ] /g' $MODPATH/module.prop

# Customize module name based on environment
if [ "$KSU" = "true" ]; then
  sed -i "s/name=.*/name=Box for KernelSU/g" $MODPATH/module.prop
elif [ "$APATCH" = "true" ]; then
  sed -i "s/name=.*/name=Box for APatch/g" $MODPATH/module.prop
else
  sed -i "s/name=.*/name=Box for Magisk/g" $MODPATH/module.prop
fi
unzip -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >&2

# Clean up temporary files
ui_print "- Cleaning up leftover files"
rm -rf /data/adb/box/bin/.bin $MODPATH/box $MODPATH/box_service.sh

# Complete installation
ui_print "- Installation complete. Please reboot your device."
ui_print "- Report issues to t.me.taamarin"
