{ lib, config, pkgs, ... }:
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
      description = lib.mkOption {
        type = lib.types.str;
        default = "Hyprvibe User";
        description = "GECOS/description for the primary user.";
      };
      linger = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Keep user services running even when not logged in.";
      };
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional groups to add on top of hyprvibe base groups.";
      };
      icon = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to user profile picture/icon file (will be copied to ~/.face for GDM).";
      };
    };
  };
in {
  options.hyprvibe.user = lib.mkOption {
    type = lib.types.either lib.types.str (lib.types.submodule userSubmodule);
    default = { name = "chrisf"; group = "users"; home = "/home/chrisf"; description = "Hyprvibe User"; linger = true; extraGroups = []; };
    description = "Primary user (string short-form or attribute set).";
    apply = value:
      if lib.isString value then
        { name = value; group = "users"; home = "/home/${value}"; }
      else
        {
          name = value.name;
          group = value.group or "users";
          home = value.home or "/home/${value.name}";
          description = value.description or "Hyprvibe User";
          linger = value.linger or true;
          extraGroups = value.extraGroups or [];
          icon = value.icon or null;
        };
  };

  # Provide a sensible default user matching both hosts, while allowing per-host adds
  config = let
    baseGroups = [
      "networkmanager" "wheel" "docker" "adbusers" "libvirtd"
      # Device access groups
      "video" "render" "audio" "i2c" "cdrom"
    ];
    finalGroups = lib.unique (baseGroups ++ (cfg.extraGroups or []));
    userHome = cfg.home;
    userIcon = cfg.icon;
  in {
    users.users."${cfg.name}" = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = cfg.description or "Hyprvibe User";
      linger = cfg.linger or true;
      extraGroups = finalGroups;
      group = cfg.group;
      home = userHome;
    };

    # Set user profile picture for GDM if icon is specified
    system.activationScripts.setUserIcon = lib.mkIf (userIcon != null) ''
      echo "[hyprvibe][user] setting profile picture for ${cfg.name}..."
      if [ -f "${userIcon}" ]; then
        # Ensure the user's home directory exists
        mkdir -p "${userHome}"
        # Copy the icon to ~/.face (standard location for user profile pictures)
        cp -f "${userIcon}" "${userHome}/.face" || true
        chown ${cfg.name}:${cfg.group} "${userHome}/.face" || true
        echo "[hyprvibe][user] profile picture set to ${userHome}/.face"
      else
        echo "[hyprvibe][user] WARNING: Icon file ${userIcon} not found, skipping..."
      fi
    '';
  };
}


