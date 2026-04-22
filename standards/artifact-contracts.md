# Artifact Contracts

Agents do not talk to each other. They read and write documents. Each document is a contract with required sections, not a freeform summary. Missing data is flagged explicitly — never silently omitted.

> The absence of data is itself data.

---

## `brief.md` — Design Analyst output

**Consumed by:** Library Researcher, Component Architect, Code Writer, Story Author, Accessibility Auditor, Visual Reviewer.

**Required sections (all mandatory; missing data = `[PENDING]` or `[UNRESOLVED]`):**

1. **Component identity** — name, Figma node id, component family (if part of one)
2. **Variants** — enumerated with Figma variant properties
3. **States** — default, hover, focus, active, disabled, loading, error, selected, expanded/collapsed as applicable
4. **Design tokens** — color, spacing, typography, shadow, border, border-radius. Each with source (Anova `$token` ref / Figma bound variable / REST fallback + penalty) and resolved value
5. **Responsive behavior** — breakpoints and what changes at each
6. **Motion specs** — durations, easing, enter/exit sequences. Flag `[HUMAN_GATE]` if not found (Figma snapshots don't capture motion; this is a structural human-gate item)
7. **Content rules** — max lengths, overflow behavior, pluralization
8. **Keyboard interactions** — every key + expected behavior
9. **Accessibility requirements** — ARIA roles, states, properties; screen-reader expectations
10. **Assets** — icons used, images, any embedded media
11. **Data sources used** — Anova spec data present? Figma Console MCP connected? REST fallback engaged?
12. **GIGO quality score** — starting value (always 1.0), penalties applied with reasons, final score

Raw Figma dump is cached as `figma-raw.json` alongside so no other agent re-queries the API.

---

## `component-rules.md` — Library Researcher output

**Consumed by:** Component Architect, Code Writer.

**Required sections:**

1. **Mandatory rules** (prefix `CR-*`) — numbered. Each: what, why, where to use it. E.g., *"CR-1: Use `useListNavigation` from `@floating-ui/react` for arrow-key traversal with roving tabIndex. Do not implement manually."*
2. **Advisory rules** (prefix `AR-*`) — numbered. Same shape, but opt-in. E.g., *"AR-1: Consider `FloatingList` with `useListItem` for dynamic item registration instead of manual ref arrays."*
3. **Dependency audit** — each project dependency, its full relevant API surface, and which parts the current component should use.
4. **OSS-alternative evaluation** — if an existing DS primitive might be better than building custom, or a different library would be a better foundation, flag it here with tradeoffs.
5. **Dependency-bloat warnings** — flag cases where a heavy library is overkill (e.g., "brief only needs basic positioning — CSS anchor positioning handles this without a JS library").

---

## `architecture.md` — Component Architect output

**Consumed by:** Code Writer, Story Author, Accessibility Auditor, Visual Reviewer.

**Required sections:**

1. **TypeScript prop interfaces** — with JSDoc on every prop
2. **File structure** — which files, what lives in each
3. **Composition strategy** — simple props vs. compound components vs. discriminated unions (with rationale)
4. **Dependency list with justifications** — tied back to `component-rules.md` rule numbers
5. **Named handoff notes** — prefixed `For Code Writer:`, `For Story Author:`, `For Accessibility Auditor:`, `For Visual Reviewer:`. Each a specific instruction tied to a specific edge case
6. **Self-confidence per section** — `HIGH` / `MEDIUM` / `LOW`. Low-confidence sections surface at the conversational architecture gate
7. **`[BLOCKING]` issues** — decisions the Architect cannot resolve from available data; phrased as design-language risk tradeoffs, not technical dumps
8. **Deferred Features — Forward Architecture** — for every feature deferred, a mini-architecture sketch of how it would plug in later

---

## `a11y-report.md` — Accessibility Auditor output

**Consumed by:** Code Writer (remediation loop), Story Author, Visual Reviewer, Quality Gate.

**Required sections:**

1. **Eight-layer findings table** — ESLint `jsx-a11y`, axe-core, virtual SR simulation, Storybook a11y addon, axe+Playwright, keyboard nav tests, contrast checks, manual checklist
2. **Classified findings** — P1 (blocker), P2 (should fix, non-blocking), P3 (enhancement)
3. **Remediation attempts** — up to 3 per P1. If same error signature recurs twice, mark `[UNRESOLVED_A11Y]` and surface to human
4. **Manual checklist** — things automated tools cannot catch; gets copied into the output PR description

---

## `visual-review.md` — Visual Reviewer output

**Consumed by:** Code Writer (fix loop), Quality Gate, human reviewer.

**Required sections:**

1. **Nine-dimension grade table** — layout, typography, colors, spacing, shadows, borders, border-radius, icons, states. Each: `PASS` / `MINOR` / `MODERATE` / `CRITICAL`
2. **Iteration log** — each iteration's delta, with stop reason (max 5 iterations OR <2% improvement)
3. **Reverted fixes** — any fix that introduced a regression, reverted per the no-regression rule
4. **Acceptable deviations** — `MINOR` issues accepted with rationale
5. **`[HUMAN_JUDGMENT]` items** — e.g., a custom indicator 1px off; reviewer documents rather than loops

---

## `quality-gate.md` — Quality Gate output

**Consumed by:** Orchestrator, human reviewer.

**Required sections:**

1. **TypeScript compilation** — pass/fail + errors
2. **ESLint** — pass/fail + violations (incl. `jsx-a11y`)
3. **Prettier** — pass/fail + diff
4. **Auto-fix applied** — what was auto-fixed
5. **Retry taken** — yes/no; if yes, what changed between passes

---

## `pipeline-state.yaml` — Orchestrator owned

**Writer:** orchestrator only. Agents emit structured reports (small, named, in `reports/`); orchestrator aggregates. Multiple agents writing pipeline-state simultaneously causes lateral conflicts, so only one writer.

**Required keys:**

```yaml
run_id: <uuid>
component: <name>
ds_adapter: <adapter-name>
phase: understand | build | verify
gigo:
  score: <0.0–1.0>
  penalties:
    - code: REST_FALLBACK | UNRESOLVED_TOKEN | MISSING_VARIANT | ...
      value: -0.30
      reason: "..."
iterations:
  visual_reviewer: <n>/5
  a11y_auditor: <n>/3
  quality_gate: <n>/1
gates:
  architecture: pending | resolved | skipped
  motion_spec: pending | resolved | deferred
  # ...one per human-gate item surfaced
push_back:
  - agent: component-architect
    severity: BLOCKING | CONCERN | SUGGESTION
    message: "..."
    resolved: true | false
```

---

## `review-log.md` — Pipeline-review agent output (post-run)

**Consumed by:** human (feedback-loop signal source).

**Required sections:**

1. **What went well** — by category: token validity, a11y compliance, story coverage, architecture adherence, visual fidelity
2. **What didn't** — same categories, with specific agent pointed to
3. **Three-tier classification** — T1 rules-fixable / T2 tools-fixable / T3 human-gate — for each new finding
4. **Proposed rule** — for each T1 finding, the exact rule text to add (with target layer: workarounds / memory / skill)
5. **Proposed tool improvement** — for each T2 finding, what tooling needs to change (MCP / adapter / infrastructure)
