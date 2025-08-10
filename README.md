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

## Features

- **Hyprland**: Modern Wayland compositor with tiling window management
- **Waybar**: Status bar with workspace management, system info, and more
- **PipeWire**: Modern audio system
- **Gaming**: Steam, Lutris, and gaming utilities
- **Development**: Full development toolchain
- **Multimedia**: Video/audio editing and playback tools

## Notes:

1. You'll need to update the path with your home dir. 
   Search for chrislas, replace with your user.
	(Would like suggestions for improvement)
