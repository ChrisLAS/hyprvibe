# SOPS-NIX Integration

This configuration includes support for [sops-nix](https://github.com/Mic92/sops-nix), a tool for atomic secret provisioning in NixOS based on [Mozilla SOPS](https://github.com/mozilla/sops). This enables declarative, secure, and version-control-friendly secret management.

## What is SOPS-NIX?

SOPS-NIX allows you to:
- **Encrypt secrets** using age keys or GPG keys
- **Store encrypted secrets** directly in version control
- **Decrypt secrets atomically** during NixOS activation
- **Manage secret permissions** declaratively
- **Template configuration files** with embedded secrets
- **Integrate with SSH keys** for automatic key derivation
- **Support multiple formats** (YAML, JSON, INI, binary, dotenv)

## ⚠️ **IMPORTANT SECURITY NOTES**

- **Never commit unencrypted secrets** to version control
- **Backup your encryption keys** securely
- **Use strong encryption keys** (Ed25519 for age, RSA 4096+ for GPG)
- **Rotate keys periodically** and update encrypted files
- **Test decryption** before deploying to production
- **Secure your `.sops.yaml`** configuration file

## Quick Start

### 1. Enable SOPS-NIX

Add to your host configuration:

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets.yaml;
  
  # Use age with SSH key conversion (recommended)
  age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    generateKey = true;
    keyFile = "/var/lib/sops-nix/key.txt";
  };
  
  # Define your secrets
  secrets = {
    "wifi-password" = {
      mode = "0440";
      owner = "networkmanager";
      group = "networkmanager";
    };
    "user-password" = {
      neededForUsers = true;
    };
  };
};
```

### 2. Generate Encryption Keys

#### For Age (Recommended)

```bash
# Generate a new age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Or convert existing SSH Ed25519 key
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt

# Get the public key
age-keygen -y ~/.config/sops/age/keys.txt
```

#### For GPG (Alternative)

```bash
# Generate new GPG key
gpg --full-generate-key

# Or convert SSH RSA key
nix-shell -p ssh-to-pgp --run "ssh-to-pgp -private-key -i ~/.ssh/id_rsa | gpg --import --quiet"

# Get fingerprint
gpg --list-secret-keys
```

### 3. Get Host Keys

#### For Age

```bash
# From SSH host key
ssh-keyscan your-server.com | ssh-to-age
# Or locally
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
```

#### For GPG

```bash
# Convert SSH host key to GPG
ssh root@server "cat /etc/ssh/ssh_host_rsa_key" | ssh-to-pgp -o server.asc
```

### 4. Configure .sops.yaml

Create `.sops.yaml` in your repository root:

```yaml
keys:
  # Personal keys
  - &admin_alice age12zlz6lvcdk6eqaewfylg35w0syh58sm7gh53q5vvn7hd7c6nngyseftjxl
  - &admin_bob 2504791468b153b8a3963cc97ba53d1919c5dfd4
  
  # Host keys
  - &host_rvbee age1rgffpespcyjn0d8jglk7km9kfrfhdyev6camd3rck6pn8y47ze4sug23v3
  - &host_nixstation age1h4w3rk5xjfgmjk8r2p9vn7q8s5t6u7v8w9x0y1z2a3b4c5d6e7f8g9h0
  
creation_rules:
  # Global secrets (accessible by all hosts)
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_alice
      - *admin_bob
      - *host_rvbee
      - *host_nixstation
      
  # Host-specific secrets
  - path_regex: secrets/rvbee/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_alice
      - *admin_bob
      - *host_rvbee
      
  - path_regex: secrets/nixstation/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_alice
      - *admin_bob
      - *host_nixstation
```

### 5. Create Secrets File

```bash
# Create and edit secrets
nix-shell -p sops --run "sops secrets/common.yaml"
```

Example `secrets/common.yaml`:
```yaml
# WiFi credentials
wifi_password: "super-secret-password"

# User passwords (use mkpasswd to hash)
user_passwords:
  alice: "$y$j9T$abc123..."
  bob: "$y$j9T$def456..."

