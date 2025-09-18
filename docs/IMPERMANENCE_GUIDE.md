# Impermanence Integration

This configuration includes optional support for [impermanence](https://github.com/nix-community/impermanence), which allows you to run a system with ephemeral root storage while persisting only the files and directories you explicitly choose.

## What is Impermanence?

Impermanence enables you to:
- Keep your system clean by default
- Force explicit declaration of what files/directories to persist
- Experiment with software without cluttering your system
- Easily reset to a clean state on reboot

## Quick Start

### Option 1: tmpfs Root (Easiest - RAM-based)

```nix
# In your host configuration (e.g., hosts/rvbee/system.nix)
hyprvibe.impermanence = {
  enable = true;
  wipingMethod = "tmpfs";
  tmpfsSize = "2G"; # Adjust based on your RAM
  persistentStoragePath = "/persistent";
};

# You'll also need a persistent partition mounted at /persistent
fileSystems."/persistent" = {
  device = "/dev/disk/by-label/persistent";
  neededForBoot = true;
  fsType = "ext4";
};
```

### Option 2: BTRFS Subvolumes (More Complex but Disk-based)

```nix
# In your host configuration
hyprvibe.impermanence = {
  enable = true;
  wipingMethod = "btrfs-subvolume";
  rootDevice = "/dev/disk/by-label/nixos";
  persistentStoragePath = "/persistent";
};

# BTRFS filesystem will be automatically configured with subvolumes:
# - root (wiped on boot)
# - nix (persistent)
# - persistent (persistent storage)
```

### Option 3: Manual Setup (Persistence Only)

```nix
# For custom filesystem setups
hyprvibe.impermanence = {
  enable = true;
  wipingMethod = "none"; # You handle the wiping manually
  persistentStoragePath = "/persistent";
};

# You configure your own filesystem wiping mechanism
```

## Configuration Options

```nix
hyprvibe.impermanence = {
  enable = false; # Set to true when ready
  
  # Wiping method: "tmpfs", "btrfs-subvolume", or "none"
  wipingMethod = "tmpfs";
  
  # Required for btrfs-subvolume method
  rootDevice = "/dev/disk/by-label/nixos";
  
  # Size for tmpfs root (default: "2G")
  tmpfsSize = "50%"; # Can use percentage of RAM
  
  # Path to persistent storage (default: "/persistent")
  persistentStoragePath = "/persistent";
  
  # System directories to persist
  directories = [
    "/var/lib/docker"
    "/var/lib/libvirt"  
    "/home"
  ];
  
  # System files to persist
  files = [
    "/etc/some-important-file"
  ];
  
  # Per-user persistence
  users.username = {
    directories = [
      "Documents"
      "Downloads"
      ".ssh"
      { directory = ".gnupg"; mode = "0700"; }
    ];
    files = [
      ".gitconfig"
    ];
  };
  
  # Hide bind mounts from file manager (default: true)
  hideMounts = true;
};
```

## Wiping Methods Explained

### tmpfs (RAM-based)
- **Pros**: Simple setup, guaranteed clean state on reboot, fast
- **Cons**: Limited by RAM size, data lost on power loss
- **Best for**: Development machines, systems with plenty of RAM

### BTRFS Subvolumes  
- **Pros**: Disk-based, supports larger root filesystems, snapshots
- **Cons**: More complex setup, requires BTRFS knowledge
- **Best for**: Production systems, complex storage setups

### Manual/None
- **Pros**: Full control over wiping mechanism
- **Cons**: You must implement the wiping yourself
- **Best for**: Advanced users with custom requirements

## Filesystem Setup Examples

### tmpfs Setup (Recommended for Development)

```nix
# Requires these partitions:
# - /boot (EFI partition)
# - /nix (for Nix store - can be large)  
# - /persistent (for persistent data)

fileSystems = {
  "/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };
  
  "/persistent" = {
    device = "/dev/disk/by-label/persistent";
    neededForBoot = true;
    fsType = "ext4";
  };
  
  "/nix" = {
    device = "/dev/disk/by-label/nix-store";
    fsType = "ext4";
  };
  
  "/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
};
```

### BTRFS Setup (Automatic with Module)

```nix
# The module automatically configures:
hyprvibe.impermanence = {
  enable = true;
  wipingMethod = "btrfs-subvolume";
  rootDevice = "/dev/disk/by-label/nixos";
};

# This creates subvolumes:
# @root - Root filesystem (wiped on boot)
# @nix - Nix store (persistent)  
# @persistent - User data (persistent)

# Boot partition still needed:
fileSystems."/boot" = {
  device = "/dev/disk/by-label/BOOT";
  fsType = "vfat";
};
```
```

## Default Persistence

When enabled, the following are automatically persisted:

### System-wide:
- `/var/log` - System logs
- `/var/lib/nixos` - NixOS state
- `/var/lib/systemd/coredump` - Core dumps
- `/etc/nixos` - NixOS configuration
- `/etc/NetworkManager/system-connections` - Network connections
- `/etc/ssh` - SSH host keys
- `/etc/machine-id` - Machine ID

### User-specific (example for user `chrisf`):
- `Documents`, `Downloads`, `Music`, `Pictures`, `Videos`
- `.ssh`, `.config`, `.local`, `.cache`
- `.gnupg` (with 0700 permissions)
- Build directory and VirtualBox VMs

## Migration Checklist

Before enabling impermanence:

1. ✅ **Backup important data** - Ensure everything critical is backed up
2. ✅ **Choose wiping method** - tmpfs (RAM) vs BTRFS (disk) vs manual
3. ✅ **Test with a VM first** - Try the setup in a virtual machine
4. ✅ **Identify additional files** - Think about what else needs persistence
5. ✅ **Document your setup** - Keep notes on your specific configuration

### Migration Steps

1. **Add impermanence to your config** (disabled):
   ```nix
   hyprvibe.impermanence.enable = false; # Start with false
   ```

2. **Plan your partitioning** based on chosen method

3. **Test the configuration**:
   ```bash
   nixos-rebuild build --flake .#hostname
   ```

4. **Backup and repartition** your system (if needed)

5. **Enable impermanence**:
   ```nix
   hyprvibe.impermanence.enable = true;
   ```

6. **Deploy and test**:
   ```bash
   nixos-rebuild switch --flake .#hostname
   ```

## Filesystem Layout Examples

### tmpfs Layout
```
/                    # tmpfs (ephemeral, 2G RAM)
├── persistent/      # Persistent storage mount (disk)
│   ├── home/        # User home directories
│   ├── var/lib/     # System state
│   └── etc/         # Important config files
├── nix/             # Nix store (persistent, disk)
└── boot/            # Boot partition (persistent, disk)
```

### BTRFS Layout  
```
/dev/nvme0n1
├── p1: /boot        # EFI boot partition
└── p2: BTRFS volume # Main BTRFS volume
    ├── @root        # Root subvolume (wiped on boot)
    ├── @nix         # Nix store (persistent)
    └── @persistent  # User data (persistent)
```

## Troubleshooting

### Build Failures
If builds fail after adding impermanence:
```bash
nix flake check
nixos-rebuild build --flake .#hostname
```

### Missing Directories
The module automatically creates required directories on the persistent storage with proper permissions.

### Service Issues
Some services may need their state directories explicitly added to the persistence configuration.

## References

- [Impermanence GitHub Repository](https://github.com/nix-community/impermanence)
- [Erase Your Darlings Blog Post](https://grahamc.com/blog/erase-your-darlings)
- [NixOS tmpfs as Root Guide](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)