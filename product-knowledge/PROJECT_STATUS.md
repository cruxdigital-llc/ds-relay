# GLaDOS System Status

This document reflects the *current state* of the codebase and project.
It should be updated whenever a significant change occurs in the architecture, roadmap, or standards.

## Project Overview
**Mission**: See [MISSION.md](./MISSION.md). Generic Figma-to-code agent-team pipeline, delivered as a Claude Code plugin.
**Current Phase**: Phase 0–3 complete (v0.1.0 scaffolding + all pipeline agents, commands, and contracts defined). MVP acceptance rehearsal pending.

## Architecture

8-agent pipeline in 3 phases:
- **Understand**: Design Analyst → Library Researcher → Component Architect
- **Build**: Code Writer → Accessibility Auditor → Story Author
- **Verify**: Visual Reviewer → Quality Gate
- **Post-run**: Pipeline Review (feedback loop source)

Handoffs are artifact files (`brief.md`, `component-rules.md`, `architecture.md`, `a11y-report.md`, `visual-review.md`, `quality-gate.md`). Orchestrator owns `pipeline-state.yaml`. Each agent has an iteration budget; push-back protocol (`[BLOCKING]`/`[CONCERN]`/`[SUGGESTION]`) surfaces uncertainty. Three persistence layers: `workarounds.md` → memory → skill files.

**Delivery:** Claude Code plugin (`.claude-plugin/plugin.json`, `agents/`, `commands/`, `hooks/`, `.mcp.json`).
**Output target (MVP):** React + TypeScript + CSS Modules + Storybook (CSF Factories) + `@floating-ui/react`.
**Reference DS adapter:** generic template at `adapters/template/` — copy and fill in per target DS.

Full detail: [TECH_STACK.md](./TECH_STACK.md).

## Current Focus

### 1. MVP acceptance rehearsal
*Lead: Architect + QA*
- [ ] Run `/relay-ds:onboard-adapter <name>` against a public design system (Material, Shadcn, Radix, or similar) to validate the onboarder
- [ ] Fill remaining `[NEEDS_INPUT]` sections in the resulting adapter
- [ ] Set up a test-target repo the pipeline can build into
- [ ] Run `/relay-ds:build-component` against a complex test component (nested menus + multi-selection + hover-intent)
- [ ] Run `/relay-ds:pipeline-review` and promote rules as they surface
- [ ] Capture the first round of `workarounds.md` entries from real runs

### 2. Infrastructure fills
- [ ] Replace hook shell stubs (`hooks/enforce-preflight.sh`, `hooks/gigo-scan.sh`) with real implementations
- [ ] Confirm MCP package names in `.mcp.json` (currently placeholders)
- [ ] `git init` + initial commit

### 3. Backlog / Upcoming
- See [ROADMAP.md](./ROADMAP.md) § Future Horizons — framework adapters (Vue/Svelte/Web Components), Figma-data independence, multi-component workflows, git+PR integration, team mode

## Known Issues / Technical Debt
- `adapters/template/` is a copy-and-fill template only; no filled-in adapter exists yet (user-gated — runs `/relay-ds:onboard-adapter` against a specific DS)
- Hook implementations cover the common rule violations but adapter-specific forbidden-prefix scanning is deferred to Quality Gate (parses adapter's `tokens.md` at runtime)
- `jq` is required on the dev machine for hooks to operate; the hooks gracefully skip if missing

## Recent Changes
- 2026-04-22: `/glados:plan-product` run. MISSION, ROADMAP, TECH_STACK defined.
- 2026-04-22: Phase 0 — plugin manifest, `.mcp.json`, hooks, standards (`tech-stack`, `ds-adapter`, `artifact-contracts`), template adapter scaffold.
- 2026-04-22: Phase 1 — 5 core subagents (Design Analyst, Component Architect, Code Writer, Story Author, Quality Gate), `/relay-ds:build-component` command, `workarounds.md` starter.
- 2026-04-22: Phase 2 — Library Researcher + Accessibility Auditor subagents, push-back protocol, GIGO score spec, three-tier failure framework.
- 2026-04-22: Phase 3 — Visual Reviewer + Pipeline Review subagents, conversational gate spec, `/relay-ds:pipeline-review` and `/relay-ds:promote-rule` commands.
- 2026-04-22: Top-level `README.md` added.
- 2026-04-22: Plugin renamed to `relay-ds`; slash commands namespaced under `/relay-ds:*`.
- 2026-04-22: Adapter onboarding — `/relay-ds:onboard-adapter` command + `adapter-onboarder` subagent + `standards/onboarding-discovery.md`. Auto-detects tokens, component names, and MCP config; emits pointed-question stubs for voice and manual checks with an `onboarding-report.md` diagnostic.
- 2026-04-22: `git init`; initial commit pushed to `github.com:cruxdigital-llc/ds-relay`. Plugin listed in `cruxdigital-llc/crux-marketplace` (PR #1).
- 2026-04-22: Gap-closing pass for end-to-end runnability. README install section; `standards/test-target-repo.md`, `figma-canary.md`, `run-retention.md`, `pr-description-template.md`; workaround ID scheme; build-component orchestrator concretized (GIGO formula, halt UI, decision matrix); real hook implementations (preflight + GIGO scan); corrected Figma Console MCP package name to `figma-console-mcp`.
