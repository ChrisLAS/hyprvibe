{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.system;
in {
  options.hyprvibe.system = {
    enable = lib.mkEnableOption "Enable shared system/kernel performance settings";
    kernelPackages = lib.mkOption {
      type = lib.types.nullOr lib.types.unspecified;
      default = pkgs.linuxPackages_zen;
      description = "Kernel packages to use. Defaults to Zen kernel. Set to null to use system default, or override with pkgs.linuxPackages for regular kernel.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Kernel: use Zen by default, but allow per-host override
    boot.kernelPackages = cfg.kernelPackages;

    # Trim SSDs weekly (harmless on HDDs)
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };

    # ZRAM swap with zstd
    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    # Nix store optimizations and GC
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Power management defaults
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "performance";
    };
  };
}
