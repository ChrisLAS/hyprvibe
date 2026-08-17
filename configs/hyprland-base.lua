-- Shared Hyprland configuration for all Hyprvibe hosts.

local terminal = "kitty"
local menu = "vicinae open"
local browser = "junction"

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("systemctl --user set-environment XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_DESKTOP=hyprland XDG_SESSION_TYPE=wayland")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_DESKTOP=hyprland XDG_SESSION_TYPE=wayland")
    -- Portals require an active graphical session target as of xdg-desktop-portal 1.22.
    hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
    -- Hyprpaper is managed by hyprvibe-hyprpaper.service.
    hl.exec_cmd("hypridle")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("playerctld daemon")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("systemctl --user stop nixos-fake-graphical-session.target")
end)

hl.env("XCURSOR_SIZE", "24")

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
        allow_tearing = false,
    },
    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
        },
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
    },
})

hl.curve("myBezier", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + L", hl.dsp.exec_cmd([[loginctl lock-session; sleep 1; hyprctl eval 'hl.dsp.dpms({ action = "off" })']]))
hl.bind("SUPER + O", hl.dsp.exec_cmd([[if command -v obsidian >/dev/null 2>&1; then exec obsidian; else exec flatpak run md.obsidian.Obsidian; fi]]))
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))
hl.bind("SUPER + F", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + B", hl.dsp.exec_cmd("~/.local/bin/rofi-brightness"))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

hl.bind("SUPER + SHIFT + L", hl.dsp.dpms({ action = "off" }))
hl.bind("SUPER + ALT + L", hl.dsp.dpms({ action = "on" }))

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + ALT + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd(menu) end })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[mkdir -p "$HOME/Pictures" && grim -g "$(slurp)" "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"]]))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
