<!--
GLaDOS-MANAGED DOCUMENT
Last Updated: 2026-04-22
To modify: Edit directly.
-->

# Roadmap

Phases are ordered by the class of failure each one closes: knowledge gaps, then cross-agent information loss, then the gap between correct and excellent.

---

## Phase 0 — Scaffolding

Plugin skeleton and design-system adapter contract. No agents operating yet.

- [x] Claude Code plugin skeleton (`.claude-plugin/plugin.json`, `agents/`, `commands/`, `.mcp.json`, `hooks/`)
- [x] Design-system adapter interface (token-prefix config, component registry hooks, editorial voice rules, manual-check surfaces)
- [x] Template adapter at `adapters/template/` — generic starter teams copy and fill in
- [x] Adapter onboarding command (`/relay-ds:onboard-adapter`) + `adapter-onboarder` subagent — auto-detect tokens from CSS/JSON/npm, component names from Storybook/npm, MCP config from provided command; structured stubs with `[NEEDS_INPUT]` markers for editorial voice and manual checks
- [x] Discovery protocol documented (`standards/onboarding-discovery.md`)
- [x] MCP wiring: Figma Console MCP, Context7, target-DS tool surface
- [x] Repo standards committed to `standards/` (tech stack, naming, file layout, artifact contracts)
- [ ] Test-target repo convention (the pipeline can't validate itself inside itself — it needs an external project to build into)

## Phase 1 — Linear pipeline

Sequential agents, single quality gate at the end, no iteration loops, no push-back. Goal: close the knowledge-gap class of failures — where agents don't know a rule and silently default to the wrong thing.

- [ ] **Design Analyst** skill — reads Figma, writes `brief.md`, caches `figma-raw.json`
- [ ] **Component Architect** skill — writes `architecture.md` with TS prop interfaces and named handoff notes (`For Code Writer: …`)
- [ ] **Code Writer** skill — produces TS + CSS Modules from brief + architecture
- [ ] **Story Author** skill — CSF Factories with interaction tests (click, keyboard, focus)
- [ ] **Quality Gate** skill — tsc + ESLint (incl. `jsx-a11y`) + Prettier; one pass + one retry
- [ ] Starter rule set encoded as skill content:
  - No hardcoded token fallbacks (`var(--x, #333)` forbidden)
  - Token-prefix compliance (delegated to DS adapter)
  - No `node_modules` spelunking; call DS MCP tools instead
  - Sentence case for all user-facing strings
  - Multi-step story interactions must test to completion, not just step one
- [ ] `workarounds.md` starter — the raw observation log for this project

**Exit:** a component in Storybook that is *functionally* correct. It can still be visually wrong or use the wrong library hooks.

## Phase 2 — Contracts + rules compounding

Address cross-agent drift: knowledge the orchestrator has doesn't always reach the agent that needs it. Introduce research as a first-class artifact and add the push-back protocol.

- [ ] **Library Researcher** skill — audits every dependency's API surface, writes `component-rules.md` (`CR-*` mandatory, `AR-*` advisory)
- [ ] Code Writer pre-flight check: must load `component-rules.md` before writing a line (enforced by skill definition and hook)
- [ ] **Accessibility Auditor** skill, positioned *inside* the Build phase (right after Code Writer) — 8-layer stack: ESLint `jsx-a11y`, axe-core, virtual screen reader simulation, Storybook a11y addon, axe+Playwright in-browser, keyboard nav tests, contrast checks, manual checklist. P1/P2/P3 findings; up to 3 remediation attempts; bail on repeated error signatures
- [ ] Push-back protocol: `[BLOCKING]` / `[CONCERN]` / `[SUGGESTION]` markers in any handoff doc
- [ ] **GIGO quality score** — deterministic, starts at 1.0, REST-API fallback = -0.30, each unresolved token = -0.02, missing variant proportional. Hard-stop at <0.8 with three human options (fix input / provide manually / accept degraded)
- [ ] Figma Console MCP canary detection (runtime test command, not config grep)
- [ ] Persistence ladder: `workarounds.md` → memory → skill files, with promotion criteria documented
- [ ] Orchestrator-only writer for `pipeline-state.yaml` (agents emit structured reports; orchestrator aggregates — prevents lateral write conflicts)

**Exit:** a component that uses the right library hooks, passes a11y, and halts (not fabricates) when input is degraded.

## Phase 3 — Autonomy + excellence (MVP target)

Where "correct" becomes "excellent." Adds visual fidelity, conversational human gates, and the review loop.

- [ ] **Visual Reviewer** skill — screenshots Storybook stories, compares to Figma across 9 dimensions (layout, typography, colors, spacing, shadows, borders, border-radius, icons, states). Each dimension graded PASS/MINOR/MODERATE/CRITICAL. Max 5 iterations. Stop on <2% delta. No-regression rule (reverts a fix that downgrades a previously-PASS dimension)
- [ ] **Conversational architecture gate** — Architect flags `[BLOCKING]` issues as design-language risk tradeoffs, not technical dumps. Human resolves; decision propagates to all downstream agents. Menu of options: explore auto-approved sections / request self-review / proceed. Exits only on explicit "proceed"
- [ ] Architect self-confidence scoring — auto-approve high-confidence sections silently; surface low-confidence ones at the gate
- [ ] "Deferred Features — Forward Architecture" section for any feature the Architect defers (mini-architecture sketch of how it would plug in later)
- [ ] Auto-discovery of component families in Figma (navigate component sets + variant groups; human doesn't have to point at the right node)
- [ ] Spec-data-first token extraction: Anova YAML → Figma bound variables → REST fallback (with GIGO penalty)
- [ ] Manual-test checklists auto-included in output PR descriptions for human-gate items (hover path, screen-reader, motion feel, visual indicator pixel-check)
- [ ] **Pipeline-review agent** — separate multi-agent review pass after every full run. Generates structured log by category (token validity, a11y, story coverage, architecture adherence, visual fidelity). Drives the feedback loop into workarounds / memory / skills
- [ ] Three-tier failure classification surfaced in review output (T1 rules-fixable / T2 tools-fixable / T3 human-gate)
- [ ] **MVP acceptance rehearsal** — run the full pipeline against a complex test component (nested submenus, portaled content, multiple selection models, typeahead, hover-intent). Target: zero fabricated tokens, zero custom keyboard nav when the library provides it, all human gates surfaced, ~3-hour end-to-end

**Exit = MVP.**

---

## Future Horizons *(post-MVP)*

Ordered roughly by anticipated demand.

- **Framework adapters** — Vue, Svelte, Web Components, plain HTML+CSS output modes
- **Adapter showcase** — a few filled-in adapters for well-known public design systems to validate the interface from different angles
- **Figma-data independence** — reliable pure-REST-API extraction for teams without the Console MCP or Anova plugin
- **Multi-component workflows** — build related components together; extract shared primitives automatically
- **Git + PR integration** — open PRs with the generated component, manual-test checklist, and GIGO report in the description
- **Team mode** — multiple humans on gates, decision audit log, merge-resolution for conflicting gate answers
- **Design-intent preservation layer** — capture "why this padding" alongside "what padding," surface it to the Architect when humans later change the design
