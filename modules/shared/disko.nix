{ config, lib, pkgs, ... }:

with lib;

{
  options.hyprvibe.disko = {
    enable = mkEnableOption "Disko declarative disk partitioning";
    
    layout = mkOption {
      type = types.enum [ "simple-efi" "simple-bios" "btrfs-subvolumes" "lvm-luks" "custom" ];
      default = "simple-efi";
      description = ''
        Pre-configured disk layout to use:
        - simple-efi: Simple GPT with EFI boot partition and ext4 root
        - simple-bios: Simple MBR with BIOS boot and ext4 root  
        - btrfs-subvolumes: BTRFS with subvolumes for /, /home, /nix
        - lvm-luks: LUKS encrypted LVM setup
        - custom: Use custom disko configuration
      '';
    };
    
    device = mkOption {
      type = types.str;
      default = "/dev/sda";
      example = "/dev/nvme0n1";
      description = "Primary disk device to partition";
    };
    
    bootSize = mkOption {
      type = types.str;
      default = "1G";
      description = "Size of boot partition";
    };
    
    swapSize = mkOption {
      type = types.nullOr types.str;
      default = "8G";
      example = "16G";
      description = "Size of swap partition (null to disable)";
    };
    
    encryption = {
      enable = mkEnableOption "LUKS encryption for root partition";
      
      label = mkOption {
        type = types.str;
        default = "nixos-enc";
        description = "LUKS device label";
      };
      
      keyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/etc/luks-keys/main";
        description = "Path to LUKS key file (for automated unlocking)";
      };
    };
    
    btrfs = {
      compression = mkOption {
        type = types.str;
        default = "zstd";
        description = "BTRFS compression algorithm";
      };
      
      subvolumes = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            mountpoint = mkOption {
              type = types.str;
              description = "Mount point for the subvolume";
            };
            mountOptions = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional mount options";
            };
          };
        });
        default = {
          "@" = { mountpoint = "/"; };
          "@home" = { mountpoint = "/home"; };
          "@nix" = { 
            mountpoint = "/nix";
            mountOptions = [ "noatime" ];
          };
          "@snapshots" = { mountpoint = "/.snapshots"; };
        };
        description = "BTRFS subvolume configuration";
      };
    };
    
    lvm = {
      vgName = mkOption {
        type = types.str;
        default = "nixos-vg";
        description = "LVM volume group name";
      };
      
      volumes = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            size = mkOption {
              type = types.str;
              description = "Size of the logical volume";
            };
            fsType = mkOption {
              type = types.str;
              default = "ext4";
              description = "Filesystem type";
            };
            mountpoint = mkOption {
              type = types.str;
              description = "Mount point";
            };
          };
        });
        default = {
          root = {
            size = "30G";
            fsType = "ext4";
            mountpoint = "/";
          };
          home = {
            size = "100%FREE";
            fsType = "ext4";
            mountpoint = "/home";
          };
        };
        description = "LVM logical volume configuration";
      };
    };
    
    customConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Custom disko configuration when layout = 'custom'";
    };
  };

  config = mkIf config.hyprvibe.disko.enable {
    # Assertions for configuration validation
    assertions = [
      {
        assertion = config.hyprvibe.disko.layout != "custom" || config.hyprvibe.disko.customConfig != {};
        message = "Custom disko configuration must be provided when layout = 'custom'";
      }
      {
        assertion = !config.hyprvibe.disko.encryption.enable || config.hyprvibe.disko.layout == "lvm-luks" || config.hyprvibe.disko.layout == "custom";
        message = "LUKS encryption is only supported with 'lvm-luks' or 'custom' layouts";
      }
    ];

    # Generate disko configuration based on selected layout
    disko.devices = mkMerge [
      # Simple EFI layout
      (mkIf (config.hyprvibe.disko.layout == "simple-efi") {
        disk.main = {
          type = "disk";
          device = config.hyprvibe.disko.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = config.hyprvibe.disko.bootSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
            } // (optionalAttrs (config.hyprvibe.disko.swapSize != null) {
              swap = {
                size = config.hyprvibe.disko.swapSize;
                content = {
                  type = "swap";
                };
              };
            }) // {
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      })
      
      # Simple BIOS layout
      (mkIf (config.hyprvibe.disko.layout == "simple-bios") {
        disk.main = {
          type = "disk";
          device = config.hyprvibe.disko.device;
          content = {
            type = "mbr";
            partitions = {
              boot = {
                size = config.hyprvibe.disko.bootSize;
                type = "primary";
                bootable = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot";
                };
              };
            } // (optionalAttrs (config.hyprvibe.disko.swapSize != null) {
              swap = {
                size = config.hyprvibe.disko.swapSize;
                type = "primary";
                content = {
                  type = "swap";
                };
              };
            }) // {
              root = {
                size = "100%";
                type = "primary";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      })
      
      # BTRFS subvolumes layout
      (mkIf (config.hyprvibe.disko.layout == "btrfs-subvolumes") {
        disk.main = {
          type = "disk";
          device = config.hyprvibe.disko.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = config.hyprvibe.disko.bootSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
            } // (optionalAttrs (config.hyprvibe.disko.swapSize != null) {
              swap = {
                size = config.hyprvibe.disko.swapSize;
                content = {
                  type = "swap";
                };
              };
            }) // {
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = mapAttrs (name: subvol: {
                    mountpoint = subvol.mountpoint;
                    mountOptions = [ "compress=${config.hyprvibe.disko.btrfs.compression}" ] ++ subvol.mountOptions;
                  }) config.hyprvibe.disko.btrfs.subvolumes;
                };
              };
            };
          };
        };
      })
      
      # LVM with LUKS layout
      (mkIf (config.hyprvibe.disko.layout == "lvm-luks") {
        disk.main = {
          type = "disk";
          device = config.hyprvibe.disko.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = config.hyprvibe.disko.bootSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = config.hyprvibe.disko.encryption.label;
                  keyFile = config.hyprvibe.disko.encryption.keyFile;
                  content = {
                    type = "lvm_pv";
                    vg = config.hyprvibe.disko.lvm.vgName;
                  };
                };
              };
            };
          };
        };
        lvm_vg."${config.hyprvibe.disko.lvm.vgName}" = {
          type = "lvm_vg";
          lvs = mapAttrs (name: vol: {
            size = vol.size;
            content = {
              type = "filesystem";
              format = vol.fsType;
              mountpoint = vol.mountpoint;
            };
          }) config.hyprvibe.disko.lvm.volumes;
        };
      })
      
      # Custom configuration
      (mkIf (config.hyprvibe.disko.layout == "custom") 
        config.hyprvibe.disko.customConfig)
    ];
    
    # Add disko CLI tools to environment
    environment.systemPackages = with pkgs; [
      disko
    ];
  };
}