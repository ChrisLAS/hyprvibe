# Read-only audit metadata. Does not execute activation or reveal service envs.
# Example:
# nix eval --impure --json --no-update-lock-file --no-write-lock-file --expr \
#   'import ./scripts/audit-activation.nix { flake = builtins.getFlake ("git+file://" + toString ./.); }'
# customActivation classifies the definitions reviewed in the 2026-10-31 audit;
# activationNames/activationDefinitionFiles must also be reviewed for new entries.
{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  names = [
    "waybar" "hyprlandBase" "setUserIcon" "installPowerProfileScript"
    "nixstationAccountsServiceSession" "nixstationLauncherEntries"
    "nixstationDisableMaestralAutostart" "lore-bootstrap" "openclaw-token-gen"
    "openclaw-tailscale-serve-setup" "openclaw-gateway-config"
    "openclaw-loop-runner-sync" "openclaw-sudo-wrapper-check" "openclaw-sudo-shim"
    "openclaw-memory-cognee-plugin-sync" "openclaw-bundled-plugins-sync"
    "openclaw-bundled-skills-sync" "openclaw-memory-cognee-policy"
    "openclaw-acpx-config" "openclaw-acp-config"
  ];
  unit = _: value: let s = value.serviceConfig; in {
    type = s.Type or "simple";
    timeoutStart = toString (s.TimeoutStartSec or "<unset>");
    timeoutStop = toString (s.TimeoutStopSec or "<unset>");
    inherit (value) after before wants requires wantedBy requiredBy partOf;
    remainAfterExit = s.RemainAfterExit or false;
    defaultDependencies = value.unitConfig.DefaultDependencies or "<default>";
    conditionUser = value.unitConfig.ConditionUser or null;
    hasExecCondition = s ? ExecCondition;
    restartIfChanged = value.restartIfChanged;
    restartTriggerCount = builtins.length value.restartTriggers;
  };
in lib.mapAttrs (host: evaluated: let
  c = evaluated.config;
  o = evaluated.options;
  snippets = lib.filterAttrs (name: _: builtins.elem name names) c.system.activationScripts;
  setup = lib.filterAttrs (name: _: lib.hasPrefix "hyprvibe-setup-" name) c.systemd.user.services;
in {
  inherit host;
  shellBackend = c.hyprvibe.hyprland.shellBackend;
  flags = {
    hyprland = c.hyprvibe.hyprland.enable;
    waybar = c.hyprvibe.waybar.enable;
    dms = c.hyprvibe.dms.enable;
    power = c.hyprvibe.power.enable;
    userIcon = c.hyprvibe.user.icon != null;
    linger = c.users.users.${c.hyprvibe.user.name}.linger;
  };
  activationNames = builtins.attrNames c.system.activationScripts;
  customActivation = lib.mapAttrs (_: raw: let
    value = if builtins.isString raw then { text = raw; } else raw;
  in {
    deps = value.deps or [];
    bytes = builtins.stringLength value.text;
    supportsDryActivation = value.supportsDryActivation or false;
    # Lexical hints, not shell parsing: heredoc payloads can contain these too.
    hasNounset = lib.hasInfix "set -u" value.text;
    hasStrictMode = lib.hasInfix "set -euo pipefail" value.text;
    hasErrTrap = lib.hasInfix "trap '" value.text;
  }) snippets;
  activationDefinitionFiles = lib.unique (map (d: d.file) o.system.activationScripts.definitionsWithLocations);
  userActivationNames = builtins.attrNames c.system.userActivationScripts;
  userSetup = lib.mapAttrs unit setup;
  userUnits = lib.mapAttrs unit c.systemd.user.services;
  systemUnits = lib.mapAttrs unit c.systemd.services;
  boot = {
    systemdBoot = c.boot.loader.systemd-boot.enable;
    grub = c.boot.loader.grub.enable;
    grubDevices = c.boot.loader.grub.devices;
    efi = c.boot.loader.efi.canTouchEfiVariables;
  };
  assertionsFailed = map (a: a.message) (builtins.filter (a: !a.assertion) c.assertions);
  toplevelDrv = c.system.build.toplevel.drvPath;
}) flake.nixosConfigurations
