# GIGO Score

A unified quality score (0.0 – 1.0) that tracks input-data quality through the pipeline. Deterministic. Same inputs → same score, every time. No language-model judgment.

Name: GIGO (garbage-in, garbage-out). The score makes input quality visible *before* it silently corrupts output.

## How it starts

Every run starts at `1.0`.

## How it degrades

Only decreases. Each degradation records a penalty row with code, value, and reason.

| Code | Penalty | Trigger |
|---|---|---|
| `REST_FALLBACK` | `-0.30` | Figma Console MCP canary failed; the Design Analyst is extracting via Figma REST API (reduced fidelity — can't expand instance children, can't resolve variable bindings to token names, can't reach internal layout properties) |
| `UNRESOLVED_TOKEN` | `-0.02` per token | A token reference in `brief.md` marked `[UNRESOLVED]` (Figma value didn't bind to any DS adapter token; typography is the most common case) |
| `MISSING_VARIANT` | proportional | Fewer variants extracted than the brief required (penalty = `0.10 * missing / requested`) |
| `DETACHED_FRAME` | `-0.10` per frame | Figma frame is detached from its DS component — designer intent is ambiguous |
| `SOURCE_CONFLICT` | `-0.05` per property | Anova spec data disagrees with Figma bound variables on the same property (not auto-resolved; surfaces at gate) |
| `MISSING_MOTION_SPEC` | `-0.05` | Motion behavior expected but no spec data found (distinct from the motion human gate — penalty applies when the gate surfaces) |
| `UNRESOLVED_A11Y` | `-0.10` per finding | An accessibility P1 finding persists after 3 remediation attempts |
| `ICON_UNVERIFIABLE` | `-0.02` per icon | An icon reference cannot be verified against the DS adapter's icon registry (common when the DS icon MCP has no enumeration support) |

Downstream agents may add penalties as they discover issues — the Design Analyst sets the starting score, but every agent can subtract.

## Hard stop

**Score < 0.80 → pipeline halts.**

Not a warning banner. A stop.

The halt message presents three things:

1. **What degraded** — e.g., *"Figma REST API fallback — missing bound variables for 12 of 34 token references."*
2. **Why it matters** — e.g., *"Downstream agents will guess or fabricate these tokens."*
3. **Three options for the human:**
   - **Fix the input** — reconnect the Figma Console MCP, re-run the Design Analyst
   - **Provide the data manually** — paste a token mapping, re-run from that point
   - **Accept degraded quality** — continue, but output ships with `[DEGRADED_QUALITY]` markers and the GIGO report

## Why deterministic

Score computation uses a fixed penalty table, not LLM judgment. Same inputs → same score, every time. This matters because:

- The score is used as a gate. LLM-judged scores drift between runs and make gating unreliable.
- The score is a feedback signal. Deterministic scores let you compare runs meaningfully — *"the score dropped 0.05 after the Figma file changed"* is a useful signal. *"the model felt a bit less confident this time"* is not.
- The score is reproducible. A user can validate *why* the score is what it is by reading the penalty log, not by trusting the model.

## Computed where

- **Design Analyst** initializes the score and applies extraction-time penalties.
- **Library Researcher** may add `UNRESOLVED_CAPABILITY` penalties (not in the default table; adapter-specific).
- **Accessibility Auditor** adds `UNRESOLVED_A11Y` on bailed remediation.
- **Visual Reviewer** may add penalties for dimension grades that bail at `CRITICAL` without a human override.
- **Orchestrator** aggregates, reports the final score, and enforces the <0.80 halt.

## Reported in

- `reports/<agent>.yaml` — each agent's contribution
- `pipeline-state.yaml` — aggregated, under `gigo.score` and `gigo.penalties[]`
- `SUMMARY.md` — final score + penalty log for the human
