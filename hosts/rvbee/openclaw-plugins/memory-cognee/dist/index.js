import fs from "node:fs/promises";
import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { dirname, join, relative, resolve } from "node:path";
// ---------------------------------------------------------------------------
// Defaults
// ---------------------------------------------------------------------------
const DEFAULT_BASE_URL = "http://localhost:8000";
const DEFAULT_DATASET_NAME = "openclaw";
const DEFAULT_SEARCH_TYPE = "GRAPH_COMPLETION";
const DEFAULT_MAX_RESULTS = 6;
const DEFAULT_MIN_SCORE = 0;
const DEFAULT_MAX_TOKENS = 512;
const DEFAULT_AUTO_RECALL = true;
const DEFAULT_AUTO_INDEX = true;
const DEFAULT_AUTO_COGNIFY = true;
const DEFAULT_REQUEST_TIMEOUT_MS = 60_000;
const DEFAULT_MAX_INDEX_CHARS = 3_000;
const DEFAULT_OVERSIZE_MODE = "truncate";
const DEFAULT_RECALL_SESSION_DENY_PATTERNS = ["^agent:[^:]+:cron:"];
const DEFAULT_RECALL_SESSION_ALLOW_PATTERNS = [];
const DEFAULT_RECALL_POLICY_LOG = true;
const DEFAULT_RECALL_MAX_CONCURRENT = 1;
const DEFAULT_RECALL_QUEUE_TIMEOUT_MS = 1_500;
const STATE_PATH = join(homedir(), ".openclaw", "memory", "cognee", "datasets.json");
const SYNC_INDEX_PATH = join(homedir(), ".openclaw", "memory", "cognee", "sync-index.json");
/** Glob patterns for memory files, relative to workspace root. */
const MEMORY_FILE_PATTERNS = ["MEMORY.md", "memory.md", "memory"];
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function resolveEnvVars(value) {
    return value.replace(/\$\{([^}]+)\}/g, (_, envVar) => {
        const envValue = process.env[envVar];
        if (!envValue) {
            throw new Error(`Environment variable ${envVar} is not set`);
        }
        return envValue;
    });
}
function hashText(value) {
    return createHash("sha256").update(value).digest("hex");
}
function normalizePatternList(value, fallback) {
    if (!Array.isArray(value)) {
        return fallback;
    }
    const cleaned = value
        .filter((entry) => typeof entry === "string")
        .map((entry) => entry.trim())
        .filter(Boolean);
    return cleaned.length > 0 ? cleaned : fallback;
}
function compileRegexList(patterns, logger, label) {
    const compiled = [];
    for (const pattern of patterns) {
        try {
            compiled.push(new RegExp(pattern));
        }
        catch (error) {
            logger.warn?.(`memory-cognee: invalid regex in ${label}: ${pattern} (${String(error)})`);
        }
    }
    return compiled;
}
function resolveConfig(rawConfig) {
    const raw = rawConfig && typeof rawConfig === "object" && !Array.isArray(rawConfig)
        ? rawConfig
        : {};
    const baseUrl = raw.baseUrl?.trim() || DEFAULT_BASE_URL;
    const datasetName = raw.datasetName?.trim() || DEFAULT_DATASET_NAME;
    const searchType = raw.searchType || DEFAULT_SEARCH_TYPE;
    const maxResults = typeof raw.maxResults === "number" ? raw.maxResults : DEFAULT_MAX_RESULTS;
    const minScore = typeof raw.minScore === "number" ? raw.minScore : DEFAULT_MIN_SCORE;
    const maxTokens = typeof raw.maxTokens === "number" ? raw.maxTokens : DEFAULT_MAX_TOKENS;
    const autoRecall = typeof raw.autoRecall === "boolean" ? raw.autoRecall : DEFAULT_AUTO_RECALL;
    const autoIndex = typeof raw.autoIndex === "boolean" ? raw.autoIndex : DEFAULT_AUTO_INDEX;
    const autoCognify = typeof raw.autoCognify === "boolean" ? raw.autoCognify : DEFAULT_AUTO_COGNIFY;
    const requestTimeoutMs = typeof raw.requestTimeoutMs === "number" ? raw.requestTimeoutMs : DEFAULT_REQUEST_TIMEOUT_MS;
    const maxIndexChars = Math.max(500, Math.floor(typeof raw.maxIndexChars === "number" ? raw.maxIndexChars : DEFAULT_MAX_INDEX_CHARS));
    const oversizeMode = raw.oversizeMode === "skip" ? "skip" : DEFAULT_OVERSIZE_MODE;
    const recallSessionDenyPatterns = normalizePatternList(raw.recallSessionDenyPatterns, DEFAULT_RECALL_SESSION_DENY_PATTERNS);
    const recallSessionAllowPatterns = normalizePatternList(raw.recallSessionAllowPatterns, DEFAULT_RECALL_SESSION_ALLOW_PATTERNS);
    const recallPolicyLog = typeof raw.recallPolicyLog === "boolean" ? raw.recallPolicyLog : DEFAULT_RECALL_POLICY_LOG;
    const recallMaxConcurrent = Math.max(1, Math.floor(typeof raw.recallMaxConcurrent === "number" ? raw.recallMaxConcurrent : DEFAULT_RECALL_MAX_CONCURRENT));
    const recallQueueTimeoutMs = Math.max(0, Math.floor(typeof raw.recallQueueTimeoutMs === "number" ? raw.recallQueueTimeoutMs : DEFAULT_RECALL_QUEUE_TIMEOUT_MS));
    const apiKey = raw.apiKey && raw.apiKey.length > 0
        ? resolveEnvVars(raw.apiKey)
        : process.env.COGNEE_API_KEY || "";
    return {
        baseUrl,
        apiKey,
        datasetName,
        searchType,
        maxResults,
        minScore,
        maxTokens,
        autoRecall,
        autoIndex,
        autoCognify,
        requestTimeoutMs,
        maxIndexChars,
        oversizeMode,
        recallSessionDenyPatterns,
        recallSessionAllowPatterns,
        recallPolicyLog,
        recallMaxConcurrent,
        recallQueueTimeoutMs,
    };
}
function buildSyncPayload(file, cfg) {
    const metadata = JSON.stringify({ path: file.path, source: "memory" });
    const header = `# ${file.path}\n\n`;
    const footer = `\n\n---\nMetadata: ${metadata}`;
    const sourceLength = file.content.length;
    if (sourceLength > cfg.maxIndexChars && cfg.oversizeMode === "skip") {
        return {
            skip: true,
            hash: hashText(""),
            data: "",
            sourceLength,
            indexedLength: 0,
        };
    }
    let indexed = file.content;
    if (sourceLength > cfg.maxIndexChars) {
        indexed = `${file.content.slice(0, cfg.maxIndexChars)}\n\n[TRUNCATED: source length ${sourceLength} chars, maxIndexChars ${cfg.maxIndexChars}]`;
    }
    const data = `${header}${indexed}${footer}`;
    return {
        skip: false,
        hash: hashText(data),
        data,
        sourceLength,
        indexedLength: indexed.length,
    };
}
// ---------------------------------------------------------------------------
// Persistence — dataset state & sync index
// ---------------------------------------------------------------------------
async function loadDatasetState() {
    try {
        const raw = await fs.readFile(STATE_PATH, "utf-8");
        const parsed = JSON.parse(raw);
        if (!parsed || typeof parsed !== "object")
            return {};
        return parsed;
    }
    catch (error) {
        if (error.code === "ENOENT")
            return {};
        throw error;
    }
}
async function saveDatasetState(state) {
    await fs.mkdir(dirname(STATE_PATH), { recursive: true });
    await fs.writeFile(STATE_PATH, JSON.stringify(state, null, 2), "utf-8");
}
async function loadSyncIndex() {
    try {
        const raw = await fs.readFile(SYNC_INDEX_PATH, "utf-8");
        const parsed = JSON.parse(raw);
        if (!parsed || typeof parsed !== "object") {
            return { entries: {} };
        }
        const record = parsed;
        record.entries ??= {};
        return record;
    }
    catch (error) {
        if (error.code === "ENOENT") {
            return { entries: {} };
        }
        throw error;
    }
}
async function saveSyncIndex(state) {
    await fs.mkdir(dirname(SYNC_INDEX_PATH), { recursive: true });
    await fs.writeFile(SYNC_INDEX_PATH, JSON.stringify(state, null, 2), "utf-8");
}
// ---------------------------------------------------------------------------
// File collection — scan workspace for memory markdown files
// ---------------------------------------------------------------------------
async function collectMemoryFiles(workspaceDir) {
    const files = [];
    for (const pattern of MEMORY_FILE_PATTERNS) {
        const target = resolve(workspaceDir, pattern);
        try {
            const stat = await fs.stat(target);
            if (stat.isFile() && target.endsWith(".md")) {
                const content = await fs.readFile(target, "utf-8");
                files.push({
                    path: relative(workspaceDir, target),
                    absPath: target,
                    content,
                    hash: hashText(content),
                });
            }
            else if (stat.isDirectory()) {
                // Recursively scan the memory/ directory for .md files
                const entries = await scanDir(target, workspaceDir);
                files.push(...entries);
            }
        }
        catch (error) {
            if (error.code !== "ENOENT") {
                throw error;
            }
            // File/dir doesn't exist — skip silently
        }
    }
    return files;
}
async function scanDir(dir, workspaceDir) {
    const files = [];
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
        const absPath = join(dir, entry.name);
        if (entry.isDirectory()) {
            const nested = await scanDir(absPath, workspaceDir);
            files.push(...nested);
        }
        else if (entry.isFile() && entry.name.endsWith(".md")) {
            const content = await fs.readFile(absPath, "utf-8");
            files.push({
                path: relative(workspaceDir, absPath),
                absPath,
                content,
                hash: hashText(content),
            });
        }
    }
    return files;
}
// ---------------------------------------------------------------------------
// Cognee HTTP client
// ---------------------------------------------------------------------------
class CogneeClient {
    baseUrl;
    apiKey;
    timeoutMs;
    constructor(baseUrl, apiKey, timeoutMs = 30_000) {
        this.baseUrl = baseUrl;
        this.apiKey = apiKey;
        this.timeoutMs = timeoutMs;
    }
    buildHeaders() {
        if (!this.apiKey)
            return {};
        return {
            Authorization: `Bearer ${this.apiKey}`,
            "X-Api-Key": this.apiKey,
        };
    }
    async fetchJson(path, init, timeoutMs = this.timeoutMs) {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), timeoutMs);
        try {
            const response = await fetch(`${this.baseUrl}${path}`, {
                ...init,
                signal: controller.signal,
            });
            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Cognee request failed (${response.status}): ${errorText}`);
            }
            return (await response.json());
        }
        finally {
            clearTimeout(timeout);
        }
    }
    async add(params) {
        const formData = new FormData();
        formData.append("data", new Blob([params.data], { type: "text/plain" }), "openclaw-memory.txt");
        formData.append("datasetName", params.datasetName);
        if (params.datasetId) {
            formData.append("datasetId", params.datasetId);
        }
        const data = await this.fetchJson("/api/v1/add", {
            method: "POST",
            headers: this.buildHeaders(),
            body: formData,
        });
        const dataId = this.extractDataId(data.data_id ?? data.data_ingestion_info);
        if (!dataId) {
            console.warn("memory-cognee: add response missing data_id", JSON.stringify({
                keys: Object.keys(data),
                data_id: data.data_id ?? null,
                data_ingestion_info: data.data_ingestion_info ?? null,
            }, null, 2));
        }
        return {
            datasetId: data.dataset_id,
            datasetName: data.dataset_name,
            dataId,
        };
    }
    async update(params) {
        const query = new URLSearchParams({
            data_id: params.dataId,
            dataset_id: params.datasetId,
        });
        const formData = new FormData();
        formData.append("data", new Blob([params.data], { type: "text/plain" }), "openclaw-memory.txt");
        const data = await this.fetchJson(`/api/v1/update?${query.toString()}`, {
            method: "PATCH",
            headers: this.buildHeaders(),
            body: formData,
        });
        return {
            datasetId: data.dataset_id,
            datasetName: data.dataset_name,
            dataId: this.extractDataId(data.data_id ?? data.data_ingestion_info),
        };
    }
    async cognify(params = {}) {
        return this.fetchJson("/api/v1/cognify", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                ...this.buildHeaders(),
            },
            body: JSON.stringify({ datasetIds: params.datasetIds }),
        });
    }
    async search(params) {
        const data = await this.fetchJson("/api/v1/search", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                ...this.buildHeaders(),
            },
            body: JSON.stringify({
                query: params.queryText,
                searchType: params.searchType,
                datasetIds: params.datasetIds,
                max_tokens: params.maxTokens,
            }),
        });
        return this.normalizeSearchResults(data);
    }
    /**
     * Normalize Cognee search response to consistent format.
     * Cognee returns a direct array of strings: ["answer text here"]
     * We convert to: [{ id, text, score }]
     */
    normalizeSearchResults(data) {
        // Handle direct array (Cognee's actual format)
        if (Array.isArray(data)) {
            return data.map((item, index) => {
                if (typeof item === "string") {
                    return { id: `result-${index}`, text: item, score: 1 };
                }
                if (item && typeof item === "object") {
                    const record = item;
                    return {
                        id: typeof record.id === "string" ? record.id : `result-${index}`,
                        text: typeof record.text === "string" ? record.text : JSON.stringify(record),
                        score: typeof record.score === "number" ? record.score : 1,
                        metadata: record.metadata,
                    };
                }
                return { id: `result-${index}`, text: String(item), score: 1 };
            });
        }
        // Handle wrapped format { results: [...] }
        if (data && typeof data === "object" && "results" in data) {
            return this.normalizeSearchResults(data.results);
        }
        return [];
    }
    extractDataId(value) {
        if (!value)
            return undefined;
        if (typeof value === "string")
            return value;
        if (Array.isArray(value)) {
            for (const entry of value) {
                const id = this.extractDataId(entry);
                if (id)
                    return id;
            }
            return undefined;
        }
        if (typeof value !== "object")
            return undefined;
        const record = value;
        if (typeof record.data_id === "string")
            return record.data_id;
        return this.extractDataId(record.data_ingestion_info);
    }
}
// ---------------------------------------------------------------------------
// Unified sync logic
//
// For each memory file:
//   - New file (no sync index entry)        → add + cognify
//   - Changed file with dataId              → update (no re-cognify)
//   - Changed file without dataId           → add + cognify
//   - Unchanged file                        → skip
//
// Matches clawdbot cognee-provider.ts syncFiles() (lines 422-513).
// ---------------------------------------------------------------------------
async function syncFiles(client, files, syncIndex, cfg, logger) {
    const result = { added: 0, updated: 0, skipped: 0, skippedOversize: 0, truncated: 0, errors: 0 };
    let datasetId = syncIndex.datasetId;
    let needsCognify = false;
    for (const file of files) {
        const prepared = buildSyncPayload(file, cfg);
        if (prepared.skip) {
            result.skipped++;
            result.skippedOversize++;
            logger.warn?.(`memory-cognee: skipped oversized file ${file.path} (${prepared.sourceLength} chars > maxIndexChars=${cfg.maxIndexChars})`);
            continue;
        }
        if (prepared.sourceLength > cfg.maxIndexChars) {
            result.truncated++;
            logger.info?.(`memory-cognee: truncating ${file.path} (${prepared.sourceLength} -> ${prepared.indexedLength} chars)`);
        }
        const existing = syncIndex.entries[file.path];
        // Skip unchanged files
        if (existing && existing.hash === prepared.hash) {
            result.skipped++;
            continue;
        }
        try {
            // Changed file with prior dataId → try update first
            if (existing?.dataId && datasetId) {
                try {
                    await client.update({
                        dataId: existing.dataId,
                        datasetId,
                        data: prepared.data,
                    });
                    syncIndex.entries[file.path] = { hash: prepared.hash, dataId: existing.dataId };
                    syncIndex.datasetId = datasetId;
                    syncIndex.datasetName = cfg.datasetName;
                    result.updated++;
                    logger.info?.(`memory-cognee: updated ${file.path}`);
                    continue; // Success, move to next file
                }
                catch (updateError) {
                    // If update fails (404/409 - document not found), fall back to add
                    const errorMsg = updateError instanceof Error ? updateError.message : String(updateError);
                    if (errorMsg.includes("404") || errorMsg.includes("409") || errorMsg.includes("not found")) {
                        logger.info?.(`memory-cognee: update failed for ${file.path}, falling back to add`);
                        // Clear the stale dataId and fall through to add
                        delete existing.dataId;
                    }
                    else {
                        throw updateError; // Re-throw other errors
                    }
                }
            }
            // New file, or changed file without dataId, or update failed → add
            const response = await client.add({
                data: prepared.data,
                datasetName: cfg.datasetName,
                datasetId,
            });
            if (response.datasetId && response.datasetId !== datasetId) {
                datasetId = response.datasetId;
                // Persist dataset ID mapping
                const state = await loadDatasetState();
                state[cfg.datasetName] = response.datasetId;
                await saveDatasetState(state);
            }
            syncIndex.entries[file.path] = {
                hash: prepared.hash,
                dataId: response.dataId,
            };
            syncIndex.datasetId = datasetId;
            syncIndex.datasetName = cfg.datasetName;
            needsCognify = true;
            result.added++;
            logger.info?.(`memory-cognee: added ${file.path}`);
        }
        catch (error) {
            result.errors++;
            logger.warn?.(`memory-cognee: failed to sync ${file.path}: ${error instanceof Error ? error.message : String(error)}`);
        }
    }
    // Cognify only after adds (not after updates — those are already processed)
    if (needsCognify && cfg.autoCognify && datasetId) {
        try {
            await client.cognify({ datasetIds: [datasetId] });
            logger.info?.("memory-cognee: cognify completed");
        }
        catch (error) {
            logger.warn?.(`memory-cognee: cognify failed: ${error instanceof Error ? error.message : String(error)}`);
        }
    }
    // Save sync index to disk
    await saveSyncIndex(syncIndex);
    return { ...result, datasetId };
}
// ---------------------------------------------------------------------------
// Plugin registration
// ---------------------------------------------------------------------------
const memoryCogneePlugin = {
    id: "memory-cognee",
    name: "Memory (Cognee)",
    description: "Cognee-backed memory: indexes workspace memory files, auto-recalls before agent runs",
    kind: "memory",
    register(api) {
        const cfg = resolveConfig(api.pluginConfig);
        const client = new CogneeClient(cfg.baseUrl, cfg.apiKey, cfg.requestTimeoutMs);
        const recallDenyRegexes = compileRegexList(cfg.recallSessionDenyPatterns, api.logger, "recallSessionDenyPatterns");
        const recallAllowRegexes = compileRegexList(cfg.recallSessionAllowPatterns, api.logger, "recallSessionAllowPatterns");
        let recallInFlight = 0;
        const shouldSkipRecallForSession = (sessionKey) => {
            if (!sessionKey) {
                return false;
            }
            const denied = recallDenyRegexes.some((regex) => regex.test(sessionKey));
            if (denied) {
                return true;
            }
            if (recallAllowRegexes.length > 0) {
                const allowed = recallAllowRegexes.some((regex) => regex.test(sessionKey));
                return !allowed;
            }
            return false;
        };
        const acquireRecallSlot = async () => {
            const started = Date.now();
            while (recallInFlight >= cfg.recallMaxConcurrent) {
                if (Date.now() - started >= cfg.recallQueueTimeoutMs) {
                    return false;
                }
                await new Promise((resolve) => setTimeout(resolve, 50));
            }
            recallInFlight++;
            return true;
        };
        const releaseRecallSlot = () => {
            if (recallInFlight > 0) {
                recallInFlight--;
            }
        };
        let datasetId;
        let syncIndex = { entries: {} };
        let syncIndexReady = false;
        let resolvedWorkspaceDir; // Set by service/CLI, used by hooks
        // Load persisted state on startup
        const stateReady = Promise.all([
            loadDatasetState()
                .then((state) => {
                datasetId = state[cfg.datasetName];
            })
                .catch((error) => {
                api.logger.warn?.(`memory-cognee: failed to load dataset state: ${String(error)}`);
            }),
            loadSyncIndex()
                .then((state) => {
                syncIndex = state;
                syncIndexReady = true;
                if (!datasetId && state.datasetId && state.datasetName === cfg.datasetName) {
                    datasetId = state.datasetId;
                }
            })
                .catch((error) => {
                api.logger.warn?.(`memory-cognee: failed to load sync index: ${String(error)}`);
            }),
        ]);
        // Helper: run sync with a given workspace dir
        async function runSync(workspaceDir, logger) {
            await stateReady;
            const files = await collectMemoryFiles(workspaceDir);
            if (files.length === 0) {
                logger.info?.("memory-cognee: no memory files found");
                return { added: 0, updated: 0, skipped: 0, errors: 0 };
            }
            logger.info?.(`memory-cognee: found ${files.length} memory file(s), syncing...`);
            const result = await syncFiles(client, files, syncIndex, cfg, logger);
            if (result.datasetId) {
                datasetId = result.datasetId;
            }
            return result;
        }
        // ------------------------------------------------------------------
        // CLI: openclaw cognee index / openclaw cognee status
        // ------------------------------------------------------------------
        api.registerCli((ctx) => {
            const cognee = ctx.program.command("cognee").description("Cognee memory management");
            const resolvedWorkspaceDir = ctx.workspaceDir || process.cwd();
            cognee
                .command("index")
                .description("Sync memory files to Cognee (add new, update changed, skip unchanged)")
                .action(async () => {
                const result = await runSync(resolvedWorkspaceDir, ctx.logger);
                const summary = `Sync complete: ${result.added} added, ${result.updated} updated, ${result.skipped} unchanged, ${result.errors} errors`;
                ctx.logger.info?.(summary);
                console.log(summary);
            });
            cognee
                .command("status")
                .description("Show Cognee sync state (files indexed, dataset info)")
                .action(async () => {
                await stateReady;
                const entryCount = Object.keys(syncIndex.entries).length;
                const entriesWithDataId = Object.values(syncIndex.entries).filter((e) => e.dataId).length;
                const files = await collectMemoryFiles(resolvedWorkspaceDir);
                let dirty = 0;
                let newCount = 0;
                for (const file of files) {
                    const existing = syncIndex.entries[file.path];
                    if (!existing) {
                        newCount++;
                    }
                    else if (existing.hash !== file.hash) {
                        dirty++;
                    }
                }
                const lines = [
                    `Dataset: ${syncIndex.datasetName ?? cfg.datasetName}`,
                    `Dataset ID: ${datasetId ?? syncIndex.datasetId ?? "(not set)"}`,
                    `Indexed files: ${entryCount} (${entriesWithDataId} with data ID)`,
                    `Workspace files: ${files.length}`,
                    `New (unindexed): ${newCount}`,
                    `Changed (dirty): ${dirty}`,
                    `Sync index: ${SYNC_INDEX_PATH}`,
                ];
                console.log(lines.join("\n"));
            });
        }, { commands: ["cognee"] });
        // ------------------------------------------------------------------
        // Auto-sync on startup
        // ------------------------------------------------------------------
        if (cfg.autoIndex) {
            api.registerService({
                id: "cognee-auto-sync",
                async start(ctx) {
                    // Store workspace dir for use in hooks
                    resolvedWorkspaceDir = ctx.workspaceDir || process.cwd();
                    try {
                        const result = await runSync(resolvedWorkspaceDir, ctx.logger);
                        ctx.logger.info?.(`memory-cognee: auto-sync complete: ${result.added} added, ${result.updated} updated, ${result.skipped} unchanged`);
                    }
                    catch (error) {
                        ctx.logger.warn?.(`memory-cognee: auto-sync failed: ${String(error)}`);
                    }
                },
            });
        }
        // ------------------------------------------------------------------
        // Auto-recall: inject memories before each agent run
        // ------------------------------------------------------------------
        if (cfg.autoRecall) {
            api.on("before_agent_start", async (event, ctx) => {
                // Wait for state to load (fixes race condition on first agent run)
                await stateReady;
                const sessionKey = ctx.sessionKey ?? "";
                if (shouldSkipRecallForSession(sessionKey)) {
                    if (cfg.recallPolicyLog) {
                        api.logger.info?.(`memory-cognee: skipping recall (session policy) for ${sessionKey || "unknown"}`);
                    }
                    return;
                }
                if (!event.prompt || event.prompt.length < 5) {
                    api.logger.debug?.("memory-cognee: skipping recall (prompt too short)");
                    return;
                }
                if (!datasetId) {
                    api.logger.debug?.("memory-cognee: skipping recall (no datasetId)");
                    return;
                }
                const slot = await acquireRecallSlot();
                if (!slot) {
                    if (cfg.recallPolicyLog) {
                        api.logger.info?.(`memory-cognee: skipping recall (queue timeout ${cfg.recallQueueTimeoutMs}ms) for ${sessionKey || "unknown"}`);
                    }
                    return;
                }
                try {
                    const results = await client.search({
                        queryText: event.prompt,
                        searchType: cfg.searchType,
                        datasetIds: [datasetId],
                        maxTokens: cfg.maxTokens,
                    });
                    const filtered = results
                        .filter((result) => result.score >= cfg.minScore)
                        .slice(0, cfg.maxResults);
                    if (filtered.length === 0) {
                        api.logger.debug?.("memory-cognee: search returned no results above minScore");
                        return;
                    }
                    const payload = JSON.stringify(filtered.map((result) => ({
                        id: result.id,
                        score: result.score,
                        text: result.text,
                        metadata: result.metadata,
                    })), null, 2);
                    api.logger.info?.(`memory-cognee: injecting ${filtered.length} memories for session ${ctx.sessionKey ?? "unknown"}`);
                    return {
                        prependContext: `<cognee_memories>\nRelevant memories:\n${payload}\n</cognee_memories>`,
                    };
                }
                catch (error) {
                    api.logger.warn?.(`memory-cognee: recall failed: ${String(error)}`);
                }
                finally {
                    releaseRecallSlot();
                }
            });
        }
        // ------------------------------------------------------------------
        // Post-agent sync: detect file changes and sync to Cognee
        // ------------------------------------------------------------------
        if (cfg.autoIndex) {
            api.on("agent_end", async (event, ctx) => {
                // Only sync if the agent succeeded
                if (!event.success)
                    return;
                await stateReady;
                // Need workspace dir to find memory files
                const workspaceDir = resolvedWorkspaceDir || process.cwd();
                try {
                    // Collect current files and find changed ones
                    const files = await collectMemoryFiles(workspaceDir);
                    const changedFiles = files.filter((f) => {
                        const existing = syncIndex.entries[f.path];
                        return !existing || existing.hash !== f.hash;
                    });
                    if (changedFiles.length === 0)
                        return;
                    api.logger.info?.(`memory-cognee: detected ${changedFiles.length} changed file(s), syncing...`);
                    const result = await syncFiles(client, changedFiles, syncIndex, cfg, api.logger);
                    if (result.datasetId) {
                        datasetId = result.datasetId;
                    }
                    api.logger.info?.(`memory-cognee: post-agent sync: ${result.added} added, ${result.updated} updated`);
                }
                catch (error) {
                    api.logger.warn?.(`memory-cognee: post-agent sync failed: ${String(error)}`);
                }
            });
        }
    },
};
export default memoryCogneePlugin;
//# sourceMappingURL=index.js.map
