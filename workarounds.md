# Workarounds

Raw observation log. Every failure, gotcha, or "that's not right" moment lands here first, before it has been promoted to memory or hardened into a skill rule.

Each entry has three parts:

1. **What happened** — what did the agent do that was wrong?
2. **Why it matters** — what breaks if this recurs?
3. **Proposed rule** — what rule, in what layer (workarounds / memory / skill), prevents it next time?

## Promotion ladder

Observations progress: **workarounds → memory → skill**.

- A single observation in this file is just an observation. It stays here.
- When the same failure recurs across components, the rule is promoted to **memory** (via the Claude Code memory system). Memory is loaded into every agent's context.
- When a rule is critical for one specific agent's workflow, it gets hardened into that agent's **skill file** (`agents/<name>.md`) as a pre-flight check. Skill-level rules are the most durable — the agent literally cannot start without them.

Promotion criteria:

| From | To | Trigger |
|---|---|---|
| workarounds | memory | Same rule would apply to 2+ different components or 2+ different agents |
| memory | skill | Rule is pre-flight-critical for exactly one agent (broader audience = stays in memory) |
| workarounds | skill (direct) | Rule is both agent-specific AND pre-flight-critical from the start |

Skill rules are *precise*; memory rules are *broad*. A rule in the wrong layer either gets ignored (too buried) or over-enforced (too broadly applied).

---

## Entries

<!--
Template:

### NNN — <short title>
**Observed:** <date>, in <component name> run <run_id>
**What happened:** <one paragraph>
**Why it matters:** <what breaks if this recurs>
**Proposed rule:** <rule text>
**Target layer:** workarounds | memory | skill:<agent-name>
**Status:** observed | promoted-to-memory | hardened-to-skill
-->

_(no entries yet — the first run will populate this)_
