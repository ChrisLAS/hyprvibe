{ lib, pkgs, config, ... }:
let cfg = config.shared.waybar;
in {
  options.shared.waybar = {
    enable = lib.mkEnableOption "Waybar setup and config copy";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.waybar ];
    system.activationScripts.waybar = lib.mkAfter ''
      mkdir -p /home/chrisf/.config/waybar/scripts
      chown -R chrisf:users /home/chrisf/.config/waybar
    '';
  };
}


