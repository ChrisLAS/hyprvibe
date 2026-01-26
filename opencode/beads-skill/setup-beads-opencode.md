# Complete Beads + OpenCode Setup Guide

This guide provides a complete, reproducible setup for Beads (bd) integration with OpenCode on new workstations.

## Prerequisites

- ✅ **OpenCode installed** and accessible
- ✅ **Beads CLI (`bd`) installed** and available in PATH
- ✅ **Git configured** for the system

## Quick Setup (Copy/Paste Commands)

### 1. Install OpenCode Beads Plugin

```bash
# Create OpenCode config directory (if it doesn't exist)
mkdir -p ~/.config/opencode

# Backup existing config (if it exists)
if [ -f ~/.config/opencode/opencode.json ]; then
    cp ~/.config/opencode/opencode.json ~/.config/opencode/opencode.json.backup
fi

# Add Beads plugin to OpenCode config
# Note: This preserves any existing configuration and adds the plugin
python3 << 'EOF'
import json
import os

config_path = os.path.expanduser("~/.config/opencode/opencode.json")

# Load existing config or create new one
if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Add plugin configuration
if "plugin" not in config:
    config["plugin"] = ["opencode-beads"]
elif "opencode-beads" not in config["plugin"]:
    config["plugin"].append("opencode-beads")

# Add schema if not present
if "$schema" not in config:
    config["$schema"] = "https://opencode.ai/config.json"

# Write updated config
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)

print("✅ OpenCode plugin configuration updated")
EOF
```

### 2. Install Beads Operator Skill

```bash
# Create skills directory
mkdir -p ~/.config/opencode/skills

# Copy skill files (assuming this directory contains the setup files)
if [ -d "./beads" ]; then
    cp -r ./beads ~/.config/opencode/skills/beads
    echo "✅ Beads skill installed from local directory"
elif [ -f "./SKILL.md" ]; then
    mkdir -p ~/.config/opencode/skills/beads
    cp -r . ~/.config/opencode/skills/beads/
    echo "✅ Beads skill installed from current directory"
else
    echo "❌ Skill files not found. Ensure beads-skill directory contents are available."
    exit 1
fi
```

### 3. Verify Installation

```bash
# Check OpenCode can find the skill
echo "🔍 Verifying skill installation..."
ls -la ~/.config/opencode/skills/beads/SKILL.md

# Verify OpenCode configuration
echo "🔍 Verifying OpenCode configuration..."
cat ~/.config/opencode/opencode.json | grep -A 5 plugin

# Check Beads CLI availability
echo "🔍 Verifying Beads CLI..."
which bd
bd --version
```

## Usage: First Project Setup

Once installation is complete, initialize Beads in your first project:

```bash
# Navigate to your project
cd your-project

# Initialize Beads
bd init --quiet

# Show onboarding information
bd onboard

# Verify installation
bd doctor

# Create your first issue
bd create "Initial project setup" -p 1 -t task

# See ready work
bd ready
```

## Verification Steps

### 1. Test OpenCode Integration

Start OpenCode and verify:
- Plugin loads without errors
- `/bd-*` commands are available
- Skill appears in skill tool listing

### 2. Test Beads Functionality

In any project directory:
```bash
bd init          # Initialize
bd doctor        # Health check
bd status        # Show overview
bd list          # List issues
```

## What This Setup Provides

### OpenCode Plugin (`opencode-beads`)
- **Automatic context injection**: `bd prime` runs on session start
- **CLI integration**: All `bd` commands available as `/bd-*` commands
- **Session persistence**: Context maintained across OpenCode sessions

### Beads Operator Skill
- **Best practices**: Automatic guidance for proper Beads usage
- **Workflow patterns**: Reference for common operations
- **Session handoffs**: Procedures for multi-agent collaboration
- **Git discipline**: Ensures proper tracking and sync

## Expected Structure After Setup

```
~/.config/opencode/
├── opencode.json          # Plugin configuration added
└── skills/
    └── beads/
        ├── SKILL.md       # Main skill definition
        ├── README.md      # Skill documentation
        └── references/
            ├── quick-reference.md
            └── workflow-patterns.md
```

## Troubleshooting

### Plugin Not Loading
```bash
# Check OpenCode logs for plugin errors
# Restart OpenCode and check startup messages

# Verify network connectivity (plugin downloaded from npm)
curl -s https://registry.npmjs.org/opencode-beads
```

### Skill Not Available
```bash
# Verify skill file structure
ls -la ~/.config/opencode/skills/beads/
cat ~/.config/opencode/skills/beads/SKILL.md | head -10

# Check frontmatter syntax
python3 << 'EOF'
import yaml
with open(os.path.expanduser("~/.config/opencode/skills/beads/SKILL.md"), 'r') as f:
    content = f.read()
    if content.startswith('---'):
        try:
            frontmatter_end = content.find('---', 3)
            frontmatter = content[3:frontmatter_end]
            yaml.safe_load(frontmatter)
            print("✅ SKILL.md frontmatter is valid")
        except yaml.YAMLError as e:
            print(f"❌ SKILL.md frontmatter error: {e}")
EOF
```

### Beads Commands Not Working
```bash
# Check Beads installation
which bd
bd version

# Initialize in a test project
mkdir -p /tmp/test-beads
cd /tmp/test-beads
bd init
bd status
```

## Next Steps

1. **Create your first Beads-enabled project**
2. **Explore the skill references** (`quick-reference.md`, `workflow-patterns.md`)
3. **Read the Beads documentation**: https://steveyegge.github.io/beads/
4. **Practice basic workflows** with sample issues

## File Locations

- **OpenCode config**: `~/.config/opencode/opencode.json`
- **Beads skill**: `~/.config/opencode/skills/beads/`
- **Plugin cache**: `~/.cache/opencode/node_modules/`
- **Beads project data**: `[project]/.beads/`

## Support

- **Beads documentation**: https://steveyegge.github.io/beads/
- **OpenCode documentation**: https://opencode.ai/docs/
- **Beads GitHub**: https://github.com/steveyegge/beads
- **OpenCode GitHub**: https://github.com/anomalyco/opencode

---

*This setup provides per-project Beads initialization with OpenCode integration, optimized for AI agent workflows and multi-session project management.*