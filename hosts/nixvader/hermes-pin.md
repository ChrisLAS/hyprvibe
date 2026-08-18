# Hermes-agent pinned revision

The Nixvader Hermes Desktop launcher (`hermes-desktop-nomad`) calls:

    nix run github:NousResearch/hermes-agent/d127b27303e16e281a75438b08d19ad89ca667b4#desktop

It is pinned to a recent upstream commit because both the current HEAD
(`c9ce66e25e55332b557b6af4471fbcdee3779022`) and `d127b273` itself
produce a Python wheel whose `fixupPhase` runs

    /nix/store/.../auto-patchelf-hook/nix-support/setup-hook: line 74: auto-patchelf: command not found

so `aiohttp-retry-2.9.1` (and any other Python wheel with ELF files)
fails to build, which cascades into `hermes-agent-env` and
`hermes-desktop-0.17.0` failing.

The Nomad dashboard at `http://nomad.coin-noodlefish.ts.net:9119` is
reachable and the secret file at
`~/.config/secrets/hermes_dashboard_session_token` is readable, so the
issue is upstream, not in our launcher.

Pinning to a recent commit does not actually fix the build. It only
gives us a deterministic revision so the launcher will at least
download the same closure each time. Going back by one commit is
documented in `git log` and corresponds to a docs-only diff against the
current HEAD.

## Nixstation has the same upstream breakage

On 2026-08-17 the same launcher was invoked on `nixstation` and
recorded a different but related failure in
`~/.cache/hermes-desktop-nomad/launcher.log`:

    > src/app/session/hooks/use-session-actions.test.tsx:51:37 - error TS2307:
    >   Cannot find module '../../../../../../tests/fixtures/session-resume-active-turn.json'

Earlier Nixstation attempts also recorded:

    error: hash mismatch in fixed-output derivation
      '/nix/store/...node-v41.10.3-headers.tar.gz.drv'
    error: unable to download
      'https://api.github.com/repos/NousResearch/hermes-agent/commits/HEAD':
      HTTP error 504

Hermes Desktop is broken upstream on both Nixvader and Nixstation, for
different reasons but at the same revision. The pin should not be
removed until upstream merges a fix that the launcher can prove works.

## Removing the pin

To test a newer upstream revision:

1. On Nixvader, run with the chosen `<sha>`:

       nix run github:NousResearch/hermes-agent?ref=<sha>#desktop

   If it builds successfully, update the `nix run ...` line in
   `hosts/nixvader/system.nix` (`hermesDesktopNomad`) to that ref.

2. File an upstream issue at
   https://github.com/NousResearch/hermes-agent/issues pointing at
   either of:

   - the `auto-patchelf: command not found` failure in the Python wheel
     `fixupPhase` (Nixvader path), or
   - the missing
     `tests/fixtures/session-resume-active-turn.json` TypeScript
     import (Nixstation path), or
   - the upstream `node-v41.10.3-headers.tar.gz` fixed-output hash
     mismatch (Nixstation path).

3. Once upstream ships a working `desktop` package, remove the pinned
   revision and switch back to:

       exec ... nix run github:NousResearch/hermes-agent#desktop -- "$@"

## Why not just override the wrapper

The wrapper script is generated inside the upstream Hermes flake's
`callPackage` set; it is not directly reachable from Nixvader's source.
The cleanest durable fix is to wait for upstream to repair the
`auto-patchelf` propagation in `nix/lib.nix`'s `pythonSrc` filter
and then drop the pin.
