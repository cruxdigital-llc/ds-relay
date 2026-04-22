# Run Retention Policy

Every `/relay-ds:build-component` invocation creates `runs/<run_id>/` with brief, architecture, reports, component source, and artifacts. Without a policy, this directory grows unbounded.

This doc defines retention, pruning, and archival for the v0.1.0 release.

---

## Defaults

- **Retention window:** the **20 most recent runs per component** are kept on disk, indexed by `run_started_at` timestamp
- **Pruning trigger:** the orchestrator runs a prune pass at the start of every `/relay-ds:build-component` invocation, before creating the new run directory
- **Archival:** none by default. Old runs are deleted. Teams that want to keep history should configure archival explicitly (see below).

---

## Prune mechanics

At the start of every build:

1. List all `runs/*/pipeline-state.yaml` where `component == <current-component-name>`
2. Sort by `run_started_at` descending
3. Keep the 20 most recent
4. Delete the rest, recursively

Runs in progress (no terminal phase marker) are NEVER pruned — only runs with `phase: complete` or `phase: halted-at-<gate>`.

---

## Index file

`runs/index.yaml` — maintained by the orchestrator. Lists every retained run with enough metadata to navigate without opening each directory.

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

## Configuring retention

Environment variables (read by the orchestrator at run-init time):

| Variable | Default | Effect |
|---|---|---|
| `ADS_KEEP_RUNS` | `20` | Number of runs to retain per component. Set to `0` to disable retention (keep everything) |
| `ADS_ARCHIVE_DIR` | *unset* | If set, pruned runs are moved to `<ADS_ARCHIVE_DIR>/<YYYY>/<MM>/<run_id>/` instead of deleted |
| `ADS_PRUNE_ON_BUILD` | `1` | Set to `0` to skip pruning on build. Useful when debugging; not recommended for normal use |

No config file yet — env vars keep v0.1.0 simple. A `pipeline-config.yaml` file is reasonable for a future release.

---

## Manual pruning

`/relay-ds:prune-runs [--component <name>] [--keep <n>] [--archive <dir>]` is a proposed command for v0.2+. Not in v0.1.0 scope.

For v0.1.0, manual pruning is a `rm -rf` against specific `runs/<run_id>/` directories. Combined with the `.gitignore` on `runs/`, this keeps repos clean without automated tooling.

---

## What never gets pruned

- `workarounds.md` at the project root — this is durable project knowledge, not per-run state
- The orchestrator's own memory / skill-file updates — promoted rules persist regardless of which run surfaced them
- `runs/index.yaml` — rewritten, never deleted

The prune policy affects only per-run artifact directories.
