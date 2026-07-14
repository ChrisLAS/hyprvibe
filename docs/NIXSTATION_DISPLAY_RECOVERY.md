# Nixstation Display Recovery

This runbook covers runtime display recovery on nixstation without restarting
Hyprland or interrupting GUI applications.

## Monitor map

| Screen | Connector | Position | Model |
|---|---|---|---|
| 1 | `DP-1` | Top | GIGABYTE M27Q |
| 2 | `DP-2` | Left, vertical | ASUS PB278 |
| 3 | `DP-3` | Center/main | ASUS PB278 |
| 4 | `HDMI-A-1` | Right, vertical | ASUS PB277 |

The tracked keybindings are:

- `SUPER+SHIFT+L`: turn all displays off with DPMS.
- `SUPER+ALT+L`: run `~/.config/hypr/scripts/wake-monitors.sh`.

The wake script powers on every output, then cycles `DP-3` three times and
reasserts its preferred mode because that monitor sometimes fails to resume.

## Safe live checks

First find the active Hyprland instance. A shell outside the desktop session
may not have its instance signature in the environment.

```bash
sig=$(hyprctl instances -j | jq -r '.[0].instance')
export HYPRLAND_INSTANCE_SIGNATURE="$sig"
export XDG_RUNTIME_DIR=/run/user/$(id -u)
hyprctl monitors all -j
```

Compare Hyprland's result with the kernel connector state:

```bash
for item in status enabled dpms; do
  printf '%s=%s\n' "$item" "$(</sys/class/drm/card0-DP-3/$item)"
done
```

These checks distinguish three different failures:

1. `status=disconnected`: the kernel does not detect the monitor.
2. Connected but `enabled=disabled` or `dpms=Off`: the output or link did not
   come up.
3. Connected, enabled, and DPMS on, with a valid Hyprland mode, but the panel
   is black: power and mode negotiation succeeded, but no image is visible.

## Safe runtime recovery

An explicit wake does not restart the desktop session:

```bash
hyprctl dispatch dpms on DP-3
```

The configured recovery script is more aggressive and visibly cycles the
center monitor:

```bash
~/.config/hypr/scripts/wake-monitors.sh
```

Do not restart Hyprland, the display manager, or the user session while GUI
jobs need to survive. If the connector is enabled and powered but remains
black, stop cycling it and wait for a convenient reboot. If the problem
survives reboot, next steps are a physical monitor power-cycle, reseating or
swapping the DisplayPort cable, and collecting fresh kernel and Hyprland logs.

## Observed incidents

### 2026-07-14: DP-3 powered but black

- `DP-3` was connected and enabled in DRM with DPMS `On`.
- Hyprland reported it enabled at 2560x1440, 59.951 Hz, on workspace 3.
- An explicit DPMS off/on cycle visibly put the panel into power save and woke
  it again, but the displayed image remained black.
- No new DRM, atomic-commit, DisplayPort link, or DPCD error appeared in the
  kernel journal during the cycle.
- The same black-after-wake behavior had occurred earlier that morning.
- The running Nix build was unaffected, so recovery was deferred to the planned
  reboot rather than risking the active desktop session.

This is not the same as a connector remaining disabled. The current
`wake-monitors.sh` workaround can restore panel power and mode state without
restoring a visible image.

### 2026-07-02: DP-2 remained disabled

Hyprland detected `DP-2`, but DRM kept it disabled and DPMS off. Repeated mode
attempts failed with atomic-commit and DisplayPort link-training errors. That
incident was below the Hyprland layout layer and did not recover through DPMS
commands alone.
