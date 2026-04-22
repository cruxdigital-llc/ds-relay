<!--
GLaDOS-MANAGED DOCUMENT
Last Updated: 2026-04-22
To modify: Edit directly.
-->

# Tech Stack

Two layers: (1) the pipeline itself (Claude Code plugin), and (2) the code it produces. The pipeline is generic; the output stack is the MVP default and is extendable later.

---

## Pipeline delivery

- **Form factor:** Claude Code plugin (`.claude-plugin/plugin.json`)
- **Plugin components:**
  - `skills/` — per-agent system prompts (8 agents + pipeline-review)
  - `agents/` — subagent definitions
  - `commands/` — slash commands: `/relay-ds:onboard-adapter`, `/relay-ds:build-component`, `/relay-ds:pipeline-review`, `/relay-ds:promote-rule`
  - `.mcp.json` — MCP server configuration
  - `hooks/` — pre-tool-call enforcement for rules that must block execution (e.g., Code Writer cannot start without `component-rules.md` loaded)

## Runtime

- **Model defaults:**
  - Sonnet 4.6 — Design Analyst, Code Writer, Story Author, Visual Reviewer, Quality Gate, Accessibility Auditor
  - Opus 4.7 — Component Architect, Library Researcher (reasoning-heavy, downstream-critical)
- **Orchestration:** Claude Code agent-team mode. Orchestrator is the single writer of `pipeline-state.yaml`; agents emit structured reports that the orchestrator aggregates. Handoffs are artifact files (`brief.md`, `component-rules.md`, `architecture.md`, etc.), never in-memory messages.

## Output target (MVP default)

- **Frontend framework:** React 18+ with TypeScript (strict)
- **Styling:** CSS Modules (scoped); CSS custom properties for all tokens; **no fallback values** (`var(--x)` only, never `var(--x, #333)`)
- **Behavior libraries (recommended):** `@floating-ui/react` — provides `useListNavigation`, `useTypeahead`, `useDismiss`, `useRole`, `FloatingFocusManager`, `FloatingTree`, `FloatingList`, `safePolygon` and similar composable hooks that cover most interactive-layer needs
- **Stories:** Storybook 8+ in CSF Factories format, one story per variant/state/edge case
- **Interaction tests:** Storybook `play` functions + Playwright for in-browser axe-core runs

## Agent tooling (MCP)

- **Figma Console MCP** — WebSocket bridge to the Figma desktop app. Primary Figma path: can expand component instance children, resolve variable bindings, reach internal layout properties
- **Figma REST API** — fallback when the Console MCP isn't connected. Triggers GIGO -0.30 penalty and `[DEGRADED_QUALITY]` markers
- **Anova plugin data** — primary token source when present (YAML `$token` references embedded in Figma frames)
- **Context7 MCP** — up-to-date library documentation; used by Library Researcher to audit dependency API surfaces
- **Design-system adapter MCP** — pluggable per target DS. The active adapter (e.g., `adapters/<name>/mcp.json`) gets merged into the plugin's MCP config at runtime. Adapter interface documented in `standards/ds-adapter.md`

## Quality stack

- **Compile / lint / format:** `tsc`, ESLint (with `jsx-a11y`), Prettier
- **Runtime a11y:** axe-core, Storybook a11y addon, axe-core + Playwright in-browser runs
- **Virtual screen reader simulation** (Auditor's static pass); manual VoiceOver/NVDA checklist shipped in output description
- **Visual diff:** Storybook screenshot capture compared against Figma render across 9 graded dimensions
- **Contrast checks** inline with the a11y audit

## Persistence layers

- **`workarounds.md`** — raw per-project observation log. Every new failure lands here first
- **Memory** (via Claude Code memory system) — broadly-applicable rules promoted from workarounds, loaded into every agent's context
- **Skill files** — hardened, agent-targeted pre-flight checks. Rules specific to one agent's workflow live here

## Artifact contracts

Required files flowing between agents — each with mandatory sections. Missing data is marked `[PENDING]` / `[UNRESOLVED]` / `[HUMAN_GATE]`, never silently omitted. Full schema: `standards/artifact-contracts.md`.

- `brief.md` — Design Analyst output
- `component-rules.md` — Library Researcher output (`CR-*` mandatory, `AR-*` advisory)
- `architecture.md` — Component Architect output (TS interfaces + named handoff notes + confidence-scored sections + deferred-features forward architecture)
- `pipeline-state.yaml` — orchestrator-owned; aggregates GIGO score, iteration counts, gate status
- `a11y-report.md` — Accessibility Auditor findings classified P1/P2/P3
- `visual-review.md` — Visual Reviewer findings graded across 9 dimensions
- `quality-gate.md` — compile/lint/format status
- `review-log.md` — post-run multi-agent review output

## Known external dependencies (modularization candidates, post-MVP)

- Figma desktop app (required for Console MCP)
- Anova Figma plugin (for structured spec data — fallback path must be kept working)
- Target design system's own MCP tools (for authoritative token and component data)

## Extension points (framework-adapter path)

Output-stack assumptions are intentionally concentrated in:
- Code Writer skill (file templates, import conventions, CSS strategy)
- Story Author skill (story format)
- Component Architect skill (prop API conventions)
- DS adapter (token conventions, component registry)

Adding Vue / Svelte / Web Components later = new Code Writer + Story Author skill variants + output-format flag in plugin config. No pipeline-level changes expected.