# API tokens
github_token: "ghp_abcdef123456..."

# SSH keys
ssh_keys:
  deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
    ...
    -----END OPENSSH PRIVATE KEY-----

# Database credentials
database:
  host: "db.example.com"
  user: "app_user"
  password: "database-secret-password"
  
# TLS certificates
tls:
  certificate: |
    -----BEGIN CERTIFICATE-----
    MIIDjTCCAnWgAwIBAgIJAL...
    -----END CERTIFICATE-----
  private_key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvgIBADANBgkqhkiG9w...
    -----END PRIVATE KEY-----
```

## Configuration Examples

### Basic Setup with Age

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets/common.yaml;
  
  # Age configuration (recommended)
  age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    generateKey = true;
    keyFile = "/var/lib/sops-nix/key.txt";
  };
  
  secrets = {
    "wifi_password" = {
      owner = "networkmanager";
      group = "networkmanager";
      mode = "0440";
    };
    
    "github_token" = {
      owner = "git";
      mode = "0400";
    };
  };
};
```

### GPG-Based Setup

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets/common.yaml;
  
  # GPG configuration
  gnupg = {
    enable = true;
    home = "/var/lib/sops-nix/gnupg";
    sshKeyPaths = [ "/etc/ssh/ssh_host_rsa_key" ];
  };
  
  secrets = {
    "database/password" = {
      owner = "postgres";
      group = "postgres";
      mode = "0440";
    };
  };
};
```

### User Password Management

```nix
{ config, ... }: {
  hyprvibe.sops = {
    enable = true;
    defaultSopsFile = ./secrets/users.yaml;
    
    secrets = {
      "user_passwords/alice" = {
        neededForUsers = true;
      };
      "user_passwords/bob" = {
        neededForUsers = true;
      };
    };
  };
  
  users.users = {
    alice = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."user_passwords/alice".path;
      extraGroups = [ "wheel" ];
    };
    
    bob = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."user_passwords/bob".path;
      extraGroups = [ "users" ];
    };
  };
}
```

### Service Configuration with Templates

```nix
{ config, ... }: {
  hyprvibe.sops = {
    enable = true;
    defaultSopsFile = ./secrets/services.yaml;
    
    secrets = {
      "database/host" = {};
      "database/user" = {};
      "database/password" = {};
      "api/github_token" = {};
    };
    
    templates = {
      "app-config.json" = {
        content = ''
          {
            "database": {
              "host": "${config.sops.placeholder."database/host"}",
              "user": "${config.sops.placeholder."database/user"}",
              "password": "${config.sops.placeholder."database/password"}"
            },
            "github": {
              "token": "${config.sops.placeholder."api/github_token"}"
            }
          }
        '';
        owner = "myapp";
        group = "myapp";
        mode = "0440";
      };
    };
  };
  
  systemd.services.myapp = {
    description = "My Application";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.myapp}/bin/myapp --config ${config.sops.templates."app-config.json".path}";
      User = "myapp";
      Group = "myapp";
      Restart = "always";
    };
  };
  
  users.users.myapp = {
    isSystemUser = true;
    group = "myapp";
  };
  users.groups.myapp = {};
}
```

### Web Server with TLS

```nix
{ config, ... }: {
  hyprvibe.sops = {
    enable = true;
    defaultSopsFile = ./secrets/tls.yaml;
    
    secrets = {
      "tls/certificate" = {
        owner = "nginx";
        group = "nginx";
        mode = "0440";
        path = "/var/lib/ssl/server.crt";
        restartUnits = [ "nginx.service" ];
      };
      
      "tls/private_key" = {
        owner = "nginx";
        group = "nginx";
        mode = "0400";
        path = "/var/lib/ssl/server.key";
        restartUnits = [ "nginx.service" ];
      };
    };
  };
  
  services.nginx = {
    enable = true;
    virtualHosts."example.com" = {
      enableACME = false;
      forceSSL = true;
      sslCertificate = config.sops.secrets."tls/certificate".path;
      sslCertificateKey = config.sops.secrets."tls/private_key".path;
      
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };
    };
  };
}
```

### Multiple File Formats

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets/default.yaml;
  defaultSopsFormat = "yaml";
  
  secrets = {
    # YAML secret (default)
    "api_key" = {};
    
    # JSON secret
    "config_json" = {
      sopsFile = ./secrets/config.json;
      format = "json";
      key = "database_config";
    };
    
    # Binary secret (certificate)
    "certificate" = {
      sopsFile = ./secrets/server.crt;
      format = "binary";
      owner = "nginx";
      mode = "0444";
    };
    
    # Environment file
    "app_env" = {
      sopsFile = ./secrets/app.env;
      format = "env";
      key = "DATABASE_URL";
    };
  };
};
```

