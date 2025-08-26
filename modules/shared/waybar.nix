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
      cp ${../../hosts/rvbee/waybar.json} /home/chrisf/.config/waybar/config || true
      cp ${../../hosts/rvbee/waybar.css} /home/chrisf/.config/waybar/style.css || true
      cp ${../../hosts/rvbee/scripts/waybar-*.sh} /home/chrisf/.config/waybar/scripts/ 2>/dev/null || true
      cp ${../../hosts/rvbee/scripts/waybar-*.py} /home/chrisf/.config/waybar/scripts/ 2>/dev/null || true
      chmod +x /home/chrisf/.config/waybar/scripts/*.sh 2>/dev/null || true
      chown -R chrisf:users /home/chrisf/.config/waybar
    '';
  };
}


