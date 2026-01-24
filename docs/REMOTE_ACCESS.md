# Remote Access Configuration

This document describes the multi-host SSH setup for managing remote systems from rvbee.

## Overview

rvbee is configured to manage multiple remote hosts via SSH with:
- Passwordless SSH key authentication
- Passwordless sudo on most Linux hosts
- Multiple connection methods (Tailscale, Nebula, direct domain/IP)
- Helper scripts for common operations

## Host Inventory

### Current Status (as of 2026-01-24)

| Host | Address | User | Connection | Sudo | Key Installed |
|------|---------|------|------------|------|---------------|
| custodian | custodian.coin-noodlefish.ts.net | chrisf | Tailscale SSH | Yes | Via Tailscale |
| nixbook | nixbook.coin-noodlefish.ts.net | chrisf | Tailscale SSH | Yes | Via Tailscale |
| nixstation | nixstation.coin-noodlefish.ts.net | chrisf | Tailscale SSH | Yes | Via Tailscale |
| nodecan-1 | nodecan-1.coin-noodlefish.ts.net | chrisf | Tailscale SSH | **NO** | Via Tailscale |
| doctor | 192.168.100.2 | chrisf | Nebula VPN | Yes | Yes |
| van | van.trailertrash.io | chrisf | Direct (domain) | Yes | Yes |
| homeassistant | 172.16.0.116 | root | Direct (local IP) | N/A | Yes |

### Connection Methods Explained

**Tailscale SSH (custodian, nixbook, nixstation, nodecan-1)**
- Uses Tailscale's built-in SSH functionality
- Authenticates via Tailscale identity (no traditional SSH keys needed)
- May occasionally require re-authentication (see Troubleshooting)
- Future consideration: May switch to traditional SSH keys to avoid re-auth prompts

**Nebula VPN (doctor)**
- Direct SSH over Nebula overlay network
- Uses traditional SSH keys
- No Tailscale re-auth issues
- Connection may be slow to establish initially

**Direct Connection (van, homeassistant)**
- van: Uses domain name `van.trailertrash.io` (Tailscale SSH not working for this host)
- homeassistant: Uses local IP `172.16.0.116` (Tailscale connects to wrong container)
- Traditional SSH key authentication
- No Tailscale re-auth issues

### Pending Configuration

**nodecan-1** needs passwordless sudo configured:
```bash
ssh nodecan-1
sudo nano /etc/nixos/configuration.nix
# Add: security.sudo.wheelNeedsPassword = false;
sudo nixos-rebuild switch
```

## Initial Setup

### Step 1: Rebuild rvbee

After modifying the NixOS configuration:

```bash
cd ~/build/config
sudo nixos-rebuild switch --flake .#rvbee
```

### Step 2: Start User Services

The systemd user services may need manual start after first rebuild:

```bash
systemctl --user start setup-ssh-config setup-ssh-helper-scripts
```

### Step 3: Distribute SSH Keys

**For hosts using Tailscale SSH:**
- No key distribution needed - Tailscale handles auth
- Just ensure you're logged into Tailscale: `tailscale status`

**For hosts using traditional SSH (doctor, van):**
```bash
ssh-copy-id doctor
ssh-copy-id van
```

**For Home Assistant (automated with sshpass):**
```bash
setup-ssh-keys homeassistant
```

Or manually:
```bash
sshpass -f ~/.config/secrets/homeassistant_password ssh-copy-id homeassistant
```

### Step 4: Verify Access

```bash
check-remote-sudo
```

## Helper Scripts

### setup-ssh-keys

Distribute SSH keys to remote hosts.

```bash
# Show usage
setup-ssh-keys

# Setup single host
setup-ssh-keys custodian

# Setup all hosts (interactive)
setup-ssh-keys all

# Setup Home Assistant (automated with sshpass)
setup-ssh-keys homeassistant
```

### check-remote-sudo

Verify SSH access and sudo configuration on all hosts.

```bash
check-remote-sudo
```

### ssh-ha

SSH to Home Assistant with automatic password fallback.

