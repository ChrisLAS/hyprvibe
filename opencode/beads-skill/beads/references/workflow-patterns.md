# Beads Workflow Patterns

This reference contains advanced patterns and real-world scenarios for using Beads effectively.

## Multi-Machine Workflows

### Pattern: Working Across Multiple Hosts

When work spans multiple machines (e.g., local dev, staging server, production):

```bash
# On custodian (local machine)
bd create epic "Deploy monitoring stack"
bd create issue "Setup Prometheus" --parent epic-001 --tags host:vps
bd create issue "Configure Grafana" --parent epic-001 --tags host:vps
bd create issue "Local dashboard dev" --parent epic-001 --tags host:custodian

bd sync
git push

# On VPS
git pull
bd sync
bd show issue-001
bd update issue-001 --status in_progress
# ... work ...
bd update issue-001 --status done
bd sync
git push

# Back on custodian
git pull
bd sync
bd show issue-001  # See VPS work completed
```

### Pattern: Session Handoffs Between Humans and LLMs

```bash
# Human creates high-level Epic
bd create epic "Q1 Feature Development" --tags session:planning

# Human creates Issues for LLM
bd create issue "Implement user profiles" --parent epic-001 --tags session:llm-primary
bd create issue "Add profile photos" --parent epic-001 --tags session:llm-primary

# LLM creates Tasks and executes
bd create task "Create User model" --parent issue-001
bd create task "Add profile API endpoints" --parent issue-001
# ... LLM completes work and creates handoff ...

# Human reviews handoff, continues
bd show handoff-001
bd create issue "Code review fixes" --tags session:human-review
```

## Risk and Priority Management

### Pattern: High-Risk Changes

For changes that could break production:

```bash
bd create task "Migrate to new database schema" \
  --tags risk:high,prio:p0,change:code \
  --body "Purpose: Update schema for v2 features
Acceptance: All tests pass, zero downtime
Risks:
- Data loss if migration fails
- Downtime if rollback needed
Mitigation:
- Full backup before migration
- Test on staging first
- Prepare rollback script
Next Action: Create backup script"

# Create subtasks for risk mitigation
bd create task "Create backup script" --parent task-001 --tags risk:high
bd create task "Test on staging" --parent task-001 --tags risk:high
bd link task-002 --depends-on task-001
```

### Pattern: Priority Triage

```bash
# P0: Must fix now (production broken)
bd create issue "Production API returning 500" --tags prio:p0,risk:high

# P1: Important (user-facing bug)
bd create issue "Login form validation broken" --tags prio:p1,risk:med

# P2: Nice to have (enhancement)
bd create issue "Add dark mode" --tags prio:p2,risk:low

# Query by priority
bd list --tags prio:p0
```

## Decision Documentation

### Pattern: Architecture Decisions

For major architectural choices:

```bash
bd create decision "Microservices vs Monolith" \
  --tags scope:infra,change:architecture \
  --body "Purpose: Choose architecture for v2

Context:
- Current system is monolith (50k LOC)
- Team of 3 developers
- Need to scale to 10k users

Options Considered:
1. Microservices
   Pros: Independent scaling, team autonomy
   Cons: Complexity, distributed debugging
2. Modular Monolith
   Pros: Simpler ops, easier debugging
   Cons: Coupled deployment
3. Hybrid (monolith + async workers)
   Pros: Balanced approach
   Cons: Some complexity

Decision: Modular Monolith with async workers

Rationale:
- Team size doesn't justify microservices overhead
- Can extract services later if needed
- Workers handle async tasks (email, reports)
- Maintains deployment simplicity

Rejected:
- Pure microservices: Too complex for team size
- Pure monolith: Can't handle async workload

References:
- https://martinfowler.com/bliki/MonolithFirst.html
- Internal doc: docs/architecture-2024.md"

bd update decision-001 --status done
```

### Pattern: Technical Spike Decisions

For research/investigation results:

```bash
bd create decision "GraphQL client library selection" \
  --tags scope:app,change:dependencies \
  --body "Purpose: Choose GraphQL client for React app

Spike Duration: 2 days
Libraries Evaluated: Apollo Client, urql, React Query + graphql-request

Findings:
- Apollo: Full-featured, 50kb bundle, complex setup
- urql: Lightweight 25kb, simpler API, good caching
- React Query: 20kb, familiar API, manual GraphQL handling

Decision: urql

Rationale:
- Best balance of features and bundle size
- Built-in caching sufficient for our needs
- Simpler than Apollo for team to learn

Trade-offs Accepted:
- Less ecosystem than Apollo
- Fewer advanced features (acceptable for MVP)

Benchmarks:
- Bundle size: urql 25kb vs Apollo 50kb
- Initial render: urql 120ms vs Apollo 180ms

Next Action: Add urql to dependencies"
```

## Epic → Issue → Task Hierarchies

### Pattern: Feature Development

```bash
# Epic: Quarter-long initiative
bd create epic "Q1: User Engagement Features" --tags scope:app,prio:p0

# Issues: Feature-sized chunks (1-2 weeks)
bd create issue "User profiles" --parent epic-001 --tags scope:app
bd create issue "Social sharing" --parent epic-001 --tags scope:app
bd create issue "Activity feed" --parent epic-001 --tags scope:app

# Tasks: Day-sized work
bd create task "Design profile schema" --parent issue-001 --tags change:code
bd create task "Create API endpoints" --parent issue-001 --tags change:code
bd create task "Build profile UI" --parent issue-001 --tags change:code
bd create task "Write integration tests" --parent issue-001 --tags change:code

# Dependencies
bd link task-002 --depends-on task-001
bd link task-003 --depends-on task-002
bd link task-004 --depends-on task-003
```

### Pattern: Infrastructure Epic

```bash
bd create epic "Production Infrastructure" --tags scope:infra

bd create issue "Monitoring setup" --parent epic-001 --tags scope:monitoring
bd create issue "CI/CD pipeline" --parent epic-001 --tags scope:infra
bd create issue "Database backups" --parent epic-001 --tags scope:infra

# Monitoring tasks
bd create task "Install Prometheus" --parent issue-001 --tags host:vps
bd create task "Configure alerting" --parent issue-001 --tags host:vps
bd create task "Create Grafana dashboards" --parent issue-001 --tags host:vps

# CI/CD tasks
bd create task "Setup GitHub Actions" --parent issue-002 --tags scope:infra
bd create task "Add deployment pipeline" --parent issue-002 --tags scope:infra
bd create task "Configure secrets" --parent issue-002 --tags scope:infra
```

## Complex Dependency Graphs

### Pattern: Parallel Workstreams

When multiple independent features can proceed simultaneously:

```bash
# Main epic
bd create epic "v2.0 Release" --tags prio:p0

# Parallel issues
bd create issue "Authentication overhaul" --parent epic-001 --tags scope:auth
bd create issue "New dashboard UI" --parent epic-001 --tags scope:ui
bd create issue "API v2 endpoints" --parent epic-001 --tags scope:api

# Dashboard depends on API, but Auth is independent
bd link issue-002 --depends-on issue-003
# issue-001 has no dependencies - can start immediately

# Tasks can be worked in parallel across issues
bd create task "Design new login flow" --parent issue-001
bd create task "Create dashboard mockups" --parent issue-002
bd create task "Design API schema" --parent issue-003

# Start work on independent streams
bd update task-001 --status in_progress --tags session:llm-1
bd update task-003 --status in_progress --tags session:llm-2
```

### Pattern: Blocking Dependencies

When one feature must complete before another can start:

```bash
bd create issue "Database migration" --tags prio:p0,risk:high
bd create issue "Update ORM models" --tags prio:p0
bd create issue "Refactor API layer" --tags prio:p1
bd create issue "Update frontend" --tags prio:p1

# Chain dependencies
bd link issue-002 --depends-on issue-001  # ORM needs DB migrated
bd link issue-003 --depends-on issue-002  # API needs new ORM
bd link issue-004 --depends-on issue-003  # Frontend needs new API

# Can only work on issue-001 initially
bd update issue-001 --status in_progress

# Once issue-001 done, issue-002 can start
bd update issue-001 --status done
bd update issue-002 --status in_progress
```

## Handoff Strategies

### Pattern: Detailed Session Handoff

