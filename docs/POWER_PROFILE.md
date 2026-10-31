# Store-backed power-profile helper

The shared power module installs `power-profile` in the system profile rather
than generating it in the user's home during root activation. Static executable
installation no longer depends on a writable home directory at boot.

## Behavior and compatibility

- Available when `hyprvibe.power.enable` is enabled.
- Supports the existing `performance`, `balanced`, `power-saver` and `status`
  arguments. The extracted runtime body preserves the previous daemon, CPU,
  Wi-Fi, disk and GPU handling; this is not a power-policy change.
- `power-profile-menu` delegates through normal `PATH`, like a direct CLI call.
  An earlier user-local override in `PATH` remains authoritative.
- Existing `~/.local/bin/power-profile` files are left untouched. There is no
  automatic cleanup, migration, replacement setup service or credential change.
- Existing daemon and user-service configuration is unchanged. Input pins and
  the lock file are unchanged.

## Safe local checks

The Python tests run with a disposable home, fake sysfs and stubbed power,
network and privileged commands. They do not invoke the real power daemon,
perform privileged writes or switch the machine's power profile.

```sh
python3 scripts/test-power-profile.py -v
```

That command runs the helper tests and explicitly skips the menu integration
case unless module-evaluation JSON is supplied. To run all nine cases, including
the menu, use the pure module check below from the repository root. It uses the
published pre-refactor module and the pinned Nixpkgs library with fake package
constructors: no real package or host closure is built.

```sh
nix eval --offline --impure --json --no-update-lock-file --no-write-lock-file \
  --option allow-import-from-derivation false \
  --option builders '' --option substituters '' --option max-jobs 0 \
  --expr 'let base = builtins.getFlake
    ("git+file://" + toString ./. + "?rev=94d63f79e4bb83e976457948ffb5bad62672ca7e");
    in import ./scripts/test-power-module.nix {
      lib = import (base.inputs.nixpkgs + "/lib");
      baselineModule = base.outPath + "/modules/shared/power.nix";
    }' \
  | python3 scripts/test-power-profile.py --module-evaluation /dev/stdin -v
```

The isolated check verifies removal of the root writer, inert disabled behavior,
unchanged service policy, helper/menu installation, exact helper source and menu
PATH delegation. The Python suite also locks the extracted body to the previous
activation heredoc's canonical fingerprint.

Offline evaluation requires the pinned source inputs to be present already;
missing inputs should be reported rather than enabling builds implicitly.

## Validation limits

These checks do not establish installed-package, full-system, VM, hardware or
post-boot behavior. Those remain separate validation gates. Preparing or reviewing
this change does not require a live switch, service restart or reboot.