```bash
# Interactive shell
ssh-ha

# Run command
ssh-ha "ls /config"
```

### remote-exec

Execute commands on multiple hosts.

```bash
# Run on all hosts
remote-exec --all "hostname"

# Run on NixOS hosts only
remote-exec --nixos "nixos-rebuild --version"

# Run on specific hosts
remote-exec custodian nixbook "uptime"
```

## Tailscale SSH Re-Authentication

### The Issue

Tailscale SSH occasionally requires re-authentication. When this happens, SSH will display:

```
# Tailscale SSH requires an additional check.
# To authenticate, visit: https://login.tailscale.com/a/XXXXXX
```

The SSH session will hang until you click the URL and authenticate.

### Impact on OpenCode/AI Sessions

When using OpenCode or an AI agent to execute remote commands:
- The SSH command may hang waiting for authentication
- The AI session will be blocked
- No visible feedback about the auth prompt

### Workaround (Current)

If an SSH command hangs or times out during an OpenCode session:

1. Open a separate terminal
2. Run: `ssh <hostname> "echo test"`
3. Click the Tailscale authentication URL if prompted
4. Return to OpenCode and retry the command

### Long-Term Solutions

**Option 1: Switch to Traditional SSH Keys (Recommended for servers)**

For hosts you manage (custodian, nodecan-1), you can disable Tailscale SSH and use traditional keys:

```bash
# 1. Copy SSH key while Tailscale SSH still works
ssh <hostname>
mkdir -p ~/.ssh
echo "$(cat ~/.ssh/id_ed25519.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# 2. Disable Tailscale SSH on that host (in tailscale admin or on host)
# Or configure to prefer traditional SSH

# 3. Update SSH config to use IP instead of Tailscale hostname if needed
```

**Option 2: Keep Tailscale SSH with Graceful Handling**

For personal devices (nixbook, nixstation) where Tailscale SSH is convenient:
- Accept occasional re-auth prompts
- Future SSH MCP server will detect these and ask for manual intervention

### Future: SSH MCP Server Handling

When we build the SSH MCP server, it will:
1. Set timeouts on all SSH commands (10 seconds default)
2. Detect Tailscale auth prompts in command output
3. Return a friendly error with the auth URL
4. Ask the user to authenticate and retry

Example expected behavior:
```
AI: I tried to run the command on custodian, but Tailscale SSH needs 
re-authentication. Please click this URL to authenticate:
https://login.tailscale.com/a/XXXXXX

Once done, let me know and I'll retry the command.
```

## Network Information

### Tailscale

- Domain: `coin-noodlefish.ts.net`
- Most hosts accessible via `<hostname>.coin-noodlefish.ts.net`
- DNS search domain is configured, so `ssh custodian` works
- **Note:** Using Tailscale hostname triggers Tailscale SSH (with re-auth issues)

### Nebula

- Subnet: `192.168.100.0/24`
- rvbee: `192.168.100.10`
- doctor: `192.168.100.2`
- Connection may take 10-30 seconds to establish initially

### Local Network

- Subnet: `172.16.0.0/24`
- custodian (static): `172.16.0.10`
- homeassistant: `172.16.0.116`
- rvbee (DHCP): varies

## Secrets

Secrets are stored in `~/.config/secrets/` (not version controlled):

| File | Purpose |
|------|---------|
| `github_token` | GitHub personal access token |
| `homeassistant_password` | Home Assistant root SSH password |

## SSH Configuration

The SSH config is managed by NixOS and located at `~/.ssh/config`.

**Do not edit manually** - changes will be overwritten on service restart.

To modify SSH config:
1. Edit `~/build/config/hosts/rvbee/system.nix`
2. Rebuild: `sudo nixos-rebuild switch --flake .#rvbee`
3. Restart services: `systemctl --user restart setup-ssh-config`

## Troubleshooting

### SSH connection fails

1. Check if host is reachable: `ping <hostname>`
2. Check Tailscale status: `tailscale status | grep <hostname>`
3. Try with verbose output: `ssh -v <hostname>`

