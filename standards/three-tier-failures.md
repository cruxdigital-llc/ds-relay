# Three-Tier Failure Framework

Not all failures are the same kind of failure. Most multi-agent systems treat every mistake as a prompt-engineering problem; only a fraction are actually prompt-fixable. Classifying failures before choosing a fix strategy is the precondition for choosing the right fix.

---

## Tier 1 — Rules-fixable

> The agent needs a rule. Once told, never recurs.

**Signs:** the agent did a plausible-but-wrong thing (fabricated token prefix, used the wrong casing, skipped a layer of validation, defaulted to title case).

**Where it gets fixed:** the persistence ladder — `workarounds.md` → memory → skill files.

**Examples of T1 rules:**
- "Token prefix is `--color-*`, not `--<dsname>-color-*`" (adapter-specific)
- "Never use `var(--x, fallback)` — if a token resolves to nothing, fix the token"
- "Lowercase the `name` argument when calling the DS component lookup"
- "Multi-step story interactions test to completion, not step one"
- "Sentence case for all user-facing strings"

**Feedback loop:** every run's `review-log.md` surfaces T1 candidates. Human decides promotion. Rules compound over time.

---

## Tier 2 — Tools-fixable

> The agent is doing the right thing; the tooling can't support it.

**Signs:** the agent needs a capability the MCP / Figma plugin / DS registry doesn't provide. The rule it *would* need is "do X," but X is impossible with current tools.

**Where it gets fixed:** infrastructure roadmap. Build or extend the tool.

**Examples of T2 gaps:**
- DS icon MCP has no `list_all` / enumeration capability (agents can verify a named icon exists but cannot discover available icons)
- Component lookup is case-sensitive and fails silently on wrong case (needs tool-level normalization)
- Figma REST API can't expand component instance children (mitigated by Figma Console MCP; degrades when bridge unavailable)
- Typography is hardcoded pixels in Figma — no bound variable path to semantic tokens (needs an Anova-equivalent or DS-side annotation)

**Feedback loop:** T2 findings become tickets for the infrastructure owner (the DS team, the MCP server maintainer, the Figma plugin author). Until fixed, they often migrate: T2 becomes T1 (write a workaround rule) or T2 becomes T3 (surface as a human gate).

---

## Tier 3 — Human-gate

> Automation cannot solve this. The information doesn't exist in machine-readable form, or the evaluation requires embodied judgment.

**Signs:** not "we haven't built it yet" — *"the information doesn't exist"* or *"the judgment is irreducibly human."*

**Where it gets fixed:** explicit human gates in the pipeline. Design *for* them, not around them.

**Examples of T3 gates:**
- **Screen reader testing** — automated tools catch roughly 30–50% of WCAG violations. The rest requires a human with VoiceOver/NVDA/JAWS/TalkBack.
- **Hover and mouse-movement interactions** — synthetic `pointerenter` events cannot reproduce the *path* of a real cursor (slow diagonals, overshoot, the moment the cursor briefly exits the safe polygon).
- **Motion specifications** — durations, easing curves, enter/exit sequences. Figma snapshots don't capture motion. This data lives outside the design.
- **Detached Figma frames** — intent is ambiguous (accidental detach? deliberate customization? DS Figma out of sync?). Agents cannot determine intent from frame structure.
- **Selection-control × cardinality** — a checkmark is a visual indicator, not a cardinality constraint. Whether checkmarks mean single-select or multi-select is a design decision that cannot be inferred from the layout.
- **Visual pixel verification of custom indicators** — sub-pixel rounding differences in scaled indicators need human eyes at 2x zoom.

**Feedback loop:** each T3 gate has a manual-check checklist item that ships in the output PR description. The human signs off *once* per component; the decision is recorded.

---

## Why classifying matters

The failure-class → fix-strategy mapping is not optional:

| If you treat… | …as… | What happens |
|---|---|---|
| T1 | T2 | You build tooling for a problem that a three-line rule would have solved |
| T1 | T3 | You burden the human with choices an agent could make correctly if told how |
| T2 | T1 | You write a rule that says "do X" when X is impossible with current tools — agent fails the rule and you blame the agent |
| T2 | T3 | You burden the human with work the infrastructure should handle |
| T3 | T1 | You fabricate a rule for a decision that structurally requires judgment — the rule becomes a silent guess |
| T3 | T2 | You try to build tooling for something that can't be automated — years of diminishing-returns investment |

Diagnosing which tier a failure belongs to is a precondition for the fix. Do this first.

## The ratio

In practice, T1 > T2 > T3 by roughly 3:1.5:1. A quarter need better tools. About a fifth are permanently human. This ratio appears to generalize to most agent systems that reach into human intent.
