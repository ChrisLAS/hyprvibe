# Beads Quick Reference

## Essential Commands

### Setup & Health

```bash
bd onboard                    # First-time setup in repo
bd doctor                     # Check system health (run daily)
bd ready                      # Check if ready to work
```

### Node Operations

```bash
# Create
bd create epic "Title"
bd create issue "Title" --parent epic-001
bd create task "Title" --parent issue-001
bd create decision "Title"
bd create handoff "Title"

# View
bd list                       # List all nodes
bd list --type task          # Filter by type
bd list --tags scope:auth    # Filter by tags
bd show <id>                 # Show node details

# Update
bd update <id> --status in_progress
bd update <id> --status done
bd update <id> --tags +newtag
bd close <id>                # Mark done and close
```

### Relationships

```bash
bd link <id> --depends-on <other-id>
bd link <id> --blocks <other-id>
bd link <id> --relates-to <other-id>
```

### Sync & Git

```bash
bd sync                      # Sync beads with git
git pull --rebase            # Get remote changes
git push                     # Share your changes

# Full session end sequence
git pull --rebase
bd sync
git push
git status                   # Verify clean
```

## Common Patterns

### Start New Work

```bash
bd create issue "Feature name"
bd create task "First step" --parent issue-001
bd update task-001 --status in_progress
```

### End Session

```bash
# Update all nodes
bd update task-001 --status done
bd update task-002 --status in_progress

# Create handoff
bd create handoff "Session $(date +%F) end" \
  --body "Completed: task-001
In Progress: task-002 (75% done)
Next: Finish task-002, start task-003"

# Sync
git commit -am "Session end: completed task-001"
bd sync
git push
```

### Make Decision

```bash
bd create decision "Choice made" \
  --body "Purpose: ...
Alternatives: A, B, C
Rationale: ...
Rejected: ..."

bd update decision-001 --status done
```

## Node Status Values

- `todo` - Not started
- `in_progress` - Currently working
- `blocked` - Can't proceed
- `done` - Completed
- `wont_do` - Cancelled

## Standard Tags

```bash
scope:<area>        # infra, app, docs, monitoring, etc.
host:<name>         # custodian, vps, server1, etc.
session:<id>        # primary, llm-1, remote, etc.
change:<type>       # code, config, docs
risk:<level>        # low, med, high
prio:<level>        # p0, p1, p2
```

## Query Examples

```bash
# High priority incomplete work
bd list --tags prio:p0 --status !done

# All auth-related work
bd list --tags scope:auth

# Recent decisions
bd list --type decision --sort created --limit 5

# Work on specific host
bd list --tags host:vps

# My current session work
bd list --tags session:llm-1 --status in_progress
```

## Pre-Session Checklist

- [ ] Run `bd doctor`
- [ ] `git pull --rebase`
- [ ] `bd sync`
- [ ] Review recent handoff: `bd list --type handoff --limit 1`
- [ ] Check blocked items: `bd list --status blocked`

## End-Session Checklist

- [ ] Update all node statuses
- [ ] Create handoff node
- [ ] Run quality gates (tests/lint)
- [ ] `git commit -am "Description"`
- [ ] `bd sync`
- [ ] `git push`
- [ ] Verify: `git status` (clean)
- [ ] Clean up branches/stashes

## Emergency Commands

```bash
# If beads and git out of sync
bd doctor
git status
git pull --rebase
bd sync

# View last handoff
bd show $(bd list --type handoff --sort created --limit 1 --format id)

# Find blocking issues
bd list --status blocked

# See what changed recently
git log --oneline -10
bd list --sort updated --limit 10
```

## Node Body Template

Every node should include:

```
Purpose: Why this exists
Acceptance Criteria: How to know it's done
Current State: Where things stand
Next Action: What to do next
```

For Decisions, add:

```
Alternatives: Options considered
Rationale: Why this choice
Rejected: Why alternatives not chosen
```

For Handoffs, add:

```
Completed: What finished
In Progress: What's ongoing
Next: What comes next
Blockers: What's blocking
Context: Key info for next session
```

## Tips

- Keep tasks < 1 day of work
- Always push before ending session
- Track decisions when they happen
- Use handoffs for session continuity
- Tag consistently for easy filtering
- Link dependencies explicitly
- Beads is the source of truth, not chat
