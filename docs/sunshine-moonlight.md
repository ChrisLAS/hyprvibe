# Sunshine/Moonlight remote desktop

Hyprvibe provisions Sunshine on `nixvader` and `nixstation` for the Quest 3
Moonlight client.

## Security model

- Sunshine is started only as the `chrisf` graphical user service; the unit is
  conditioned so GDM's greeter cannot start a competing instance.
- UPnP is disabled.
- The launcher resolves the current Tailscale IPv4 address at service start and
  binds all Sunshine TCP/UDP listeners to that address only.
- Streaming encryption is required for connections classified as WAN. Tailscale
  remains the network boundary; Sunshine credentials and pairings stay in the
  existing owner-only files under `~/.config/sunshine/`.
- The host firewall remains unchanged because these hosts already use
  interface binding and have other declared services. The bind address is the
  access control for Sunshine.

## Published applications

Each host exposes:

- `Desktop` — the current Hyprland session.
- `Hermes Desktop` — launches the remote-only Hermes Desktop client, using its
  existing owner-only gateway registry.

The direct Hermes entry is convenience only; starting `Desktop` and launching
Hermes manually is equivalent.

## Pairing

1. Confirm the host service is running:

   ```bash
   systemctl --user status sunshine
   ss -ltnup | grep -E '4798[4-9]|4800[0-9]|48010'
   ```

2. In Moonlight, add the host by its Tailscale name (`nixvader` or
   `nixstation`) or its tailnet IPv4 address.
3. Select the host, enter the PIN shown by Moonlight in Sunshine’s web UI, and
   launch `Desktop`.

The Sunshine web UI is HTTPS on port `47990` (base port `47989`). Use the
existing Sunshine account on Nixstation; Nixvader requires creating its first
account during initial setup. Never put that password in this repository.

## Troubleshooting

```bash
journalctl --user -u sunshine -n 100 --no-pager
tail -n 100 ~/.config/sunshine/sunshine.log
systemctl --user restart sunshine
```

If a Tailscale address changes, restarting the user service rebinds Sunshine.
The service intentionally fails rather than falling back to a LAN or wildcard
listener when Tailscale is unavailable.
