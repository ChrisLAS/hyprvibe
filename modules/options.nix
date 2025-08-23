{
  config,
  lib,
  ...
}: let
  cfg = config.hyprvibe;
in {
  options = {
    hyprvibe = {
      enable = lib.mkEnableOption "Hyprvibe host configuration";
      user = lib.mkOption {
        type = lib.types.str;
        default = "chrisf";
        description = "Primary username used for Hyprvibe host configuration.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "users";
        description = "Primary group name used for Hyprvibe host configuration.";
      };
      homeDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${cfg.user}";
        description = "Home directory for the primary user.";
      };
    };
  };
}
