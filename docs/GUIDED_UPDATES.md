# Guided desktop updates

Use **`nixstation-update`** by default on this host. It builds in Nixstation's
local store because Colony has unresolved cross-store NAR mismatches. `--colony`
remains available for explicit parity work and requires full owner verification.
The shared implementation is pinned by `colony-client`; host configuration and
the owning branch remain in this repository.

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

Nixstation guided commands default to the owner-local route. Ordinary `nix build`
and `nixos-rebuild` also stay local. Use `build --colony`, `validate --colony` and
`boot --colony` only for explicit Colony parity work. Nixvader guided commands
default to Colony; use their `--local` option for an explicit owner-local build.
There is no silent fallback.

Kernel exception: systemd 261 `hwdb.bin` has a reviewed owning-host route because
Colony's 5.4 kernel lacks required statx mount-ID support. The coordinator binds
the exact recipe/source/output, builds missing prerequisites on Colony, then
requests `colony-kernel@ID` locally (one job, two cores, 2 GiB, eight minutes).
Output manifests are verified on Nomad and Colony before normal remote work
continues. Existing valid outputs are reused. Progress explicitly names the
exception; unknown failures still stop. Policy/recovery details live in Nomad's
`hosts/nomad/colony-builder/KERNEL-EXCEPTIONS.md`.

The owning-host worker runs from the active system generation. Updating the
`colony-client` pin does not change the helper used during that same candidate's
build. If an exact owner recovery requires changed helper behavior, build the
pinned helper and use a temporary `colony-kernel@` systemd drop-in for that
worker, preserving its 480-second limit, 2-core quota and 2 GiB memory cap. The
runtime drop-in is not durable source; the validated candidate carries the
declarative helper update and a reboot removes the temporary override.

Local exception outputs are unsigned. Only these pinned fleet copies use a
per-command signature override plus content/manifest verification; global cache
trust settings remain unchanged. The initial diagnosed copy rejection has an
explicit hash-bound transport continuation, separate from the kernel budget.
The later diagnosed udev failure has a separate `recover-udev` gate bound to the
same job, exact failed attempt, plan, receipt, and reviewed udev derivations.
An owner-policy deployment defect has a separate `recover-udev-owner` repair
gate; it cannot consume or reset the normal udev recovery budget.

The wrapper snapshots dirty `flake.lock` using a private index; it never includes
unrelated staged/unstaged/untracked work. Commit intended source changes first.
Validation builds the exact committed candidate and checks NixOS assertions.
`commit` promotes that same snapshot, preserving its identity. No independent
shared Beads database migration is needed for this workflow.

Nixvader uses `/home/chrisf/build/config` on `main` and systemd-boot. Nixstation
uses `/home/chrisf/build/config/hyprvibe` on `rollout/opencode2-nixstation` and
BIOS GRUB. Keep the deployed wrapper's owning-branch guard: the 2026-10-29
main reconciliation can fast-forward that branch to the same published main
revision, rather than weakening its policy or discarding host-specific fixes.

Boot staging requires a clean owning checkout, exact published branch revision,
matching validation receipt, retained output, dry activation and exact boot
assets. It does not run a new full build. Neither wrapper switches or reboots.
Nixstation live activation always requires Chris's explicit permission.

Ctrl-C stops the foreground monitor, not systemd-owned work. Rerun the same
command to reconnect. Jobs are keyed by host/revision, with one bounded admission
recovery. Failed or uncertain outcomes require receipt/log inspection rather
than a new key or a blind retry. Progress goes to Operations Kanban and the
`colony-builds` Telegram lane. Slow Starlink uploads are displayed separately
from build activities; a warm Colony store reuses identical dependencies.

Local state: `~/.local/state/HOST-update/`. Root receipts: `/var/lib/colony-jobs`.
Nomad's `hosts/nomad/colony-builder/GUIDED-UPDATES.md` describes the shared
protocol, exact-output staging and tests.
