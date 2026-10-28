#!/usr/bin/env python3
"""Exercise Hokum on a private D-Bus and headless Wayland seat, never the desktop.

Usage: dbus-run-session -- python3 scripts/test-hokum-integration.py \
         --hokum /path/to/hokum --sway /path/to/sway
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


def wait_for(predicate, description):
    for _ in range(100):
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError(f"Timed out: {description}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hokum", required=True)
    parser.add_argument("--sway", required=True)
    parser.add_argument("--dms", help="Also check the built DMS's embedded notification-server patch")
    parser.add_argument("--quickshell", help="Quickshell binary for the DMS disablement check")
    args = parser.parse_args()
    # Refuse a real desktop bus. Modern dbus-run-session only exports ADDRESS,
    # so verify that it is our direct parent rather than assuming a PID variable.
    parent_command = Path(f"/proc/{os.getppid()}/cmdline").read_bytes().split(b"\0")[0]
    if b"dbus-run-session" not in parent_command:
        parser.error("Run under dbus-run-session, not your desktop session bus")

    with tempfile.TemporaryDirectory(prefix="hokum-test-", dir="/tmp/opencode") as tmp:
        home = Path(tmp)
        runtime = home / "runtime"
        runtime.mkdir(mode=0o700)
        config = home / ".config/hokum/config.kdl"
        config.parent.mkdir(parents=True)
        config.write_text((Path(__file__).resolve().parents[1] / "configs/hokum/config.kdl").read_text())
        env = os.environ.copy()
        env.update(HOME=tmp, XDG_RUNTIME_DIR=str(runtime), XDG_CONFIG_HOME=str(home / ".config"),
                   XDG_STATE_HOME=str(home / ".local/state"), XDG_CACHE_HOME=str(home / ".cache"),
                   XDG_DATA_HOME=str(home / ".local/share"), WLR_BACKENDS="headless",
                   WLR_RENDERER="pixman", WLR_LIBINPUT_NO_DEVICES="1")
        for key in ("WAYLAND_DISPLAY", "DISPLAY", "SWAYSOCK", "HYPRLAND_INSTANCE_SIGNATURE"):
            env.pop(key, None)
        sway_config = home / "sway.conf"
        sway_config.write_text("xwayland disable\noutput * mode 1280x800\n")
        children = []
        logs = []

        def start(command, name):
            log = open(home / f"{name}.log", "w+")
            logs.append(log)
            process = subprocess.Popen(command, env=env, stdout=log, stderr=log)
            children.append(process)
            return process

        def run(*command):
            return subprocess.check_output(command, env=env, text=True, timeout=10).strip()

        def bus(method, *arguments):
            return run("busctl", "--user", "call", "org.freedesktop.Notifications",
                       "/org/freedesktop/Notifications", "org.freedesktop.Notifications",
                       method, *arguments)

        def owned():
            return subprocess.run(["busctl", "--user", "--quiet", "status",
                                   "org.freedesktop.Notifications"], env=env,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

        try:
            start([args.sway, "--unsupported-gpu", "--config", str(sway_config)], "sway")
            wait_for(lambda: bool(list(runtime.glob("wayland-*"))), "headless Wayland socket")
            env["WAYLAND_DISPLAY"] = next(p.name for p in runtime.glob("wayland-*") if p.is_socket())
            assert not owned(), "Private bus already has a notification server"
            if args.dms:
                assert args.quickshell, "--dms requires --quickshell"
                # Resolve/extract the built binary's embedded UI through read-only
                # IPC discovery, using a fake qs so no full shell is started.
                fake_bin = home / "bin"
                fake_bin.mkdir()
                fake_qs = fake_bin / "qs"
                fake_qs.write_text("#!/bin/sh\nexit 1\n")
                fake_qs.chmod(0o755)
                probe_env = env | {"PATH": str(fake_bin) + ":" + env["PATH"]}
                subprocess.run([args.dms, "ipc", "list"], env=probe_env, capture_output=True, timeout=10)
                embedded = list(runtime.glob("danklinux-shell/*/Services/NotificationService.qml"))
                assert len(embedded) == 1, embedded
                source = embedded[0].read_text()
                assert "property Component hyprvibeDisabledNotificationServer: Component {" in source
                # Load the exact disabled server component with real Quickshell.
                # It must neither acquire Notifications nor prevent Hokum from doing so.
                component = source[source.index("    property Component hyprvibeDisabled"):
                                   source.index("    function isFocusedScreen")]
                qml = home / "disabled-server.qml"
                qml.write_text("import QtQuick\nimport Quickshell\n"
                               "import Quickshell.Services.Notifications\n"
                               "ShellRoot { id: root\n" + component + "}\n")
                qs = start([args.quickshell, "--path", str(qml)], "disabled-dms-server")
                time.sleep(1)
                assert qs.poll() is None, "Disabled DMS server component failed to load"
                assert not owned(), "DMS still owns the notification name"
            daemon = start([args.hokum, "service"], "hokum")
            wait_for(owned, "Hokum notification bus ownership")
            info = bus("GetServerInformation")
            assert '"Hokum"' in info and '"0.1.1"' in info, info
            first = bus("Notify", "susssasa{sv}i", "Hyprvibe test", "0", "", "Migration test",
                        "Normal notification", "0", "0", "5000")
            notification_id = first.split()[1]
            replaced = bus("Notify", "susssasa{sv}i", "Hyprvibe test", notification_id, "",
                           "Replacement test", "Replaces the same card", "0", "0", "5000")
            assert replaced == first, (first, replaced)
            for state, expected in (("on", True), ("off", False), ("toggle", True)):
                assert json.loads(run(args.hokum, "dnd", state, "--json"))["dnd"] == expected
            assert "do-not-disturb #true" in config.read_text(), config.read_text()
            run(args.hokum, "dismiss", "--all")
            daemon.terminate()
            daemon.wait(timeout=10)
            wait_for(lambda: not owned(), "notification name released")
            start([args.hokum, "service"], "hokum-restarted")
            wait_for(owned, "Hokum restart")
            assert json.loads(run(args.hokum, "dnd", "--json"))["dnd"] is True
            run(args.hokum, "check", str(config))
            print("PASS: private Wayland/D-Bus ownership, notify, replacement, dismiss, DND and restart persistence")
            if args.dms:
                print("PASS: built DMS embeds the patch; its exact server component loads without claiming Notifications")
        except Exception:
            for log in logs:
                log.flush()
                log.seek(0)
                print(f"--- {log.name} ---\n{log.read()[-6000:]}")
            raise
        finally:
            for child in reversed(children):
                if child.poll() is None:
                    child.terminate()
                    try:
                        child.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        child.wait()
            for log in logs:
                log.close()


if __name__ == "__main__":
    main()
