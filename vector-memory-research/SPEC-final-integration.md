# SPEC: Complete OpenClaw Integration & Voyage Migration

## Overview

Finalize the transition from Voyage AI to self-hosted vector memory by updating OpenClaw configuration, completing memory migration, and removing Voyage dependencies.

**Parent Issue:** https://github.com/ChrisLAS/hyprvibe/issues/17 (completed deployment)  
**This Issue:** Final integration and cleanup

---

## Current State

| Component | Status | Notes |
|-----------|--------|-------|
| Qdrant | ✅ Running | localhost:6333, "lore" collection created |
| Embedding Service | ✅ Running | localhost:18000, all-MiniLM-L6-v2 loaded |
| Test Migration | ✅ Verified | MEMORY.md and session files stored |
| OpenClaw Config | ⚠️ Still uses Voyage | `memorySearch.provider: "voyage"` |
| Full Migration | ⏳ Partial | Some files migrated, need complete run |
| Voyage Cleanup | ⏳ Pending | API key still in config |

---

## Phase 1: Update OpenClaw Configuration

### 1.1 Goal
Switch OpenClaw's `memory_search` tool from Voyage API to local Qdrant + Embedding Service.

### 1.2 Configuration Changes

**File:** `/home/chrisf/.openclaw/openclaw.json`

**Current:**
```json
"memorySearch": {
  "provider": "voyage",
  "remote": {
    "apiKey": "pa-..."
  },
  "model": "voyage-3"
}
```

**New:**
```json
"memorySearch": {
  "provider": "local",
  "local": {
    "embeddingUrl": "http://localhost:18000/embed",
    "qdrantUrl": "http://localhost:6333",
    "collection": "lore"
  },
  "fallback": {
    "provider": "voyage",
    "remote": {
      "apiKey": "pa-..."
    }
  }
}
```

### 1.3 Implementation Options

**Option A: Gateway Config Update (Preferred)**
Update `openclaw.json` directly. Requires gateway restart.

**Option B: Environment Override**
Set environment variables that override config:
```bash
export MEMORY_EMBEDDING_URL="http://localhost:18000"
export MEMORY_QDRANT_URL="http://localhost:6333"
```

**Option C: Hybrid Mode**
Keep Voyage as fallback if local fails (safest for transition).

### 1.4 Testing Plan

| Test | Command | Expected |
|------|---------|----------|
| Health check | `memory_search --health` | "local provider active" |
| Simple query | `memory_search "test query"` | Returns local results |
| Latency | Time the query | <20ms vs ~200ms before |
| Fallback | Stop Qdrant, retry | Falls back to Voyage |

---

## Phase 2: Complete Memory Migration

### 2.1 Full Migration Run

Execute migration script on all memory files:

```bash
cd /home/chrisf/code/clawdbot-local/documents
python3 ~/.openclaw/scripts/migrate_memory.py --full
```

**Files to Migrate:**
- [ ] `MEMORY.md` (core memory)
- [ ] `memory/*.md` (session logs)
- [ ] `BOOTSTRAP.md` (if exists)
- [ ] Any other `.md` files in workspace

### 2.2 Verification

After migration:
```bash
# Check point count
curl http://localhost:6333/collections/lord

# Test search
curl -X POST http://localhost:6333/collections/lore/points/search \
  -d '{"vector": [...], "limit": 5}'
```

### 2.3 Expected Results

- All markdown files stored as vectors in Qdrant
- Each file has metadata payload (source, type, migrated_at)
- Search returns relevant results from local database

---

## Phase 3: Remove Voyage Dependency

### 3.1 Cleanup Tasks

- [ ] Remove Voyage API key from `openclaw.json`
- [ ] Remove `memorySearch.fallback` (once confident)
- [ ] Archive or delete Voyage-related scripts
- [ ] Update documentation

### 3.2 Rollback Plan

If issues arise:
1. Revert `openclaw.json` to use Voyage
2. Restore API key from backup
3. Debug local services

---

## Success Criteria

- [ ] OpenClaw uses local vector memory by default
- [ ] All memory files migrated to Qdrant
- [ ] Search latency <20ms (vs ~200ms with Voyage)
- [ ] No Voyage API calls in normal operation
- [ ] Fallback works if local services fail
- [ ] GitHub issue updated with completion notes
- [ ] Documentation reflects new architecture

---

## GitHub Issue Template

**Title:** `[FINAL] Complete OpenClaw Integration - Switch to Local Vector Memory`

**Labels:** `integration`, `vector-memory`, `milestone`

**Body:**
```markdown
## Final Phase: OpenClaw Integration

Complete the transition from Voyage AI to self-hosted vector memory.

### Tasks
- [ ] Update OpenClaw config to use local endpoints
- [ ] Run full memory migration
- [ ] Remove Voyage dependency
- [ ] Performance validation

### Acceptance Criteria
- [ ] memory_search tool uses localhost:18000/6333
- [ ] All memory files in Qdrant
- [ ] <20ms search latency
- [ ] No Voyage API calls

Refs: #17 (deployment completed)
```

---

## Timeline

| Phase | Estimated | Dependencies |
|-------|-----------|--------------|
| 1. Config Update | 15 min | None |
| 2. Full Migration | 10 min | Config updated |
| 3. Voyage Cleanup | 10 min | Migration verified |
| **Total** | **~35 min** | |

---

## Notes

- Keep Voyage as fallback during transition period
- Monitor embedding service memory (512MB limit)
- Consider ROCm GPU acceleration if CPU becomes bottleneck
- Document any issues for future reference
