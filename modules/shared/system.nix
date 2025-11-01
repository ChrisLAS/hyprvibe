{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.system;
in {
  options.hyprvibe.system = {
    enable = lib.mkEnableOption "Enable shared system/kernel performance settings";
  };

  config = lib.mkIf cfg.enable {
    # Kernel: use Zen by default
    boot.kernelPackages = pkgs.linuxPackages_zen;

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


