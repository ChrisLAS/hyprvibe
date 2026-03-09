# OpenClaw Host Admin Todo

## Goal

Make the rvbee OpenClaw deployment support real host administration from trusted agents and trusted human operators, using declarative NixOS config instead of ad hoc local state.

## Todo

- [x] Review current OpenClaw exec policy and confirm whether unrestricted or denylist mode exists.
- [x] Review rvbee NixOS modules that generate `~/.openclaw/openclaw.json`.
- [x] Remove declarative `safeBins` enforcement from the rvbee OpenClaw config merge.
- [x] Declaratively enforce `tools.exec.security = "full"` and `tools.exec.ask = "off"` in the generated OpenClaw config.
- [x] Declaratively enable `tools.elevated` with a tight trusted-sender allowlist.
- [x] Keep the sudo shim and wrapper-path ordering intact so host exec uses `/run/wrappers/bin/sudo`.
- [x] Validate the Nix evaluation/build path for rvbee.
- [ ] Review the resulting git diff, commit, and push.

## Notes

- OpenClaw exec policy supports `deny`, `allowlist`, and `full`; there is no denylist mode in the docs.
- `tools.elevated` is the documented control for `/elevated` and `! <cmd>` from trusted senders.
