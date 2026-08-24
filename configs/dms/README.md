# Shared DankMaterialShell profile

The JSON files in this directory are the portable DMS preferences shared by
nixvader and nixstation. Nix composes them with each host's bar targets and
wallpaper; raw `~/.config/DankMaterialShell` files are deliberately not synced.

After changing DMS through its UI, preview the portable changes from the
hyprvibe repository:

```bash
hyprvibe-dms-config diff
```

Promote them into Git with:

```bash
hyprvibe-dms-config export
```

The export only updates keys already present in `portable-settings.json`, the
selected host's full bar template, and settings for the tracked plugins. It
does not export connector names, display profiles, wallpapers, widget
coordinates, hardware/security settings, history, or cache state.

Host-specific bars and wallpapers live in `hosts/<host>/dms.nix`. To share a
new DMS setting, first add that key and its desired value to
`portable-settings.json`; subsequent exports will include it.

The setup service keeps timestamped JSON backups before applying a changed
profile. User-installed copies of Nix-managed plugins are moved to
`~/.config/DankMaterialShell/plugin-source-backups/` so the pinned system copy
is authoritative and recoverable.
