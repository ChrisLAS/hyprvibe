# Hyprvibe

A flake-based NixOS configuration with Hyprland window manager support.

Tuned to squeeze every bit of performance out of your system. It's not in a drop-and-go state, but if you're willing to tweak a few things *(like replacing my username)*, you should be mostly set. 

There are a few ways we could improve for easier sharing. I'd appreciate suggestions/PRs. 


## Structure

```
.
├── flake.nix                    # Main flake configuration
├── hosts/
│   └── rvbee/
│       ├── system.nix           # Main system configuration
│       ├── hardware-configuration.nix  # Hardware-specific config
│       ├── hyprland.conf        # Hyprland window manager config
│       └── waybar.json          # Waybar status bar config
└── README.md                    # This file
```

### Full system overview

![Screenshot](screenshotv4.jpg)


- **Hyprland/Wayland desktop**
  - Hyprland session via GDM (Wayland), `programs.hyprland.enable` with `xwayland.enable`
  - Autostarts `waybar`, `dunst`, `hyprpaper`, `hypridle`
  - Hyprland env/theme: `QT_QPA_PLATFORMTHEME=qt6ct`, Wayland-first (`NIXOS_OZONE_WL=1`, `MOZ_ENABLE_WAYLAND=1`, `QT_QPA_PLATFORM=wayland`, `GDK_BACKEND=wayland`)
  - Keybinds for DPMS, screenshots (grim/slurp), media/brightness, app launchers, workspace mgmt

- **Lock screen and idle**
  - `hyprlock` with PAM enabled (`security.pam.services.hyprlock = { };`)
  - `hypridle` drives DPMS/off-on and lock-before-sleep
  - Wallpaper templated into `hyprpaper` and `hyprlock` via activation script

- **Waybar + notifications**
  - Waybar modules for Hyprland workspaces/window, audio, network, CPU/Mem, brightness, AMD GPU, weather, BTC price, public IP, clock, tray
  - Dunst notifications; custom scripts installed into `~/.config/waybar/scripts/`

- **NixOS, flakes, channel**
  - Flake-based config on `nixos-unstable`
  - Inputs: `hyprwm/Hyprland` and `noblepayne/pretty-switch`
  - Formatter: `alejandra`
  - Declarative activation copies Hyprland/Waybar configs into `$HOME` each rebuild

- **Portals, audio, screenshare**
  - `xdg.portal.enable = true` with Hyprland preferred and GTK as extra
  - PipeWire + WirePlumber, ALSA/Pulse/JACK enabled (screenshare and pro-audio friendly)

- **Performance and reliability**
  - Zen kernel, ZRAM (`zstd`) enabled
  - BPF auto-tuning (`services.bpftune`) and BCC tools
  - Nix store auto-optimise; weekly GC
  - systemd OOM tuning for `nix-daemon`
  - Btrfs root with fstrim and autoscrub
  - CPU governor set to “performance”

- **Graphics**
  - Wayland + XWayland
  - RADV (Mesa) by default; 32-bit graphics enabled for gaming

- **Gaming**
  - Steam (Gamescope session, Remote Play and dedicated server firewall openings)
  - Lutris, `wineWowPackages.staging`, `winetricks`, `vulkan-tools`
  - `hardware.steam-hardware.enable = true` (controllers/udev rules)

- **Virtualization and containers**
  - libvirtd + virt-manager
  - Docker with weekly auto-prune

- **Files and desktop integration**
  - Dolphin with `kio-extras`, `kio-fuse`, `kio-admin`, thumbnailers, `ark`
  - `udisks2` for mounting; KDE polkit agent
  - Clipboard (`wl-clipboard`, `cliphist`), screen capture (grim/slurp), OSD, portals

- **Networking and security**
  - NetworkManager, Tailscale, OpenSSH, Netdata
  - Polkit enabled; sudo for wheel without password
  - Firewall currently disabled (intended choice)

- **Shell and tooling**
  - Fish shell + Atuin; rich dev/multimedia/system toolsets
  - Secrets kept out of the repo; systemd user service imports `GITHUB_TOKEN` from `~/.config/secrets/github_token` at login

## Notes:

1. You'll need to update the path with your home dir. 
   Search for chrislas, replace with your user.
	(Would like suggestions for improvement)

### Waybar & Hyprland UX changes

- **Waybar visuals**: Blur + slight transparency enabled (Hyprland `layerrule = blur, waybar` and `ignorealpha 0.1`; CSS background rgba(…, 0.75)).
- **Module chips**: Each module wrapped with padded, rounded boxes to reduce jitter when values change. Fixed minimum widths for key modules.
- **Left window title**: `hyprland/window` moved to the left next to workspaces.
- **Added modules**: MPRIS (media), idle inhibitor (icons: ☀️ active / 🌙 inactive), Gamemode indicator, reboot button (⏻ with rofi confirm), brightness menu icon (🖥️).

### Brightness control (rofi)

