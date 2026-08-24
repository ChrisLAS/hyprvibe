{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hyprvibe.dms;
  user = config.hyprvibe.user;
  portableSettings = builtins.fromJSON (builtins.readFile cfg.settingsProfile);
  portablePluginSettings = builtins.fromJSON (builtins.readFile cfg.pluginSettingsProfile);
  composedSettings = lib.recursiveUpdate portableSettings { barConfigs = cfg.barConfigs; };
  composedPluginSettings = lib.recursiveUpdate portablePluginSettings cfg.pluginSettingsOverrides;
  settingsSeed = pkgs.writeText "hyprvibe-dms-settings.json" (builtins.toJSON composedSettings);
  pluginSeed = pkgs.writeText "hyprvibe-dms-plugin-settings.json" (
    builtins.toJSON composedPluginSettings
  );
  sessionSeed = pkgs.writeText "hyprvibe-dms-session.json" (
    builtins.toJSON {
      wallpaperPath = cfg.wallpaper;
      wallpaperPathDark = cfg.wallpaper;
      wallpaperPathLight = cfg.wallpaper;
    }
  );
  profileHash = builtins.hashString "sha256" (
    builtins.toJSON {
      settings = composedSettings;
      plugins = composedPluginSettings;
      wallpaper = cfg.wallpaper;
    }
  );
  dmsConfigTool = pkgs.writeShellApplication {
    name = "hyprvibe-dms-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
      pkgs.git
      pkgs.jq
    ];
    text = ''
      export HYPRVIBE_DMS_EXPORT_BAR_ID=${lib.escapeShellArg cfg.exportBarId}
      exec ${../../scripts/hyprvibe-dms-config.sh} "$@"
    '';
  };
  shellTool = pkgs.writeShellApplication {
    name = "hyprvibe-shell";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      pkgs.systemd
    ];
    text = ''
      start_unit() {
        local unit="$1"
        shift
        systemctl --user stop "$unit.service" >/dev/null 2>&1 || true
        systemd-run --user --unit="$unit" --collect --property=Restart=on-failure -- "$@" >/dev/null
      }

      case "''${1:-status}" in
        dms)
          systemctl --user stop 'hyprvibe-legacy-*' >/dev/null 2>&1 || true
          pkill -x waybar 2>/dev/null || true
          pkill -x swaync 2>/dev/null || true
          systemctl --user stop hyprvibe-hyprpaper.service >/dev/null 2>&1 || true
          systemctl --user restart dms.service
          ;;
        legacy)
          systemctl --user stop dms.service >/dev/null 2>&1 || true
          systemctl --user start hyprvibe-hyprpaper.service >/dev/null 2>&1 || true
          start_unit hyprvibe-legacy-swaync ${pkgs.swaynotificationcenter}/bin/swaync
          start_unit hyprvibe-legacy-hypridle ${pkgs.hypridle}/bin/hypridle
          systemctl --user stop hyprvibe-legacy-waybar.service >/dev/null 2>&1 || true
          systemd-run --user --unit=hyprvibe-legacy-waybar --collect --property=Restart=on-failure -- \
            ${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg cfg.legacyWaybarCommand} >/dev/null
          ;;
        status)
          systemctl --user --no-pager --full status dms.service || true
          ;;
        *)
          echo "Usage: hyprvibe-shell {dms|legacy|status}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.hyprvibe.dms = {
    enable = lib.mkEnableOption "DankMaterialShell desktop shell profile";
    settingsProfile = lib.mkOption {
      type = lib.types.path;
      default = ../../configs/dms/portable-settings.json;
      description = "Portable DMS settings promoted through Git.";
    };
    pluginSettingsProfile = lib.mkOption {
      type = lib.types.path;
      default = ../../configs/dms/plugin-settings.json;
      description = "Portable DMS plugin settings promoted through Git.";
    };
    barConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Host-specific DMS bar configurations.";
    };
    wallpaper = lib.mkOption {
      type = lib.types.str;
      description = "Host-specific DMS wallpaper path.";
    };
    pluginSettingsOverrides = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Host-specific recursive overrides for plugin settings.";
    };
    exportBarId = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Full bar ID exported by hyprvibe-dms-config.";
    };
    legacyWaybarCommand = lib.mkOption {
      type = lib.types.str;
      default = "exec waybar";
      description = "Foreground shell command used by the legacy Waybar fallback.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dms-shell = {
      enable = true;
      systemd = {
        enable = true;
        target = "nixos-fake-graphical-session.target";
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = true;
      enableClipboardPaste = true;
      plugins = {
        nixvaderCodex.src = ../../configs/dms/plugins/nixvaderCodex;
        nixvaderWorldClock.src = ../../configs/dms/plugins/nixvaderWorldClock;
        markets.src = pkgs.fetchFromGitHub {
          owner = "TMS-Namespace";
          repo = "DMS-Markets-Plugin";
          rev = "1398805cd9ac425ebe742e473c1a42d6ee35f730";
          sha256 = "1zwpfv63s0cb7pks89fmaw9pzpw19rpb8b0iafz0dddcfq4r4b5z";
        };
        wallpaperCarousel.src = pkgs.fetchFromGitHub {
          owner = "motor-dev";
          repo = "wallpaperCarousel";
          rev = "761ecd1b7f347beee9f17909f8334d987c935a1a";
          sha256 = "0whjnaz8jmwh4dcq90z181wg3ypwwnif7w45h2jflyfj6y2ixfpw";
        };
        quickCapture.src = pkgs.fetchFromGitHub {
          owner = "hthienloc";
          repo = "dms-quick-capture";
          rev = "8e923d1604fd860007f0d5a3a3088011f253f2c1";
          sha256 = "12v2lhv7hrlci238i5l0qckqcblqn9z97938pgl1h5jn6qia5900";
        };
        batteryPlus.src = pkgs.fetchFromGitHub {
          owner = "arcatva";
          repo = "dms-battery-plus";
          rev = "4e653d09174e1edc260f279c42ec2477b6fb2e24";
          sha256 = "11h1y8qgadnsx2a404v43fv8jx0xvqh59blzwzn365dc72fjyh2w";
        };
      };
    };

    environment.systemPackages = [
      dmsConfigTool
      shellTool
    ];

    systemd.user.services.hyprvibe-setup-dms = {
      description = "Hyprvibe: merge the tracked DMS profile";
      unitConfig.ConditionUser = user.name;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-dms" ''
          set -euo pipefail
          config_dir=${lib.escapeShellArg user.home}/.config/DankMaterialShell
          state_dir=${lib.escapeShellArg user.home}/.local/state/DankMaterialShell
          migration_dir=${lib.escapeShellArg user.home}/.config/hyprvibe
          marker="$migration_dir/dms-profile-v2"
          mkdir -p "$config_dir" "$state_dir" "$migration_dir"

          merge_json() {
            local destination="$1" seed="$2"
            if [ -e "$destination" ]; then
              cp -p "$destination" "$destination.backup.$(${pkgs.coreutils}/bin/date +%s)"
              tmp="$(${pkgs.coreutils}/bin/mktemp "$destination.XXXXXX")"
              ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$destination" "$seed" > "$tmp"
              chmod 0644 "$tmp"
              mv "$tmp" "$destination"
            else
              install -m0644 "$seed" "$destination"
            fi
          }

          current_hash="$(cat "$marker" 2>/dev/null || true)"
          if [ "$current_hash" != ${lib.escapeShellArg profileHash} ] \
            || [ ! -e "$config_dir/settings.json" ] \
            || [ ! -e "$config_dir/plugin_settings.json" ] \
            || [ ! -e "$state_dir/session.json" ]; then
            plugin_backup_dir=""
            for plugin_id in markets wallpaperCarousel quickCapture batteryPlus nixvaderCodex nixvaderWorldClock; do
              plugin_dir="$config_dir/plugins/$plugin_id"
              if [ -e "$plugin_dir" ] && [ ! -L "$plugin_dir" ]; then
                if [ -z "$plugin_backup_dir" ]; then
                  plugin_backup_dir="$config_dir/plugin-source-backups/$(${pkgs.coreutils}/bin/date +%s)"
                  mkdir -p "$plugin_backup_dir"
                fi
                mv "$plugin_dir" "$plugin_backup_dir/$plugin_id"
              fi
            done
            merge_json "$config_dir/settings.json" ${settingsSeed}
            merge_json "$config_dir/plugin_settings.json" ${pluginSeed}
            merge_json "$state_dir/session.json" ${sessionSeed}
            printf '%s\n' ${lib.escapeShellArg profileHash} > "$marker"
          fi
        '';
      };
    };

    systemd.user.services.dms = {
      after = [ "hyprvibe-setup-dms.service" ];
      requires = [ "hyprvibe-setup-dms.service" ];
    };
  };
}
