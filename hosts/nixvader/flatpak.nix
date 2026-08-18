{ pkgs, ... }:
{
  # Allow passwordless flatpak system operations for the user session.
  security.sudo.extraRules = [
    {
      users = [ "chrisf" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/flatpak";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Reconcile requested system Flatpaks after networking is available.
  systemd.services.nixvader-flatpak-declared-apps = {
    description = "Reconcile nixvader declared Flatpak applications";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "flatpak-system-helper.service" ];
    unitConfig = {
      StartLimitIntervalSec = "1h";
      StartLimitBurst = 3;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5min";
    };
    path = [ pkgs.flatpak pkgs.gnugrep ];
    script = ''
      set -euo pipefail

      flatpak remote-add --if-not-exists --system flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak update --appstream --system flathub

      for app_id in \
        com.obsproject.Studio \
        com.github.tchx84.Flatseal \
        app.zen_browser.zen \
        com.moonlight_stream.Moonlight \
        be.alexandervanhee.gradia \
        org.gnome.Firmware; do
        if ! flatpak list --system --columns=application | grep -qx "$app_id"; then
          echo "Installing declared Flatpak: $app_id" >&2
          flatpak install --system --noninteractive --assumeyes flathub "$app_id"
        fi
      done
    '';
  };
}
