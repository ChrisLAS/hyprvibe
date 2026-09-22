# Colony Remote Builder

Nixvader has an explicit remote-build client for the isolated builder on
`colony.jupiterbroadcasting.com`. The client is intentionally opt-in: ordinary
`nix build` and `nixos-rebuild` commands remain local.

## Use

**Prefer `nixvader-update` / `nixstation-update` for host builds and updates.**
Chris approved default Colony routing for these guided wrappers. See
[GUIDED_UPDATES.md](GUIDED_UPDATES.md) for resumable builds, explicit local
override, validation and exact-output boot staging. The low-level submission
command below remains available for explicit manual orchestration.

From the Hyprvibe checkout:

```console
colony-build .#nixosConfigurations.nixvader.config.system.build.toplevel
```

The source client now submits clean committed snapshots to Nomad for planning
and queueing. It does not dispatch a build. Both Nixvader and Nixstation import
the shared implementation from the revision-pinned, non-flake `colony-client`
input. Host configuration remains owned here. Existing deployed generations
continue using their previous client until an explicitly staged rollout.

Reviewed boot policies are enabled: systemd-boot on Nixvader, BIOS GRUB on
Nixstation. The guided wrappers require clean published source and matching
host validation before explicit `boot`; build alone never stages or activates.

Before starting a large build, check for an existing coordinated job on
Nixvader, Nomad, Nixobs, or Colony. Never interrupt or compete with an active
remote build merely to test this client.

## Boundaries

- Client source: `modules/colony-builder-client.nix`.
- Nixvader import: `hosts/nixvader/system.nix`.
- Container and authoritative operations source:
  `hosts/nomad/colony-builder/` in the Nomad NixOS repository.
- Colony runs production Matrix; do not make it an automatic or mandatory
  builder without a new operator decision.
- The builder is reached through Colony's existing SSH service and a
  loopback-only container port. Both host keys are pinned.
- A direct `ssh colony-builder` shell is expected to fail because the container
  permits only `nix-daemon --stdio`.
- Do not copy the client module's host-specific SSH identity path to hosts where
  the `chrisf` key does not exist.

After deploying the coordinator client, verify the protocol marker:

```console
cat /etc/colony-client.json
```

It must identify protocol 1, coordinator mode and Nomad. Root-assisted fleet
admission on Nomad must also establish all peers idle and enrolled before an
explicit smoke-build release. Direct builder connectivity is no longer a client
acceptance requirement; only Nomad retains execution authority after rollout.
