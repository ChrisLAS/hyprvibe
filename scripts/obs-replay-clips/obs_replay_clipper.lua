obs = obslua

local helper_command = "obs-replay-clip-helper"
local clips_dir = "/home/chrisf/obs/Clips"
local markers_dir = "/home/chrisf/obs/Markers"
local logs_dir = "/home/chrisf/obs/Logs"
local marker_note = "Marker added"
local add_obs_chapter = true

local hotkey_clip_30s
local hotkey_clip_60s
local hotkey_clip_300s
local hotkey_marker
local pending_jobs = {}

local function shell_quote(value)
    value = tostring(value or "")
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function script_log(message)
    obs.script_log(obs.LOG_INFO, "[obs-replay-clipper] " .. message)
end

local function script_warn(message)
    obs.script_log(obs.LOG_WARNING, "[obs-replay-clipper] " .. message)
end

local function run_background(arguments)
    local command = shell_quote(helper_command)
    for _, value in ipairs(arguments) do
        command = command .. " " .. shell_quote(value)
    end
    os.execute(command .. " >/dev/null 2>&1 &")
end

local function queue_clip(seconds, copy_replay)
    if not obs.obs_frontend_replay_buffer_active() then
        script_warn("Replay buffer is not active; cannot create " .. tostring(seconds) .. "s clip")
        return
    end

    table.insert(pending_jobs, {
        duration = seconds,
        copy = copy_replay,
    })
    script_log("Saving replay buffer for " .. tostring(seconds) .. "s clip")
    obs.obs_frontend_replay_buffer_save()
end

local function clip_30s(pressed)
    if pressed then
        queue_clip(30, false)
    end
end

local function clip_60s(pressed)
    if pressed then
        queue_clip(60, false)
    end
end

local function clip_300s(pressed)
    if pressed then
        queue_clip(300, true)
    end
end

local function add_marker(pressed)
    if not pressed then
        return
    end

    if add_obs_chapter and obs.obs_frontend_recording_add_chapter ~= nil then
        local ok = obs.obs_frontend_recording_add_chapter(marker_note)
        if ok then
            script_log("Added OBS chapter marker")
        else
            script_warn("OBS chapter marker was not added; writing text marker only")
        end
    end

    run_background({
        "marker",
        "--markers-dir", markers_dir,
        "--logs-dir", logs_dir,
        "--note", marker_note,
    })
end

local function button_clip_30s()
    queue_clip(30, false)
    return false
end

local function button_clip_60s()
    queue_clip(60, false)
    return false
end

local function button_clip_300s()
    queue_clip(300, true)
    return false
end

local function button_marker()
    add_marker(true)
    return false
end

local function process_saved_replay()
    if #pending_jobs == 0 then
        return
    end

    local replay_path = obs.obs_frontend_get_last_replay()
    if replay_path == nil or replay_path == "" then
        script_warn("Replay saved event fired, but OBS did not report a replay path")
        return
    end

    local job = table.remove(pending_jobs, 1)
    local arguments = {
        "clip",
        "--duration", tostring(job.duration),
        "--replay-file", replay_path,
        "--clips-dir", clips_dir,
        "--logs-dir", logs_dir,
    }
    if job.copy then
        table.insert(arguments, "--copy")
    end

    script_log("Dispatching clip helper for replay: " .. replay_path)
    run_background(arguments)
end

local function on_frontend_event(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        process_saved_replay()
    end
end

function script_description()
    return "Registers OBS hotkeys for local replay-buffer clips: Clip 30s, Clip 1m, Clip 5m, and Add marker."
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "helper_command", helper_command)
    obs.obs_data_set_default_string(settings, "clips_dir", clips_dir)
    obs.obs_data_set_default_string(settings, "markers_dir", markers_dir)
    obs.obs_data_set_default_string(settings, "logs_dir", logs_dir)
    obs.obs_data_set_default_string(settings, "marker_note", marker_note)
    obs.obs_data_set_default_bool(settings, "add_obs_chapter", add_obs_chapter)
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "helper_command", "Helper command", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_path(props, "clips_dir", "Clips directory", obs.OBS_PATH_DIRECTORY, "", nil)
    obs.obs_properties_add_path(props, "markers_dir", "Markers directory", obs.OBS_PATH_DIRECTORY, "", nil)
    obs.obs_properties_add_path(props, "logs_dir", "Logs directory", obs.OBS_PATH_DIRECTORY, "", nil)
    obs.obs_properties_add_text(props, "marker_note", "Marker note text", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_bool(props, "add_obs_chapter", "Also try OBS chapter marker")
    obs.obs_properties_add_button(props, "button_clip_30s", "Clip 30s now", button_clip_30s)
    obs.obs_properties_add_button(props, "button_clip_60s", "Clip 1m now", button_clip_60s)
    obs.obs_properties_add_button(props, "button_clip_300s", "Clip 5m now", button_clip_300s)
    obs.obs_properties_add_button(props, "button_marker", "Add marker now", button_marker)
    return props
end

function script_update(settings)
    helper_command = obs.obs_data_get_string(settings, "helper_command")
    clips_dir = obs.obs_data_get_string(settings, "clips_dir")
    markers_dir = obs.obs_data_get_string(settings, "markers_dir")
    logs_dir = obs.obs_data_get_string(settings, "logs_dir")
    marker_note = obs.obs_data_get_string(settings, "marker_note")
    add_obs_chapter = obs.obs_data_get_bool(settings, "add_obs_chapter")
end

function script_load(settings)
    hotkey_clip_30s = obs.obs_hotkey_register_frontend("obs_replay_clipper.clip_30s", "Clip 30s", clip_30s)
    hotkey_clip_60s = obs.obs_hotkey_register_frontend("obs_replay_clipper.clip_60s", "Clip 1m", clip_60s)
    hotkey_clip_300s = obs.obs_hotkey_register_frontend("obs_replay_clipper.clip_300s", "Clip 5m", clip_300s)
    hotkey_marker = obs.obs_hotkey_register_frontend("obs_replay_clipper.marker", "Add marker", add_marker)

    local saved = obs.obs_data_get_array(settings, "clip_30s_hotkey")
    obs.obs_hotkey_load(hotkey_clip_30s, saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_data_get_array(settings, "clip_60s_hotkey")
    obs.obs_hotkey_load(hotkey_clip_60s, saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_data_get_array(settings, "clip_300s_hotkey")
    obs.obs_hotkey_load(hotkey_clip_300s, saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_data_get_array(settings, "marker_hotkey")
    obs.obs_hotkey_load(hotkey_marker, saved)
    obs.obs_data_array_release(saved)

    obs.obs_frontend_add_event_callback(on_frontend_event)
    script_log("Loaded")
end

function script_save(settings)
    local saved = obs.obs_hotkey_save(hotkey_clip_30s)
    obs.obs_data_set_array(settings, "clip_30s_hotkey", saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_hotkey_save(hotkey_clip_60s)
    obs.obs_data_set_array(settings, "clip_60s_hotkey", saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_hotkey_save(hotkey_clip_300s)
    obs.obs_data_set_array(settings, "clip_300s_hotkey", saved)
    obs.obs_data_array_release(saved)

    saved = obs.obs_hotkey_save(hotkey_marker)
    obs.obs_data_set_array(settings, "marker_hotkey", saved)
    obs.obs_data_array_release(saved)
end

function script_unload()
    obs.obs_frontend_remove_event_callback(on_frontend_event)
end
