{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hyprvibe.sops;
in
{
  options.hyprvibe.sops = {
    enable = mkEnableOption "sops-nix secret management";

    defaultSopsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Default sops file for secrets";
      example = literalExpression "./secrets.yaml";
    };

    defaultSopsFormat = mkOption {
      type = types.enum [ "yaml" "json" "env" "ini" "binary" ];
      default = "yaml";
      description = "Default format for sops files";
    };

    age = {
      keyFile = mkOption {
        type = types.nullOr types.str;
        default = "/var/lib/sops-nix/key.txt";
        description = "Path to age key file for decryption";
      };

      generateKey = mkOption {
        type = types.bool;
        default = true;
        description = "Generate age key if it doesn't exist";
      };

      sshKeyPaths = mkOption {
        type = types.listOf types.str;
        default = [ "/etc/ssh/ssh_host_ed25519_key" ];
        description = "SSH keys to import as age keys";
      };
    };

    gnupg = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPG-based decryption";
      };

      home = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "GPG home directory";
      };

      sshKeyPaths = mkOption {
        type = types.listOf types.str;
        default = if cfg.gnupg.enable then [ ] else [ "/etc/ssh/ssh_host_rsa_key" ];
        description = "SSH keys to import as GPG keys";
      };
    };

    secrets = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          sopsFile = mkOption {
            type = types.nullOr types.path;
            default = cfg.defaultSopsFile;
            description = "Sops file for this secret";
          };

          format = mkOption {
            type = types.enum [ "yaml" "json" "env" "ini" "binary" ];
            default = cfg.defaultSopsFormat;
            description = "Format of the sops file";
          };

          key = mkOption {
            type = types.str;
            default = name;
            description = "Key name in the sops file";
          };

          mode = mkOption {
            type = types.str;
            default = "0400";
            description = "File permissions (octal)";
          };

          owner = mkOption {
            type = types.str;
            default = "root";
            description = "File owner";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "File group";
          };

          path = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Custom path for the secret file";
          };

          restartUnits = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Systemd units to restart when secret changes";
          };

          reloadUnits = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Systemd units to reload when secret changes";
          };

          neededForUsers = mkOption {
            type = types.bool;
            default = false;
            description = "Make secret available before users are created";
          };
        };
      }));
      default = { };
      description = "Secrets configuration";
    };

    templates = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          content = mkOption {
            type = types.str;
            description = "Template content with placeholders";
          };

          mode = mkOption {
            type = types.str;
            default = "0400";
            description = "File permissions (octal)";
          };

          owner = mkOption {
            type = types.str;
            default = "root";
            description = "File owner";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "File group";
          };

          path = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Custom path for the template file";
          };
        };
      }));
      default = { };
      description = "Template configuration for secrets";
    };

    placeholder = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "Placeholders for use in templates";
    };
  };

  config = mkIf cfg.enable {
    # Configure sops-nix
    sops = {
      defaultSopsFile = mkIf (cfg.defaultSopsFile != null) cfg.defaultSopsFile;
      defaultSopsFormat = cfg.defaultSopsFormat;

      age = mkIf (!cfg.gnupg.enable) {
        keyFile = mkIf (cfg.age.keyFile != null) cfg.age.keyFile;
        generateKey = cfg.age.generateKey;
        sshKeyPaths = cfg.age.sshKeyPaths;
      };

      gnupg = mkIf cfg.gnupg.enable {
        home = mkIf (cfg.gnupg.home != null) cfg.gnupg.home;
        sshKeyPaths = cfg.gnupg.sshKeyPaths;
      };

      secrets = mapAttrs
        (name: secretCfg: {
          sopsFile = mkIf (secretCfg.sopsFile != null) secretCfg.sopsFile;
          format = secretCfg.format;
          key = secretCfg.key;
          mode = secretCfg.mode;
          owner = secretCfg.owner;
          group = secretCfg.group;
          path = mkIf (secretCfg.path != null) secretCfg.path;
          restartUnits = secretCfg.restartUnits;
          reloadUnits = secretCfg.reloadUnits;
          neededForUsers = secretCfg.neededForUsers;
        })
        cfg.secrets;

      templates = mapAttrs
        (name: templateCfg: {
          content = templateCfg.content;
          mode = templateCfg.mode;
          owner = templateCfg.owner;
          group = templateCfg.group;
          path = mkIf (templateCfg.path != null) templateCfg.path;
        })
        cfg.templates;
    };

    # Expose placeholders for templates
    hyprvibe.sops.placeholder = config.sops.placeholder;

    # Install necessary packages
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ] ++ optionals cfg.gnupg.enable [
      gnupg
      ssh-to-pgp
    ];
  };
}