#!/usr/bin/env python3
"""Validate the pinned remote-only Desktop recipe and optional realized outputs.

Run from the Hyprvibe root. This never starts Desktop or reads gateway secrets.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def check_closure(output):
    closure = run("nix-store", "--query", "--requisites", str(output)).splitlines()
    forbidden = re.compile(r"-(?:hermes-agent(?:-env)?-\d|hermes-agent-env-|hermes-tui-|hermes-web-|hermes-pm-runtime)")
    unexpected = [path for path in closure if forbidden.search(path)]
    require(not unexpected, "Local Hermes runtime in closure: " + ", ".join(unexpected))
    return closure


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", required=True, choices=("nixstation", "nixvader"))
    parser.add_argument("--package", type=Path, help="already built Desktop output")
    parser.add_argument("--system", type=Path, help="already built host toplevel")
    args = parser.parse_args()

    lock = json.loads(Path("flake.lock").read_text())["nodes"]["hermes-agent"]
    tag = lock["original"]["ref"]
    version = tag.removeprefix("v")
    recipe = json.loads(run(
        "nix", "eval", "--json", "--no-update-lock-file", "--no-write-lock-file",
        f".#nixosConfigurations.{args.host}.pkgs.hermes-desktop", "--apply",
        "p: { inherit (p) version; recipe = p.installPhase; derivation = p.drvPath; }",
    ))
    require(recipe["version"] == version, "Desktop version does not match its release pin")
    require("HERMES_DESKTOP_HERMES" in recipe["recipe"], "Missing explicit backend override")
    require(not re.search(r"-hermes-agent-\d", recipe["recipe"]), "Recipe embeds a local agent")
    print(f"{args.host}: release {tag}, recipe {recipe['derivation']}")

    if args.package:
        package = args.package.resolve(strict=True)
        closure = check_closure(package)
        source_info = json.loads(run("nix", "flake", "metadata", "--json", "--no-update-lock-file",
                                     "--no-write-lock-file", f"github:NousResearch/hermes-agent/{lock['locked']['rev']}"))
        require(source_info["path"] not in closure, "Desktop retains the entire upstream source tree")
        stamp = json.loads((package / "share/hermes-desktop/install-stamp.json").read_text())
        for name, expected in {
            "commit": lock["locked"]["rev"], "baseVersion": version,
            "displayVersion": version, "tag": tag, "distribution": "nix",
            "updateMechanism": "external", "dirty": False,
        }.items():
            require(stamp.get(name) == expected, f"Incorrect install-stamp {name}")
        require(not stamp.get("pmRuntime"), "Desktop stamp retains a local package-manager runtime")
        wrapper = (package / "bin/hermes-desktop").read_text()
        require("nix run" not in wrapper, "Desktop launcher builds at launch time")
        stubs = set(re.findall(r"/nix/store/[a-z0-9]+-hermes/bin/hermes", wrapper))
        require(len(stubs) == 1, "Desktop does not use the remote-only backend stub")
        stub = subprocess.run([stubs.pop()], capture_output=True, text=True)
        require(stub.returncode == 1 and "remote backend" in stub.stderr,
                "Local backend stub does not fail with its explanation")
        require((package / "share/icons/hicolor/1024x1024/apps/hermes.png").is_file(), "Missing app icon")
        require((package / "share/hermes-desktop/dist/node_modules/node-pty/build/Release/pty.node").is_file(),
                "Missing Electron native node-pty module")
        print(f"{args.host}: built package, provenance, native module, stub and remote-only closure passed ({len(closure)} paths)")

    if args.system:
        require(args.package is not None, "--system requires --package")
        system = args.system.resolve(strict=True)
        closure = check_closure(system)
        require(str(package) in closure, "Host closure does not contain the tested Desktop output")
        launcher = (system / "sw/bin/hermes-desktop-remote").read_text()
        require(str(package / "bin/hermes-desktop") in launcher and "nix run" not in launcher,
                "Remote launcher does not execute the tested immutable package")
        entry = (system / "sw/share/applications/hermes-desktop-remote.desktop").read_text()
        require("Exec=" in entry and "hermes-desktop-remote" in entry and "nix run" not in entry,
                "Invalid remote desktop entry")
        print(f"{args.host}: host closure and remote launcher passed ({len(closure)} paths)")


if __name__ == "__main__":
    main()
