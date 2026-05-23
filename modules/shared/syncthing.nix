{
  lib,
  config,
  ...
}:
let
  cfg = config.hyprvibe.services.syncthing;
  user = config.hyprvibe.user;
  hostname = config.networking.hostName;

  devices = {
    nixstation = {
      id = "KHJYIB5-L5LK6TE-G5BCAXD-UKTVWYU-GX4YG7T-QEXMBWO-YIJ4B5Y-JG24VQ6";
    };
    rvbee = {
      id = "XG257UG-LBMN4ZM-5JA4NM2-I32JYUL-VPSEUJK-7JQHPNI-NYABXZB-C66KKAY";
    };
    nixbook = {
      id = "RV7GZDJ-OE2DQFT-LTXETQF-BU5VGCC-7CRZDAJ-UJWG72P-WF6VSIL-DLKVYQP";
    };
  };

  knownHosts = lib.attrNames devices;
  peerNames = lib.filter (name: name != hostname) knownHosts;
  secretsFile = ../../secrets/syncthing + "/${hostname}.yaml";
in
{
  options.hyprvibe.services.syncthing = {
    enable = lib.mkEnableOption "Declarative Syncthing mesh for Hyprvibe hosts";

    folderPath = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/build/hosts";
      description = "Path to the Hyprvibe hosts folder synced across machines.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem hostname knownHosts;
        message = "hyprvibe.services.syncthing only has device IDs for: ${lib.concatStringsSep ", " knownHosts}";
      }
    ];

    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    sops.secrets."syncthing/cert" = {
      sopsFile = secretsFile;
      key = "cert";
      owner = user.name;
      group = user.group;
      mode = "0400";
    };
    sops.secrets."syncthing/key" = {
      sopsFile = secretsFile;
      key = "key";
      owner = user.name;
      group = user.group;
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.folderPath} 0750 ${user.name} ${user.group} -"
    ];

    services.syncthing = {
      enable = true;
      user = user.name;
      group = user.group;
      dataDir = user.home;
      configDir = "${user.home}/.config/syncthing";
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = devices;
        folders.hyprvibe-hosts = {
          id = "hyprvibe-hosts";
          label = "Hyprvibe hosts";
          path = cfg.folderPath;
          type = "sendreceive";
          devices = peerNames;
        };
      };
    };
  };
}