## Advanced Features

### Automatic Service Restart

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets.yaml;
  
  secrets = {
    "nginx/ssl_cert" = {
      owner = "nginx";
      restartUnits = [ "nginx.service" ];
    };
    
    "systemd/service_token" = {
      reloadUnits = [ "my-daemon.service" ];
    };
  };
};
```

### Custom Secret Paths

```nix
hyprvibe.sops = {
  enable = true;
  defaultSopsFile = ./secrets.yaml;
  
  secrets = {
    "app_config" = {
      path = "/etc/myapp/config.secret";
      owner = "myapp";
      mode = "0440";
    };
    
    "ssh_key" = {
      path = "/home/deploy/.ssh/id_rsa";
      owner = "deploy";
      mode = "0600";
    };
  };
};
```

### Per-Host Secrets

```nix
# hosts/rvbee/system.nix
{ config, ... }: {
  hyprvibe.sops = {
    enable = true;
    defaultSopsFile = ./secrets/rvbee.yaml;
    
    secrets = {
      "wifi_password" = {
        owner = "networkmanager";
        group = "networkmanager";
      };
      
      "gaming/steam_token" = {
        owner = "gaming";
      };
    };
  };
  
  # Also include global secrets
  sops.secrets = {
    "global_api_key" = {
      sopsFile = ../../secrets/global.yaml;
    };
  };
}
```

## Encryption Key Management

### Age Key Generation

```bash
# Generate new age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Display public key
age-keygen -y ~/.config/sops/age/keys.txt

# Convert SSH Ed25519 key to age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt

# Convert public SSH key to age
ssh-to-age < ~/.ssh/id_ed25519.pub
```

### GPG Key Management

```bash
# Generate GPG key
gpg --full-generate-key

# List keys
gpg --list-secret-keys

# Export public key
gpg --armor --export-secret-keys YOUR_FINGERPRINT > private.asc
gpg --armor --export YOUR_FINGERPRINT > public.asc

# Convert SSH RSA key to GPG
ssh-to-pgp -private-key -i ~/.ssh/id_rsa | gpg --import --quiet
ssh-to-pgp -i ~/.ssh/id_rsa -o public.asc
```

### Host Key Extraction

```bash
# Age from SSH Ed25519
ssh-keyscan hostname | ssh-to-age
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

# GPG from SSH RSA
ssh hostname "cat /etc/ssh/ssh_host_rsa_key" | ssh-to-pgp -o hostname.asc
cat /etc/ssh/ssh_host_rsa_key.pub | ssh-to-pgp > hostname.asc
```

## Secrets File Management

### Creating Secrets

```bash
# Create new secrets file
nix-shell -p sops --run "sops secrets/new.yaml"

# Edit existing file
nix-shell -p sops --run "sops secrets/existing.yaml"

# Specify format explicitly
nix-shell -p sops --run "sops --input-type json secrets/config.json"
```

### Updating Keys

```bash
# Update keys for all secrets after adding new hosts
find secrets -name "*.yaml" -exec nix-shell -p sops --run "sops updatekeys {}" \;

# Update specific file
nix-shell -p sops --run "sops updatekeys secrets/database.yaml"
```

### Viewing Secrets

```bash
# View decrypted content (don't save)
nix-shell -p sops --run "sops -d secrets/database.yaml"

