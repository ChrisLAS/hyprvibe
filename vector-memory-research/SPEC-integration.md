# SPEC: OpenClaw Integration with Local Vector Memory

## Overview

Integrate the self-hosted Qdrant + MiniLM stack with OpenClaw, replacing Voyage AI for all memory operations. Migrate existing memory and update the `memory_search` tool to use local endpoints.

## Current State

| Component | Status | Endpoint |
|-----------|--------|----------|
| Qdrant | ✅ Running | localhost:6333 |
| Embedding Service | ✅ Running | localhost:18000 |
| Test Collection | ✅ Created | "test" (verified working) |

## Goals

1. Create production "lore" collection in Qdrant
2. Update OpenClaw's `memory_search` tool to use local endpoints
3. Migrate existing memory from Voyage to local Qdrant
4. Verify end-to-end functionality
5. Update GitHub issue #17 with completion status

---

## Phase 1: Production Collection Setup

### 1.1 Create "lore" Collection

**API Call:**
```bash
curl -X PUT http://localhost:6333/collections/lore \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 384,
      "distance": "Cosine",
      "hnsw_config": {
        "m": 16,
        "ef_construct": 100
      }
    },
    "optimizers_config": {
      "default_segment_number": 2
    }
  }'
```

**Verification:**
```bash
curl http://localhost:6333/collections/lore
```

### 1.2 Collection Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `size` | 384 | all-MiniLM-L6-v2 dimensions |
| `distance` | Cosine | Best for semantic similarity |
| `m` | 16 | HNSW graph connectivity |
| `ef_construct` | 100 | Index quality vs build time tradeoff |

---

## Phase 2: OpenClaw Integration

### 2.1 Update memory_search Tool

**File to Modify:** OpenClaw configuration (via gateway or config file)

**Current Behavior:**
- Calls Voyage API for embeddings
- Uses Voyage for vector search
- Subject to rate limits (3 RPM)

**New Behavior:**
- Call local embedding service: `POST http://localhost:18000/embed`
- Call local Qdrant: `POST http://localhost:6333/collections/lore/points/search`
- No rate limits, <10ms latency

### 2.2 Implementation Options

**Option A: Direct HTTP in Tool (Recommended)**
```python
# Pseudo-code for memory_search tool
async def memory_search(query: str, limit: int = 5):
    # 1. Generate embedding locally
    embedding_resp = await httpx.post(
        "http://localhost:18000/embed",
        json={"text": query, "normalize": True}
    )
    embedding = embedding_resp.json()["embedding"]
    
    # 2. Search Qdrant
    search_resp = await httpx.post(
        "http://localhost:6333/collections/lore/points/search",
        json={
            "vector": embedding,
            "limit": limit,
            "with_payload": True
        }
    )
    return search_resp.json()["result"]
```

**Option B: Via Gateway Config**
Update OpenClaw's memory provider configuration to point to local endpoints.

### 2.3 Fallback Strategy

Keep Voyage as fallback if local services fail:
```python
try:
    return await local_memory_search(query)
except Exception as e:
    log.warning(f"Local memory failed: {e}, falling back to Voyage")
    return await voyage_memory_search(query)
```

---

## Phase 3: Memory Migration

### 3.1 Export from Voyage

**Approach:** Use existing MEMORY.md + memory/*.md files
- These are already local markdown files
- Need to generate embeddings and store in Qdrant

### 3.2 Migration Script

Create `/home/chrisf/.openclaw/scripts/migrate_memory.py`:
```python
#!/usr/bin/env python3
"""Migrate memory from markdown files to Qdrant"""

import os
import glob
import httpx
from pathlib import Path

EMBEDDING_URL = "http://localhost:18000/embed"
QDRANT_URL = "http://localhost:6333/collections/lore/points"
MEMORY_DIR = "/home/chrisf/code/clawdbot-local/documents/memory"

def migrate_file(filepath: Path):
    with open(filepath) as f:
        content = f.read()
    
    # Generate embedding
    resp = httpx.post(EMBEDDING_URL, json={"text": content[:512]})
    embedding = resp.json()["embedding"]
    
    # Store in Qdrant
    point = {
        "points": [{
            "id": hash(str(filepath)),
            "vector": embedding,
            "payload": {
                "source": str(filepath),
                "content": content,
                "type": "memory"
            }
        }]
    }
    httpx.put(QDRANT_URL, json=point)
    print(f"Migrated: {filepath}")

def main():
    for md_file in glob.glob(f"{MEMORY_DIR}/**/*.md", recursive=True):
        migrate_file(Path(md_file))

if __name__ == "__main__":
    main()
```

### 3.3 Migration Execution

```bash
python3 /home/chrisf/.openclaw/scripts/migrate_memory.py
```

---

## Phase 4: Testing & Validation

### 4.1 Unit Tests

| Test | Expected | Command |
|------|----------|---------|
| Embedding API | 200 OK, 384-dim vector | `curl -X POST localhost:18000/embed` |
| Qdrant health | `healthz check passed` | `curl localhost:6333/healthz` |
| Collection exists | `lore` in list | `curl localhost:6333/collections` |
| Search works | Results returned | Search with test vector |

### 4.2 Integration Tests

| Test | Expected |
|------|----------|
| Memory search tool | Returns relevant results |
| Latency | <20ms end-to-end |
| Concurrent queries | 10+ simultaneous searches |
| Fallback | Voyage used if local fails |

### 4.3 Performance Benchmark

```bash
# Benchmark embedding throughput
for i in {1..100}; do
  curl -s -X POST localhost:18000/embed \
    -H "Content-Type: application/json" \
    -d '{"text": "test query '$i'"}'
done
```

---

## Phase 5: Documentation & Cleanup

### 5.1 Update GitHub Issue #17

Add comment with:
- Deployment confirmation
- Migration completion
- Performance metrics
- Any issues encountered

### 5.2 Update MEMORY.md

Document the new architecture:
```markdown
## Vector Memory Architecture (2026-02-11)

**Stack:** Self-hosted Qdrant + all-MiniLM-L6-v2
**Location:** rvbee (localhost)
**Endpoints:**
- Embedding: localhost:18000
- Vector DB: localhost:6333

**Replaces:** Voyage AI (rate-limited cloud service)
```

### 5.3 Cleanup

- Remove Voyage API key from active use (keep as fallback)
- Archive old Voyage-dependent code
- Update any hardcoded Voyage references

---

## Success Criteria

- [ ] "lore" collection created and verified
- [ ] OpenClaw memory_search uses local endpoints
- [ ] All existing memory migrated to Qdrant
- [ ] End-to-end test passes (<20ms latency)
- [ ] GitHub issue #17 updated with results
- [ ] Documentation updated

---

## Rollback Plan

If issues occur:
1. Revert OpenClaw config to use Voyage
2. Keep Qdrant running for testing
3. Debug and retry integration

---

## Timeline Estimate

| Phase | Estimated Time |
|-------|----------------|
| 1. Collection Setup | 5 min |
| 2. OpenClaw Integration | 20 min |
| 3. Migration | 10 min |
| 4. Testing | 15 min |
| 5. Documentation | 10 min |
| **Total** | **~1 hour** |

---

## References

- GitHub Issue: https://github.com/ChrisLAS/hyprvibe/issues/17
- Qdrant Docs: https://qdrant.tech/documentation/
- Sentence-Transformers: https://www.sbert.net/
- SPEC (Deployment): vector-memory-research/SPEC.md
