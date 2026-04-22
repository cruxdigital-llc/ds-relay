# Plan-Product Trace — 2026-04-22

## Session start
Invoked via `/glados:plan-product`. User requested a generic Figma-to-code agent pipeline, delivered as a Claude Code plugin.

## Prerequisite status
- [ ] `product-knowledge/MISSION.md` — not present at session start; drafted in-session
- [x] `product-knowledge/PROJECT_STATUS.md` — template in place, populated in-session

## Initial understanding of the target system
**Pipeline architecture (3 phases, 8 agents):**
- **Understand**: Design Analyst → Library Researcher → Component Architect
- **Build**: Code Writer → Accessibility Auditor → Story Author
- **Verify**: Visual Reviewer → Quality Gate

**Artifact handoffs:** Figma → `brief.md` → `component-rules.md` → `architecture.md` → source code + stories + a11y report + visual comparison + QG report

**Core mechanisms:**
- Artifact-based handoffs (contracts with required fields; gaps marked `[PENDING]`/`[UNRESOLVED]`)
- Fresh-context validation (validators see just the component, not the full codebase)
- Iteration budgets per agent (Visual Reviewer 5, a11y Auditor 3, QG 1)
- GIGO quality score (deterministic, starts at 1.0, hard-stops below 0.8)
- Conversational architecture gate (human resolves `[BLOCKING]` issues before code)
- Push-back protocol (`[BLOCKING]` / `[CONCERN]` / `[SUGGESTION]`)
- Three persistence layers for rules: `workarounds.md` → memory → skill files
- Three failure tiers: rules-fixable (T1) / tools-fixable (T2) / human-gate (T3)

## Open questions (resolved by user)
1. **Target design system** — generic pipeline, design-system-agnostic core with pluggable adapters. A generic template adapter ships for teams to copy.
2. **Distribution form** — Claude Code plugin.
3. **Output framework** — React + TypeScript + CSS Modules + Storybook (CSF Factories) + `@floating-ui/react`. Extensible later via adapter pattern.
4. **Third-party tooling** — Figma Console MCP, Anova Figma plugin, Context7 MCP as baseline MCP dependencies. Modularize / provide fallbacks post-MVP.
5. **MVP scope** — full pipeline end-to-end: all 8 agents, 3 phases, the full set of human gates, GIGO score, conversational architecture gate, Visual Reviewer with diminishing-returns stop, push-back protocol, three-tier failure framework, pipeline-review feedback loop.

## Decisions
- **Architecture is generic; adapters are specific.** Core pipeline agents know nothing about any particular design system. DS-specific knowledge (token prefixes, editorial voice, component registry) lives in a pluggable adapter. MVP ships a generic template adapter at `adapters/template/`.
- **Phased roadmap.** Phase 0 scaffolding → Phase 1 linear pipeline (close knowledge-gap failures) → Phase 2 contracts + rules compounding (close cross-agent drift) → Phase 3 autonomy + excellence (MVP target). Each phase has an exit criterion tied to the failure class it closes.
- **Model allocation.** Sonnet 4.6 default; Opus 4.7 for Component Architect and Library Researcher (reasoning-heavy, downstream-critical).
- **MVP acceptance rehearsal.** Full pipeline run against a complex test component (nested submenus, multiple selection models, typeahead, hover-intent). Target: zero fabricated tokens, correct library-hook usage, all human gates surfaced, ~3-hour end-to-end.
- **Documentation convention.** All project documentation is written as if ADS is a standalone product. No citations to external sources, specific companies, or specific existing design systems.
- **Prerequisite note.** `MISSION.md` was missing at session start (prereq of the plan-product workflow). Drafted in-session given the user's clear intent.

## Files created
- `product-knowledge/MISSION.md`
- `product-knowledge/ROADMAP.md`
- `product-knowledge/TECH_STACK.md`
- `.claude-plugin/plugin.json`
- `.mcp.json`
- `hooks/hooks.json`, `hooks/enforce-preflight.sh`, `hooks/gigo-scan.sh`
- `standards/tech-stack.md`, `standards/ds-adapter.md`, `standards/artifact-contracts.md`
- `adapters/template/` (pending)

## Files updated
- `product-knowledge/PROJECT_STATUS.md` — architecture summary + Phase 0 active tasks
- `specs/2026-04-22_plan-product/README.md` (this file)

## Memory saved
- Project memory: repo overview (what ADS is, MVP definition, delivery form)
- Feedback memory: documentation must not reference external source material; ADS is its own standalone product
