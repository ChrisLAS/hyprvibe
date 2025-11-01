{ lib, config, ... }:
let
  cfg = config.hyprvibe.user;
in {
  options.hyprvibe.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "chrisf";
      description = "Primary user name for the host.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Primary user group for the host.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/chrisf";
      description = "Home directory path for the primary user.";
    };
  };
}


