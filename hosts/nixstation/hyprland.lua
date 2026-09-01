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

-- Applications such as Nautilus and Obsidian persist their last maximized
-- state and request it again at launch. Keep window sizing under Hyprland's
-- control so new clients join the existing tiled layout instead.
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})
