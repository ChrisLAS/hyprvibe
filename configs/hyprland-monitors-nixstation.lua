-- Nixstation four-monitor layout.
hl.monitor({ output = "DP-1", mode = "preferred", position = "2560x-1440", scale = 1 })
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = 1, transform = 1 })
hl.monitor({ output = "DP-3", mode = "preferred", position = "1440x0", scale = 1 })
hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "4000x0",
    scale = 1,
    transform = 1,
    reserved_area = 0,
})

if os.getenv("HYPRVIBE_SHELL_BACKEND") == "legacy" then
    hl.on("hyprland.start", function()
        hl.exec_cmd("~/.config/waybar/scripts/waybar-per-monitor.sh")
    end)
end

hl.bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "left" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "right" }))
hl.bind("SUPER + CTRL + up", hl.dsp.focus({ monitor = "up" }))
hl.bind("SUPER + CTRL + down", hl.dsp.focus({ monitor = "down" }))

hl.bind("SUPER + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "left" }))
hl.bind("SUPER + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "right" }))
hl.bind("SUPER + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "up" }))
hl.bind("SUPER + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "down" }))

local monitor_keys = {
    F1 = "DP-1",
    F2 = "DP-2",
    F3 = "DP-3",
    F4 = "HDMI-A-1",
}

for key, monitor in pairs(monitor_keys) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ monitor = monitor }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ monitor = monitor }))
end

hl.bind("SUPER + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/launch-communication.sh"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/launch-development.sh"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/launch-junction.sh"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/launch-mpv.sh"))
