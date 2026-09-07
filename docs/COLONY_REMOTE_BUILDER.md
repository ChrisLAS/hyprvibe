# Colony Remote Builder

Nixvader has an explicit remote-build client for the isolated builder on
`colony.jupiterbroadcasting.com`. The client is intentionally opt-in: ordinary
`nix build` and `nixos-rebuild` commands remain local.

## Use

From the Hyprvibe checkout:

```console
colony-build .#nixosConfigurations.nixvader.config.system.build.toplevel
```

`colony-build` sets local `max-jobs` to zero for that invocation, so uncached
build work is sent to Colony. Colony can fetch substitutes directly from
`cache.nixos.org`; uncached inputs and finished outputs still cross Starlink.

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

After activating a generation containing the client, an idle protocol check is:

```console
sudo nix store info --store ssh-ng://root@colony-builder
```

This checks connectivity but does not launch a derivation build. A real smoke
build must wait until no coordinated heavy build is active.