# Extract specific key
nix-shell -p sops --run "sops -d --extract '[\"database\"][\"password\"]' secrets/database.yaml"
```

## File Format Examples

### YAML Format

```yaml
# secrets/database.yaml
database:
  host: postgres.example.com
  port: 5432
  username: app_user
  password: super_secret_password
  ssl_cert: |
    -----BEGIN CERTIFICATE-----
    MIIDjTCCAnWgAwIBAgIJAL...
    -----END CERTIFICATE-----

api_keys:
  github: ghp_abcdef123456789
  stripe: sk_test_abcdef123456789
```

### JSON Format

```json
{
  "database": {
    "connection_string": "postgresql://user:pass@host:5432/db"
  },
  "auth": {
    "jwt_secret": "your-jwt-secret-here",
    "oauth": {
      "client_id": "oauth_client_id",
      "client_secret": "oauth_client_secret"
    }
  }
}
```

### Environment Format

```env
# secrets/app.env
DATABASE_URL=postgresql://user:pass@localhost:5432/myapp
REDIS_URL=redis://localhost:6379/0
API_KEY=your-secret-api-key
JWT_SECRET=your-jwt-secret
STRIPE_SECRET_KEY=sk_test_abc123
```

### INI Format

```ini
# secrets/config.ini
[database]
host = localhost
port = 5432
username = myapp
password = secret_password

[api]
key = your_api_key_here
secret = your_api_secret_here

[email]
smtp_username = smtp_user
smtp_password = smtp_secret
```

## Security Best Practices

### Key Security

1. **Use Strong Keys**
   - Ed25519 for SSH/age keys
   - RSA 4096+ for GPG keys
   - Generate keys on secure systems

2. **Key Storage**
   - Store private keys securely
   - Use hardware security modules when available
   - Backup keys to secure offline storage

3. **Access Control**
   - Limit who can access private keys
   - Use separate keys for different environments
   - Rotate keys periodically

### Secret Management

1. **File Permissions**
   - Use minimal required permissions (e.g., 0400, 0440)
   - Set appropriate ownership
   - Avoid world-readable secrets

2. **Rotation**
   - Rotate secrets regularly
   - Have a key rotation procedure
   - Test secret updates before deployment

3. **Auditing**
   - Track who has access to which secrets
   - Log secret access where possible
   - Review access permissions regularly

### Development Workflow

1. **Testing**
   - Test secret decryption in development
   - Validate secret permissions
   - Verify service restarts work correctly

2. **Deployment**
   - Use separate secrets for different environments
   - Validate secrets exist before deployment
   - Have rollback procedures

3. **Monitoring**
   - Monitor for failed secret decryption
   - Alert on permission errors
   - Track secret usage

## Troubleshooting

### Common Issues

#### Secret Decryption Fails

```bash
# Check if age key exists
ls -la /var/lib/sops-nix/key.txt

# Verify age key can decrypt
nix-shell -p sops --run "sops -d secrets/test.yaml"

# Check SSH key permissions
ls -la /etc/ssh/ssh_host_*_key

# Test SSH to age conversion
cat /etc/ssh/ssh_host_ed25519_key.pub | nix-shell -p ssh-to-age --run ssh-to-age
```

#### Permission Errors

```bash
# Check secret file permissions
ls -la /run/secrets/

# Verify user/group exists
id username
getent group groupname

