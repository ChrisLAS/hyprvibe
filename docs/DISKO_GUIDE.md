# Disko Integration

This configuration includes support for [disko](https://github.com/nix-community/disko), a declarative disk partitioning and formatting tool for NixOS. Disko allows you to define your entire disk layout in code, making installations reproducible and automated.

## What is Disko?

Disko enables you to:
- **Declaratively define** disk partitions, filesystems, and mount points
- **Automate** disk formatting during NixOS installation
- **Reproduce** identical disk layouts across multiple systems
- **Support** complex setups like LUKS encryption, LVM, BTRFS subvolumes
- **Integrate** with tools like nixos-anywhere for remote installations

## ⚠️ **IMPORTANT WARNING**

**Disko will DESTROY all data on the target disk!** Always backup important data before using disko. Only enable disko when you're ready to completely repartition and format your disk.

## Quick Start

### 1. Choose Your Layout

The hyprvibe disko module provides several pre-configured layouts:

```nix
hyprvibe.disko = {
  enable = true;
  layout = "simple-efi";     # Choose your layout
  device = "/dev/nvme0n1";   # YOUR DISK DEVICE
  bootSize = "1G";
  swapSize = "16G";          # Or null to disable
};
```

### 2. Available Layouts

#### `simple-efi` (Recommended)
- **Best for**: Most modern systems with UEFI
- **Partitions**: EFI boot (1G) + swap (optional) + ext4 root
- **Filesystem**: ext4

#### `simple-bios`
- **Best for**: Older systems with BIOS boot
- **Partitions**: Boot (1G) + swap (optional) + ext4 root  
- **Filesystem**: ext4

#### `btrfs-subvolumes`
- **Best for**: Advanced users wanting snapshots and compression
- **Partitions**: EFI boot + swap (optional) + BTRFS root
- **Features**: Subvolumes for /, /home, /nix, /.snapshots
- **Filesystem**: BTRFS with compression

#### `lvm-luks`
- **Best for**: Encrypted systems with flexible storage
- **Partitions**: EFI boot + LUKS encrypted LVM
- **Features**: Full disk encryption, logical volume management
- **Filesystem**: ext4 on encrypted LVM

#### `custom`
- **Best for**: Expert users with specific requirements
- **Configuration**: Define your own disko configuration

## Configuration Examples

### Basic EFI System

```nix
# In your host configuration (hosts/rvbee/system.nix)
hyprvibe.disko = {
  enable = true;
  layout = "simple-efi";
  device = "/dev/nvme0n1";  # CHANGE THIS TO YOUR ACTUAL DISK!
  bootSize = "1G";
  swapSize = "16G";
};
```

### BTRFS with Subvolumes

```nix
hyprvibe.disko = {
  enable = true;
  layout = "btrfs-subvolumes";
  device = "/dev/sda";
  bootSize = "1G";
  swapSize = "8G";
  
  # Customize BTRFS settings
  btrfs = {
    compression = "zstd";
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
      "@nix" = { 
        mountpoint = "/nix";
        mountOptions = [ "noatime" ];
      };
      "@snapshots" = { mountpoint = "/.snapshots"; };
      "@var-log" = { mountpoint = "/var/log"; };
    };
  };
};
```

### Encrypted LVM System

```nix
hyprvibe.disko = {
  enable = true;
  layout = "lvm-luks";
  device = "/dev/nvme0n1";
  bootSize = "1G";
  swapSize = null; # No separate swap partition
  
  # LUKS encryption
  encryption = {
    enable = true;
    label = "nixos-encrypted";
    # keyFile = "/etc/luks-keys/main"; # For automated unlocking
  };
  
  # LVM volumes
  lvm = {
    vgName = "nixos-vg";
    volumes = {
      root = {
        size = "50G";
        fsType = "ext4";
        mountpoint = "/";
      };
      home = {
        size = "100%FREE";
        fsType = "ext4";
        mountpoint = "/home";
      };
    };
  };
};
```

### Custom Configuration

```nix
hyprvibe.disko = {
  enable = true;
  layout = "custom";
  customConfig = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          # Your custom partition layout here
          # See disko documentation for full syntax
        };
      };
    };
  };
};
```

## Installation Workflow

### Option 1: Manual Installation

1. **Boot from NixOS installer**
2. **Configure disko** in your system configuration
3. **Run disko** to partition and format:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
     --mode destroy,format,mount /path/to/your/disko-config.nix
   ```
4. **Install NixOS**:
   ```bash
   nixos-install --flake .#hostname
   ```

### Option 2: Using disko-install

The modern approach combines disko and nixos-install:

```bash
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake .#hostname --disk main /dev/nvme0n1
```

### Option 3: Standalone Disko Configuration

Create a separate disko configuration file:

```nix
# disk-config.nix
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
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
  };
}
```

Then run:
```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount ./disk-config.nix
```

## Remote Installation with nixos-anywhere

Disko integrates perfectly with [nixos-anywhere](https://github.com/numtide/nixos-anywhere) for fully automated remote installations:

```bash
nix run github:numtide/nixos-anywhere -- \
  --flake .#hostname root@target-ip
