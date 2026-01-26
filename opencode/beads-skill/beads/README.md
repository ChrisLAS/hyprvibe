# Beads Operator Skill for OpenCode

This skill transforms OpenCode into an excellent Beads operator, enabling distributed, git-backed issue tracking across multiple LLM sessions and machines.

## What This Skill Provides

### Core Capabilities

1. **Session Continuity** - Enables seamless handoffs between LLM sessions
2. **Git-First Workflow** - Ensures all work is properly synced and pushed
3. **Structured Tracking** - Uses Epics, Issues, Tasks, Decisions, and Handoffs
4. **Best Practices** - Follows proven patterns for AI agent collaboration

### Skill Structure

```
beads-skill/
├── SKILL.md                           # Core Beads operator instructions
└── references/
    ├── workflow-patterns.md           # Advanced patterns and real-world scenarios
    └── quick-reference.md             # Command cheat sheet
```

## Installation

### 1. Install Beads Plugin for OpenCode

```bash
opencode install joshuadavidthomas/opencode-beads
```

### 2. Add This Skill to OpenCode

Place this skill folder in your OpenCode skills directory, or package it as a `.skill` file and load it through the OpenCode interface.

### 3. Initialize Beads in Your Repository

```bash
cd /path/to/your/repo
bd onboard
```

## How It Works

### Triggering the Skill

The skill automatically activates when you:

- Ask to setup or configure Beads
- Create or manage issues, tasks, or epics
- Request session handoffs
- Track decisions
- Use Beads-related commands

### What OpenCode Will Do

When this skill is active, OpenCode will:

1. **Think in Beads** - Translate work into trackable nodes
2. **Maintain Git Discipline** - Always sync and push changes
3. **Structure Responses** - Provide Beads updates, commands, and handoffs
4. **Follow Best Practices** - Use proper node types, tags, and dependencies

### Standard Response Format

OpenCode will structure all Beads-related responses as:

- **A) Beads Updates** - Node details and changes
- **B) Commands** - Exact bd/git commands to run
- **C) Working Notes** - Assumptions and risks
- **D) Handoff Snapshot** - Context for next session

## Key Concepts

### Node Types

- **Epic** - Large initiatives (weeks/months)
- **Issue** - Feature-sized chunks (1-2 weeks)
- **Task** - Day-sized work (hours)
- **Decision** - Architectural choices (immutable when done)
- **Handoff** - Session-to-session continuity

### Standard Tags

- `scope:<area>` - infra, app, docs, monitoring
- `host:<n>` - custodian, vps, server1
- `session:<id>` - primary, llm-1, remote
- `change:<type>` - code, config, docs
- `risk:<level>` - low, med, high
- `prio:<level>` - p0, p1, p2

### Session Workflow

**Start:**
1. Run `bd doctor`
2. Pull latest: `git pull --rebase && bd sync`
3. Review last handoff
4. Plan Epic → Issues → Tasks

**During:**
1. Create nodes before work
2. Update status as you go
3. Track decisions
4. Sync frequently

**End:**
1. Update all nodes
2. Create handoff
3. Sync and push: `bd sync && git push`
4. Verify clean: `git status`

## Example Usage

### Starting a Feature

```bash
You: "I want to add user authentication to my app using Beads to track the work"

OpenCode will:
1. Create an Epic for "User Authentication"
2. Break it into Issues (login, registration, password reset)
3. Create Tasks for each Issue
4. Set up dependencies
5. Provide exact bd commands
6. Start tracking progress
```

### Ending a Session

```bash
You: "I need to stop working now, please wrap up the session"

OpenCode will:
1. Update all node statuses
2. Create a detailed handoff node
3. Run git commit, bd sync, git push
4. Verify everything is clean
5. Provide resume instructions
```

### Making Decisions

```bash
You: "Should we use PostgreSQL or MySQL for this project?"

OpenCode will:
1. Research both options
2. Create a Decision node
3. Document alternatives and rationale
4. Mark decision as done
5. Reference it in related tasks
```

## Advanced Features

### Multi-Machine Workflows

Use host tags to track work across machines:

```bash
bd create task "Setup monitoring" --tags host:vps
bd create task "Local development" --tags host:custodian
```

### Risk Management

Tag high-risk changes appropriately:

```bash
bd create task "Database migration" --tags risk:high,prio:p0
```

### Dependency Tracking

Link related work explicitly:

```bash
bd link task-002 --depends-on task-001
bd link issue-003 --blocks issue-004
```

## Reference Files

### workflow-patterns.md

Contains advanced patterns including:
- Multi-machine workflows
- Risk and priority management
- Complex dependency graphs
- Handoff strategies
- Maintenance patterns
- Anti-patterns to avoid

**When to read:** Working on complex multi-session projects, setting up cross-machine workflows, or dealing with high-risk changes.

### quick-reference.md

A cheat sheet with:
- Essential commands
- Common patterns
- Node templates
- Query examples
- Session checklists

**When to read:** Need a quick command reference or session checklist.

## Best Practices

### Do's ✅

- Run `bd doctor` daily
- Keep tasks under 1 day of work
- Always push before ending sessions
- Track architectural decisions
- Use handoffs for continuity
- Tag consistently
- Link dependencies explicitly

### Don'ts ❌

- Don't leave work unpushed
- Don't create vague task titles
- Don't skip handoff nodes
- Don't work without syncing first
- Don't make decisions without documenting them

## Troubleshooting

### Beads and Git Out of Sync

```bash
bd doctor
git pull --rebase
bd sync
```

### Lost Context Between Sessions

```bash
bd list --type handoff --sort created --limit 1
bd show <handoff-id>
```

### Finding Blocked Work

```bash
bd list --status blocked
```

## Philosophy

> **Beads is the source of truth — not chat history.**

This skill ensures that all work, decisions, and context are properly tracked in Beads so that:

1. Another LLM can resume with near-zero context
2. Work survives across sessions and machines
3. Decisions are documented with full rationale
4. Nothing is lost when a session ends

## Support

For issues with Beads itself, see:
- GitHub: https://github.com/joshuadavidthomas/opencode-beads
- Beads documentation: https://beads.dev (if available)

For issues with this skill, review the SKILL.md and reference files for guidance.
