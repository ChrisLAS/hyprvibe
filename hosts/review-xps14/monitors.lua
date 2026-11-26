-- 2880x1800 internal panel: comfortable 1920x1200 logical workspace.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5 })
-- Dock/external displays retain their preferred mode and automatic placement.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Hold F8 to dictate; releasing it finishes transcription and pastes.
hl.bind("F8", hl.dsp.exec_cmd("hex dictation start"))
hl.bind("F8", hl.dsp.exec_cmd("hex dictation stop"), { release = true })
