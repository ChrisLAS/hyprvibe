# @cognee/cognee-openclaw

OpenClaw plugin that adds Cognee-backed memory with automatic recall and indexing.

## Features

- **Auto-recall**: Before each agent run, searches Cognee for relevant memories and injects them as context
- **Auto-index**: On startup and after each agent run, syncs memory markdown files to Cognee (add new, update changed, skip unchanged)
- **CLI commands**: `openclaw cognee index` to manually sync, `openclaw cognee status` to check state
- **Configurable**: Search type, max results, score filtering, token limits, and more

## Installation

Install the plugin locally for development:

```bash
cd integrations/openclaw
npm install
npm run build
openclaw plugins install -l .
```

Or once published:

```bash
openclaw plugins install @cognee/cognee-openclaw
```

## Configuration

Enable the plugin in your OpenClaw config (`~/.openclaw/config.yaml` or project config):

```yaml
plugins:
  entries:
    memory-cognee:
      enabled: true
      config:
        baseUrl: "http://localhost:8000"
        apiKey: "${COGNEE_API_KEY}"
        datasetName: "my-project"
        searchType: "GRAPH_COMPLETION"
        maxResults: 6
        autoRecall: true
        autoIndex: true
```

Set your API key in the environment:

```bash
export COGNEE_API_KEY="your-key-here"
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseUrl` | string | `http://localhost:8000` | Cognee API base URL |
| `apiKey` | string | `$COGNEE_API_KEY` | API key for authentication |
| `datasetName` | string | `openclaw` | Dataset name for storing memories |
| `searchType` | string | `GRAPH_COMPLETION` | Search mode: `GRAPH_COMPLETION`, `CHUNKS`, `SUMMARIES` |
| `maxResults` | number | `6` | Max memories to inject per recall |
| `minScore` | number | `0` | Minimum relevance score filter |
| `maxTokens` | number | `512` | Token cap for recall context |
| `autoRecall` | boolean | `true` | Inject memories before agent runs |
| `autoIndex` | boolean | `true` | Sync memory files on startup and after agent runs |
| `autoCognify` | boolean | `true` | Run cognify after new memories are added |
| `requestTimeoutMs` | number | `60000` | HTTP timeout for Cognee requests |
| `maxIndexChars` | number | `3000` | Max characters per memory file sent to Cognee |
| `oversizeMode` | string | `truncate` | Oversize handling: `truncate` or `skip` |
| `recallSessionDenyPatterns` | string[] | `["^agent:[^:]+:cron:"]` | Regex denylist for session keys (skip recall) |
| `recallSessionAllowPatterns` | string[] | `[]` | Optional regex allowlist for session keys |
| `recallPolicyLog` | boolean | `true` | Emit logs when recall is skipped by policy |
| `recallMaxConcurrent` | number | `1` | Max concurrent recall searches |
| `recallQueueTimeoutMs` | number | `1500` | Max wait for recall slot before skipping |

## How It Works

1. **On startup**: Scans `memory/` directory for markdown files and syncs to Cognee (add new, update changed, skip unchanged)
2. **Before agent start**: Searches Cognee for memories relevant to the prompt and prepends as `<cognee_memories>` context
3. **After agent end**: Re-scans memory files and syncs any changes the agent made
4. **State tracking**:
   - `~/.openclaw/memory/cognee/datasets.json` — dataset ID mapping
   - `~/.openclaw/memory/cognee/sync-index.json` — per-file hash and Cognee data IDs

Memory files detected at: `MEMORY.md`, `memory.md`, or `memory/*.md`

## CLI Commands

```bash
# Manually sync memory files to Cognee
openclaw cognee index

# Check sync status (indexed files, pending changes)
openclaw cognee status
```

## Development

```bash
cd integrations/openclaw
# Build once, then link for local development with an OpenClaw project
npm install
npm run build
openclaw plugins install -l .
```

For live rebuilds during development:

```bash
npm run dev
```