# Check systemd service user
systemctl show myservice.service | grep User
```

#### Template Issues

```bash
# Check if placeholders are resolved
cat /run/secrets.d/*/template_name

# Verify template syntax
nix-instantiate --eval -E 'with import <nixpkgs> {}; config.sops.templates."name".content'
```

#### GPG Issues

```bash
# Check GPG home permissions
ls -la /var/lib/sops-nix/gnupg/

# List imported keys
GNUPGHOME=/var/lib/sops-nix/gnupg gpg --list-keys

# Test GPG decryption
GNUPGHOME=/var/lib/sops-nix/gnupg sops -d secrets/test.yaml
```

### Debug Mode

```bash
# Enable debug logging
SOPS_DEBUG=1 sops -d secrets/test.yaml

# Check systemd service logs
journalctl -u sops-nix.service

# Verify activation script
nixos-rebuild dry-activate --flake .#hostname
```

## Integration Examples

### With Home Manager

```nix
# home-manager configuration
{ config, ... }: {
  home.homeDirectory = "/home/alice";
  
  sops = {
    age.keyFile = "/home/alice/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/personal.yaml;
    
    secrets = {
      "personal/ssh_key" = {
        path = "${config.home.homeDirectory}/.ssh/id_rsa";
        mode = "0600";
      };
      
      "personal/git_token" = {};
    };
  };
  
  programs.git = {
    enable = true;
    extraConfig = {
      credential."https://github.com" = {
        helper = "!f() { echo 'password='$(cat ${config.sops.secrets."personal/git_token".path}); }; f";
      };
    };
  };
}
```

### With Cloud Providers

```nix
# AWS KMS example (via environment variables)
{ config, ... }: {
  systemd.services.sops-nix = {
    environment = {
      AWS_ACCESS_KEY_ID = "your-access-key";
      AWS_SECRET_ACCESS_KEY = "your-secret-key";
      AWS_DEFAULT_REGION = "us-west-2";
    };
  };
  
  hyprvibe.sops = {
    enable = true;
    # SOPS will use AWS KMS for encryption if configured in .sops.yaml
    defaultSopsFile = ./secrets/aws-encrypted.yaml;
  };
}
```

### With Containers

```nix
# Docker container with secrets
{ config, ... }: {
  hyprvibe.sops = {
    enable = true;
    defaultSopsFile = ./secrets/containers.yaml;
    
    secrets = {
      "docker/registry_password" = {
        owner = "docker";
        group = "docker";
      };
      
      "app/database_url" = {
        owner = "app";
        mode = "0440";
      };
    };
  };
  
  virtualisation.docker.enable = true;
  
  systemd.services.my-container = {
    description = "My Application Container";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    
    script = ''
      ${pkgs.docker}/bin/docker run \
        --name myapp \
        --env-file ${config.sops.secrets."app/database_url".path} \
        --restart unless-stopped \
        myapp:latest
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
```

## Migration Guide

### From Plain Text Secrets

```bash
# 1. Create sops file from existing secrets
echo "database_password: $(cat /etc/secrets/db_password)" | sops -e /dev/stdin > secrets/database.yaml

# 2. Update configuration to use sops
# Replace: passwordFile = "/etc/secrets/db_password";
# With: passwordFile = config.sops.secrets.database_password.path;
```

### From Other Secret Managers

```bash
# From pass
pass show database/password | sops -e --input-type raw /dev/stdin > secrets/database.yaml

# From vault
vault kv get -field=password secret/database | sops -e --input-type raw /dev/stdin > secrets/database.yaml
```

## Performance Considerations

### Startup Time

- Secrets are decrypted during activation
- Large numbers of secrets can slow boot time
- Consider grouping related secrets

### Storage

- Encrypted secrets are stored in Nix store
- Original files remain on disk
- Use `.gitattributes` for git efficiency:

```gitattributes
# .gitattributes
*.yaml diff=sopsdiffer
*.json diff=sopsdiffer
```

### Network

- Cloud KMS requires network access
- Consider caching for offline scenarios
- Age/GPG work offline

## Further Reading

- [SOPS-NIX GitHub Repository](https://github.com/Mic92/sops-nix)
- [Mozilla SOPS Documentation](https://github.com/mozilla/sops)
- [Age Encryption Specification](https://age-encryption.org/)
- [NixOS Manual - Security](https://nixos.org/manual/nixos/stable/#sec-security)
- [SOPS-NIX Examples](https://github.com/Mic92/sops-nix/tree/master/example)

## Support and Community

- [GitHub Issues](https://github.com/Mic92/sops-nix/issues)
- [NixOS Discourse](https://discourse.nixos.org/)
- [Matrix Chat](https://matrix.to/#/#sops-nix:matrix.org)