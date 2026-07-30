# Hyprland Configuration Guide

Hyprvibe uses Hyprland's Lua configuration API across every host. The shared
module installs a host composition as `~/.config/hypr/hyprland.lua` and sets
`HYPRLAND_CONFIG` to that path.

## File structure

```text
configs/
├── hyprland-base.lua
├── hyprland-default.lua
├── hyprland-monitors-nixbook.lua
├── hyprland-monitors-nixstation.lua
├── hyprland-monitors-rvbee.lua
└── hyprland-monitors-rvbee-120hz.lua
hosts/
├── nixbook/hyprland.lua
├── nixstation/hyprland.lua
└── rvbee/hyprland.lua
```

`configs/hyprland-base.lua` contains shared appearance, input, animations,
gestures, autostart, and keybindings. Each host composition requires the shared
base, the generic deployed `hyprland-monitors.lua` module, and the generated
`hyprland-local.lua` overrides:

```lua
require("hyprland-base")
require("hyprland-monitors")
require("hyprland-local")
```

The Nix module maps each host's selected monitor source to the generic deployed
module name, so the composition stays identical between hosts.

## Lua API patterns

Use the supported `hl.*` API rather than the removed Hyprlang assignment syntax:

```lua
hl.config({
    general = {
        gaps_in = 5,
        layout = "dwindle",
    },
})

hl.monitor({
    output = "DP-1",
    mode = "2560x1440@144",
    position = "0x0",
    scale = 1,
})

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
```

Runtime dispatcher calls also take Lua expressions:

```bash
hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-1" })'
hyprctl dispatch 'hl.dsp.dpms({ action = "on", monitor = "DP-1" })'
hyprctl eval 'hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1 })'
```

## Monitor setup

The helper can inspect outputs, generate a Lua template, and evaluate active
one-line `hl.monitor(...)` declarations:

```bash
setup-monitors detect
setup-monitors setup nixstation
setup-monitors apply nixstation
setup-monitors status
```

For declarative changes, edit the appropriate tracked monitor module and rebuild:

- `configs/hyprland-monitors-nixstation.lua`
- `configs/hyprland-monitors-nixbook.lua`
- `configs/hyprland-monitors-rvbee-120hz.lua`

## Adding a host

1. Copy the closest monitor module and host composition.
2. Add the host to `flake.nix` if it is not already declared.
3. Set `hyprvibe.hyprland.monitorsFile` and `mainConfig` in its `system.nix`.
4. Evaluate the host and verify its composed config before boot activation.

Example Nix wiring:

```nix
hyprvibe.hyprland.monitorsFile = ../../configs/hyprland-monitors-newhost.lua;
hyprvibe.hyprland.mainConfig = ./hyprland.lua;
```

## Validation and rebuilding

Run the shared checks before staging a host:

```bash
nix flake check
sudo nixos-rebuild boot --flake .#nixstation
```

On nixstation, use `boot` unless live activation has been explicitly approved.
After reboot, check the compositor configuration directly:

```bash
hyprctl version
hyprctl configerrors
```

For an offline host, the flake evaluation confirms its Nix wiring. Perform its
real build and boot activation when the machine is next available.
