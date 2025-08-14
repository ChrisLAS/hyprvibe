#!/usr/bin/env bash
set -euo pipefail

# Requires amdgpu top info via sysfs; fallback to radeontop if available

format_output() {
  local text tooltip
  text="$1"
  tooltip="$2"
  echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\"}"
}

# Locate AMD GPU card index and path dynamically (vendor 0x1002)
card_index=""
for dev in /sys/class/drm/card*/device; do
  [[ -e "$dev" ]] || continue
  if [[ -r "$dev/vendor" ]] && grep -qi "0x1002" "$dev/vendor"; then
    card_index=$(basename "$(dirname "$dev")" | sed 's/card//')
    gpu_path="$dev"
    break
  fi
done

temp_c=""
power_w=""
util=""

# Try sysfs hwmon sensors for temp and power
if [[ -n "${gpu_path:-}" && -r "${gpu_path}/hwmon" ]]; then
  hwmon_dir=$(readlink -f "${gpu_path}/hwmon"/* 2>/dev/null || true)
  if [[ -n "${hwmon_dir}" ]]; then
    if [[ -r "${hwmon_dir}/temp1_input" ]]; then
      t_raw=$(cat "${hwmon_dir}/temp1_input" 2>/dev/null || echo 0)
      temp_c=$(( t_raw / 1000 ))
    fi
    if [[ -r "${hwmon_dir}/power1_average" ]]; then
      p_raw=$(cat "${hwmon_dir}/power1_average" 2>/dev/null || echo 0)
      power_w=$(awk -v v="${p_raw}" 'BEGIN{ printf "%.1f", v/1000000 }')
    fi
  fi
fi

# Utilization via gpu_busy_percent if available; fallback to amdgpu_pm_info
if [[ -n "${gpu_path:-}" && -r "${gpu_path}/gpu_busy_percent" ]]; then
  util=$(cat "${gpu_path}/gpu_busy_percent" 2>/dev/null | tr -dc '0-9')
elif [[ -n "${card_index}" && -r "/sys/kernel/debug/dri/${card_index}/amdgpu_pm_info" ]]; then
  pm_info=$(cat "/sys/kernel/debug/dri/${card_index}/amdgpu_pm_info" 2>/dev/null || true)
  util=$(grep -iE 'GPU load' <<<"${pm_info}" | awk '{print $(NF-1)}' | tr -d '%')
fi

text=""
tooltip="AMD GPU"

parts=()
[[ -n "${util}" ]] && parts+=("${util}%")
[[ -n "${temp_c}" ]] && parts+=("${temp_c}°C")
[[ -n "${power_w}" ]] && parts+=("${power_w}W")

if [[ ${#parts[@]} -gt 0 ]]; then
  text="${parts[*]}"
  tooltip="AMD GPU: ${parts[*]}"
fi

format_output "${text}" "${tooltip}"

