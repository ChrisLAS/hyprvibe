{
  config,
  lib,
  pkgs,
  modulesPath,
  targetSystem,
  sourceTree,
  ...
}:
let
  # The newc archive format cannot represent a single file >= 4 GiB.
  storeChunks = pkgs.runCommand "review-store-chunks" { } ''
    mkdir "$out"
    split -b 1073741824 -d -a 4 ${config.system.build.squashfsStore} "$out/chunk-"
    hash=$(sha256sum ${config.system.build.squashfsStore} | cut -d ' ' -f1)
    printf '%s  nix-store.squashfs\n' "$hash" > "$out/squashfs.sha256"
  '';
in
{
  imports = [ (modulesPath + "/installer/netboot/netboot-minimal.nix") ];
  networking.hostName = "review-xps14-installer";
  networking.networkmanager.enable = lib.mkForce true;
  # NetworkManager enables wireless in D-Bus-controlled mode; do not disable
  # its wpa_supplicant backend with a forced wireless.enable = false.
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
  netboot.storeContents = [
    targetSystem
    sourceTree
  ];
  netboot.squashfsCompression = "zstd -Xcompression-level 6";
  system.build.netbootRamdisk = lib.mkForce (
    (pkgs.makeInitrdNG {
      inherit (config.boot.initrd) compressor compressorArgs;
      prepend = [ "${config.system.build.initialRamdisk}/initrd" ];
      contents = [
        {
          source = storeChunks;
          target = "/review-store-chunks";
        }
      ];
    }).overrideAttrs
      (old: {
        # Propagate cpio errors rather than accepting a truncated RAM store.
        buildCommand = "set -o pipefail\n" + old.buildCommand;
      })
  );
  # kexec_file_load cannot read this >4 GiB initrd; the legacy load API can.
  # Never change lockdown or other security settings to make loading succeed.
  system.build.kexecScript = lib.mkForce (
    pkgs.writeScript "kexec-boot" ''
      #!/usr/bin/env bash
      set -euo pipefail
      if [[ -r /sys/kernel/security/lockdown ]] && ! grep -q '\[none\]' /sys/kernel/security/lockdown; then
        echo "Kernel lockdown is active; stop and review boot policy." >&2
        exit 1
      fi
      SCRIPT_DIR=$(cd -- "$(dirname -- "''${BASH_SOURCE[0]}")" && pwd)
      kexec --kexec-syscall --load "$SCRIPT_DIR/bzImage" \
        --initrd="$SCRIPT_DIR/initrd.gz" \
        --command-line "init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
      kexec --exec
    ''
  );
  boot.initrd.systemd.services.review-reassemble-store = {
    description = "Reassemble and verify complete review installer RAM store";
    requiredBy = [ "sysroot.mount" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.coreutils ];
    script = ''
      set -euo pipefail
      : > /nix-store.squashfs
      for chunk in /review-store-chunks/chunk-*; do
        cat "$chunk" >> /nix-store.squashfs
        # These are disposable initrd RAM copies, never the physical disk.
        rm "$chunk"
      done
      cd /
      sha256sum -c /review-store-chunks/squashfs.sha256
    '';
  };
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
    timerConfig = {
      OnBootSec = "8min";
      Unit = "review-installer-recovery.service";
    };
  };
  systemd.services.review-installer-recovery = {
    unitConfig.ConditionPathExists = "!/run/review-xps14/confirmed";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    builders = lib.mkForce "";
    max-jobs = 2;
    cores = 6;
  };

  # nixos-init does not execute the legacy postBootCommands hook.
  boot.postBootCommands = lib.mkForce "";
  systemd.services.review-load-handoff = {
    description = "Load Dell-local private installer handoff before networking";
    wantedBy = [ "multi-user.target" ];
    requiredBy = [
      "NetworkManager.service"
      "sshd-keygen.service"
      "sshd.service"
    ];
    before = [
      "NetworkManager.service"
      "sshd-keygen.service"
      "sshd.service"
    ];
    after = [
      "local-fs.target"
      "systemd-udev-trigger.service"
    ];
    path = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.gnutar
      pkgs.gzip
      pkgs.systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      device=/dev/disk/by-partuuid/45f7de6f-afa3-4036-88ec-d7107551957e
      for attempt in $(seq 1 30); do
        test -b "$device" && break
        sleep 1
      done
      test -b "$device"
      mkdir -p /run/review-xps14-esp
      mount -t vfat -o ro,umask=0077 "$device" /run/review-xps14-esp
      trap 'umount /run/review-xps14-esp' EXIT
      tar -xzf /run/review-xps14-esp/review-xps14/private-handoff.tar.gz -C /
      test -s /etc/NetworkManager/system-connections/review-wifi.nmconnection
      test -s /etc/ssh/ssh_host_ed25519_key
      test -s /var/lib/review-xps14/login-password-hash
      test -s /run/review-xps14/source.tar.gz
      touch /run/review-xps14/handoff-loaded
      echo "Private handoff loaded; no secret values logged."
    '';
  };
  # Keep diagnostics across the automatic fallback, without logging secrets.
  systemd.timers.review-installer-diagnostics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "90s";
      OnUnitActiveSec = "90s";
    };
  };
  systemd.services.review-installer-diagnostics = {
    unitConfig.ConditionPathExists = "!/run/review-xps14/confirmed";
    path = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.systemd
      pkgs.iproute2
      pkgs.networkmanager
    ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      mkdir -p /run/review-diagnostics-esp
      mount -t vfat -o rw,umask=0077 \
        /dev/disk/by-partuuid/45f7de6f-afa3-4036-88ec-d7107551957e /run/review-diagnostics-esp
      trap 'umount /run/review-diagnostics-esp' EXIT
      mkdir -p /run/review-diagnostics-esp/review-xps14
      log=/run/review-diagnostics-esp/review-xps14/installer-diagnostics-$(cat /proc/sys/kernel/random/boot_id).log
      {
        date -u
        systemctl --failed --no-pager || true
        ip -brief address || true
        nmcli general status || true
        nmcli device status || true
        journalctl -b --no-pager -o short-monotonic || true
      } > "$log"
      sync
    '';
  };
  environment.systemPackages = with pkgs; [
    git
    jq
    rsync
    gptfdisk
    e2fsprogs
    dosfstools
    pciutils
    usbutils
    (writeShellScriptBin "review-xps14-install" ''
      export REVIEW_TARGET_SYSTEM=${targetSystem}
      export REVIEW_SOURCE_TREE=${sourceTree}
      exec ${pkgs.bash}/bin/bash ${./install.sh} "$@"
    '')
  ];
  system.stateVersion = "26.11";
}
