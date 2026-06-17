# OBS Replay Clipping on nixstation

This setup keeps OBS's built-in Replay Buffer at 5 minutes and adds local OBS
hotkeys for shorter clips:

- `Clip 30s`
- `Clip 1m`
- `Clip 5m`
- `Add marker`

The OBS Lua script registers the hotkeys. When a clip hotkey is pressed it asks
OBS to save the current replay buffer, waits for OBS's replay-saved event, then
runs `obs-replay-clip-helper` in the background. The helper uses `ffmpeg -sseof`
with `-c copy` for 30s/60s clips, so clips are fast and lossless but can start
on the nearest practical keyframe rather than the exact requested frame.

## Research Summary

OBS has one built-in replay-buffer duration. Current OBS exposes script hotkeys,
`obs_frontend_replay_buffer_save`, replay-buffer active state, replay-buffer
saved events, and `obs_frontend_get_last_replay`, so a native OBS script is the
cleanest local-first approach.

OBS 32 also exposes `obs_frontend_recording_add_chapter`, but it only succeeds
when the active recording output supports chapter insertion. This workflow writes
plain Markdown markers regardless and can also try OBS-native chapters.

The older "Additional Replay Buffer" Python script depended on a heavier Python
runtime/moviepy-style workflow and has forum reports of reliability problems on
newer OBS sessions. It is not the best fit here. Replay Buffer Pro demonstrates
the same general idea, but it is a third-party plugin path; this setup stays
boring and repo-owned.

OBS WebSocket can save the replay buffer and report the saved path, but it is not
needed for local OBS hotkeys. On this host the WebSocket config exists and the
server is disabled.

NixOS already provides OBS 32.1.2 and `ffmpeg-full` on `nixstation`. The package
added here only installs the helper and Lua script.

## Paths

The active OBS profile records to `/home/chrisf/obs`, so this workflow defaults
to:

- Clips: `/home/chrisf/obs/Clips`
- Markers: `/home/chrisf/obs/Markers`
- Logs: `/home/chrisf/obs/Logs`

Clip filenames preserve OBS's replay file extension. The active profile currently
uses `mp4`; if OBS is later changed to MKV, the clips will be MKV. Filenames look
like:

```text
clip-YYYYMMDD-HHMMSS-30s.ext
clip-YYYYMMDD-HHMMSS-1m.ext
clip-YYYYMMDD-HHMMSS-5m.ext
```

Marker files look like:

```text
markers-YYYYMMDD.md
```

## Install

Rebuild or boot into the updated `nixstation` config so
`obs-replay-clip-helper` is on `PATH` and the Lua script is installed under the
system profile.

Use a staged build first:

```bash
nix flake check
sudo nixos-rebuild boot --flake .#nixstation
```

Do not run `nixos-rebuild switch` or `nixos-rebuild test` on `nixstation`
without explicit approval.

In OBS:

1. Back up the current OBS config:

   ```bash
   tar -C /home/chrisf/.config -czf "/home/chrisf/obs/obs-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz" obs-studio
   ```

2. Open `Tools` -> `Scripts`.
3. Add this Lua script:

   ```text
   /run/current-system/sw/share/obs-replay-clips/obs_replay_clipper.lua
   ```

4. Confirm the script settings:
   - Helper command: `obs-replay-clip-helper`
   - Clips directory: `/home/chrisf/obs/Clips`
   - Markers directory: `/home/chrisf/obs/Markers`
   - Logs directory: `/home/chrisf/obs/Logs`
5. Open `Settings` -> `Hotkeys`.
6. Assign keys for `Clip 30s`, `Clip 1m`, `Clip 5m`, and `Add marker`.

The script settings panel also has immediate buttons for `Clip 30s now`,
`Clip 1m now`, `Clip 5m now`, and `Add marker now`. These are useful for a live
event before hotkeys are assigned.

To disable it, remove the script in `Tools` -> `Scripts` and remove or unassign
the hotkeys.

## Test Plan

1. Confirm OBS is running.
2. Start OBS recording.
3. Start the OBS Replay Buffer.
4. Press `Clip 30s`; confirm a new file appears in `/home/chrisf/obs/Clips`.
5. Press `Clip 1m`; confirm a new file appears in `/home/chrisf/obs/Clips`.
6. Press `Clip 5m`; confirm a copied full replay appears in `/home/chrisf/obs/Clips`.
7. Press `Add marker`; confirm today's marker file is updated in `/home/chrisf/obs/Markers`.
8. Play generated clips with `mpv` or `vlc`.
9. Confirm the full recording in `/home/chrisf/obs` continues and remains intact.
10. Check logs in `/home/chrisf/obs/Logs` if anything fails.

## Manual Helper Checks

Create a marker without OBS:

```bash
obs-replay-clip-helper marker \
  --markers-dir /home/chrisf/obs/Markers \
  --logs-dir /home/chrisf/obs/Logs \
  --note "Manual marker test"
```

Trim a known replay file:

```bash
obs-replay-clip-helper clip \
  --duration 30 \
  --replay-file "/path/to/replay.mkv" \
  --clips-dir /home/chrisf/obs/Clips \
  --logs-dir /home/chrisf/obs/Logs
```

Copy a full 5-minute replay:

```bash
obs-replay-clip-helper clip \
  --duration 300 \
  --copy \
  --replay-file "/path/to/replay.mkv" \
  --clips-dir /home/chrisf/obs/Clips \
  --logs-dir /home/chrisf/obs/Logs
```

## Notes

- `ffmpeg -sseof -30 -c copy` is fast and avoids generation loss. With stream
  copy, exact frame accuracy is not guaranteed because video usually has to start
  near a keyframe. That is acceptable for live clipping and avoids re-encoding.
- If exact frame starts become important later, add an optional re-encode mode
  for short clips.
- The helper never overwrites existing clips. If a timestamp collides, it appends
  `-01`, `-02`, and so on.

## References

- OBS scripting API: https://docs.obsproject.com/scripting
- OBS frontend API: https://docs.obsproject.com/reference-frontend-api
- OBS WebSocket protocol: https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md
- FFmpeg seek options: https://ffmpeg.org/ffmpeg.html
- Replay Buffer Pro behavior reference: https://joshuapotter.github.io/replay-buffer-pro/
- StreamUP Chapter Marker Manager platform/reference notes: https://obsproject.com/forum/resources/streamup-chapter-marker-manager.1962/
