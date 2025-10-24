Wallpapers
===========

Place shared wallpapers for all hosts here. Recommended usage:

- Add your image file into this directory and commit it to the repo.
- Point each host's `wallpaperPath` to this file using a Nix path literal, e.g.:
  - In `hosts/<host>/system.nix`:
    - `wallpaperPath = ../../wallpapers/aishot-2602.jpg;`
  - This embeds the image into the Nix store and makes it available on all hosts when they build.

Notes
- Hyprpaper and Hyprlock configs are rendered during activation with this path, so both desktop and lock screen use the same image.
- Update the file name here to change wallpapers across systems in one commit.
- If you want per-host wallpapers, keep different files in this folder and reference the desired one per host.


