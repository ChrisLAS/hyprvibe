{ lib, config, ... }:
let
  cfg = config.hyprvibe.user;
  userSubmodule = { ... }: {
    options = {
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
  };
in {
  options.hyprvibe.user = lib.mkOption {
    type = lib.types.either lib.types.str (lib.types.submodule userSubmodule);
    default = { name = "chrisf"; group = "users"; home = "/home/chrisf"; };
    description = "Primary user (string short-form or attribute set).";
    apply = value:
      if lib.isString value then
        { name = value; group = "users"; home = "/home/${value}"; }
      else
        {
          name = value.name;
          group = value.group or "users";
          home = value.home or "/home/${value.name}";
        };
  };
}


