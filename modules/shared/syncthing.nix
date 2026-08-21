{
  lib,
  config,
  ...
}: let
  cfg = config.hyprvibe.services.syncthing;
  user = config.hyprvibe.user;
  hostname = config.networking.hostName;
  devices = {
    aurora.id = "4CD2OSH-B6OBHJ2-3LZS3NI-LFYCVLQ-POGG2SS-LNEKDXA-RBG5ZKS-X3UJ3QK";
    nixstation.id = "KHJYIB5-L5LK6TE-G5BCAXD-UKTVWYU-GX4YG7T-QEXMBWO-YIJ4B5Y-JG24VQ6";
    rvbee.id = "XG257UG-LBMN4ZM-5JA4NM2-I32JYUL-VPSEUJK-7JQHPNI-NYABXZB-C66KKAY";
    nixbook.id = "RV7GZDJ-OE2DQFT-LTXETQF-BU5VGCC-7CRZDAJ-UJWG72P-WF6VSIL-DLKVYQP";
    nomad.id = "HUAZMND-Q4QYPQQ-UEYHN3N-I72DZCR-DTOPZUY-N2KE5WT-FTKTA5Z-YPICHQ7";
  };
  knownHosts = lib.attrNames devices;
  peerNames = lib.filter (name: name != hostname) knownHosts;
  dropboxPeers = ["nixstation" "aurora" "nomad"];
  dropboxFolders = {
    "03-chrislas-prods" = {
      directory = "03-ChrisLAS-PRODS";
      label = "03 ChrisLAS productions";
    };
    "04-lup" = {
      directory = "04-LUP";
      label = "04 LUP";
    };
    "05-twib" = {
      directory = "05-TWIB";
      label = "05 TWiB";
    };
    "06-launch" = {
      directory = "06-Launch";
      label = "06 Launch";
    };
    "07-wyab" = {
      directory = "07-WYAB";
      label = "07 WYAB";
    };
    "10-friday" = {
      directory = "10-FRIDAY";
      label = "10 Friday";
    };
    "50-heremes" = {
      directory = "50-Heremes";
      label = "50 Heremes";
    };
    "60-backups" = {
      directory = "60-BACKUPS";
      label = "60 Backups";
      backup = true;
    };
  };
  secretsFile = ../../secrets/syncthing + "/${hostname}.yaml";
in {
  options.hyprvibe.services.syncthing = {
    enable = lib.mkEnableOption "Declarative Syncthing mesh for Hyprvibe hosts";
    folderPath = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/build/hosts";
      description = "Path to the Hyprvibe hosts folder synced across machines.";
    };
    agentConfigs = {
      enable = lib.mkEnableOption "shared agent configuration Syncthing folder";
      path = lib.mkOption {
        type = lib.types.str;
        default = "${user.home}/Sync/agent-configs";
        description = "Path to the Git-backed shared agent configuration folder.";
      };
    };
    dropbox = {
      enable = lib.mkEnableOption "shared Dropbox replacement folders";
      root = lib.mkOption {
        type = lib.types.str;
        default = "${user.home}/Dropbox/Chris Fisher";
        description = "Host-local Dropbox replacement root.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem hostname knownHosts;
        message = "hyprvibe.services.syncthing only has device IDs for: ${lib.concatStringsSep ", " knownHosts}";
      }
      {
        assertion = lib.all (name: lib.elem name knownHosts) dropboxPeers;
        message = "All Dropbox peers must have configured Syncthing device IDs.";
      }
    ];
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
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
    systemd.tmpfiles.rules =
      ["d ${cfg.folderPath} 0750 ${user.name} ${user.group} -"]
      ++ lib.optionals cfg.agentConfigs.enable [
        "d ${user.home}/Sync 0750 ${user.name} ${user.group} -"
        "d ${cfg.agentConfigs.path} 0750 ${user.name} ${user.group} -"
      ]
      ++ lib.optionals cfg.dropbox.enable (lib.mapAttrsToList (
          _id: folder: "d ${cfg.dropbox.root}/${folder.directory} 0750 ${user.name} ${user.group} -"
        )
        dropboxFolders);
    services.syncthing = {
      enable = true;
      user = user.name;
      group = user.group;
      dataDir = user.home;
      configDir = "${user.home}/.config/syncthing";
      cert = config.sops.secrets."syncthing/cert".path;
      key = config.sops.secrets."syncthing/key".path;
      openDefaultPorts = true;
      guiAddress = "0.0.0.0:8384";
      guiPasswordFile = "${user.home}/.config/secrets/syncthing-gui-password";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = devices;
        folders =
          {
            hyprvibe-hosts = {
              id = "hyprvibe-hosts";
              label = "Hyprvibe hosts";
              path = cfg.folderPath;
              type = "sendreceive";
              devices = peerNames;
            };
          }
          // lib.optionalAttrs cfg.agentConfigs.enable {
            agent-configs = {
              id = "agent-configs";
              label = "Agent configs";
              path = cfg.agentConfigs.path;
              type = "sendreceive";
              devices = peerNames;
            };
          }
          // lib.optionalAttrs cfg.dropbox.enable (lib.mapAttrs (_id: folder:
            {
              id = _id;
              label = folder.label;
              path = "${cfg.dropbox.root}/${folder.directory}";
              type =
                if folder.backup or false
                then
                  if hostname == "nomad"
                  then "sendonly"
                  else "receiveonly"
                else "sendreceive";
              devices = lib.filter (name: name != hostname) dropboxPeers;
            }
            // lib.optionalAttrs ((folder.backup or false) && hostname != "nomad") {
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            })
          dropboxFolders);
      };
    };
  };
}
