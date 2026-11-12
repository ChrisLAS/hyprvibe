#!/usr/bin/env bash
# Run only inside the verified RAM installer, after network/SSH checks.
set -euo pipefail
mode=${1:-}
[[ "$mode" == --check || "$mode" == --erase-ubuntu ]] || { echo 'Use --check, or --erase-ubuntu to replace Ubuntu on this Dell.' >&2; exit 2; }
[[ $EUID == 0 && $(hostname) == review-xps14-installer ]]
[[ $(findmnt -n -o FSTYPE /) == tmpfs ]]
[[ $(cat /sys/class/dmi/id/product_name) == 'XPS 14 DA14260' ]]
[[ $(cat /sys/class/block/nvme0n1/size) == 1000215216 ]]
[[ $(lsblk -n -o PARTUUID /dev/nvme0n1p3) == bdcd3564-d63a-4b5f-b341-6cbf62498e4f ]]
[[ -d ${REVIEW_TARGET_SYSTEM:?}/etc && -x $REVIEW_TARGET_SYSTEM/activate ]]
[[ -f /var/lib/review-xps14/login-password-hash ]]
[[ -f /run/review-xps14/source.tar.gz ]]
[[ -f /run/review-xps14/confirmed ]]
find /etc/NetworkManager/system-connections -name '*.nmconnection' -type f | grep -q .
[[ $(nmcli -t -f STATE general) == connected* ]]
[[ -z $(findmnt -rn -S /dev/nvme0n1p3) ]]
nix path-info --recursive "$REVIEW_TARGET_SYSTEM" >/dev/null
[[ "$mode" != --check ]] || { echo 'Installer preflight passed; no disks modified.'; exit 0; }

# Keep the ESP and OEM recovery partition. Only Ubuntu's root partition is
# reformatted; its exact original identity/size is checked above.
mkfs.ext4 -F -L nixos-review /dev/nvme0n1p3
mkdir -p /mnt
mount /dev/disk/by-label/nixos-review /mnt
mkdir -p /mnt/boot
mount -o umask=0077 /dev/disk/by-partuuid/45f7de6f-afa3-4036-88ec-d7107551957e /mnt/boot
install -d -m0700 /mnt/var/lib/review-xps14 /mnt/etc/NetworkManager/system-connections /mnt/etc/ssh
install -m0600 /var/lib/review-xps14/login-password-hash /mnt/var/lib/review-xps14/login-password-hash
cp -a /etc/NetworkManager/system-connections/*.nmconnection /mnt/etc/NetworkManager/system-connections/
cp -a /etc/ssh/ssh_host_* /mnt/etc/ssh/
# Pre-create writable user directories before activation creates root-owned parents.
mkdir -p /mnt/home/chrisf/{build/hyprvibe,.config,.cache,.local}
tar -xzf /run/review-xps14/source.tar.gz -C /mnt/home/chrisf/build/hyprvibe
chown -R 1000:100 /mnt/home/chrisf
ln -s /home/chrisf/build/hyprvibe /mnt/etc/nixos

# --system installs the exact already-built closure carried in the RAM image.
nixos-install --root /mnt --system "$REVIEW_TARGET_SYSTEM" --no-root-passwd --no-channel-copy --option builders ''
sync
test -s /mnt/boot/EFI/systemd/systemd-bootx64.efi
test -e /mnt/nix/var/nix/profiles/system
printf 'Installed %s. Inspect /mnt and reboot when ready.\n' "$REVIEW_TARGET_SYSTEM"
