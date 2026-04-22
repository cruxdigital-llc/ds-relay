---
description: Promote a rule up the persistence ladder — workarounds → memory, or memory → skill. Requires evidence from multiple runs.
argument-hint: <rule-id-or-text> [--to memory|skill:<agent>]
---

# /relay-ds:promote-rule

Move a rule up the persistence ladder based on accumulated evidence.

## The ladder

```
workarounds.md  ──┬──►  memory  ──►  skill file
                  │
                  └──► skill file (direct, for agent-specific pre-flight rules)
```

- **`workarounds.md`** — raw observation log. Lives per-project. Not loaded into any agent's context.
- **Memory** — standing instructions loaded into *every* agent's context. Promoted when a rule applies broadly.
- **Skill file** — agent-targeted pre-flight check. Hardened when a rule is critical to exactly one agent's workflow.

## Usage

```
/relay-ds:promote-rule <rule-id-or-text> [--to memory|skill:<agent>]
```

- `<rule-id-or-text>` — the numbered entry in `workarounds.md` (e.g., `003`) or the text of a memory entry.
- `--to memory` — promote to broadly-applicable memory.
- `--to skill:<agent>` — harden into a specific agent's skill file (e.g., `--to skill:code-writer`).

If `--to` is omitted, the command proposes a target based on the rule's applicability.

## Promotion criteria

Do not promote on a single observation. Evidence required:

| Target | Evidence |
|---|---|
| **Memory** | Same rule would have prevented failures in 2+ different components OR 2+ different agents |
| **Skill** | Rule is pre-flight-critical for exactly one agent. If it applies to more than one agent, it belongs in memory. |

Skill rules are *precise*; memory rules are *broad*. A rule in the wrong layer either gets ignored (too buried) or over-enforced (too broadly applied).

## Flow

1. **Look up the rule** by ID (workarounds) or search text.
2. **Verify evidence:**
   - For memory: at least 2 distinct recurrences in different runs or across different components.
   - For skill: verify the agent is the sole consumer of this rule (grep other agents' skill files and the memory index for contradictions).
3. **Ask for confirmation.** Show the rule text, the proposed target, and the evidence. Wait for user approval.
4. **On approval:**
   - **Memory target:** write the rule to the appropriate memory file under the project's memory directory. Update `MEMORY.md` index. Remove the entry from `workarounds.md` (or mark it `status: promoted-to-memory`).
   - **Skill target:** edit `agents/<agent-name>.md` to add the rule to the "Hard rules" section or the relevant process step. Update the workarounds entry to `status: hardened-to-skill`.
5. **Record the promotion** with a dated note in `workarounds.md`.

## When to harden skill-first (skip memory)

Promote workaround → skill directly when:

- The rule is a pre-flight check (agent must verify something *before* doing anything — e.g., "call `<tool>` to confirm tokens exist")
- The rule is trivially testable (one assertion, not a judgment call)
- The rule is genuinely specific to one agent (not a general principle)

Example: *"Code Writer must read `component-rules.md` before writing any source line"* — skill-first. It's pre-flight, trivially testable, and only Code Writer cares.

Example: *"Never use `var(--x, fallback)`"* — memory. Applies to anyone writing CSS across the pipeline.

## Reverse promotion

A promoted rule can be demoted if it turned out to be wrong. Use `/relay-ds:promote-rule <rule-id> --to workarounds` to move back (or simply delete the memory/skill entry and re-observe). Demotion is rare — memory and skill rules should be chosen carefully enough that they rarely need to move back.

## What this command doesn't do

- **Does not create new rules.** Those come from `/relay-ds:pipeline-review` output or from observed workarounds.
- **Does not enforce anything at runtime.** It only moves the rule to a layer where the runtime enforcement happens (memory loads into context; skill files gate agent invocation via hooks).
