# Guided desktop updates

Default host workflow, approved by Chris on 2026-09-22: use `nixvader-update`
on Nixvader or `nixstation-update` on Nixstation. The shared implementation is
pinned from Nomad by `colony-client`; persistent host values stay in this repo.

```console
nixvader-update update [INPUT...]
nixvader-update validate
nixvader-update diff
nixvader-update commit
nixvader-update push
nixvader-update boot
# After a separately approved reboot:
nixvader-update health
```

Use the same commands with `nixstation-update` on Nixstation. `all [INPUT...]`
runs update, validation, promotion, push and boot staging. `build` builds and
retains the output only. `resume` continues validation without updating inputs.
`status` shows the coordinator phase, job/attempt and retained transfer evidence.

Colony is the default for these wrappers, not for ordinary Nix commands.
`build --local`, `validate --local`, and `boot --local` are explicit local-route
operations; no failure or unavailable builder causes a silent local fallback.

Kernel exception: systemd 261 `hwdb.bin` has a reviewed owning-host route because
Colony's 5.4 kernel lacks required statx mount-ID support. The coordinator binds
the exact recipe/source/output, builds missing prerequisites on Colony, then
requests `colony-kernel@ID` locally (one job, two cores, 2 GiB, eight minutes).
Output manifests are verified on Nomad and Colony before normal remote work
continues. Existing valid outputs are reused. Progress explicitly names the
exception; unknown failures still stop. Policy/recovery details live in Nomad's
`hosts/nomad/colony-builder/KERNEL-EXCEPTIONS.md`.

The wrapper snapshots dirty `flake.lock` using a private index; it never includes
unrelated staged/unstaged/untracked work. Commit intended source changes first.
Validation builds the exact committed candidate and checks NixOS assertions.
`commit` promotes that same snapshot, preserving its identity. No independent
shared Beads database migration is needed for this workflow.

Nixvader uses `/home/chrisf/build/config` on `main` and systemd-boot. Nixstation
uses `/home/chrisf/build/config/hyprvibe` on `rollout/opencode2-nixstation` and
BIOS GRUB. Do not move the rollout branch or infer another host's bootloader.

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
