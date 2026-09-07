{lib, pkgs, ...}: let
  sshKey = "/home/chrisf/.ssh/id_ed25519";
  builders = "ssh-ng://root@colony-builder x86_64-linux ${sshKey} 4 4 big-parallel -";
  colonyBuild = pkgs.writeShellApplication {
    name = "colony-build";
    runtimeInputs = [pkgs.nix pkgs.openssh];
    text = ''
      if [[ $# -eq 0 ]]; then
        echo "usage: colony-build INSTALLABLE [NIX BUILD OPTIONS...]" >&2
        echo "example: colony-build .#nixosConfigurations.$(hostname).config.system.build.toplevel" >&2
        exit 2
      fi

      if [[ ! -r ${sshKey} ]]; then
        echo "colony-build: missing SSH identity ${sshKey}" >&2
        exit 1
      fi

      exec sudo -n ${pkgs.nix}/bin/nix build \
        --max-jobs 0 \
        --builders ${lib.escapeShellArg builders} \
        --option builders-use-substitutes true \
        "$@"
    '';
  };
in {
  # This is intentionally opt-in. Merely installing this module does not add
  # Colony to the daemon's global builders list; only colony-build offloads.
  environment.systemPackages = [colonyBuild];

  environment.etc."ssh/colony-builder-known-hosts".text = ''
    colony-builder-gateway ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPdJ1dwqJcIc6AXn7LylJpraj6YWEvVUegDtwL5+8Qf
    colony-builder ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/6M/thWeyuHaNu3Z4eczBPQg2TZq8V/hp+gU+KBiOu
  '';

  programs.ssh.extraConfig = ''
    Host colony-builder-gateway
      HostName colony.jupiterbroadcasting.com
      User chris
      IdentityFile ${sshKey}
      IdentitiesOnly yes
      HostKeyAlias colony-builder-gateway
      UserKnownHostsFile /etc/ssh/colony-builder-known-hosts
      StrictHostKeyChecking yes
      ConnectTimeout 15
      ServerAliveInterval 30
      ServerAliveCountMax 6

    Host colony-builder
      HostName 127.0.0.1
      Port 3022
      User root
      IdentityFile ${sshKey}
      IdentitiesOnly yes
      ProxyJump colony-builder-gateway
      HostKeyAlias colony-builder
      UserKnownHostsFile /etc/ssh/colony-builder-known-hosts
      StrictHostKeyChecking yes
      ConnectTimeout 15
      ServerAliveInterval 30
      ServerAliveCountMax 6
  '';
}
