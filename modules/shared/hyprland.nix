{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hyprvibe.hyprland;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
  defaultMain = ../../configs/hyprland-default.lua;
  defaultPaper = ../../configs/hyprpaper-default.conf;
  defaultLock = ../../configs/hyprlock-default.conf;
  defaultIdle = ../../configs/hypridle-default.conf;
  defaultWallpaper = ../../wallpapers/aishot-2602.jpg;
  mainConfig = if cfg.mainConfig != null then cfg.mainConfig else defaultMain;
  localConfig = pkgs.writeText "hyprland-local.lua" (
    lib.optionalString (cfg.monitorsFile != null) ''
      require("hyprland-monitors")
    ''
    + lib.optionalString cfg.amd.enable ''
      -- AMD-specific overrides (opt-in)
      hl.env("AMD_VULKAN_ICD", "RADV")
      hl.env("MESA_LOADER_DRIVER_OVERRIDE", "radeonsi")
    ''
  );
  hyprlandConfigDir = pkgs.runCommand "hyprvibe-hyprland-config" { } ''
    mkdir -p "$out"
    cp ${mainConfig} "$out/hyprland.lua"
    cp ${../../configs/hyprland-base.lua} "$out/hyprland-base.lua"
    cp ${localConfig} "$out/hyprland-local.lua"
    ${lib.optionalString (cfg.monitorsFile != null) ''
      cp ${cfg.monitorsFile} "$out/hyprland-monitors.lua"
    ''}
  '';
in
{
  options.hyprvibe.hyprland = {
    enable = lib.mkEnableOption "Hyprland base setup";
    waybar.enable = lib.mkEnableOption "Waybar autostart integration";
    shellBackend = lib.mkOption {
      type = lib.types.enum [
        "legacy"
        "dms"
      ];
      default = "legacy";
      description = "Desktop shell started with Hyprland. The legacy backend uses Waybar and SwayNC; dms uses DankMaterialShell.";
    };
    monitorsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Per-host Hyprland Lua monitor configuration path";
    };
    mainConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to host's hyprland.lua";
    };
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper file path for hyprpaper/hyprlock generation";
    };
    hyprpaperTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprpaper.conf with __WALLPAPER__ placeholder";
    };
    wallpaperOutputs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "DEPRECATED: No longer used. Monitor outputs are now defined directly in hyprpaper.conf templates using 0.8.0+ block syntax.";
    };
    wallpaperBackend = lib.mkOption {
      type = lib.types.enum [
        "hyprpaper"
        "swaybg"
      ];
      default = "hyprpaper";
      description = "Wallpaper backend to use. hyprpaper is preferred; swaybg is a reliable fallback.";
    };
    hyprlockTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprlock.conf with __WALLPAPER__ placeholder";
    };
    hypridleConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to hypridle.conf to install";
    };
    scriptsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Directory of Hyprland helper scripts to copy and chmod +x";
    };
    amd.enable = lib.mkEnableOption "Enable AMD-specific OpenGL/Vulkan env overrides";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Load the complete immutable composition directly. The home-directory
    # links below are for inspection and editing convenience, not startup.
    environment.sessionVariables = {
      HYPRLAND_CONFIG = "${hyprlandConfigDir}/hyprland.lua";
      HYPRVIBE_SHELL_BACKEND = cfg.shellBackend;
    };

    # Install base config; fall back to shared defaults where host options are not provided
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      set -u  # Fail on undefined variables, but allow commands to fail
      trap 'echo "[hyprvibe][hyprland] WARNING at line $LINENO - continuing anyway"' ERR
      echo "[hyprvibe][hyprland] starting activation"
      install -d -m0755 -o ${userName} -g ${userGroup} ${userHome}/.config/hypr
      # Wallpaper-backed configs
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${
        if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper
      }#g" ${
        if cfg.hyprpaperTemplate != null then cfg.hyprpaperTemplate else defaultPaper
      } > ${userHome}/.config/hypr/hyprpaper.conf
      echo "[hyprvibe][hyprland] rendered hyprpaper.conf"
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${
        if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper
      }#g" ${
        if cfg.hyprlockTemplate != null then cfg.hyprlockTemplate else defaultLock
      } > ${userHome}/.config/hypr/hyprlock.conf
      echo "[hyprvibe][hyprland] rendered hyprlock.conf"
      # Idle config
      rm -f ${userHome}/.config/hypr/hypridle.conf
      ln -sf ${
        if cfg.hypridleConfig != null then cfg.hypridleConfig else defaultIdle
      } ${userHome}/.config/hypr/hypridle.conf
      echo "[hyprvibe][hyprland] linked hypridle.conf"
      ${lib.optionalString (cfg.scriptsDir != null) ''
        mkdir -p ${userHome}/.config/hypr/scripts
        # Copy scripts but skip if source and dest are the same (handles symlinked nix store paths)
        for script in ${cfg.scriptsDir}/*; do
          if [ -f "$script" ]; then
            dest_file="${userHome}/.config/hypr/scripts/$(basename "$script")"
            # Check if source and destination resolve to the same file (handles symlinks)
            script_real=$(readlink -f "$script" 2>/dev/null || echo "$script")
            dest_real=$(readlink -f "$dest_file" 2>/dev/null || echo "$dest_file")
            if [ "$script_real" != "$dest_real" ]; then
              # Use cp --remove-destination to handle symlinks properly.
              cp --remove-destination -f "$script" "$dest_file"
            fi
          fi
        done
        chmod +x ${userHome}/.config/hypr/scripts/* 2>/dev/null || true
        echo "[hyprvibe][hyprland] installed scripts from ${cfg.scriptsDir}"
      ''}
      # Fix ownership without following symlinks (prevents hangs on broken symlinks)
      # Only chown regular files/directories, not symlinks
      # Use find with -print0 and xargs for better error handling, or fallback to simple chown if find fails
      if [ -d ${userHome}/.config/hypr ]; then
        chown ${userName}:${userGroup} ${userHome}/.config/hypr
        find ${userHome}/.config/hypr -mindepth 1 -maxdepth 1 -not -type l -print0 2>/dev/null | xargs -0 -r chown -R ${userName}:${userGroup} 2>/dev/null || true
        # Fix ownership of symlinks themselves (not their targets)
        find ${userHome}/.config/hypr -mindepth 1 -maxdepth 1 -type l -print0 2>/dev/null | xargs -0 -r chown -h ${userName}:${userGroup} 2>/dev/null || true
      fi
      echo "[hyprvibe][hyprland] ownership fixed; activation complete"
    '';
    # Start hyprpaper via systemd so it runs *after* hyprvibe has generated
    # ~/.config/hypr/hyprpaper.conf. This avoids race conditions with Hyprland
    # exec-once during session startup and makes debugging easy via journalctl.
    systemd.user.services.hyprvibe-hyprpaper = lib.mkIf (cfg.wallpaperBackend == "hyprpaper") {
      description = "Hyprvibe: hyprpaper wallpaper daemon";
      unitConfig.ConditionUser = userName;
      after = [ "hyprvibe-setup-hyprland.service" ];
      wants = [ "hyprvibe-setup-hyprland.service" ];
      wantedBy = lib.optionals (cfg.shellBackend == "legacy") [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "hyprvibe-start-hyprpaper" ''
          set -euo pipefail

          # Hyprpaper is sensitive to starting before Hyprland/Wayland are ready.
          # On some versions it can segfault if started too early. We wait for:
          # - a wayland socket (WAYLAND_DISPLAY)
          # - the Hyprland instance socket (.socket2.sock)
          #
          # Then we export the env vars Hyprpaper expects and exec it.
          RUNDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

          pick_wayland_display() {
            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              echo "''${WAYLAND_DISPLAY}"
              return 0
            fi
            local sock
            sock="$(ls -1 "$RUNDIR"/wayland-* 2>/dev/null | head -n1 || true)"
            [ -n "$sock" ] || return 1
            basename "$sock"
          }

          pick_hypr_signature() {
            if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
              echo "''${HYPRLAND_INSTANCE_SIGNATURE}"
              return 0
            fi
            local d
            d="$(ls -1d "$RUNDIR"/hypr/* 2>/dev/null | head -n1 || true)"
            [ -n "$d" ] || return 1
            basename "$d"
          }

          # Wait up to ~10s for session readiness.
          for _ in $(seq 1 100); do
            wl="$(pick_wayland_display || true)"
            sig="$(pick_hypr_signature || true)"
            if [ -n "$wl" ] && [ -n "$sig" ] && [ -S "$RUNDIR/hypr/$sig/.socket2.sock" ]; then
              export XDG_RUNTIME_DIR="$RUNDIR"
              export WAYLAND_DISPLAY="$wl"
              export HYPRLAND_INSTANCE_SIGNATURE="$sig"
              exec ${pkgs.hyprpaper}/bin/hyprpaper --config ${userHome}/.config/hypr/hyprpaper.conf
            fi
            sleep 0.1
          done

          echo "[hyprvibe][hyprpaper] timeout waiting for Hyprland/Wayland readiness" >&2
          exit 1
        ''}";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # Fallback wallpaper backend that doesn't depend on hyprpaper's IPC/config semantics.
    systemd.user.services.hyprvibe-swaybg = lib.mkIf (cfg.wallpaperBackend == "swaybg") {
      description = "Hyprvibe: swaybg wallpaper";
      unitConfig.ConditionUser = userName;
      after = [ "hyprvibe-setup-hyprland.service" ];
      wants = [ "hyprvibe-setup-hyprland.service" ];
      wantedBy = lib.optionals (cfg.shellBackend == "legacy") [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "hyprvibe-start-swaybg" ''
          set -euo pipefail

          rundir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

          pick_wayland_display() {
            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              echo "''${WAYLAND_DISPLAY}"
              return 0
            fi
            local sock
            sock="$(ls -1 "$rundir"/wayland-* 2>/dev/null | head -n1 || true)"
            [ -n "$sock" ] || return 1
            basename "$sock"
          }

          for _ in $(seq 1 100); do
            wl="$(pick_wayland_display || true)"
            if [ -n "$wl" ] && [ -S "$rundir/$wl" ]; then
              export XDG_RUNTIME_DIR="$rundir"
              export WAYLAND_DISPLAY="$wl"
              exec ${pkgs.swaybg}/bin/swaybg -i ${
                if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper
              } -m fill
            fi
            sleep 0.1
          done

          echo "[hyprvibe][swaybg] timeout waiting for Wayland readiness" >&2
          exit 1
        '';
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # Move setup to systemd --user oneshot to avoid blocking stage-2
    systemd.user.services.hyprvibe-setup-hyprland = {
      description = "Hyprvibe: setup Hyprland configs in user home";
      unitConfig.ConditionUser = userName;
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-hyprland" ''
          set -euo pipefail
          echo "[hyprvibe][hyprland] starting user setup"
          mkdir -p ${userHome}/.config/hypr
          rm -f ${userHome}/.config/hypr/hyprland.conf
          rm -f ${userHome}/.config/hypr/hyprland-base.conf
          rm -f ${userHome}/.config/hypr/hyprland-local.conf
          rm -f ${userHome}/.config/hypr/hyprland.lua
          rm -f ${userHome}/.config/hypr/hyprland-base.lua
          rm -f ${userHome}/.config/hypr/hyprland-local.lua
          rm -f ${userHome}/.config/hypr/hyprland-monitors.lua
          ln -sf ${hyprlandConfigDir}/hyprland.lua ${userHome}/.config/hypr/hyprland.lua
          ln -sf ${hyprlandConfigDir}/hyprland-base.lua ${userHome}/.config/hypr/hyprland-base.lua
          ln -sf ${hyprlandConfigDir}/hyprland-local.lua ${userHome}/.config/hypr/hyprland-local.lua
          ${lib.optionalString (cfg.monitorsFile != null) ''
            ln -sf ${hyprlandConfigDir}/hyprland-monitors.lua ${userHome}/.config/hypr/hyprland-monitors.lua
          ''}
          # Ensure files are writable (previous generations may have left them read-only)
          rm -f ${userHome}/.config/hypr/hyprpaper.conf ${userHome}/.config/hypr/hyprlock.conf
          # Render wallpaper path into hyprpaper config (templates use 0.8.0+ block syntax with monitors defined inline)
          ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${
            if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper
          }#g" ${
            if cfg.hyprpaperTemplate != null then cfg.hyprpaperTemplate else defaultPaper
          } > ${userHome}/.config/hypr/hyprpaper.conf
          ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${
            if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper
          }#g" ${
            if cfg.hyprlockTemplate != null then cfg.hyprlockTemplate else defaultLock
          } > ${userHome}/.config/hypr/hyprlock.conf
          rm -f ${userHome}/.config/hypr/hypridle.conf
          ln -sf ${
            if cfg.hypridleConfig != null then cfg.hypridleConfig else defaultIdle
          } ${userHome}/.config/hypr/hypridle.conf
          ${lib.optionalString (cfg.scriptsDir != null) ''
            mkdir -p ${userHome}/.config/hypr/scripts
            cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/hypr/scripts/ 2>/dev/null || true
            chmod +x ${userHome}/.config/hypr/scripts/*.sh 2>/dev/null || true
          ''}
          echo "[hyprvibe][hyprland] user setup complete"
        '';
      };
    };
  };
}
