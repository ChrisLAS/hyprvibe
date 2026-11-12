# ChatGPT font rendering on review-xps14

2026-11-12: The running ChatGPT window reports `xwayland: true`; eDP-1
is 2880x1800 at scale 1.5. Its renderer arguments select `--ozone-platform=x11`
despite the session's `NIXOS_OZONE_WL=1`. Fontconfig resolves installed fonts.

Updated `pkgs/chatgpt-desktop.nix` to pass `--ozone-platform=wayland` when
WAYLAND_DISPLAY is set, preserving X11 sessions and user arguments.
`nix build .#chatgpt-desktop --no-link --print-out-paths` and
`git diff --check` passed. No system activation or app restart performed.

Follow-up: fully quit ChatGPT and run `nix run .#chatgpt-desktop` from this
checkout, then confirm sharp text and `xwayland: false` in `hyprctl clients -j`.
The system launcher picks up the fix on the next system update.
Native Wayland is experimental; an explicit `--ozone-platform=x11` argument
remains available for compatibility.

Reference: https://learn.chatgpt.com/docs/linux/linux-app#wayland-support

Beads CLI (`bd`) is unavailable on this install, so issue database updates
and `bd dolt pull`/`bd dolt push` could not run. Recorded follow-up here for
the next session with Beads installed.
