{ lib, pkgs, config, ... }:
let
  cfg = config.shared.packages;
in {
  options.shared.packages = {
    enable = lib.mkEnableOption "Shared base package groups";
    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additional packages to append to shared packages.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = cfg.extraPackages;
  };
}


