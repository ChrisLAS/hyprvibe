{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  user = config.hyprvibe.user;
  package = config.programs.hex.package;
  supportDir = "${user.home}/.local/share/hex";
  sessionTarget = "nixos-fake-graphical-session.target";
  settings = (pkgs.formats.json {}).generate "hex-shortcuts.json" {
    dictation_hotkey = "f8";
    shortcut_mode = "hold";
    "capture.enabled" = true;
    "capture.hotkey" = "f9";
  };
  waitForSession = pkgs.writeShellApplication {
    name = "hex-wait-for-session";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.xprop
    ];
    text = builtins.readFile (inputs.hex + "/nix/wait-for-session.sh");
  };
  prepare = pkgs.writeShellApplication {
    name = "hex-prepare";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep];
    text = ''
      # A source-run launcher otherwise shadows the system desktop entry.
      entry=${lib.escapeShellArg "${user.home}/.local/share/applications/anomaly.hex.desktop"}
      backup_dir=${lib.escapeShellArg "${supportDir}/migration-backups"}
      if [[ -f "$entry" && ! -L "$entry" ]] && grep -Fxq 'X-Hex-Managed=true' "$entry"; then
        mkdir -p "$backup_dir"
        mv --backup=numbered "$entry" "$backup_dir/anomaly.hex.desktop"
      fi
      exec ${lib.getExe package} settings apply ${settings}
    '';
  };
in {
  imports = [inputs.hex.nixosModules.hex];

  programs.hex.enable = true;

  # Match the upstream user service without introducing Home Manager.
  # This target starts after Hyprland imports the display environment.
  systemd.user.services.hex = {
    description = "Hex local voice dictation and Annotate";
    wantedBy = [sessionTarget];
    after = [sessionTarget];
    partOf = [sessionTarget];
    unitConfig.ConditionUser = user.name;
    environment.HEX_APPLICATION_SUPPORT_DIR = supportDir;
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "main";
      ExecStartPre = [
        (lib.getExe waitForSession)
        (lib.getExe prepare)
      ];
      ExecStart = "${lib.getExe package} service";
      EnvironmentFile = "-${supportDir}/session.env";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStartSec = 35;
      TimeoutStopSec = 30;
      UMask = "0077";
    };
  };
}
