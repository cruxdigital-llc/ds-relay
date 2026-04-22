---
description: Build a production React component from a Figma node. Runs the full Relay DS pipeline (Understand → Build → Verify) with the active DS adapter.
argument-hint: <figma-url-or-node-id> [--adapter <name>] [--out <path>]
---

# /relay-ds:build-component

Build one component end-to-end. The pipeline runs agents sequentially, pauses at documented human gates, and halts on degraded input.

## Usage

```
/relay-ds:build-component <figma-url-or-node-id> [--adapter <name>] [--out <path>]
```

- `<figma-url-or-node-id>` — required. The Figma component to build.
- `--adapter <name>` — DS adapter directory under `adapters/`. Defaults to `template` (which will fail — fork it first via `/relay-ds:onboard-adapter`).
- `--out <path>` — target output directory. Resolution order: `--out` flag → `$RELAY_DS_TARGET_REPO/src/components/<ComponentName>/` → `./out/<component-name>/` (not useful for real builds). See `standards/test-target-repo.md`.

## Orchestrator flow

Follow this flow precisely. Each step is a Task dispatch to a specific subagent. Do not skip steps. Do not write `pipeline-state.yaml` from any subagent — only the orchestrator (you, in this command) writes it, by aggregating the per-agent reports.

### 0. Prune old runs

Per `standards/run-retention.md`:

1. List every `runs/*/pipeline-state.yaml` with a terminal `phase` value (`complete` or `halted-at-*`)
2. Filter to runs matching the current `component` name
3. Sort by `run_started_at` descending
4. If the count exceeds `$RELAY_DS_KEEP_RUNS` (default 20), delete (or archive, if `$RELAY_DS_ARCHIVE_DIR` is set) the oldest excess runs
5. Rewrite `runs/index.yaml`

### 1. Initialize the run

- Generate a `run_id` (UUID v4)
- Create `runs/<run_id>/` and `runs/<run_id>/reports/`
- Capture the current timestamp as `run_started_at`
- Set `RELAY_DS_RUN_DIR=runs/<run_id>` in the environment so hooks can find artifacts
- Write the initial `runs/<run_id>/pipeline-state.yaml`:

```yaml
run_id: <uuid>
component: <to-be-filled-after-brief>
ds_adapter: <adapter>
target_repo: <resolved-out-path>
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

1. **`code-writer`** — produces the component source files in `<target>/src/components/<ComponentName>/`. Emits `reports/code-writer.yaml`.

   **Pre-flight check (hook-enforced):** `brief.md`, `component-rules.md`, `architecture.md` must all be present in `$RELAY_DS_RUN_DIR`.

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
- Dispatch the PR-description populator (inline — not a subagent; just template substitution per `standards/pr-description-template.md`). Output: `runs/<run_id>/PR_DESCRIPTION.md`.
- Update `runs/index.yaml` with the new run's summary line
- Write `runs/<run_id>/SUMMARY.md` as a shorter human-facing digest (one screen of text; the PR description is the long form)
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

| Situation | Action | Pipeline-state `phase` |
|---|---|---|
| GIGO < 0.80 at any point | Halt with GIGO UI | `halted-gigo` |
| `[BLOCKING]` issue at architecture gate | Pause for conversational gate | `halted-architecture` (until resolved) |
| Code Writer compliance fails twice | Halt, surface error signature | `halted-code-writer` |
| Same a11y error after 3 rounds | Halt, mark `[UNRESOLVED_A11Y]`, apply penalty | `halted-a11y` |
| Visual Reviewer hits max 5 iterations | Exit with `[VISUAL_CRITICAL]` deviations surfaced | `complete` (with caveats) or `halted-visual` if critical |
| Quality Gate same error twice | Halt | `halted-quality-gate` |
| Target repo validation fails | Halt before dispatching anything | `halted-target-repo` |

All halt paths write a clear reason to `pipeline-state.yaml` under `halt_reason`.

---

## What to tell the user at completion

A short message — two to three sentences, not a wall of text:

```
Built <Component Name> at <target-path>.
GIGO final: <score>. Gates resolved: <n>. Visual review: <grade summary>.
See runs/<run_id>/PR_DESCRIPTION.md for the manual-check checklist to ship with the PR.
```

Nothing more. The artifacts are self-contained; the user reads them when ready.
