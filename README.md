# Chris' NixOS Configuration with Hyprland

This is a flake-based NixOS configuration with Hyprland window manager support.

It's not really in a drop and go state, but if you're willing to tweak a few things
 (like replace my username) you sould be mostly set.

There are no doubt a few ways we could improve this for easier sharing. 


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

![Screenshot](screenshot.jpg)


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
