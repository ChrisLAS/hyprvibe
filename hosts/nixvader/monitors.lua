-- Use each connected panel or dock display's preferred mode.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("power-profile-menu"))
