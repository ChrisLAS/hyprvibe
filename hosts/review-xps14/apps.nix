{ config, lib, pkgs, ... }:
let
  # The shared Beads database is schema 32; newer clients require a migration.
  beadsSource = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/c27cdad491a991b11ed731760aa2ef8db0cb0410.tar.gz";
    sha256 = "1r58xn9xdka8bw710i431srl3dmy7dyrhd32rjv709f2mkb6m1ix";
  };
  beadsPkgs = import beadsSource { system = pkgs.stdenv.hostPlatform.system; };
  firefoxMcp = ./firefox-mcp.nix;
  hermesRemote = pkgs.callPackage ../../pkgs/hermes-desktop-nomad.nix { };
  sunshineApps = pkgs.writeText "review-xps14-sunshine-apps.json" (builtins.toJSON {
    env.PATH = "${pkgs.coreutils}/bin:${pkgs.util-linux}/bin";
    apps = [
      { name = "Desktop"; "image-path" = "desktop.png"; }
      {
        name = "Hermes Desktop";
        detached = [ "${pkgs.util-linux}/bin/setsid ${lib.getExe hermesRemote.wrapper}" ];
        "image-path" = "desktop.png";
      }
    ];
  });
  sunshineLauncher = pkgs.writeShellScript "review-xps14-sunshine" ''
    set -eu
    tailscale_ip=""
    for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
      tailscale_ip="$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || true)"
      if printf '%s\n' "$tailscale_ip" | ${pkgs.gnugrep}/bin/grep -Eq '^[0-9]+(\.[0-9]+){3}$'; then
        break
      fi
      tailscale_ip=""
      ${pkgs.coreutils}/bin/sleep 2
    done
    if [ -z "$tailscale_ip" ]; then
      echo "Sunshine requires an available Tailscale IPv4 address" >&2
      exit 1
    fi
    exec ${config.security.wrapperDir}/sunshine \
      "address_family=ipv4" "bind_address=$tailscale_ip" "upnp=disabled" \
      "origin_web_ui_allowed=wan" "wan_encryption_mode=2" \
      "csrf_allowed_origins=https://review-xps14.coin-noodlefish.ts.net,https://$tailscale_ip" \
      "adapter_name=/dev/dri/renderD128" "file_apps=${sunshineApps}"
  '';
in
{
  imports = [ firefoxMcp ];

  environment.systemPackages = with pkgs; [
    brave google-chrome signal-desktop element-desktop obs-studio handbrake
    easyeffects yt-dlp zed-editor ghostty codex codex-acp
    (callPackage ../../pkgs/codexbar.nix { })
    beadsPkgs.beads rclone mosh moonlight-qt gradia gnome-firmware
    losslesscut lmstudio discord syncthing
  ];
  programs.firefox.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [ thunar-archive-plugin thunar-volman ];
  };

  # Syncthing is installed only: no device identity, default folder, peer, or service.
  # Sunshine is limited to the host’s existing Tailscale connection.
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = false;
  };
  # Unlike Nixvader, the review host keeps its firewall enabled. Admit only
  # Sunshine/Moonlight defaults on Tailscale, never on the LAN interfaces.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPorts = [ 47998 47999 48000 48002 48010 ];
  };
  systemd.user.services.sunshine = {
    unitConfig.ConditionUser = config.hyprvibe.user.name;
    after = [ "tailscaled.service" ];
    serviceConfig.ExecStart = lib.mkForce sunshineLauncher;
  };

  # Follow the existing Nixvader pattern without granting passwordless Flatpak sudo.
  # Only ensure the requested applications exist; never remove other installations.
  systemd.services.review-xps14-flatpak-declared-apps = {
    description = "Reconcile review XPS 14 declared Flatpak applications";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "flatpak-system-helper.service" ];
    unitConfig = { StartLimitIntervalSec = "1h"; StartLimitBurst = 3; };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5min";
      TimeoutStartSec = "30min";
    };
    path = [ pkgs.flatpak pkgs.gnugrep ];
    script = ''
      set -euo pipefail
      flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak update --appstream --system flathub
      for app_id in com.github.tchx84.Flatseal top.akizip.akizip; do
        if ! flatpak list --system --columns=application | grep -Fxq "$app_id"; then
          flatpak install --system --noninteractive --assumeyes flathub "$app_id"
        fi
      done
    '';
  };
}
