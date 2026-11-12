{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Dell XPS 14 DA14260, Panther Lake. Do not inherit Latitude/i915 workarounds.
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "vmd" ];
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.sof-firmware ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-review";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/45f7de6f-afa3-4036-88ec-d7107551957e";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  # ZRAM is provided by the shared system module; no encrypted disk or swapfile.
  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
