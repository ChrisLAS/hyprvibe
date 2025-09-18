{ config, lib, pkgs, ... }:

with lib;

{
  options.hyprvibe.impermanence = {
    enable = mkEnableOption "Impermanence configuration for ephemeral root storage";
    
    persistentStoragePath = mkOption {
      type = types.str;
      default = "/persistent";
      description = "Path to persistent storage location";
    };
    
    wipingMethod = mkOption {
      type = types.enum [ "tmpfs" "btrfs-subvolume" "none" ];
      default = "none";
      description = ''
        Method for wiping the root filesystem:
        - tmpfs: Mount root as tmpfs (RAM-based, wiped on reboot)
        - btrfs-subvolume: Use BTRFS subvolumes with automatic cleanup
        - none: Only persistence, no automatic wiping (for manual setup)
      '';
    };
    
    rootDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Root device for BTRFS subvolume method (e.g., /dev/disk/by-label/nixos)";
    };
    
    tmpfsSize = mkOption {
      type = types.str;
      default = "2G";
      description = "Size of tmpfs root filesystem (e.g., '2G', '50%')";
    };
    
    directories = mkOption {
      type = types.listOf (types.either types.str (types.submodule {
        options = {
          directory = mkOption {
            type = types.str;
            description = "Path to directory to persist";
          };
          user = mkOption {
            type = types.str;
            default = "root";
            description = "User ownership of the directory";
          };
          group = mkOption {
            type = types.str;
            default = "root";
            description = "Group ownership of the directory";
          };
          mode = mkOption {
            type = types.str;
            default = "0755";
            description = "Directory permissions";
          };
        };
      }));
      default = [];
      description = "System directories to persist across reboots";
    };
    
    files = mkOption {
      type = types.listOf (types.either types.str (types.submodule {
        options = {
          file = mkOption {
            type = types.str;
            description = "Path to file to persist";
          };
          parentDirectory = mkOption {
            type = types.submodule {
              options = {
                user = mkOption {
                  type = types.str;
                  default = "root";
                  description = "User ownership of parent directory";
                };
                group = mkOption {
                  type = types.str;
                  default = "root";
                  description = "Group ownership of parent directory";
                };
                mode = mkOption {
                  type = types.str;
                  default = "0755";
                  description = "Parent directory permissions";
                };
              };
            };
            default = {};
            description = "Parent directory configuration";
          };
        };
      }));
      default = [];
      description = "System files to persist across reboots";
    };
    
    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          directories = mkOption {
            type = types.listOf (types.either types.str (types.submodule {
              options = {
                directory = mkOption {
                  type = types.str;
                  description = "Path to directory relative to user home";
                };
                mode = mkOption {
                  type = types.str;
                  default = "0755";
                  description = "Directory permissions";
                };
              };
            }));
            default = [];
            description = "User directories to persist";
          };
          files = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "User files to persist";
          };
        };
      });
      default = {};
      description = "Per-user persistence configuration";
    };
    
    hideMounts = mkOption {
      type = types.bool;
      default = true;
      description = "Hide bind mounts from file manager";
    };
  };

  config = mkIf config.hyprvibe.impermanence.enable {
    assertions = [
      {
        assertion = config.hyprvibe.impermanence.wipingMethod == "none" || 
                   config.hyprvibe.impermanence.wipingMethod == "tmpfs" || 
                   (config.hyprvibe.impermanence.wipingMethod == "btrfs-subvolume" && config.hyprvibe.impermanence.rootDevice != null);
        message = "btrfs-subvolume wiping method requires rootDevice to be set";
      }
    ];

    # Filesystem configuration for wiping methods
    fileSystems = mkMerge [
      # tmpfs root configuration
      (mkIf (config.hyprvibe.impermanence.wipingMethod == "tmpfs") {
        "/" = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "defaults" "size=${config.hyprvibe.impermanence.tmpfsSize}" "mode=755" ];
        };
      })
      
      # BTRFS subvolume configuration
      (mkIf (config.hyprvibe.impermanence.wipingMethod == "btrfs-subvolume") {
        "/" = {
          device = config.hyprvibe.impermanence.rootDevice;
          fsType = "btrfs";
          options = [ "subvol=root" "compress=zstd" "noatime" ];
        };
        
        "/nix" = {
          device = config.hyprvibe.impermanence.rootDevice;
          fsType = "btrfs";
          options = [ "subvol=nix" "compress=zstd" "noatime" ];
        };
        
        "${config.hyprvibe.impermanence.persistentStoragePath}" = {
          device = config.hyprvibe.impermanence.rootDevice;
          fsType = "btrfs";
          options = [ "subvol=persistent" "compress=zstd" "noatime" ];
          neededForBoot = true;
        };
      })
    ];

    # BTRFS subvolume cleanup service
    systemd.services.btrfs-root-wipe = mkIf (config.hyprvibe.impermanence.wipingMethod == "btrfs-subvolume") {
      description = "Wipe BTRFS root subvolume";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@*.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -o subvol=/ ${config.hyprvibe.impermanence.rootDevice} /mnt
        
        # Create a blank snapshot if it doesn't exist
        if [[ ! -e /mnt/root-blank ]]; then
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create /mnt/root-blank
        fi
        
        # Delete the current root subvolume if it exists
        if [[ -e /mnt/root ]]; then
          ${pkgs.btrfs-progs}/bin/btrfs subvolume delete /mnt/root
        fi
        
        # Create a new root subvolume from the blank snapshot
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /mnt/root-blank /mnt/root
        
        umount /mnt
      '';
    };

    # Base system directories that are commonly needed
    environment.persistence.${config.hyprvibe.impermanence.persistentStoragePath} = {
      enable = true;
      hideMounts = config.hyprvibe.impermanence.hideMounts;
      
      directories = [
        # Essential system directories
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/nixos"
        
        # Network configuration
        "/etc/NetworkManager/system-connections"
        
        # SSH host keys
        "/etc/ssh"
      ] ++ config.hyprvibe.impermanence.directories;
      
      files = [
        # Machine ID for systemd
        "/etc/machine-id"
      ] ++ config.hyprvibe.impermanence.files;
      
      users = config.hyprvibe.impermanence.users;
    };
    
    # Ensure the persistent storage path exists and has correct permissions
    systemd.tmpfiles.rules = [
      "d ${config.hyprvibe.impermanence.persistentStoragePath} 0755 root root -"
    ];
  };
}