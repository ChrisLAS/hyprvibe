# Pure isolated module contract; fake package constructors intentionally cannot
# build anything. This is NOT a host/closure or installed-package evaluation.
# Pass the frozen nixpkgs lib and the original power module as baselineModule.
{ lib, baselineModule }:
let
  package = name: {
    inherit name;
    type = "derivation";
    outPath = "/fixture/${name}";
    meta.mainProgram = name;
  };
  pkgs = {
    writeShellScriptBin = name: text: (package name) // { inherit text; };
    writeShellScript = name: text: "/fixture/${name}-${builtins.hashString "sha256" text}";
    vicinae = package "vicinae";
    coreutils = package "coreutils";
    power-profiles-daemon = package "power-profiles-daemon";
    upower = package "upower";
    acpi = package "acpi";
  };
  evaluate = module: enable: (lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      module
      ({ lib, ... }: {
        options = lib.genAttrs [ "environment" "services" "systemd" "system" ]
          (_: lib.mkOption { type = lib.types.attrs; default = {}; }) // {
            hyprvibe.user = lib.mkOption { type = lib.types.attrs; };
          };
        config.hyprvibe = {
          power = { inherit enable; };
          # Non-default fixture identity: paths must not leak into a writer.
          user = { name = "fixture-user"; group = "fixture-group"; home = "/fixture/home"; };
        };
      })
    ];
  }).config;
  before = evaluate baselineModule true;
  after = evaluate ../modules/shared/power.nix true;
  disabled = evaluate ../modules/shared/power.nix false;
  getScript = name: builtins.head (builtins.filter (p: p.name == name) after.environment.systemPackages);
  helper = getScript "power-profile";
  menu = getScript "power-profile-menu";
in
assert builtins.attrNames before.system.activationScripts == [ "installPowerProfileScript" ];
assert after.system == {};
assert disabled.system == {} && disabled.environment == {} && disabled.systemd == {} && disabled.services == {};
assert before.systemd == after.systemd && before.services == after.services;
assert map (p: p.name) after.environment.systemPackages == [
  "power-profiles-daemon" "upower" "acpi" "power-profile" "power-profile-menu"
];
assert helper.text == builtins.readFile ./power-profile.sh;
assert lib.hasInfix "exec power-profile" menu.text;
assert !lib.hasInfix "/fixture/home" menu.text;
{
  checks = [ "no-root-writer" "disabled-is-inert" "unchanged-service-policy"
    "helper-and-menu-installed" "exact-helper-source" "menu-uses-path" ];
  menuScript = menu.text;
}
