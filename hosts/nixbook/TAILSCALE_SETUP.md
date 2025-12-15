# Tailscale Setup for Nixbook

## Current Configuration Status

Tailscale is **already configured** in the nixbook system, but there's a configuration inconsistency that should be fixed.

## Current State

1. ✅ Tailscale service is enabled: `services.tailscale.enable = true;` (line 624)
2. ⚠️ Configuration inconsistency: Using direct `services.tailscale.enable` instead of shared module option
3. ✅ Firewall is disabled: `networking.firewall.enable = false;` (line 569) - Tailscale will work fine
4. ⚠️ Routing features may not be configured properly

## What Needs to Be Done

### Option 1: Use Shared Module (Recommended)

Update `hosts/nixbook/system.nix` to use the shared module's Tailscale option:

**Remove:**
```nix
services = {
  # ...
  tailscale.enable = true;
  # ...
};
```

**Add to hyprvibe.services section (if it exists) or add:**
```nix
hyprvibe.services = {
  enable = true;
  tailscale.enable = true;  # This will configure with useRoutingFeatures = "both"
};
```

### Option 2: Keep Direct Configuration (Current)

If you want to keep the direct configuration, ensure routing features are set:

**Change:**
```nix
services.tailscale.enable = true;
```

**To:**
```nix
services.tailscale = {
  enable = true;
  useRoutingFeatures = "both";  # or "client" or "server" depending on your needs
};
```

## After Configuration

1. **Rebuild the system:**
   ```bash
   sudo nixos-rebuild switch --flake .#nixbook
   ```

2. **Start Tailscale:**
   ```bash
   sudo systemctl start tailscaled
   sudo systemctl enable tailscaled
   ```

3. **Authenticate the machine:**
   ```bash
   sudo tailscale up
   ```
   This will give you a URL to authenticate via your Tailscale account.

4. **Verify status:**
   ```bash
   tailscale status
   ```

## Routing Features Explained

- **"both"**: Can act as both a client (use routes) and server (advertise routes)
- **"client"**: Can use routes advertised by other devices, but won't advertise routes
- **"server"**: Can advertise routes but won't use routes from other devices
- **"none"**: No routing features (default)

For a laptop like nixbook, **"client"** is usually sufficient unless you want to advertise routes.

## Firewall Considerations

The firewall is currently disabled (`networking.firewall.enable = false`), which means Tailscale will work without any firewall rules. If you enable the firewall later, Tailscale will automatically configure the necessary rules via `networking.firewall.checkReversePath`.

## Troubleshooting

### Check if Tailscale is running:
```bash
sudo systemctl status tailscaled
```

### Check Tailscale logs:
```bash
sudo journalctl -u tailscaled -f
```

### Verify network connectivity:
```bash
tailscale ping <other-tailscale-device>
```

### Check if authenticated:
```bash
tailscale status
```

If you see "Logged out", run `sudo tailscale up` to authenticate.
