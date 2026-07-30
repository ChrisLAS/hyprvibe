# Beads - AI-Native Issue Tracking

This repository uses **Beads** for issue tracking. The local Dolt database is
the source of truth, with its history shared through the repository's Git
remote.

## What is Beads?

Beads is issue tracking that lives in your repo, making it perfect for AI coding agents and developers who want their issues close to their code. No web UI required - everything works through the CLI and integrates seamlessly with git.

**Learn more:** [github.com/steveyegge/beads](https://github.com/steveyegge/beads)

## Quick Start

After cloning this repository for the first time, restore its Dolt database:

```bash
chmod 700 .beads
bd bootstrap
```

For an already-bootstrapped checkout, use `bd dolt pull` to retrieve shared
issue history.

### Essential Commands

```bash
# Create new issues
bd create "Add user authentication"

# View all issues
bd list

# View issue details
bd show <issue-id>

# Update issue status
bd update <issue-id> --status in_progress
bd update <issue-id> --status done

# Sync issue history with the configured Dolt remote
bd dolt pull
bd dolt push
```

### Working with Issues

Issues in Beads are:
- **Versioned**: Stored in Dolt with database history independent of code commits
- **AI-friendly**: CLI-first design works perfectly with AI coding agents
- **Offline-capable**: Local reads and writes work without network access
- **Portable**: JSONL remains available as an import/export format

## Why Beads?

✨ **AI-Native Design**
- Built specifically for AI-assisted development workflows
- CLI-first interface works seamlessly with AI coding agents
- No context switching to web UIs

🚀 **Developer Focused**
- Issues live in your repo, right next to your code
- Works offline, syncs when you push
- Fast, lightweight, and stays out of your way

🔧 **Dolt Integration**
- Versioned issue data with explicit pull and push operations
- Shared through the configured Git-origin Dolt remote
- JSONL import and export for interchange and recovery

## Get Started with Beads

Try Beads in your own projects:

```bash
# Install Beads
curl -sSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Initialize in your repo
bd init

# Create your first issue
bd create "Try out Beads"
```

## Learn More

- **Documentation**: [github.com/steveyegge/beads/docs](https://github.com/steveyegge/beads/tree/main/docs)
- **Quick Start Guide**: Run `bd quickstart`
- **Examples**: [github.com/steveyegge/beads/examples](https://github.com/steveyegge/beads/tree/main/examples)

---

*Beads: Issue tracking that moves at the speed of thought* ⚡
