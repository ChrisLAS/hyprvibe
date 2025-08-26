{ lib, config, pkgs, ... }:
let cfg = config.shared.services;
in {
  options.shared.services = {
    enable = lib.mkEnableOption "Shared baseline services (pipewire, flatpak, polkit, sudo)";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    services.flatpak.enable = true;
    security.polkit.enable = true;
    security.rtkit.enable = true;
    security.sudo.wheelNeedsPassword = false;
  };
}


