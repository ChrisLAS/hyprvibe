---
name: beads-operator
description: Distributed git-backed graph issue tracker for AI agents. Use this skill when working with Beads (bd) for tracking issues, tasks, decisions, and progress across multiple LLM sessions. Triggers include: setup/configuration of Beads, creating or managing issues/tasks/epics, session handoffs, tracking decisions, or any request to use Beads for project management.
---

# Beads Operator

Beads (bd) is a distributed, git-backed, graph issue tracker designed for AI agents. This skill guides you to be an excellent Beads operator, ensuring work is properly tracked across sessions and machines.

## Core Philosophy

**Beads is the source of truth — not chat history.**

Think in Beads, not chat. Translate all work into Beads nodes so another LLM can resume with near-zero context. Assume another LLM will pick this up later with no memory of this conversation.

## Installation & Setup

### First-time Setup

Install the Beads plugin for OpenCode:

```bash
opencode install joshuadavidthomas/opencode-beads
```

On first use in a repository, run:

```bash
bd onboard
```

### Daily Discipline

Run `bd doctor` once per day to verify health of the Beads system.

## Operating Mode

### 1. Atomic, Graph-First Workflow

- One intent per node
- Tasks should be small and verifiable
- Track relationships explicitly: `depends_on`, `blocks`, `relates_to`
- Track Decisions separately from Tasks (immutable once done)

### 2. Git Discipline (Mandatory)

- Beads and git must stay in sync
- Never leave work unpushed
- Work is NOT complete until `git push` succeeds

### 3. Always Ask

- "What changed?"
- "What is the next smallest verifiable step?"

## Node Types & Requirements

Every Beads node MUST include:

- **Purpose** - Why this node exists
- **Acceptance Criteria** - How to know it's done
- **Current State** - Where things stand now
- **Next Action** - What to do next

### Node Types

- **Epic** → Owns multiple Issues (large initiatives)
- **Issue** → Owns multiple Tasks (features or problems)
- **Task** → The only thing that goes Done quickly (atomic work)
- **Decision** → Rationale + alternatives rejected (immutable once Done)
- **Handoff** → Session-to-session continuity (for LLM handoffs)

### Standard Tags

Use consistently across all nodes:

- `scope:<area>` - infra, app, docs, monitoring, etc.
- `host:<name>` - custodian, ha, vps, etc.
- `session:<name>` - primary, remote, followup, etc.
- `change:<type>` - code, config, docs
- `risk:<low|med|high>` - Risk level
- `prio:<p0|p1|p2>` - Priority level

## Quick Command Reference

```bash
# Check readiness
bd ready

# View node details
bd show <id>

# Update node status
bd update <id> --status in_progress

# Close completed node
bd close <id>

# Sync with git
bd sync

# List all nodes
bd list

# Create new node
bd create issue "Title" --body "Description"
```

## Standard Response Format

For EVERY response when working with Beads, structure output as:

### A) Beads Updates

```
Node: <title>
Type: <epic|issue|task|decision|handoff>
Status: <status>
Tags: <tag1>, <tag2>
Links: depends_on <id>, blocks <id>
Body:
  Purpose: ...
  Acceptance Criteria: ...
  Current State: ...
  Next Action: ...
```

### B) Commands

Provide exact `bd` and git commands:

```bash
bd update issue-123 --status in_progress
git commit -am "Update issue-123 status"
bd sync
```

### C) Working Notes

Terse notes on:

- Assumptions
- Risks
- Unknowns

### D) Handoff Snapshot

Compact "resume here" paragraph for the next LLM session.

## Session Workflow

### Session Start

Before doing any work, gather:

1. Repo path + git remote
2. Objective for this session
3. Other machines or LLM sessions that need handoff

Then propose:

- 1 Epic
- 2-5 Issues
- 5-12 Tasks

With explicit dependencies.

### During Work

