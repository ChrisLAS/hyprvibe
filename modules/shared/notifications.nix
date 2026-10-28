{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hyprvibe.notifications;
  user = config.hyprvibe.user;
  hokum = pkgs.callPackage ../../pkgs/hokum.nix {};
in {
  options.hyprvibe.notifications.enable = lib.mkOption {
    type = lib.types.bool;
    default = config.hyprvibe.hyprland.enable;
    description = "Use Hokum as the sole Hyprvibe desktop notification server.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [hokum pkgs.libnotify];
    services.dbus.packages = [hokum];
    hyprvibe.packages.dunst.enable = lib.mkForce false;

    # Mask even old user-unit enablement links; no competing D-Bus server.
    systemd.user.services =
      lib.genAttrs [
        "dunst"
        "mako"
        "swaync"
        "hyprvibe-legacy-swaync"
        "nixvader-legacy-swaync"
      ] (_: {enable = false;})
      // {
        hyprvibe-setup-hokum = {
          description = "Hyprvibe: seed writable Hokum settings";
          unitConfig.ConditionUser = user.name;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "hyprvibe-setup-hokum" ''
              set -eu
              directory=${lib.escapeShellArg user.home}/.config/hokum
              ${pkgs.coreutils}/bin/mkdir -p "$directory"
              if [ ! -e "$directory/config.kdl" ]; then
                ${pkgs.coreutils}/bin/install -m0644 ${../../configs/hokum/config.kdl} "$directory/config.kdl"
              fi
            '';
          };
        };
        hokum = {
          description = "Hokum desktop notification daemon";
          documentation = ["https://hokum.app"];
          wantedBy = ["nixos-fake-graphical-session.target"];
          partOf = ["nixos-fake-graphical-session.target"];
          after = ["nixos-fake-graphical-session.target" "hyprvibe-setup-hokum.service"];
          requires = ["hyprvibe-setup-hokum.service"];
          conflicts = ["dunst.service" "mako.service" "swaync.service"];
          unitConfig = {
            ConditionUser = user.name;
            StartLimitIntervalSec = 60;
            StartLimitBurst = 5;
          };
          serviceConfig = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecCondition = "${pkgs.runtimeShell} -c 'test -n \"$WAYLAND_DISPLAY\"'";
            ExecStart = "${hokum}/bin/hokum service";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      };
  };
}