### SSH hangs (no response)

**For Tailscale hosts:**
- Likely a Tailscale SSH re-auth prompt
- Open another terminal and run: `ssh <hostname> "echo test"`
- Click the auth URL if prompted, then retry

**For other hosts:**
- Check network connectivity
- Check if SSH service is running on remote host

### Sudo requires password

1. Verify sudo config: `ssh <host> "sudo -n true && echo OK || echo FAIL"`
2. For NixOS: Check `/etc/nixos/configuration.nix` has `security.sudo.wheelNeedsPassword = false;`
3. For Ubuntu: Check `/etc/sudoers.d/chrisf` exists with `chrisf ALL=(ALL) NOPASSWD:ALL`

### Doctor connection slow

Doctor is on Nebula only. Initial connection may take 10-30 seconds while Nebula establishes the tunnel. Subsequent connections are faster.

### Van SSH fails with Tailscale name

Van's Tailscale SSH is not working correctly. Use the domain name instead:
- Correct: `ssh van` (resolves to `van.trailertrash.io` via SSH config)
- Incorrect: `ssh van.coin-noodlefish.ts.net` (won't work)

### Home Assistant SSH connects to wrong container

Home Assistant runs Tailscale in a container. Using the Tailscale name connects to that container, not the HASSOS host.
- Correct: `ssh homeassistant` (uses local IP `172.16.0.116`)
- Incorrect: `ssh homeassistant.coin-noodlefish.ts.net` (connects to Tailscale container)

### "No identities found" error with ssh-copy-id

Ensure your SSH key is loaded in the agent:
```bash
ssh-add -l                    # Check if key is loaded
ssh-add ~/.ssh/id_ed25519     # Add key if not loaded
```

## MCP Servers

OpenCode is configured with the following MCP servers:

| Server | Type | Purpose |
|--------|------|---------|
| nixos | Local | Search NixOS packages, options, Home Manager options |
| context7 | Remote | Search documentation |

Configuration: `~/.config/opencode/opencode.json`

## Future Plans

### SSH MCP Server

Once basic SSH access is stable, we plan to build an MCP server with tools like:

| Tool | Purpose |
|------|---------|
| `ssh_exec(host, command)` | Execute remote commands |
| `ssh_read(host, path)` | Read remote files |
| `ssh_write(host, path, content)` | Write remote files |
| `ssh_sudo(host, command)` | Execute with sudo |
| `ssh_logs(host, service, lines)` | Tail service logs |
| `ssh_nixos_rebuild(host)` | Rebuild NixOS systems |

**Design considerations:**
- Implement timeouts on all operations (10 second default)
- Detect Tailscale re-auth prompts and report gracefully
- Fail fast with actionable error messages
- Support both Tailscale SSH and traditional SSH hosts

### Migrate to Traditional SSH Keys

For servers (custodian, nodecan-1), consider migrating from Tailscale SSH to traditional SSH keys to:
- Eliminate re-authentication prompts
- Improve reliability for automated operations
- Maintain consistent behavior across all hosts

This can be done incrementally per host as needed.

### Nebula Migration

Long-term consideration: Migrate all hosts to Nebula for consistent overlay networking. This would:
- Eliminate Tailscale SSH re-auth issues entirely
- Provide consistent connection method across all hosts
- Require updating SSH config to use Nebula IPs/names

## Related Files

| File | Purpose |
|------|---------|
| `~/build/config/hosts/rvbee/system.nix` | SSH config source |
| `~/build/config/configs/remote-hosts.json` | Host inventory (JSON) |
| `~/.ssh/config` | Generated SSH config (do not edit) |
| `~/.local/bin/setup-ssh-keys` | Key distribution script |
| `~/.local/bin/check-remote-sudo` | Sudo verification script |
| `~/.local/bin/ssh-ha` | Home Assistant SSH wrapper |
| `~/.local/bin/remote-exec` | Multi-host command execution |
| `~/.config/opencode/opencode.json` | OpenCode MCP configuration |