```

The disko configuration in your flake will automatically partition and format the remote system.

## Advanced Features

### Temporary Filesystems (tmpfs)

For ephemeral root filesystems (great with impermanence):

```nix
hyprvibe.disko = {
  enable = true;
  layout = "custom";
  customConfig = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            # ... EFI partition config
          };
          nix = {
            size = "50G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          };
          persistent = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persistent";
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "size=8G" "mode=755" ];
    };
  };
};
```

### Multiple Disks

```nix
hyprvibe.disko = {
  enable = true;
  layout = "custom";
  customConfig = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          # System partitions on SSD
        };
      };
      hdd = {
        type = "disk";
        device = "/dev/sda";
        content = {
          # Data partitions on HDD
        };
      };
    };
  };
};
```

### RAID Configurations

```nix
hyprvibe.disko = {
  enable = true;
  layout = "custom";
  customConfig = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions.raid = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "raid1";
            };
          };
        };
      };
      disk2 = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions.raid = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "raid1";
            };
          };
        };
      };
    };
    mdadm.raid1 = {
      type = "mdadm";
      level = 1;
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
};
```

## Testing and Validation

### Build Test (Safe)

Before applying, test your configuration:

```bash
# Build the configuration (doesn't apply changes)
nixos-rebuild build --flake .#hostname

# Validate the disko configuration
nix run github:nix-community/disko/latest -- \
  --mode mount /path/to/disko-config.nix --dry-run
```

### VM Testing

Test your disko configuration in a virtual machine first:

```bash
# Build a VM with your configuration
nixos-rebuild build-vm --flake .#hostname

# Run the VM and test the disk layout
```

## Troubleshooting

### Common Issues

#### "Device is busy"
```bash
# Unmount all partitions
sudo umount -R /mnt
# Deactivate LVM/LUKS devices
sudo vgchange -an
sudo cryptsetup luksClose <device-name>
```

#### "Partition table exists"
Disko will fail if a partition table already exists. Use `--mode destroy` to override:
```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount ./disk-config.nix
```

#### Boot Issues After Installation
- Verify EFI partition is correctly mounted at `/boot`
- Check that boot loader configuration matches disko layout
- Ensure encrypted devices have proper key files or passwords

### Debug Mode

Run disko with debug output:
```bash
sudo nix run github:nix-community/disko/latest -- \
  --mode format,mount ./disk-config.nix --debug
```

## Device Identification

### Find Your Disk Device

```bash
# List all block devices
lsblk

# List by ID (more stable)
ls -la /dev/disk/by-id/

# List NVMe devices
ls /dev/nvme*

# Check disk information
sudo fdisk -l
```

### Recommended Device Naming

- **NVMe SSD**: `/dev/nvme0n1`
- **SATA SSD/HDD**: `/dev/sda`
- **By ID (more stable)**: `/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_...`

## Integration with Other Features

### With Impermanence

Disko works great with the impermanence module:

```nix
# Use tmpfs root with persistent storage
hyprvibe = {
  disko = {
    enable = true;
    layout = "custom";
    customConfig = {
      # tmpfs root + persistent storage configuration
    };
  };
  
  impermanence = {
    enable = true;
    persistentStoragePath = "/persistent";
    # ... persistence configuration
  };
};
```

### With Secure Boot (Lanzaboote)

Disko configurations work with lanzaboote:

```nix
hyprvibe.disko = {
  enable = true;
  layout = "simple-efi";  # EFI required for secure boot
  # ... other configuration
};

# Lanzaboote will automatically use the EFI partition created by disko
```

## Security Considerations

### LUKS Key Management

For automated setups with LUKS:

```nix
# Generate a key file
sudo dd if=/dev/random of=/etc/luks-keys/main bs=1024 count=4
sudo chmod 600 /etc/luks-keys/main

# Use in disko configuration
hyprvibe.disko = {
  encryption = {
    enable = true;
    keyFile = "/etc/luks-keys/main";
  };
};
```

### Secure Erasure

Before deploying disko on sensitive systems:

```bash
# Secure erase (for SSDs)
sudo nvme format /dev/nvme0n1 --ses=1

# Random overwrite (for HDDs)
sudo dd if=/dev/urandom of=/dev/sda bs=1M status=progress
```

## Performance Considerations

### SSD Optimization

For SSD systems, consider:

```nix
hyprvibe.disko = {
  layout = "btrfs-subvolumes";
  btrfs.subvolumes."@nix".mountOptions = [ 
    "noatime"      # Reduce SSD wear
    "compress=zstd" # Better performance than lzo
    "ssd"          # SSD-specific optimizations
  ];
};
```

### Large Systems

For systems with large storage needs:

```nix
hyprvibe.disko = {
  layout = "lvm-luks";
  lvm.volumes = {
    root = { size = "100G"; };        # Fixed root size
    home = { size = "50%VG"; };       # Percentage of volume group
    data = { size = "100%FREE"; };    # Remaining space
  };
};
```

## Migration from Existing Systems

### From Manual Partitioning

1. **Backup all data**
2. **Boot from NixOS installer**
3. **Configure disko** to match your desired layout
4. **Run disko** to repartition
5. **Restore data** to appropriate partitions

### From Other Linux Distributions

1. **Create NixOS configuration** with disko
2. **Use nixos-anywhere** for remote conversion:
   ```bash
   nix run github:numtide/nixos-anywhere -- \
     --flake .#hostname root@target-system
   ```

## Examples Repository

See the [disko examples directory](https://github.com/nix-community/disko/tree/master/example) for more complex configurations including:

- ZFS configurations
- bcachefs support
- Complex RAID setups
- Multi-boot configurations

## Best Practices

1. **Always test first** in a VM or spare system
2. **Use stable device identifiers** (`/dev/disk/by-id/...`)
3. **Document your layout** in your configuration comments
4. **Keep backups** of important data
5. **Version control** your disko configurations
6. **Test recovery procedures** before deploying

## Further Reading

- [Disko GitHub Repository](https://github.com/nix-community/disko)
- [Disko Documentation](https://github.com/nix-community/disko/blob/master/docs/INDEX.md)
- [nixos-anywhere Documentation](https://github.com/numtide/nixos-anywhere)
- [NixOS Manual - Storage](https://nixos.org/manual/nixos/stable/index.html#ch-file-systems)