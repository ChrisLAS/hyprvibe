{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hyprvibe.sunshine;
  hermesDesktopRemote = pkgs.callPackage ../pkgs/hermes-desktop-nomad.nix {
    hermes-desktop = pkgs.hermes-desktop;
  };
  applicationsFile = pkgs.writeText "sunshine-apps.json" (builtins.toJSON {
    env = {
      PATH = "${pkgs.coreutils}/bin:${pkgs.util-linux}/bin";
    };
    apps = [
      {
        name = "Desktop";
        "image-path" = "desktop.png";
      }
      {
        name = "Hermes Desktop";
        detached = [
          "${pkgs.util-linux}/bin/setsid ${lib.getExe hermesDesktopRemote.wrapper}"
        ];
        "image-path" = "desktop.png";
      }
    ];
  });
  sunshineExecutable =
    if config.services.sunshine.capSysAdmin
    then "${config.security.wrapperDir}/sunshine"
    else lib.getExe config.services.sunshine.package;
  sunshineLauncher = pkgs.writeShellScript "sunshine-tailscale" ''
    set -eu

    # Sunshine accepts an IP address, not an interface name. Resolve the
    # current Tailscale address at every service start so this remains valid
    # if the host's tailnet address changes.
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

    exec ${sunshineExecutable} \
      "address_family=ipv4" \
      "bind_address=$tailscale_ip" \
      "upnp=disabled" \
      "origin_web_ui_allowed=wan" \
      "wan_encryption_mode=2" \
      "csrf_allowed_origins=https://nixvader.coin-noodlefish.ts.net,https://$tailscale_ip" \
      "adapter_name=${cfg.adapterName}" \
      "file_apps=${applicationsFile}"
  '';
in {
  options.hyprvibe.sunshine = {
    enable = lib.mkEnableOption "Tailscale-only Sunshine streaming";
    adapterName = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/renderD128";
      description = "VA-API render device used by Sunshine for encoding.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      # KMS capture can require CAP_SYS_ADMIN; PipeWire/Wayland remains
      # available when Sunshine selects it for the active graphical session.
      capSysAdmin = true;
      openFirewall = false;
    };

    # Replace only the generated ExecStart. The NixOS Sunshine module still
    # supplies the user service lifecycle, uinput rules, package, and wrapper.
    # This launcher adds the dynamic Tailscale bind and declarative app list.
    systemd.user.services.sunshine = {
      after = [ "tailscaled.service" ];
      serviceConfig.ExecStart = lib.mkForce sunshineLauncher;
    };
  };
}
