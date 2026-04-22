<!--
GLaDOS-MANAGED DOCUMENT
Last Updated: 2026-04-22
To modify: Edit directly.
-->

# Mission

**Automated Design System (ADS)** is an agent-team pipeline, delivered as a Claude Code plugin, that turns a Figma component file into a production-quality React component — source code, Storybook stories with interaction tests, accessibility report, visual comparison, and quality gate report — with structured human gates at the places where human judgment matters most.

## What it is

An orchestrated team of eight specialized agents organized in three phases (Understand → Build → Verify), communicating through artifact contracts, bounded by iteration budgets, and stopping at explicit human gates rather than silently guessing.

## What we're optimizing for

- **Zero silent failure.** When the pipeline can't reach a confident answer — ambiguous spec, missing motion data, degraded Figma input — it halts and asks rather than fabricates.
- **Correct *and* excellent.** "Correct" (tests pass, types compile) is table stakes. Excellent — right library hooks, right ARIA semantics, right design intent — requires structural space for human judgment.
- **Transferable architecture.** Design-system-agnostic core with pluggable adapters for token conventions, component registries, and editorial voice. A team copies the template adapter, fills in their design system's specifics, and points the pipeline at their Figma.

## Who it's for

Design-systems teams and product engineers who want to build production components from Figma without hand-rolling behavior their component library already provides, without fabricating token names, and without shipping inaccessible output that passed automated tests.

## Non-goals

- Replacing human design judgment.
- Running fully autonomously. The pipeline is a thought partner with documented human gates, not a black box.
- Producing prototypes. Single-prompt Figma-to-code already works for prototypes. This is for production-bar output.
