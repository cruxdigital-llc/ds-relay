---
description: Build a production React component from a Figma node. Runs the full Relay DS pipeline (Understand → Build → Verify) with the active DS adapter.
argument-hint: <figma-url-or-node-id> into <target-repo-path> using <adapter-name>
---

# /relay-ds:build-component

Build one component end-to-end. The pipeline runs agents sequentially, pauses at documented human gates, and halts on degraded input.

## What the user provides

The orchestrator needs three things to start:

1. **Figma node URL or ID** — the component to build
2. **Target repo absolute path** — where generated files land; validated per `standards/test-target-repo.md`
3. **DS adapter name** — directory under `adapters/`

The user can supply all three in the invocation (*"build the Button from figma.com/file/… into ~/sds-target using the sds adapter"*) or provide them incrementally as the orchestrator asks. The orchestrator always asks for anything missing; it never guesses.

If only one adapter exists under `adapters/`, the orchestrator uses it without asking. If multiple exist, it asks.

## Orchestrator flow

Follow this flow precisely. Each numbered step is a Task dispatch to a specific subagent or an in-conversation action. Do not skip steps. Do not write `pipeline-state.yaml` from any subagent — only the orchestrator writes it, by aggregating the per-agent reports.

### 0. Gather inputs + validate the target

- Collect figma node, target path, adapter name (from invocation text, session state, or by asking)
- Validate the target repo per `standards/test-target-repo.md`. If validation fails: halt, report the specific check that failed, suggest the fix.
- Prune old runs under `<target>/runs/` per `standards/run-retention.md` (keep 20 most recent per component, unless the user said otherwise in this session)

### 1. Initialize the run

- Generate a `run_id` (UUID v4)
- Create `<target>/runs/<run_id>/` and `<target>/runs/<run_id>/reports/`
- Capture the current timestamp as `run_started_at`
- Write the initial `<target>/runs/<run_id>/pipeline-state.yaml`:

```yaml
run_id: <uuid>
component: <to-be-filled-after-brief>
ds_adapter: <adapter>
target_repo: <target-path>
run_started_at: <timestamp>
phase: understand
gigo:
  score: 1.00
  penalties: []
iterations:
  visual_reviewer: 0/5
  a11y_auditor: 0/3
  quality_gate: 0/1
gates:
  architecture: pending
  # more gates added as they surface
push_back: []
```

The orchestrator remembers `<target>/runs/<run_id>/` as the run directory for the remainder of this invocation. Subagents are dispatched with this absolute path in their Task prompt so they know where to read/write artifacts. Hooks infer the run directory from the artifact paths they see in tool input.

### 2. Understand phase

