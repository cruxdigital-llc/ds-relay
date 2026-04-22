# Figma Console MCP Canary Protocol

Before the Design Analyst extracts anything from Figma, it runs a **canary call** against the Figma Console MCP. If the canary fails, the pipeline falls back to the REST API and applies a `-0.30` GIGO penalty. This doc defines the canary precisely — not as prose.

---

## Why a canary

A stale Figma Console MCP session can hold the WebSocket port without responding. A grep of the MCP config tells you the server is *configured*, not that the server is *alive*. Without a real call, the Design Analyst silently wastes the first extraction attempt, discovers failure mid-flight, and the pipeline gets inconsistent behavior depending on server state.

A canary turns that into a binary, upfront answer: Console MCP is live and responding, or we're falling back to REST — with a score penalty — and everyone knows.

---

## The canary call

**Tool:** a lightweight document-introspection tool exposed by the Figma Console MCP. The exact tool name depends on the MCP's published API; as of v0.1.0, use the MCP's document-level metadata tool (e.g., `get_document_info`, `figma_get_document`, or equivalent — confirm against the installed MCP version).

**Arguments:** minimal. Just enough to force the MCP to touch the Figma desktop app. Passing the current Figma file URL or node ID is sufficient; no traversal required.

**Expected response shape:**

```json
{
  "document": {
    "id": "<some-id>",
    "name": "<file-name>",
    "type": "DOCUMENT"
  }
}
```

Any response that includes a `document` field with an `id` passes the canary. The canary does NOT validate document content, only liveness.

**Timeout:** 5 seconds. WebSocket calls to a responsive MCP return in sub-second range; 5 seconds is generous and catches the common stale-session case where the port accepts connections but never replies.

---

## Canary outcomes

| Outcome | Penalty | Action |
|---|---|---|
| Response with `document.id` in ≤5s | none | Proceed with Console MCP as the primary path |
| Timeout (no response in 5s) | `-0.30` `REST_FALLBACK` | Fall back to REST API; mark pipeline-state `figma_path: rest` |
| Error response (e.g., MCP not running, plugin not installed) | `-0.30` `REST_FALLBACK` | Same as timeout |
| Malformed response (no `document` field) | `-0.30` `REST_FALLBACK` + log warning | Treat as if the MCP is non-functional; MCP version likely incompatible |

---

## Who runs the canary

The **Design Analyst** — once, at the start of its run, before any real extraction. The canary result is written to `reports/design-analyst.yaml` under a `canary` key:

```yaml
canary:
  attempted_at: 2026-04-22T14:30:01Z
  result: pass | timeout | error | malformed
  response_time_ms: 342
  figma_path: console_mcp | rest
```

The orchestrator reads this to decide whether to apply the GIGO penalty and which path to record in `pipeline-state.yaml`.

---

## Re-running the canary

If the canary fails on first run, the orchestrator does NOT auto-retry. Retry is cheap but obscures the underlying problem (stale session, plugin not installed, Figma not running). The human-facing halt message includes the three standard GIGO options, plus a fourth for MCP issues specifically:

> *"Figma Console MCP canary failed: &lt;timeout / error / malformed&gt;. The pipeline fell back to REST and applied `-0.30` GIGO penalty. You can:*
> 1. *Fix the MCP (check Figma desktop is running + plugin is installed + no stale session) and re-run*
> 2. *Accept REST fallback and continue with `[DEGRADED_QUALITY]` markers in output*
> 3. *Halt the pipeline and provide token/component data manually"*

---

## Not in scope for the canary

The canary only tests MCP liveness. It does NOT validate:

- Figma credentials / auth scope
- Access to the specific component being built
- Presence of Anova spec data
- Figma variable bindings

Those are extraction-time concerns surfaced later in `brief.md` as `[UNRESOLVED]` or `[PENDING]` markers with their own penalties.
