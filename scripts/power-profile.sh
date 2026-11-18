#!/usr/bin/env bash
set -euo pipefail

# Power profile switcher for NixOS + Hyprland
# Supports: performance, balanced, power-saver

PROFILE="${1:-}"

if [ -z "$PROFILE" ]; then
  echo "Usage: power-profile [performance|balanced|power-saver|status]"
  exit 1
fi

# Check if power-profiles-daemon is available
if ! command -v powerprofilesctl >/dev/null 2>&1; then
  echo "Error: powerprofilesctl not found. Install power-profiles-daemon."
  exit 1
fi

case "$PROFILE" in
  performance|balanced|power-saver)
    # Set via power-profiles-daemon
    powerprofilesctl set "$PROFILE" 2>/dev/null || {
      echo "Warning: Failed to set power profile via powerprofilesctl"
      echo "Falling back to manual CPU governor setting..."

      # Fallback: manual CPU governor setting
      case "$PROFILE" in
        performance)
          echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
          ;;
        power-saver)
          echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
          ;;
        balanced)
          echo "schedutil" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
          ;;
      esac
    }

    # WiFi power management
    case "$PROFILE" in
      performance)
        # Disable WiFi power saving for performance
        for iface in $(ip link show | awk '/^[0-9]+:/ {print $2}' | sed 's/:$//' | grep -E '^wl|^wifi|^wlan'); do
          # Use iw if available (modern)
          if command -v iw >/dev/null 2>&1; then
            sudo iw dev "$iface" set power_save off 2>/dev/null || true
          # Fallback to iwconfig (legacy)
          elif command -v iwconfig >/dev/null 2>&1; then
            sudo iwconfig "$iface" power off 2>/dev/null || true
          fi
        done
        ;;
      balanced|power-saver)
        # Enable WiFi power saving
        for iface in $(ip link show | awk '/^[0-9]+:/ {print $2}' | sed 's/:$//' | grep -E '^wl|^wifi|^wlan'); do
          if command -v iw >/dev/null 2>&1; then
            sudo iw dev "$iface" set power_save on 2>/dev/null || true
          elif command -v iwconfig >/dev/null 2>&1; then
            sudo iwconfig "$iface" power on 2>/dev/null || true
          fi
        done
        ;;
    esac

    # Disk power management (for NVMe/SSD)
    case "$PROFILE" in
      performance)
        # Disable disk power saving - keep drives active
        for disk in /sys/block/nvme* /sys/block/sd*; do
          [ -e "$disk/power/control" ] && echo "on" | sudo tee "$disk/power/control" >/dev/null 2>&1 || true
        done
        # For NVMe: disable power state transitions
        for nvme in /sys/class/nvme/nvme*; do
          [ -e "$nvme/device/queue" ] && echo "0" | sudo tee "$nvme/device/queue/nvme_core/default_ps_max_latency_us" >/dev/null 2>&1 || true
        done
        ;;
      balanced)
        # Balanced: allow some power saving
        for disk in /sys/block/nvme* /sys/block/sd*; do
          [ -e "$disk/power/control" ] && echo "auto" | sudo tee "$disk/power/control" >/dev/null 2>&1 || true
        done
        ;;
      power-saver)
        # Enable disk power saving (auto)
        for disk in /sys/block/nvme* /sys/block/sd*; do
          [ -e "$disk/power/control" ] && echo "auto" | sudo tee "$disk/power/control" >/dev/null 2>&1 || true
        done
        # For NVMe: enable power state transitions
        for nvme in /sys/class/nvme/nvme*; do
          [ -e "$nvme/device/queue" ] && echo "2500" | sudo tee "$nvme/device/queue/nvme_core/default_ps_max_latency_us" >/dev/null 2>&1 || true
        done
        ;;
    esac

    # GPU power management
    # Intel GPU (i915)
    if [ -d /sys/class/drm ]; then
      for card in /sys/class/drm/card*/device; do
        [ ! -e "$card" ] && continue

        # Check if Intel GPU (i915)
        if [ -d "$card/driver" ] && [ "$(readlink -f "$card/driver")" = "/sys/bus/pci/drivers/i915" ] 2>/dev/null; then
          case "$PROFILE" in
            performance)
              # Disable GPU RC6 power saving (Intel)
              echo "0" | sudo tee "$card/power/rc6_enable" >/dev/null 2>&1 || true
              # Disable GPU RC6p (deep RC6)
              echo "0" | sudo tee "$card/power/rc6p_enable" >/dev/null 2>&1 || true
              ;;
            balanced|power-saver)
              # Enable GPU RC6 power saving
              echo "1" | sudo tee "$card/power/rc6_enable" >/dev/null 2>&1 || true
              echo "1" | sudo tee "$card/power/rc6p_enable" >/dev/null 2>&1 || true
              ;;
          esac
        fi

        # AMD GPU (amdgpu) - if present
        if [ -d "$card/driver" ] && [ "$(readlink -f "$card/driver")" = "/sys/bus/pci/drivers/amdgpu" ] 2>/dev/null; then
          if [ -e "$card/power_dpm_force_performance_level" ]; then
            case "$PROFILE" in
              performance)
                echo "high" | sudo tee "$card/power_dpm_force_performance_level" >/dev/null 2>&1 || true
                ;;
              balanced)
                echo "auto" | sudo tee "$card/power_dpm_force_performance_level" >/dev/null 2>&1 || true
                ;;
              power-saver)
                echo "low" | sudo tee "$card/power_dpm_force_performance_level" >/dev/null 2>&1 || true
                ;;
            esac
          fi
        fi
      done
    fi

    echo "Power profile set to: $PROFILE"
    ;;

  status)
    if command -v powerprofilesctl >/dev/null 2>&1; then
      echo "Current profile: $(powerprofilesctl get)"
    else
      echo "Current CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'unknown')"
    fi

    # Show battery status if available
    if command -v upower >/dev/null 2>&1; then
      BATTERY=$(upower -e | grep -i battery | head -1)
      if [ -n "$BATTERY" ]; then
        echo "Battery: $(upower -i "$BATTERY" | grep -E 'state|percentage' | head -2)"
      fi
    fi
    ;;

  *)
    echo "Unknown profile: $PROFILE"
    echo "Available profiles: performance, balanced, power-saver"
    exit 1
    ;;
esac
