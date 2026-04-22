---
description: Run the pipeline-review agent on a completed run. Produces review-log.md with findings classified T1/T2/T3 and proposed fixes.
argument-hint: <run-id> [--propose-promotions]
---

# /relay-ds:pipeline-review

Post-run analysis. Reads every artifact from a completed run, classifies findings, and proposes fixes.

## Usage

```
/relay-ds:pipeline-review <run-id>
/relay-ds:pipeline-review <run-id> --propose-promotions
```

- `<run-id>` — required. The run directory under `runs/`.
- `--propose-promotions` — optional. If set, the review also proposes which workarounds should be promoted to memory and which memories should be hardened into skill files, based on this run's evidence plus accumulated history.

## Flow

1. **Verify the run completed.** `runs/<run-id>/pipeline-state.yaml` must exist with a terminal phase marker (`complete` or `halted-at-<gate>`). A run that's mid-flight cannot be reviewed.
2. **Dispatch the `pipeline-review` subagent** with the run directory as input.
3. **Wait for `review-log.md`** to be produced.
4. **If `--propose-promotions`:** also read `workarounds.md` and the project's memory directory. For each candidate in the review, check whether the same pattern has appeared in prior runs. If so, flag it in the review-log as `[PROMOTE_TO_MEMORY]` or `[HARDEN_TO_SKILL]`.
5. **Report to the user.** Summary shape:
   - Count of T1/T2/T3 findings
   - Top 3 proposed T1 rules (with target layer)
   - Any T2 tool improvements needed
   - Any T3 manual checks that are missing from the output PR description
   - Any `[REVIEW_GAP]` items (cases where the review itself might have missed something)
   - If `--propose-promotions`: list of rules ready for promotion and which layer to promote to

## When to run

- **After every pipeline run** that produced output (not after halts). The compounding effect of rules comes from running this every time, not just when something obvious broke.
- **After any run where the output shipped but felt off.** "The component renders, but something's wrong" is exactly the situation the review surfaces.
- **Before promoting a workaround to memory.** The review is the evidence for the promotion decision.

## What it costs

One Opus pass over ~6-10 artifact files. A few thousand tokens of input, a thousand or two of output. Cheap relative to any round of re-running the full pipeline.

## What to do with the output

- Open `review-log.md`.
- For each T1 finding with a proposed rule, decide: add to `workarounds.md` now, or skip.
- For each T2 finding, open a ticket with the named owner.
- For each T3 finding, verify the manual check is in the output's PR description; if not, add it.
- Use `/relay-ds:promote-rule` to move a workaround up the persistence ladder when it's ready.
