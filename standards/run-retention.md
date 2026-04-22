# Run Retention Policy

Every `/relay-ds:build-component` invocation creates a per-run directory with brief, architecture, reports, component source, and artifacts. Without a policy, this grows unbounded.

This doc defines retention, pruning, and archival for the v0.1.0 release.

---

## Defaults

- **Retention window:** the **20 most recent runs per component** are kept on disk, ordered by `run_started_at`
- **Pruning trigger:** the orchestrator runs a prune pass at the start of every `/relay-ds:build-component` invocation, before creating the new run directory
- **Archival:** none by default. Old runs are deleted. Teams that want to keep history tell the orchestrator to archive (see below).

---

## Where runs live

Runs live inside the target repo, at `<target>/runs/<run_id>/`. This keeps per-run artifacts next to the code they relate to, and ensures nothing leaks into the plugin install directory.

The target repo's `.gitignore` should include `runs/` — a future `/relay-ds:init-target` command will add this automatically. For manual target-repo setup, add it by hand.

---

## Prune mechanics

At the start of every build, the orchestrator:

1. Lists all `<target>/runs/*/pipeline-state.yaml` where `component == <current-component-name>`
2. Sorts by `run_started_at` descending
3. Keeps the 20 most recent
4. Deletes (or archives, if the user specified archival) the rest, recursively

Runs in progress (no terminal `phase` marker) are NEVER pruned — only runs with `phase: complete` or `phase: halted-at-<gate>`.

---

## Index file

`<target>/runs/index.yaml` — maintained by the orchestrator. Lists every retained run with enough metadata to navigate without opening each directory.

```yaml
runs:
  - run_id: 8f3a…
    component: Menu
    ds_adapter: acme
    phase: complete
    run_started_at: 2026-04-22T14:30:00Z
    gigo_score_final: 0.94
    human_gates_resolved: 2
    visual_iterations: 3
  - run_id: b12e…
    component: Menu
    ds_adapter: acme
    phase: halted-at-architecture
    run_started_at: 2026-04-22T13:15:00Z
    gigo_score_at_halt: 0.78
    halt_reason: GIGO below threshold
```

The index is rewritten after every prune. Human-readable; also consumable by `/relay-ds:pipeline-review` to spot trends across runs.

---

## User overrides

The user changes retention behavior by saying so in the slash-command invocation or a follow-up message:

- *"keep the last 50 runs"* → orchestrator uses 50 instead of the 20 default for this build
- *"archive old runs to ~/relay-ds-archive instead of deleting"* → orchestrator moves pruned runs to `~/relay-ds-archive/<YYYY>/<MM>/<run_id>/`
- *"don't prune anything this time"* → skip the prune pass for this run

There are no environment variables. Defaults live in the command prompt; overrides come from conversation.

---

## Manual pruning

`/relay-ds:prune-runs [--component <name>] [--keep <n>] [--archive <dir>]` is a proposed command for v0.2+. Not in v0.1.0 scope.

For v0.1.0, manual pruning is a plain `rm -rf <target>/runs/<run_id>/` in a shell when the user wants to clean up outside the automatic pass. The orchestrator doesn't manage this.

---

## What never gets pruned

- `workarounds.md` at the plugin root — this is durable project knowledge, not per-run state
- Promoted memory / skill-file updates — rules persist regardless of which run surfaced them
- `<target>/runs/index.yaml` — rewritten, never deleted

The prune policy affects only per-run artifact directories inside the target repo's `runs/`.