```bash
bd create handoff "Session 2025-01-26 16:30 handoff" \
  --tags session:primary \
  --body "Session Duration: 2 hours
LLM: Claude Sonnet 4

Completed This Session:
- ✅ task-045: Implemented user login endpoint
- ✅ task-046: Added JWT token generation
- ✅ task-047: Created login integration tests
- ✅ decision-012: Chose bcrypt for password hashing

In Progress:
- 🔄 task-048: Add rate limiting middleware (80% done)
  - Code written, needs tests
  - See: src/middleware/rateLimit.js
  - Remaining: Write unit tests

Blocked:
- ❌ task-049: Deploy to staging
  - Blocked by: infra team needs to provision server
  - Ticket: INFRA-234

Next Session Should:
1. Finish tests for task-048
2. Review and merge rate limiting PR
3. Create task for token refresh logic
4. Check status of INFRA-234

Context for Next LLM:
- Using Express.js framework
- JWT secret in .env file
- Test db: users_test
- Rate limit: 100 req/hour per IP
- Decision log: All auth decisions in decision-auth-*

Files Changed:
- src/routes/auth.js (login endpoint)
- src/middleware/jwt.js (token validation)
- tests/integration/auth.test.js

Dependencies Installed:
- jsonwebtoken@9.0.0
- bcrypt@5.1.0
- express-rate-limit@6.7.0

Commands to Resume:
$ cd /path/to/project
$ git pull
$ bd sync
$ bd show task-048
$ npm test

Gotchas:
- JWT secret must be 32+ chars
- Bcrypt rounds set to 12 (performance vs security balance)
- Rate limiter uses in-memory store (switch to Redis for production)"
```

### Pattern: Emergency Handoff

For urgent mid-session handoffs:

```bash
bd create handoff "URGENT: Production down handoff" \
  --tags prio:p0,session:emergency \
  --body "STATUS: PRODUCTION API RETURNING 500

Time: 2025-01-26 14:30 PST
Duration So Far: 15 minutes

Issue:
- All API endpoints returning 500
- Started ~14:15 PST
- Error logs show DB connection timeout

Actions Taken:
1. ✅ Checked server health - CPU/Memory normal
2. ✅ Verified DB is up - responds to ping
3. ✅ Checked connection pool - EXHAUSTED
4. 🔄 Investigating why pool exhausted

Current Theory:
- Connection leak in recent deployment
- Deployed: user-profiles feature (commit abc123)
- Suspect: src/db/users.js not closing connections

Next Actions:
1. IMMEDIATE: Restart API server (will reset pool)
2. Roll back to previous deploy (commit def456)
3. Investigate connection leak in users.js
4. Add connection pool monitoring

Commands:
$ ssh production-api-1
$ sudo systemctl restart api-service
$ git revert abc123 --no-commit
$ git push production

Monitoring:
- Watch: https://grafana.example.com/db-pool
- Alert channel: #incidents slack

DO NOT:
- Deploy any new code until leak found
- Modify DB configuration
- Restart DB server"
```

## Maintenance Patterns

### Pattern: Weekly Review

```bash
# Create review handoff weekly
bd create handoff "Week 04 2025 review" \
  --tags session:review \
  --body "Week: Jan 22-26, 2025

Completed: 12 tasks, 3 issues
In Progress: 8 tasks, 2 issues
Blocked: 1 task

Velocity: 12 tasks/week (up from 8 last week)

Key Decisions Made:
- decision-015: Migrated to TypeScript
- decision-016: Added E2E testing framework

Blockers Resolved:
- INFRA-234: Staging server provisioned

New Blockers:
- task-065: Waiting on design mockups

Tech Debt Created:
- TODO in auth.js: Add refresh token rotation
- TODO in users.js: Optimize bulk update query

Next Week Focus:
- Complete user profiles feature
- Start social sharing feature
- Pay down TODO items in auth module"
```

### Pattern: Quarterly Planning