Dispatch agents **sequentially** (each reads the prior's output):

1. **`design-analyst`** — produces `brief.md` and caches `figma-raw.json`. Emits `reports/design-analyst.yaml` with canary result + penalties per `standards/figma-canary.md`.

   **After dispatch:**
   - Read `reports/design-analyst.yaml`
   - Update `pipeline-state.yaml`: fill `component` name from the brief; merge `gigo.penalties` from the report; recompute `gigo.score` = `1.00 - sum(penalties[].value)`
   - **Halt check:** if `gigo.score < 0.80`, print the halt UI (see § Halt UI below). Wait for human resolution before continuing.

2. **`library-researcher`** — produces `component-rules.md`. Emits `reports/library-researcher.yaml`.

   **After dispatch:** merge any additional penalties; recompute score; halt if < 0.80.

3. **`component-architect`** — produces `architecture.md`. Emits `reports/component-architect.yaml`.

   **After dispatch:**
   - Scan `architecture.md` for `[BLOCKING]` markers and `confidence: LOW` section labels
   - If any present: print the conversational gate UI (see § Conversational gate UI). Loop until human says "proceed." Append resolutions to `brief.md` as a `## Human-resolved decisions` section.
   - Update `pipeline-state.yaml`: `gates.architecture: resolved`

### 3. Build phase

Update `pipeline-state.yaml`: `phase: build`.

1. **`code-writer`** — produces the component source files at `<target>/src/components/<ComponentName>/`. Emits `reports/code-writer.yaml`.

   **Pre-flight check (hook-enforced):** `brief.md`, `component-rules.md`, `architecture.md` must all be present in the run directory. The hook infers the run directory from the paths in the subagent's prompt.

   **Compliance-fix loop:**
   - Scan `reports/code-writer.yaml` for `[TOKEN_MISMATCH]` or `[ARCH_DEVIATION]` markers
   - If any: re-dispatch Code Writer with the report appended to its context. Max 1 fix loop.
   - If the same marker type recurs after the fix loop: halt with a specific error.

2. **`accessibility-auditor`** — produces `a11y-report.md`. Emits `reports/accessibility-auditor.yaml`.

   **Remediation loop:**
   - If `a11y-report.md` has P1 findings: emit a `fix-request.md` and re-dispatch Code Writer. Increment `iterations.a11y_auditor` in `pipeline-state.yaml`.
   - Max 3 remediation rounds. If the same error signature persists after 2 rounds (3 audits total counting the first): mark `[UNRESOLVED_A11Y]` in `pipeline-state.yaml`, apply `-0.10` GIGO penalty per unresolved P1, halt.

3. **`story-author`** — produces `<ComponentName>.stories.tsx`. Emits `reports/story-author.yaml`. Up to 2 retries on test failures; bail if same signature fails twice.

### 4. Verify phase

Update `pipeline-state.yaml`: `phase: verify`.

1. **`visual-reviewer`** — produces `visual-review.md`. Emits `reports/visual-reviewer.yaml`.

   **Iteration loop:**
   - Visual Reviewer itself loops internally up to 5 iterations with the <2% improvement stop and no-regression rule
   - Orchestrator: after completion, update `pipeline-state.yaml`: `iterations.visual_reviewer: <n>/5`
   - If visual-review.md has `[VISUAL_CRITICAL]` markers that didn't resolve in 5 iterations: surface to human (halt with options) — do not auto-continue.

2. **`quality-gate`** — produces `quality-gate.md`. Emits `reports/quality-gate.yaml`.

   **Retry:** 1 pass + 1 retry. Same error twice = bail.

### 5. Finalize

- Write final `pipeline-state.yaml` with `phase: complete`, `run_ended_at: <timestamp>`
- Populate `<target>/runs/<run_id>/PR_DESCRIPTION.md` via template substitution per `standards/pr-description-template.md`
- Update `<target>/runs/index.yaml` with the new run's summary line
- Write `<target>/runs/<run_id>/SUMMARY.md` as a shorter human-facing digest (one screen of text; the PR description is the long form)
- Copy manual-check items from the adapter into `SUMMARY.md` and `PR_DESCRIPTION.md`

---

## GIGO aggregation

Formula (deterministic, no model judgment):

```
score = 1.00 - Σ penalties[i].value
```

- `penalties[]` is the flat list in `pipeline-state.yaml` `gigo.penalties`
- Each penalty has `code`, `value`, `reason`, `raised_by` (agent name)
- Penalties may be added by any agent at any time; the orchestrator aggregates by merging `penalties` from each report's `gigo_additions` field into `pipeline-state.yaml`
- Clamp at 0.00 (score never goes negative in reporting, but the halt still fires)

After any merge, run the halt check: `if score < 0.80 → halt with UI below`.

---

## Halt UI (GIGO threshold breach)

When `gigo.score < 0.80`, print this to the user and wait for input:

```
Pipeline halted. GIGO score dropped below 0.80.

Current score: <score> / 1.00
Threshold: 0.80
Phase halted at: <phase>

Penalties accumulated:
  - <code> (-<value>) — <reason> [raised by <agent>]
  - ...

This means downstream agents are likely to guess or fabricate. You can:

  1. Fix the input and re-run from the degraded step
     (e.g., reconnect the Figma Console MCP and re-run Design Analyst)
  2. Provide the missing data manually
     (e.g., paste a token mapping; the orchestrator writes it into brief.md)
  3. Accept degraded quality and continue
     (output ships with [DEGRADED_QUALITY] markers and the full GIGO log in the PR description)

Which would you like to do? (1 / 2 / 3 / cancel)
```

Wait for explicit choice. Do not auto-continue.

---

## Conversational gate UI (architecture)

When `architecture.md` has `[BLOCKING]` markers or `LOW`-confidence sections:

1. Print the issue list in design-language framing per `standards/conversational-gate.md`
2. Offer the three options: **explore auto-approved sections** / **request self-review** / **proceed**
3. Loop: after each option, either show more context, re-dispatch the Architect for self-review, or exit on "proceed"
4. Persist the final decisions to `brief.md`'s `## Human-resolved decisions` section so downstream agents see them as spec, not as meta-discussion

---

## Failure modes (decision matrix)

| Situation | Action | `pipeline-state.phase` |
|---|---|---|
| Target repo validation fails | Halt before run directory is created | N/A (no run created) |
| GIGO < 0.80 at any point | Halt with GIGO UI | `halted-gigo` |
| `[BLOCKING]` issue at architecture gate | Pause for conversational gate | `halted-architecture` (until resolved) |
| Code Writer compliance fails twice | Halt, surface error signature | `halted-code-writer` |
| Same a11y error after 3 rounds | Halt, mark `[UNRESOLVED_A11Y]`, apply penalty | `halted-a11y` |
| Visual Reviewer hits max 5 iterations | Exit with `[VISUAL_CRITICAL]` deviations surfaced | `complete` (with caveats) or `halted-visual` if critical |
| Quality Gate same error twice | Halt | `halted-quality-gate` |

All halt paths write a clear reason to `pipeline-state.yaml` under `halt_reason`.

---

## What to tell the user at completion

A short message — two to three sentences, not a wall of text:

```
Built <Component Name> at <target-path>/src/components/<ComponentName>/.
GIGO final: <score>. Gates resolved: <n>. Visual review: <grade summary>.
See <target-path>/runs/<run_id>/PR_DESCRIPTION.md for the manual-check checklist to ship with the PR.
```

Nothing more. The artifacts are self-contained; the user reads them when ready.
