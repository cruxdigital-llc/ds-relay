---
description: Build a production React component from a Figma node. Runs the full ADS pipeline (Understand → Build → Verify) with the active DS adapter.
argument-hint: <figma-url-or-node-id> [--adapter <name>] [--out <path>]
---

# /relay-ds:build-component

Build one component end-to-end. The pipeline runs agents sequentially, pauses at documented human gates, and halts on degraded input.

## Usage

```
/relay-ds:build-component <figma-url-or-node-id> [--adapter <name>] [--out <path>]
```

- `<figma-url-or-node-id>` — required. The Figma component to build.
- `--adapter <name>` — DS adapter directory under `adapters/`. Defaults to `template` (which will fail — fork it first).
- `--out <path>` — target output directory. Defaults to `./out/<component-name>/`.

## Orchestrator flow

Follow this flow precisely. Each step is a Task dispatch to a specific subagent. Do not skip steps. Do not write `pipeline-state.yaml` from any subagent — only the orchestrator (you, in this command) writes it, by aggregating the per-agent reports.

### 1. Initialize the run

- Generate a `run_id` (UUID v4).
- Create the run directory: `runs/<run_id>/`.
- Write `runs/<run_id>/pipeline-state.yaml` with the initial state (run_id, component, ds_adapter, phase: `understand`, GIGO score 1.0, all iteration counters at 0/budget).

### 2. Understand phase

Dispatch agents **sequentially** (each reads the prior's output):

1. **`design-analyst`** — produces `brief.md` and caches `figma-raw.json`. Emits `reports/design-analyst.yaml`.
   - **Halt check:** if the emitted GIGO score is < 0.8, stop the pipeline. Present the degraded categories and the three options (fix input / provide manually / accept degraded). Wait for human resolution.
2. **`library-researcher`** — produces `component-rules.md`. Emits `reports/library-researcher.yaml`. *(Phase 2+ only — skip in Phase 1 linear mode.)*
3. **`component-architect`** — produces `architecture.md`. Emits `reports/component-architect.yaml`.
   - **Conversational gate:** if any architecture section has confidence `LOW`, or any `[BLOCKING]` issue is present, pause the pipeline. Present the tradeoffs in plain language. Wait for explicit "proceed" from the human. Propagate the resolution to downstream agents by appending it to `brief.md` as a human-resolved decision.

### 3. Build phase

1. **`code-writer`** — produces the component source files in `--out`. Emits `reports/code-writer.yaml`.
   - **Pre-flight check (hook-enforced):** `brief.md`, `component-rules.md`, `architecture.md` must all be present. If Phase 1 linear mode, `component-rules.md` may be a generated stub.
   - **Compliance-fix loop:** if the compliance report contains `[TOKEN_MISMATCH]` or `[ARCH_DEVIATION]` markers, re-dispatch Code Writer with the report as additional input. One fix loop max.
2. **`accessibility-auditor`** — *(Phase 2+ only — skip in Phase 1 linear mode.)* Produces `a11y-report.md`. If P1 findings exist, loop Code Writer up to 3 times. Bail if same error signature recurs.
3. **`story-author`** — produces `<ComponentName>.stories.tsx`. Up to 2 retries on test failures.

### 4. Verify phase

1. **`visual-reviewer`** — *(Phase 3+ only — skip in Phase 1/2.)* Produces `visual-review.md`. Up to 5 iterations; stop on <2% improvement; no-regression rule.
2. **`quality-gate`** — produces `quality-gate.md`. 1 pass + 1 retry. Bail on same error twice.

### 5. Finalize

- Aggregate all reports into the final `pipeline-state.yaml`.
- Write a summary file: `runs/<run_id>/SUMMARY.md` covering: which agents ran, each one's exit status, each human gate's resolution, the final GIGO score, and the manual-test checklist to ship with the component.
- Copy adapter-specific and pipeline-wide manual-check items into the summary for human review.

## What to tell the user

Report the final GIGO score, the list of resolved gates, and the location of the generated component. If the pipeline halted at a gate, summarize what the gate was asking and what options exist.

## Failure modes

- **Degraded input (GIGO < 0.8):** halt at Design Analyst. Do not auto-continue.
- **Architecture `[BLOCKING]`:** halt at Architect. Do not auto-continue.
- **Code Writer compliance fails twice:** halt. Surface the error signature to the human.
- **Same a11y error after 3 remediation attempts:** halt with `[UNRESOLVED_A11Y]`.
- **Visual Reviewer hits max 5 iterations without crossing the 2% delta:** exit with documented acceptable-deviations list.
- **Quality Gate same error twice:** halt.
