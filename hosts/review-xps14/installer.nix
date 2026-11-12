{ lib, pkgs, modulesPath, targetSystem, sourceTree, ... }:
{
  imports = [ (modulesPath + "/installer/netboot/netboot-minimal.nix") ];
  networking.hostName = "review-xps14-installer";
  networking.networkmanager.enable = lib.mkForce true;
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.wifi.powersave = false;
  hardware.enableRedistributableFirmware = lib.mkForce true;
  hardware.firmware = [ pkgs.sof-firmware ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # The generic installer enables ZFS, which does not support this pinned new
  # kernel. This machine installs ext4; do not bypass a broken-package guard.
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.kernelParams = [ "console=tty0" ];
  boot.loader.timeout = 5;
  documentation.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  nix.channel.enable = lib.mkForce false;
  system.extraDependencies = lib.mkForce [ ];
  netboot.storeContents = [ targetSystem sourceTree ];
  netboot.squashfsCompression = "zstd -Xcompression-level 6";
  users.users.root.openssh.authorizedKeys.keys = import ./ssh-keys.nix;
  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "prohibit-password";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  # If networking fails after kexec, reboot to the untouched Ubuntu boot entry.
  # A successful live SSH check disarms this before the explicit installation.
  systemd.timers.review-installer-recovery = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "8min"; Unit = "review-installer-recovery.service"; };
  };
  systemd.services.review-installer-recovery = {
    unitConfig.ConditionPathExists = "!/run/review-xps14/confirmed";
    serviceConfig = { Type = "oneshot"; ExecStart = "${pkgs.systemd}/bin/systemctl reboot"; };
  };
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    builders = lib.mkForce "";
    max-jobs = 2;
    cores = 6;
  };

  # The private handoff lives ONLY on the Dell's existing ESP, outside Git
  # and /nix/store. Load it before systemd starts SSH/NetworkManager. Nothing
  # erases disks automatically: installation starts only after live SSH checks.
  boot.postBootCommands = lib.mkBefore ''
    mkdir -p /run/review-xps14-esp
    mount -t vfat -o ro,umask=0077 \
      /dev/disk/by-partuuid/45f7de6f-afa3-4036-88ec-d7107551957e /run/review-xps14-esp
    ${pkgs.gnutar}/bin/tar -xzf /run/review-xps14-esp/review-xps14/private-handoff.tar.gz -C /
    umount /run/review-xps14-esp
  '';
  environment.systemPackages = with pkgs; [
    git jq rsync gptfdisk e2fsprogs dosfstools pciutils usbutils
    (writeShellScriptBin "review-xps14-install" ''
      export REVIEW_TARGET_SYSTEM=${targetSystem}
      export REVIEW_SOURCE_TREE=${sourceTree}
      exec ${pkgs.bash}/bin/bash ${./install.sh} "$@"
    '')
  ];
  system.stateVersion = "26.11";
}
