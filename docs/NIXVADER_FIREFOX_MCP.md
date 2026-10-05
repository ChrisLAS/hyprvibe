# Firefox MCP on Nixvader

Nomad OpenCode v2's `firefox-nixvader` server controls Chris's existing Firefox
profile on Nixvader, including tabs, cookies and logged-in sites. Nixvader must
be online and reachable via SSH, with Chris logged into its graphical session
and Firefox running in MCP mode. It is distinct from Nomad's Chrome DevTools,
Firecrawl search/crawling, and Hypruse desktop control.

`hosts/nixvader/firefox-mcp.nix` installs the pinned nixpkgs Firefox DevTools MCP
and browser/attachment launchers. MCP stdio travels over SSH; Marionette (2828) and WebDriver
BiDi (9223) retain Firefox's loopback-only defaults. There is no MCP HTTP service
or firewall change. The MCP runs as Chris and permits one controller at a time.

After activating this configuration, quit Firefox normally on Nixvader, then
open **Firefox — Nixvader MCP** from its desktop launcher, or run:

```console
firefox-mcp
```

`firefox-mcp` delegates to `nixvader-firefox-mcp-start`, which remains available
for compatibility. The desktop entry uses the same wrapper. URL and other
Firefox arguments are forwarded unchanged. The standard Firefox launcher does
not enable MCP; it reuses any already-running instance, so quit before changing
modes.

This opens the existing default profile with `--marionette` and
`--remote-debugging-port=9223`. The wrapper refuses to launch over an existing
ordinary Firefox process because startup flags cannot modify a running browser.
No profile files are copied or replaced. Firefox's own session restore determines
which tabs reopen. To return to ordinary browsing, quit Firefox and launch the
normal Firefox desktop entry. Mozilla notes that automation changes browser
fingerprinting and can trigger bot detection.

On Nomad, select/connect `firefox-nixvader` in OpenCode's MCP controls after
Firefox is ready. If offline, OpenCode reports an SSH connection failure; if
Firefox lacks its startup flags, the remote wrapper gives the restart command.
Do not substitute another browser when this host is requested. File upload and
saved output paths refer to Nixvader, not Nomad. The pinned 0.9.9 server uses `--enable-script` and enables
navigation, snapshots, input, screenshots, network/console inspection, and page
JavaScript. Tools act on the real session; ask before closing user tabs, logging
out, or submitting consequential actions. Disconnecting MCP releases control
without intentionally quitting Firefox (upstream connect-existing behavior).

Validation:

```console
nix eval .#nixosConfigurations.nixvader.config.environment.systemPackages --apply 'ps: map (p: p.name) ps'
nixvader-update validate
nixvader-update push
nixvader-update boot
```

Boot staging does not activate these launchers. A separately approved reboot or
live switch is required. Do not restart Firefox automatically during a rebuild.

Upstream: https://github.com/mozilla/firefox-devtools-mcp
