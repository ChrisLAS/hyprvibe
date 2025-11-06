{ lib, config, pkgs, ... }:
let cfg = config.hyprvibe.services;
in {
  options.hyprvibe.services = {
    enable = lib.mkEnableOption "Shared baseline services (pipewire, flatpak, polkit, sudo)";
    openssh.enable = lib.mkEnableOption "OpenSSH server";
    tailscale.enable = lib.mkEnableOption "Tailscale";
    virt.enable = lib.mkEnableOption "Virtualization (libvirtd)";
    docker.enable = lib.mkEnableOption "Docker";
    direnv.enable = lib.mkEnableOption "direnv with nix-direnv integration";
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

    # Desktop support services common to both hosts
    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.blueman.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
    services.davfs2.enable = true;
    services.gnome.gnome-keyring.enable = true;

    services.openssh.enable = lib.mkIf cfg.openssh.enable true;
    services.tailscale = lib.mkIf cfg.tailscale.enable {
      enable = true;
      useRoutingFeatures = "both";
    };
    virtualisation.libvirtd.enable = lib.mkIf cfg.virt.enable true;
    virtualisation.docker.enable = lib.mkIf cfg.docker.enable true;
    
    # direnv configuration with nix-direnv integration
    programs.direnv = lib.mkIf cfg.direnv.enable {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    
    # Install direnv and nix-direnv for all users when enabled
    environment.systemPackages = lib.mkIf cfg.direnv.enable (with pkgs; [
      direnv
      nix-direnv
    ]);
  };
}


