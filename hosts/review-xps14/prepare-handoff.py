"""Ubuntu-side, Dell-local provisioning; never print or publish secret values."""
from pathlib import Path
import configparser
import hashlib
import os
import shutil
import subprocess
import tarfile
import tempfile

assert os.geteuid() == 0
assert Path("/sys/class/dmi/id/product_name").read_text().strip() == "XPS 14 DA14260"
state = Path("/home/dell/.local/state/review-xps14-install")
destination = Path("/boot/efi/review-xps14")
destination.mkdir(mode=0o700, exist_ok=True)

with tempfile.TemporaryDirectory(prefix="private-handoff-", dir=state) as tmp:
    root = Path(tmp)
    nm = root / "etc/NetworkManager/system-connections"
    ssh = root / "etc/ssh"
    provision = root / "var/lib/review-xps14"
    run = root / "run/review-xps14"
    for d in (nm, ssh, provision, run):
        d.mkdir(mode=0o700, parents=True)
    interface = subprocess.check_output(["ip", "-o", "route", "show", "default"], text=True).split(" dev ")[1].split()[0]
    active_uuid = subprocess.check_output(["nmcli", "-g", "GENERAL.CON-UUID", "device", "show", interface], text=True).strip()
    mac = Path(f"/sys/class/net/{interface}/address").read_text().strip()
    matches = []
    profiles = list(Path("/etc/NetworkManager/system-connections").glob("*"))
    profiles += list(Path("/run/NetworkManager/system-connections").glob("*"))
    for source in profiles:
        if not source.is_file():
            continue
        profile = configparser.ConfigParser(interpolation=None, strict=False)
        profile.read(source)
        if profile.get("connection", "uuid", fallback="") != active_uuid:
            continue
        # Keep the same active MAC/DHCP identity and allow the new chrisf user.
        profile["connection"]["permissions"] = ""
        profile["connection"]["autoconnect"] = "true"
        if "wifi" in profile:
            profile["wifi"]["cloned-mac-address"] = mac
        target = nm / "review-wifi.nmconnection"
        with target.open("w") as output:
            profile.write(output, space_around_delimiters=False)
        target.chmod(0o600)
        matches.append(source)
    assert len(matches) == 1, "Require exactly the active Wi-Fi connection profile"
    for source in Path("/etc/ssh").glob("ssh_host_*"):
        shutil.copy2(source, ssh / source.name)
    shadow = next(line.split(":")[1] for line in Path("/etc/shadow").read_text().splitlines() if line.startswith("dell:"))
    assert shadow and shadow[0] not in "!*", "Existing login password must be usable"
    password = provision / "login-password-hash"
    password.write_text(shadow + "\n")
    password.chmod(0o600)
    # Source snapshot is refreshed only after the exact validated source is committed.
    bundle = state / "source.tar.gz"
    if bundle.exists():
        shutil.copy2(bundle, run / "source.tar.gz")
    archive = destination / "private-handoff.tar.gz"
    with tarfile.open(archive, "w:gz", format=tarfile.PAX_FORMAT) as output:
        for child in root.iterdir():
            output.add(child, arcname=child.name)
    archive.chmod(0o600)
    print("Private handoff staged on Dell ESP; active Wi-Fi, host identity and existing login password retained.")
    print("Source snapshot included:", bundle.exists())
    print("Handoff SHA256:", hashlib.sha256(archive.read_bytes()).hexdigest())
    # Check required material by name only; never print archive member contents.
    with tarfile.open(archive) as check:
        names = set(check.getnames())
    assert "etc/NetworkManager/system-connections/review-wifi.nmconnection" in names
    assert "etc/ssh/ssh_host_ed25519_key" in names
    assert "var/lib/review-xps14/login-password-hash" in names
