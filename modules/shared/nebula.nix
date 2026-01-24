{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.hyprvibe.services.nebula;
  hostname = config.networking.hostName;
in
{
  options.hyprvibe.services.nebula = {
    enable = lib.mkEnableOption "Nebula VPN mesh network";

    nebulaIp = lib.mkOption {
      type = lib.types.str;
      description = "This host's Nebula IP address with CIDR (e.g., 192.168.100.10/24)";
      example = "192.168.100.10/24";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add Nebula CLI tools to system packages
    environment.systemPackages = [ pkgs.nebula ];

    services.nebula.networks.nebula = {
      enable = true;
      ca = "/etc/nebula/ca.crt";
      cert = "/etc/nebula/${hostname}.crt";
      key = "/etc/nebula/${hostname}.key";

      isLighthouse = false;
      lighthouses = [ "192.168.100.1" ];
      staticHostMap = {
        "192.168.100.1" = [ "45.33.58.165:4242" ];
      };

      settings = {
        punchy = {
          punch = true;
          respond = true;
          delay = "1s";
        };
        relay = {
          am_relay = false;
          use_relays = true;
          relays = [ "192.168.100.1" ];
        };
      };

      firewall = {
        inbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
        outbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
      };
    };

    # Ensure secrets directory exists with proper permissions
    # Group must be nebula-nebula so the service (which runs as nebula-nebula user) can traverse the directory
    systemd.tmpfiles.rules = [
      "d /etc/nebula 0750 root nebula-nebula -"
    ];
  };
}
