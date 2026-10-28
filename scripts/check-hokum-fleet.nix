# nix eval --impure --json --expr 'import ./scripts/check-hokum-fleet.nix { flake = builtins.getFlake (toString ./.); }'
{flake}: let
  lib = flake.inputs.nixpkgs.lib;
  oldServers = ["dunst" "mako" "swaynotificationcenter"];
  masks = ["dunst" "mako" "swaync" "hyprvibe-legacy-swaync" "nixvader-legacy-swaync"];
in
  lib.mapAttrs (name: host: let
    c = host.config;
    packages = map lib.getName c.environment.systemPackages;
    unit = c.systemd.user.services.hokum;
    dms = c.hyprvibe.dms.enable;
    bars =
      if dms
      then c.hyprvibe.dms.barConfigs
      else [];
    widgets = lib.concatMap (bar: (bar.leftWidgets or []) ++ (bar.centerWidgets or []) ++ (bar.rightWidgets or [])) bars;
  in
    assert c.hyprvibe.notifications.enable;
    assert !c.hyprvibe.packages.dunst.enable;
    assert builtins.elem "hokum" packages;
    assert lib.intersectLists oldServers packages == [];
    assert lib.all (name: !c.systemd.user.services.${name}.enable) masks;
    assert unit.serviceConfig.Type == "dbus";
    assert unit.serviceConfig.BusName == "org.freedesktop.Notifications";
    assert builtins.elem "nixos-fake-graphical-session.target" unit.wantedBy;
    assert builtins.elem "nixos-fake-graphical-session.target" unit.partOf;
    assert builtins.elem "hyprvibe-setup-hokum.service" unit.requires;
    assert lib.all (a: a.assertion) c.assertions;
    assert !dms || (builtins.elem "hokum" widgets && !(builtins.elem "notificationButton" widgets)); {
      inherit dms;
      package = "hokum 0.1.1";
      oldServers = lib.intersectLists oldServers packages;
      maskedServices = masks;
      toplevel = c.system.build.toplevel.drvPath;
    })
  flake.nixosConfigurations
