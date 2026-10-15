{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hyprvibe.opencode2Client;
  opencode2 = pkgs.callPackage ../../pkgs/opencode2-beta {};
  pluginPkgs = import inputs.opencode-plugin-nixpkgs { system = pkgs.stdenv.hostPlatform.system; };
  opencodeGoalPlugin = pluginPkgs.callPackage ../../pkgs/opencode-goal-plugin.nix {};

  client = name: endpoint: credentials: key: directory:
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.python3}/bin/python3 ${../../pkgs/opencode2-client.py} \
        ${lib.getExe opencode2} ${lib.escapeShellArg endpoint} \
        ${lib.escapeShellArg credentials} ${lib.escapeShellArg key} \
        ${lib.escapeShellArg directory} "$@"
    '';
  opencode2Nomad = client "opencode2-nomad" cfg.serverUrl cfg.secretFile "OPENCODE_PASSWORD" cfg.projectRoot;
  opencode2Default = client "opencode2" cfg.serverUrl cfg.secretFile "OPENCODE_PASSWORD" cfg.projectRoot;
  opencodeAlias = client "opencode" cfg.serverUrl cfg.secretFile "OPENCODE_PASSWORD" cfg.projectRoot;
  opencode2Showfactory = client "opencode2-showfactory" cfg.showfactoryServerUrl
    cfg.showfactorySecretFile "OPENCODE_SERVER_PASSWORD" cfg.showfactoryServerProjectRoot;
  opencode2ShowfactoryHermes = client "opencode2-showfactory-hermes" cfg.serverUrl
    cfg.secretFile "OPENCODE_PASSWORD" cfg.showfactoryProjectRoot;
  opencode2NomadStatus = pkgs.writeShellScriptBin "opencode2-nomad-status" ''
    exec ${opencode2Nomad}/bin/opencode2-nomad api get /api/info
  '';
in {
  options.hyprvibe.opencode2Client = {
    enable = lib.mkEnableOption "OpenCode 2 stable client for the Nomad server";

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://nomad.coin-noodlefish.ts.net:8444";
      description = "Tailnet URL of the OpenCode 2 server";
    };

    projectRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/chrisf/build/nomad-nixos";
      description = "Nomad-side project selected by a no-argument remote TUI";
    };

    showfactoryProjectRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/opencode/showfactory";
      description = "Local mirror used to scope the Showfactory TUI state";
    };

    showfactoryServerUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://100.65.102.108:49374";
      description = "Tailnet URL of Showfactory's OpenCode 2 backend";
    };

    showfactoryServerProjectRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes/workspace";
      description = "Showfactory-side workspace opened by a no-argument TUI";
    };

    showfactorySecretFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/.config/secrets/showfactory-opencode2.env";
      description = "Local secret file containing OPENCODE_SERVER_PASSWORD";
    };

    secretFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/.config/secrets/opencode2-server.env";
      description = "Local environment file containing OPENCODE_PASSWORD";
    };
  };

  config = lib.mkIf cfg.enable {
    # V2 clients use backend-owned config; retire the V1 config generator here.
    hyprvibe.opencode.enable = lib.mkForce false;
    # The Nomad server advertises the TUI entrypoint by its immutable store
    # path. Keep the plugin in every remote client closure so that path exists
    # when the OpenCode TUI loads the server's active plugin list.
    environment.etc."opencode2/plugins/goal-mode".source = opencodeGoalPlugin;

    systemd.tmpfiles.rules = [
      # OpenCode 2.0.20's remote TUI needs this server-side path to exist
      # locally too; workspace reads and writes still run on Showfactory.
      "d /var/lib/hermes 0755 root root -"
      "d /var/lib/hermes/workspace 0755 root root -"
      "d ${builtins.dirOf cfg.showfactoryProjectRoot} 0755 ${config.hyprvibe.user.name} ${config.hyprvibe.user.group} -"
      "d ${cfg.showfactoryProjectRoot} 0755 ${config.hyprvibe.user.name} ${config.hyprvibe.user.group} -"
    ];

    environment.systemPackages = [
      opencode2
      (lib.hiPrio opencode2Default)
      (lib.hiPrio opencodeAlias)
      opencode2Nomad
      opencode2Showfactory
      opencode2ShowfactoryHermes
      opencode2NomadStatus
    ];
  };
}
