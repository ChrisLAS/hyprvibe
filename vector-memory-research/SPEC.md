# SPEC: NixOS Self-Hosted Vector Memory

## Overview

Deploy Qdrant vector database and all-MiniLM-L6-v2 embedding model on rvbee (NixOS) to replace Voyage AI dependency.

**Architecture:** Qdrant (vector storage) + Python embedding service (FastAPI wrapper around sentence-transformers)

---

## Components

### 1. Qdrant Vector Database
- **Package:** `nixos.qdrant` v1.12.1
- **Service:** `services.qdrant` module
- **Ports:** 6333 (HTTP API), 6334 (gRPC)
- **Storage:** SSD/NVMe at `/var/lib/qdrant`

### 2. Embedding Service
- **Runtime:** Python 3.11+
- **Framework:** FastAPI (async, lightweight)
- **Model:** all-MiniLM-L6-v2 via sentence-transformers
- **Cache:** HuggingFace models at `/var/cache/embedding-service`
- **Port:** 8000 (localhost only)

---

## File Structure

```
/home/chrisf/build/config/
├── lore.nix                    # Main configuration (imports vector-memory.nix)
├── vector-memory-research/
│   ├── SPEC.md                 # This document
│   ├── issues.json             # Project tracking
│   └── implementation/         # Created during implementation
│       ├── qdrant.nix          # Qdrant service config
│       └── embedding-service/  # Embedding service package
│           ├── default.nix
│           ├── app.py
│           └── requirements.txt
```

---

## Configuration Requirements

### Qdrant (via NixOS module)
- Enable service: `services.qdrant.enable = true`
- Storage path: `/var/lib/qdrant`
- Config storage: on-disk (memory-map mode for efficiency)
- Log level: info
- Disable telemetry for privacy

### Embedding Service (custom systemd service)
- Run as dedicated user: `embedding-service`
- Group: `openclaw` (for access)
- Working directory: `/var/lib/embedding-service`
- Environment:
  - `HF_HOME=/var/cache/embedding-service/huggingface`
  - `TRANSFORMERS_CACHE=/var/cache/embedding-service/transformers`
  - `SENTENCE_TRANSFORMERS_HOME=/var/cache/embedding-service/sentence-transformers`
- Pre-download model on first run (with HuggingFace token)

---

## Data Flow

```
OpenClaw Agent
    │
    ▼ memory_search tool
┌─────────────────────┐
│  Embedding Service  │  localhost:8000
│  (FastAPI +         │  • POST /embed
│   MiniLM-L6-v2)     │    → returns 384-dim vector
└─────────────────────┘
    │
    ▼ HTTP POST 6333
┌─────────────────────┐
│  Qdrant             │  localhost:6333
│  (Vector Search)    │  • POST /collections/lore/points/search
└─────────────────────┘
    │
    ▼ Results
OpenClaw Agent
```

---

## Security Considerations

1. **Network binding:**
   - Qdrant: localhost:6333 only (not exposed externally)
   - Embedding: localhost:8000 only
   - No external network exposure

2. **File permissions:**
   - Qdrant data: 0700 (qdrant user)
   - Embedding cache: 0750 (embedding-service:openclaw)

3. **HuggingFace token:**
   - Stored in `/etc/secrets/huggingface_token`
   - Readable by embedding-service user only (0400)

4. **Service isolation:**
   - Separate users for each service
   - No sudo access
   - Minimal filesystem access

---

## Testing Plan

1. **Qdrant health check:**
   ```bash
   curl http://localhost:6333/healthz
   ```

2. **Embedding service test:**
   ```bash
   curl -X POST http://localhost:8000/embed \
     -H "Content-Type: application/json" \
     -d '{"text": "hello world"}'
   ```

3. **End-to-end vector search:**
   ```python
   # Test script to verify full pipeline
   ```

4. **Performance benchmark:**
   - Measure embedding latency (<5ms expected)
   - Measure search latency (<10ms expected)
   - Verify 750+ sentences/sec throughput

---

## Rollback Plan

If issues occur:
1. Disable services: `services.qdrant.enable = false;`
2. Remove custom service from lore.nix
3. Rebuild: `nixos-rebuild switch`
4. Data preserved in `/var/lib/qdrant` for later recovery

---

## GitHub Issue

Create issue: `[MILESTONE] Implement NixOS vector memory stack`
- Label: `milestone`, `nixos`, `vector-memory`
- Link to this SPEC.md
- Mark VEC-008 as in-progress

---

## Acceptance Criteria

- [ ] Qdrant service running and healthy
- [ ] Embedding service responding on :8000
- [ ] Model downloaded and cached locally
- [ ] End-to-end test passes
- [ ] Performance meets targets (750+ qps embedding)
- [ ] Configuration committed to repo
- [ ] GitHub issue closed with summary

---

## References

- VEC-001 to VEC-007 research findings
- Qdrant NixOS module docs
- Sentence-Transformers docs: https://www.sbert.net
- all-MiniLM-L6-v2: https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2
