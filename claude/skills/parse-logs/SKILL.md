---
name: parse-logs
description: Investigate AWS CloudWatch log exports. Use when the user reports an incident, asks to investigate logs, or when JSON files are present in logs-for-claude/.
---

# parse-logs

Structured investigation workflow for AWS CloudWatch Insights JSON exports.

## Setup

Scripts live at `~/.claude/skills/parse-logs/`. Log files go in `logs-for-claude/` (gitignored).
Always use the scripts — never `Read` raw JSON log files directly (wastes context budget).

Export from CloudWatch Insights as **JSON** (not CSV). The JSON format has `@message` as a
parsed object; CSV requires double-unescaping and is not supported.

## Investigation Workflow

Work through these steps in order. Each step builds on the previous one.

### Step 1 — Locate files

```bash
ls -lh logs-for-claude/*.json 2>/dev/null || echo "No JSON files in logs-for-claude/"
```

If multiple files exist, note their names and sizes. Ask the user which to focus on, or
start with the most recently modified.

### Step 2 — Cold-start overview

```bash
~/.claude/skills/parse-logs/parse-logs.sh logs-for-claude/<file>.json
```

Read the output. Note:

- The UTC and ET time range covered
- Any `ERROR` or `WARN` rows visible at a glance
- Which containers are active
- Infra noise volume (collapsed summary lines)

### Step 3 — Error sweep

```bash
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json --errors --app-only
```

List every error. For each one, note the `reqId` or `trace_id` if present — these are the
threads to pull in step 4.

### Step 4 — Pursue threads

Use one or more targeted queries based on what step 3 surfaces:

```bash
# Trace a single request end-to-end
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json --req <reqId>

# Trace by distributed trace ID
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json --trace <traceId>

# Find all activity for a patient
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json --patient <uuid>

# Search for a keyword (service name, error text, job name)
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json --grep "endChatSession"

# Narrow to a time window
~/.claude/skills/parse-logs/filter-logs.sh logs-for-claude/<file>.json \
  --from 14:01:00 --to 14:02:00 --app-only
```

### Step 5 — Build timeline

Assemble findings into a markdown table:

```markdown
| Time (UTC)    | ET           | Event |
|---------------|--------------|-------|
| 14:01:11.775  | 10:01:11 ET  | POST /ai-chat/start/dd96e8fa → 204 (old session being ended) |
| 14:01:43.562  | 10:01:43 ET  | POST /ai-chat/start/dd96e8fa → 201 — new session created |
```

Include both UTC and ET columns. One row per meaningful event (skip noise, heartbeats, routine
200s unless they establish timing context).

### Step 6 — Summarize findings

Output a summary covering:

- What the logs **confirm** happened
- What the logs **rule out**
- What is **still unknown** (and what additional logs or data would resolve it)

Include this summary in the final report to the user, along with the timeline from Step 5.

## Filter flag reference

| Flag | Effect |
|------|--------|
| `--errors` | Level ≥ 50 only |
| `--warn` | Level ≥ 40 only |
| `--app-only` | App logs only (suppresses all infra noise) |
| `--grep <pattern>` | Case-insensitive search across msg/reqUrl/err/log text |
| `--req <reqId>` | Exact reqId match |
| `--trace <traceId>` | Exact trace_id match |
| `--patient <uuid>` | Partial patient UUID match anywhere in entry |
| `--from <HH:MM:SS>` | Entries at or after this UTC time |
| `--to <HH:MM:SS>` | Entries at or before this UTC time |

Flags combine freely: `--app-only --errors`, `--req req-abc --from 14:01:00`, etc.

## Log entry types

**App logs** (`container_name: backend` or `worker`): pino-structured with `level`, `msg`,
`reqId`, `reqUrl`, `status`, `elapsedTime`, `userId`, `userRole`, `worker`, `jobName`, etc.

**Infra noise** (collapsed in parse-logs.sh output):

- K8s audit events (`kind: Event`, `apiVersion: audit.k8s.io/v1`) — lease heartbeats, RBAC
  decisions, watch responses from kube-system, argo-rollouts, argocd, external-dns, etc.
- Cluster autoscaler, CloudWatch agent, EBS CSI controller chatter

## Tips

- All timestamps in logs are **UTC**. ET column is derived automatically; DST is handled.
- `reqId` is the fastest way to trace a single HTTP request through all its log lines.
- `trace_id` links across services (backend + any downstream calls in the same trace).
- An error at `level: 50` with `status: 200` means SSE headers were already committed —
  the HTTP response was 200 but an error frame was sent over the stream.
- 16ms END_SESSION jobs almost always hit the `session.status !== 'current'` early-exit path.