- **Keybind**: SUPER+B opens a rofi menu with common steps/presets.
- **Waybar**: monitor icon launches the same menu.
- **Script location**: installed to `~/.local/bin/rofi-brightness` (tilde path used in configs for portability).
- **Backends**: Uses `brightnessctl` for kernel backlight or `ddcutil` for external monitors. For DDC:
  - Ensure `hardware.i2c.enable = true;`
  - Add your user to the `i2c` group
  - Have `ddcutil` installed

### Network mounts (Thunar)

- Requires `services.gvfs.enable = true`, `services.gnome.gnome-keyring.enable = true`, and `glib-networking` package.
- Avahi mDNS discovery uses `services.avahi.nssmdns4 = true;` (renamed option).
- Optional: `services.davfs2.enable = true;` for WebDAV filesystem mounts (GVFS WebDAV also available).

### Theming

- GTK theme: Tokyo Night GTK; icons: Papirus; cursor: Bibata.
- Qt: `qt.platformTheme = "gnome"` with `qt.style = "adwaita-dark"` for consistency; `adwaita-qt{,6}` and `qt6ct` present.
- GTK4/libadwaita apps mostly follow dark mode + accent; GTK3/Thunar follow the full theme.

### Portability checklist

- `~/.local/bin/rofi-brightness` must be installed (activation script handles this) and `rofi` available.
- User should be in groups used by this setup: `wheel`, `networkmanager`, `i2c`, `docker`, etc.
- External monitor brightness: verify `ddcutil detect` sees your display; otherwise only kernel backlight works.
- Waybar CSS: GTK CSS is strict; avoid unsupported units/properties. This config uses conservative `em` widths and supported rules.
- Reboot button uses `rofi` for confirmation; adjust to your preferred prompt if you don’t use rofi.

## Keybindings

| Category | Keys | Action | Command/Notes |
|---|---|---|---|
| Launchers | SUPER+RETURN | Launch terminal | `$terminal` (alacritty) |
| Launchers | SUPER+SPACE | App launcher | `$menu` (rofi run/drun) |
| Launchers | SUPER+F | Launch browser | `$browser` (firefox) |
| Launchers | SUPER+E | File manager | `dolphin` |
| Launchers | SUPER+O | Obsidian | `flatpak run md.obsidian.Obsidian` |
| Brightness | SUPER+B | Brightness menu | `~/.local/bin/rofi-brightness` (rofi menu) |
| Session | SUPER+M | Exit Hyprland | `exit` |
| Session | SUPER+L | Lock | `hyprlock` |
| Rofi | SUPER+SHIFT+SPACE | Rofi drun | `rofi -show drun -modi drun,run,filebrowser` |
| Rofi | SUPER+ALT+SPACE | Rofi file browser | `rofi -show filebrowser -modi drun,run,filebrowser` |
| Rofi | SUPER+CTRL+SPACE | Rofi keys | `rofi -show keys -modi drun,run,filebrowser,keys` |
| Windows | SUPER+V | Toggle floating | `togglefloating` |
| Windows | SUPER+left/right/up/down | Move focus | `movefocus l/r/u/d` |
| Layout (dwindle) | SUPER+P | Pseudotile | `pseudo` |
| Layout (dwindle) | SUPER+J | Toggle split | `togglesplit` |
| Workspaces | SUPER+1..0 | Switch workspace 1–10 | `workspace 1..10` |
| Workspaces | SUPER+SHIFT+1..0 | Move window to ws 1–10 | `movetoworkspace 1..10` |
| Workspaces | SUPER+mouse_down | Next workspace | `workspace e+1` |
| Workspaces | SUPER+mouse_up | Previous workspace | `workspace e-1` |
| Special ws | SUPER+S | Toggle special | `togglespecialworkspace magic` |
| Special ws | SUPER+SHIFT+S | Move to special | `movetoworkspace special:magic` |
| Mouse | SUPER + LMB drag | Move window | `bindm … movewindow` |
| Mouse | SUPER + RMB drag | Resize window | `bindm … resizewindow` |
| Display power | SUPER+SHIFT+L | Screen off (DPMS) | `hyprctl dispatch dpms off` |
| Display power | SUPER+ALT+L | Screen on (DPMS) | `hyprctl dispatch dpms on` |
| Screenshot | Print | Region to clipboard | `grim -g "$(slurp)" - | wl-copy` |
| Screenshot | SHIFT+Print | Region to file | `grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png` |
| Audio | XF86AudioRaiseVolume | Volume up +5% | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` |
| Audio | XF86AudioLowerVolume | Volume down -5% | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` |
| Audio | XF86AudioMute | Toggle mute | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| Media | XF86AudioPlay | Play/Pause | `playerctl play-pause` |
| Media | XF86AudioNext | Next track | `playerctl next` |
| Media | XF86AudioPrev | Previous track | `playerctl previous` |
| Brightness | XF86MonBrightnessUp | Increase brightness | `brightnessctl set +5%` |
| Brightness | XF86MonBrightnessDown | Decrease brightness | `brightnessctl set 5%-` |