1. Create nodes BEFORE starting work
2. Update status as work progresses
3. Track all decisions in Decision nodes
4. Keep Tasks atomic and verifiable
5. Sync frequently

### Landing the Plane (MANDATORY)

When ending ANY work session, complete ALL steps:

1. **File Beads issues for remaining work**
   - Don't leave untracked work

2. **Run quality gates** (if code/config changed)
   - Tests, linters, etc.

3. **Update Beads status**
   - Close finished nodes
   - Update in-progress nodes

4. **Sync + Push (CRITICAL)**

   ```bash
   git pull --rebase
   bd sync
   git push
   git status   # Must show clean + up to date
   ```

5. **Clean up local state**
   - Remove stashes
   - Delete temp branches

6. **Verify nothing uncommitted**

   ```bash
   git status
   ```

7. **Update/Create Handoff node**
   - Summary for next LLM
   - Current state
   - Next actions

### Critical Rules for Session End

- Work is NOT complete until `git push` succeeds
- NEVER stop with local-only changes
- NEVER say "ready to push" — YOU push
- If push fails, resolve and retry until it succeeds

## Best Practices

### Node Granularity

- **Too Big**: "Implement authentication system"
- **Just Right**: "Add login endpoint", "Add JWT validation middleware", "Add password hashing"

### Decision Tracking

When making architectural or implementation decisions:

```bash
bd create decision "Use JWT for auth tokens" \
  --body "Purpose: Choose auth mechanism
Alternatives: Sessions, OAuth only
Rationale: JWT allows stateless auth, better for distributed systems
Rejected: Sessions (stateful), OAuth (overkill for MVP)"
```

### Dependencies

Always track dependencies explicitly:

```bash
bd link task-123 --depends-on task-122
bd link issue-45 --blocks issue-46
```

### Session Continuity

For multi-session work, always create/update a Handoff node:

```bash
bd create handoff "Session 2025-01-26 handoff" \
  --body "Purpose: Enable next LLM to resume
Current State: Auth endpoints implemented, tests passing
Next Action: Implement rate limiting middleware
Blockers: None
Context: Using Express.js + JWT, see decision-auth-001"
```

## Common Patterns

### Starting a New Feature

```bash
# Create hierarchy
bd create epic "User Authentication"
bd create issue "Implement login flow" --parent epic-001
bd create task "Add login endpoint" --parent issue-001
bd create task "Add JWT middleware" --parent issue-001

# Add relationships
bd link task-002 --depends-on task-001

# Start work
bd update task-001 --status in_progress
```

### Making a Decision

```bash
bd create decision "Database choice: PostgreSQL" \
  --body "Purpose: Select database for production
Alternatives: MySQL, MongoDB
Rationale: PostgreSQL for JSONB support, better concurrency
Rejected: MySQL (limited JSON), MongoDB (need ACID)"

bd update decision-001 --status done
```

### Ending a Session

```bash
# Update all nodes
bd update task-001 --status done
bd update task-002 --status in_progress

# Create handoff
bd create handoff "End of session 2025-01-26" \
  --body "Completed: Login endpoint
In Progress: JWT middleware (80% done)
Next: Finish JWT, add tests
Blockers: None"

# Sync everything
git add .
git commit -am "Session end: login endpoint complete"
bd sync
git push
```

## Troubleshooting

### Beads Not Syncing

```bash
bd doctor
git status
git pull --rebase
bd sync
```

### Lost Context

Check the most recent Handoff node:

```bash
bd list --type handoff --sort created --limit 1
bd show <handoff-id>
```

### Conflicts

```bash
git pull --rebase
# Resolve conflicts
git add .
git rebase --continue
bd sync
git push
```

## Remember

- **Beads is the memory** - Chat history is ephemeral
- **Small tasks** - Break down until tasks are < 1 hour
- **Always push** - Local work doesn't exist to other LLMs
- **Track decisions** - Future you will thank present you
- **Handoffs matter** - Next LLM session depends on good handoffs
