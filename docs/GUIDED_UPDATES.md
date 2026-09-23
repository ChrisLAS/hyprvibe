# Guided desktop updates

Use **`nixstation-update`** by default on this host. Chris approved the supervised
Colony workflow on 2026-09-22. Shared implementation is pinned by `colony-client`;
host configuration and the owning branch remain in this repository.

```console
nixstation-update update [INPUT...]
nixstation-update validate
nixstation-update diff
nixstation-update commit
nixstation-update push
nixstation-update boot
# After a separately approved reboot:
nixstation-update health
```

`all [INPUT...]` performs update → validate → promote → push → boot-stage.
`build` builds/transfers only. `resume` continues validation without choosing
newer inputs. `status` reports the existing fleet/job/attempt and transfer.
The corresponding wrapper on Nixvader is `nixvader-update`.

Colony is the default only for these guided wrappers. Ordinary `nix build` and
`nixos-rebuild` stay local. Use `build --local`, `validate --local` and
`boot --local` to select the explicit local route. There is no silent fallback.

Kernel exception: systemd 261 `hwdb.bin` has a reviewed owning-host route because
Colony's 5.4 kernel lacks required statx mount-ID support. The coordinator binds
the exact recipe/source/output, builds missing prerequisites on Colony, then
requests `colony-kernel@ID` locally (one job, two cores, 2 GiB, eight minutes).
Output manifests are verified on Nomad and Colony before normal remote work
continues. Existing valid outputs are reused. Progress explicitly names the
exception; unknown failures still stop. Policy/recovery details live in Nomad's
`hosts/nomad/colony-builder/KERNEL-EXCEPTIONS.md`.

Local exception outputs are unsigned. Only these pinned fleet copies use a
per-command signature override plus content/manifest verification; global cache
trust settings remain unchanged. The initial diagnosed copy rejection has an
explicit hash-bound transport continuation, separate from the kernel budget.
The later diagnosed udev failure has a separate `recover-udev` gate bound to the
same job, exact failed attempt, plan, receipt, and reviewed udev derivations.
An owner-policy deployment defect has a separate `recover-udev-owner` repair
gate; it cannot consume or reset the normal udev recovery budget.

Only dirty `flake.lock` is snapshotted into a committed candidate with a private
Git index. Unrelated dirty source must be intentionally committed first.
Validation checks the exact built revision and NixOS assertions; `commit`
fast-forwards to that same validated snapshot. It does not migrate Beads state.

Nixstation owns `/home/chrisf/build/config/hyprvibe` on
`rollout/opencode2-nixstation`, using BIOS GRUB. Nixvader owns
`/home/chrisf/build/config` on `main`, using systemd-boot.

Boot staging requires clean published owning source, matching validation,
retained output, dry activation and verified default boot assets. It never
rebuilds a different output, live-switches or reboots. Nixstation live switch
and reboot require Chris's explicit approval.

Ctrl-C stops the monitor while existing systemd workers continue. Rerun the
same command to resume its deterministic host/revision identity. One bounded
admission recovery is allowed; failures/uncertain effects require receipt and
rolling-log diagnosis rather than blind retries. Kanban/Telegram follow the
normal Colony integration. Dependency upload can dominate on Starlink.

Operator state: `~/.local/state/nixstation-update/`; root receipts:
`/var/lib/colony-jobs`. Shared protocol and tests:
Nomad `hosts/nomad/colony-builder/GUIDED-UPDATES.md`.
