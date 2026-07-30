-- Hyprland configuration for nixstation.
require("hyprland-base")
require("hyprland-monitors")
require("hyprland-local")

hl.on("hyprland.start", function()
    hl.exec_cmd("r2-mount")
end)

-- Software cursors avoid cursor corruption on the transformed displays.
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})
