{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.hyprvibe.user;
  wallpaper = "/home/chrisf/Pictures/bkgrounds/vaderhole.jpg";

  barConfig = {
    id = "default";
    name = "Nixvader";
    enabled = true;
    position = 0;
    screenPreferences = [ "all" ];
    showOnLastDisplay = true;
    leftWidgets = [
      "launcherButton"
      "workspaceSwitcher"
      "focusedWindow"
    ];
    centerWidgets = [
      "music"
      "clock"
    ];
    rightWidgets = [
      "idleInhibitor"
      "cpuUsage"
      "memUsage"
      "nixvaderCodex"
      "nixvaderWorldClock"
      "systemTray"
      "notificationButton"
      "battery"
      "controlCenterButton"
    ];
    spacing = 6;
    innerPadding = 6;
    bottomGap = 8;
    transparency = 0.88;
    widgetTransparency = 0.78;
    squareCorners = false;
    noBackground = false;
    maximizeWidgetIcons = false;
    maximizeWidgetText = false;
    removeWidgetPadding = false;
    widgetPadding = 8;
    gothCornersEnabled = false;
    gothCornerRadiusOverride = true;
    gothCornerRadiusValue = 14;
    borderEnabled = true;
    borderColor = "primary";
    borderOpacity = 0.35;
    borderThickness = 1;
    widgetOutlineEnabled = true;
    widgetOutlineColor = "primary";
    widgetOutlineOpacity = 0.18;
    widgetOutlineThickness = 1;
    fontScale = 1.0;
    iconScale = 1.0;
    autoHide = false;
    autoHideStrict = false;
    autoHideDelay = 250;
    showOnWindowsOpen = false;
    openOnOverview = false;
    visible = true;
    popupGapsAuto = true;
    popupGapsManual = 6;
    maximizeDetection = true;
    useOverlayLayer = false;
    scrollEnabled = true;
    scrollXBehavior = "column";
    scrollYBehavior = "workspace";
    shadowIntensity = 8;
    shadowOpacity = 55;
    shadowColorMode = "default";
    shadowCustomColor = "#000000";
    clickThrough = false;
    hoverPopouts = false;
    hoverPopoutDelay = 150;
  };

  settingsSeed = pkgs.writeText "nixvader-dms-settings.json" (
    builtins.toJSON {
      currentThemeName = "dynamic";
      matugenScheme = "scheme-tonal-spot";
      clockFormat = "12h";
      showSeconds = false;
      showDock = false;
      blurEnabled = true;
      cornerRadius = 14;
      soundsEnabled = false;
      controlCenterShowNetworkIcon = true;
      controlCenterShowBluetoothIcon = true;
      controlCenterShowAudioIcon = true;
      controlCenterShowAudioPercent = true;
      controlCenterShowBrightnessIcon = true;
      controlCenterShowBrightnessPercent = true;
      lockBeforeSuspend = true;
      loginctlLockIntegration = true;
      acLockTimeout = 0;
      acSuspendTimeout = 0;
      batteryLockTimeout = 0;
      batterySuspendTimeout = 0;
      barConfigs = [ barConfig ];
    }
  );

  sessionSeed = pkgs.writeText "nixvader-dms-session.json" (
    builtins.toJSON {
      wallpaperPath = wallpaper;
      wallpaperPathDark = wallpaper;
      wallpaperPathLight = wallpaper;
    }
  );

  pluginSeed = pkgs.writeText "nixvader-dms-plugin-settings.json" (
    builtins.toJSON {
      nixvaderCodex.enabled = true;
      nixvaderWorldClock.enabled = true;
    }
  );
in
{
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
      nixvaderCodex.src = ./dms-plugins/nixvaderCodex;
      nixvaderWorldClock.src = ./dms-plugins/nixvaderWorldClock;
    };
  };

  programs.dank-calendar = {
    enable = true;
    systemd = {
      enable = true;
      target = "nixos-fake-graphical-session.target";
      restartIfChanged = true;
    };
  };

  systemd.user.services.hyprvibe-setup-dms = {
    description = "Nixvader: seed DankMaterialShell user settings";
    unitConfig.ConditionUser = user.name;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "hyprvibe-setup-dms" ''
        set -euo pipefail
        config_dir=${lib.escapeShellArg user.home}/.config/DankMaterialShell
        state_dir=${lib.escapeShellArg user.home}/.local/state/DankMaterialShell
        migration_dir=${lib.escapeShellArg user.home}/.config/nixvader
        marker="$migration_dir/dms-plugins-v1"
        mkdir -p "$config_dir" "$state_dir" "$migration_dir"

        if [ ! -e "$config_dir/settings.json" ]; then
          install -m0644 ${settingsSeed} "$config_dir/settings.json"
        fi
        if [ ! -e "$state_dir/session.json" ]; then
          install -m0644 ${sessionSeed} "$state_dir/session.json"
        fi

        if [ ! -e "$marker" ]; then
          if [ -e "$config_dir/plugin_settings.json" ]; then
            tmp="$(${pkgs.coreutils}/bin/mktemp "$config_dir/plugin_settings.json.XXXXXX")"
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$config_dir/plugin_settings.json" ${pluginSeed} > "$tmp"
            chmod 0644 "$tmp"
            mv "$tmp" "$config_dir/plugin_settings.json"
          else
            install -m0644 ${pluginSeed} "$config_dir/plugin_settings.json"
          fi
          touch "$marker"
        fi
      '';
    };
  };

  systemd.user.services.dms = {
    after = [ "hyprvibe-setup-dms.service" ];
    requires = [ "hyprvibe-setup-dms.service" ];
  };
}