```bash
bd create epic "Q2 2025 Roadmap" --tags session:planning,prio:p0

bd create handoff "Q1 2025 retrospective" \
  --body "Q1 Completed: 15 issues, 87 tasks

Major Achievements:
- ✅ User authentication system
- ✅ Profile management
- ✅ CI/CD pipeline
- ✅ Monitoring infrastructure

Metrics:
- Uptime: 99.8%
- API latency p95: 120ms
- Test coverage: 87%
- Velocity: 10 tasks/week average

What Went Well:
- Strong decision documentation
- Effective LLM handoffs
- Good test coverage

What Needs Improvement:
- Too many P1 bugs escaped to production
- Handoff nodes sometimes lacking detail
- Risk assessment on high-impact changes

Q2 Focus Areas:
1. Quality: Reduce production bugs
2. Performance: Improve API latency
3. Features: Social sharing, activity feed
4. Tech debt: Refactor auth module

Process Changes:
- Mandatory risk assessment for P0 tasks
- Weekly review handoffs
- Stricter test requirements for critical paths"
```

## Query Patterns

### Finding Related Work

```bash
# All tasks for a specific scope
bd list --tags scope:auth

# High-priority incomplete work
bd list --tags prio:p0 --status !done

# Work for specific host
bd list --tags host:vps

# Recent decisions
bd list --type decision --sort created --limit 10

# Blocked tasks
bd list --tags blocked

# Session-specific work
bd list --tags session:llm-primary
```

### Audit Trails

```bash
# All changes to infrastructure
bd list --tags scope:infra,change:config

# High-risk changes
bd list --tags risk:high

# Architecture decisions
bd list --type decision --tags scope:infra
```

## Anti-Patterns to Avoid

### ❌ Tasks Too Large

```bash
# BAD: Vague, multi-week task
bd create task "Build user system"

# GOOD: Specific, day-sized tasks
bd create task "Create User model schema"
bd create task "Add user registration endpoint"
bd create task "Add user login endpoint"
```

### ❌ Missing Dependencies

```bash
# BAD: No dependency tracking
bd create task "Deploy to production"
bd create task "Write tests"

# GOOD: Explicit dependencies
bd create task "Write tests"
bd create task "Deploy to production"
bd link task-002 --depends-on task-001
```

### ❌ Poor Handoffs

```bash
# BAD: Vague handoff
bd create handoff "Done for today" --body "Worked on stuff"

# GOOD: Detailed handoff
bd create handoff "End of session" --body "
Completed: User login endpoint
In Progress: JWT middleware (80% done, needs tests)
Next: Add refresh token logic
Context: Using Express + JWT, see decision-auth-001
Files: src/routes/auth.js, tests/auth.test.js"
```

### ❌ Skipping Decisions

```bash
# BAD: Make major choice with no decision node
# (chooses database, implements it, no documentation)

# GOOD: Document the decision
bd create decision "Database: PostgreSQL vs MySQL" \
  --body "Chose PostgreSQL for JSONB support..."
```

### ❌ Not Syncing

```bash
# BAD: End session without syncing
bd update task-001 --status done
# ... close terminal ...

# GOOD: Always sync and push
bd update task-001 --status done
git commit -am "Complete task-001"
bd sync
git push
```

## Advanced Tagging

### Multi-dimensional Tags

```bash
# Combine tags for precise filtering
bd create task "Update Prometheus config" \
  --tags scope:monitoring,host:vps,change:config,risk:med,prio:p1,session:llm-1

# Query by multiple dimensions
bd list --tags scope:monitoring,host:vps,risk:med
```

### Custom Tag Taxonomies

Extend beyond standard tags for your domain:

```bash
# For a multi-tenant SaaS
--tags tenant:acme,scope:billing

# For microservices
--tags service:auth,deployment:k8s

# For compliance
--tags compliance:gdpr,audit:required
```

## Integration with External Systems

### Pattern: Reference External Tickets

```bash
bd create task "Fix payment processing bug" \
  --body "Purpose: Resolve Stripe webhook failures

External References:
- Support ticket: SUPP-1234
- Stripe logs: https://dashboard.stripe.com/logs/abc123
- User report: https://github.com/company/app/issues/456

Root Cause: Webhook signature validation failing
Next Action: Update Stripe SDK to v10.5.0"
```

### Pattern: Link to Documentation

```bash
bd create decision "API rate limiting strategy" \
  --body "Decision: Token bucket algorithm

References:
- Algorithm explanation: docs/rate-limiting.md
- Stripe's approach: https://stripe.com/blog/rate-limiters
- Our implementation: src/middleware/rateLimit.js
- Grafana dashboard: https://grafana/rate-limits"
```
