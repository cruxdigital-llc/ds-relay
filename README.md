# Automated Design System (ADS)

A Claude Code plugin that turns a Figma component into a production-quality React component — source code, Storybook stories with interaction tests, accessibility report, visual comparison, and quality gate report — via an 8-agent pipeline with structured human gates.

Design-system-agnostic core. Pluggable adapters per target DS.

---

## Install

```
/plugin marketplace add cruxdigital-llc/crux-marketplace
/plugin install relay-ds@crux-marketplace
```

### Prerequisites

- **Claude Code** — the plugin targets current Claude Code plugin conventions (subagents, slash commands, hooks, MCP config)
- **Figma desktop app** with the **Figma Console MCP plugin** installed — the Design Analyst's primary Figma path. Without it, the pipeline falls back to Figma REST and applies a `-0.30` GIGO penalty
- **A target repo** where generated components will land — React 18+, TypeScript, Storybook, CSS Modules. Convention: `standards/test-target-repo.md`
- **A filled-in DS adapter** — run `/relay-ds:onboard-adapter <your-ds-name>` once per design system (see step 1 in *How to use* below)

### Verifying the install

After installing, confirm the commands are registered:

```
/relay-ds:onboard-adapter --help
/relay-ds:build-component --help
```

Both should print the argument hint from the command's frontmatter.

---

## What you get

- **Eight specialized agents** across three phases (Understand → Build → Verify), each with its own system prompt, tool allowlist, and iteration budget
- **Artifact-file handoffs** — every agent reads and writes structured documents with required sections; missing data is flagged, never silently omitted
- **Push-back protocol** — `[BLOCKING]` / `[CONCERN]` / `[SUGGESTION]` markers turn a one-way pipeline into a structured asynchronous conversation
- **GIGO quality score** — deterministic input-quality score; hard-stops the pipeline on degraded input (<0.80)
- **Conversational architecture gate** — the Component Architect surfaces low-confidence decisions as design-language risk tradeoffs; the human resolves; decisions propagate everywhere
- **Visual Reviewer** — screenshots stories, compares to Figma across 9 graded dimensions, iterates up to 5 times, stops on diminishing returns, reverts regressions
- **Three-layer persistence ladder** — observations land in `workarounds.md`, recurring rules get promoted to memory, agent-critical rules harden into skill files
- **Three-tier failure framework** — classify every failure as rules-fixable (T1) / tools-fixable (T2) / human-gate (T3) before choosing a fix strategy
- **Post-run review agent** — produces the feedback signal that makes the next run better

---

## Layout

```
.claude-plugin/plugin.json     # plugin manifest
.mcp.json                      # core MCP servers (Figma Console, Context7)
hooks/                         # pre-tool-call enforcement + post-write scanning

agents/                        # subagent definitions
  design-analyst.md                # Understand
  library-researcher.md            # Understand
  component-architect.md           # Understand
  code-writer.md                   # Build
  accessibility-auditor.md         # Build
  story-author.md                  # Build
  visual-reviewer.md               # Verify
  quality-gate.md                  # Verify
  pipeline-review.md               # Post-run feedback
  adapter-onboarder.md             # Invoked by /relay-ds:onboard-adapter

commands/                      # slash commands
  onboard-adapter.md               # scaffold a new DS adapter with auto-detection
  build-component.md               # full pipeline run
  pipeline-review.md               # post-run review
  promote-rule.md                  # advance a rule up the persistence ladder

standards/                     # the contracts
  artifact-contracts.md            # every doc, every required section
  tech-stack.md                    # output-code conventions
  ds-adapter.md                    # adapter interface
  test-target-repo.md              # target-repo shape + ADS_TARGET_REPO resolution
  push-back-protocol.md            # [BLOCKING]/[CONCERN]/[SUGGESTION]
  gigo-score.md                    # deterministic quality score
  figma-canary.md                  # MCP liveness check protocol
  three-tier-failures.md           # T1/T2/T3 classification
  conversational-gate.md           # architecture gate behavior
  run-retention.md                 # prune policy + env knobs
  pr-description-template.md       # exact populated PR body
  onboarding-discovery.md          # adapter auto-detection contract

adapters/template/             # copy this, fill in for your DS
  adapter.md
  tokens.md
  components.md
  editorial-voice.md
  mcp.json
  manual-checks.md

workarounds.md                 # raw observation log (per-project)

product-knowledge/             # managed project docs
  MISSION.md
  ROADMAP.md
  TECH_STACK.md
  PROJECT_STATUS.md

specs/                         # trace log for planning sessions
```

---

## How to use

### 1. Onboard a design-system adapter

```
/relay-ds:onboard-adapter <your-ds-name> \
  --tokens ./path/to/tokens.css \
  --components https://storybook.example.com \
  --mcp "npx -y @your-co/ds-mcp" \
  --voice https://wiki.example.com/voice
```

The onboarder parses what it can (token prefixes from CSS/JSON, component names from Storybook, MCP server config) and emits pointed-question stubs for what needs human judgment (editorial voice, manual-check items). Produces an `onboarding-report.md` with confidence per section.

If you'd rather fill everything by hand, skip to `cp -r adapters/template adapters/<your-ds-name>` and follow `standards/ds-adapter.md`.

### 2. Install MCPs

Core MCPs (already declared in `.mcp.json`):

- **Figma Console MCP** — WebSocket bridge to the Figma desktop app. Required for reliable extraction.
- **Context7 MCP** — library documentation; used by the Library Researcher to audit dependency API surfaces.

Adapter MCPs (from `adapters/<name>/mcp.json`) are merged in at runtime when the adapter is active.

### 3. Run the pipeline

```
/relay-ds:build-component <figma-node-url> --adapter <your-ds-name>
```

The pipeline will:

- Extract a brief from Figma (Design Analyst)
- Audit every dependency and write `component-rules.md` (Library Researcher)
- Design the component API and surface `[BLOCKING]` issues (Component Architect)
- **→ Pause at the conversational gate if any architectural decisions need human input**
- Produce source following the architecture (Code Writer)
- Audit accessibility across 8 layers (Accessibility Auditor)
- Write Storybook stories with interaction tests (Story Author)
- Screenshot + compare to Figma across 9 graded dimensions (Visual Reviewer)
- Run mechanical checks (Quality Gate)
- Halt and report if GIGO < 0.80 at any point

### 4. Review the run

```
/relay-ds:pipeline-review <run-id>
```

Produces `review-log.md` — findings classified T1/T2/T3, each with a proposed fix.

### 5. Promote rules

When a rule from `workarounds.md` proves itself across multiple runs, promote it:

```
/relay-ds:promote-rule <rule-id> --to memory
/relay-ds:promote-rule <rule-id> --to skill:code-writer
```

Rules compound. Knowledge doesn't decay.

---

## Design principles

1. **Separate creation from evaluation.** Validators get fresh context — just the component and its spec, not the full codebase. Fresh eyes catch what familiar eyes miss.
2. **Front-load the hard questions.** No code gets written in the Understand phase. By the time code generation starts, the missing conversations have happened.
3. **Encode rules at the right persistence layer.** Workarounds → memory → skill. A rule in the wrong layer either gets ignored or over-enforced.
4. **Define exit criteria before agents start.** Every agent knows what "done" looks like before it begins. Specific, measurable, bounded.
5. **Human gates are a feature, not a limitation.** Structural space for human judgment, surfaced where judgment produces the most leverage.
6. **Rules compound, but failures evolve.** Solve knowledge gaps, expose cross-agent drift. Fix drift, expose autonomy limits. The frontier of difficulty stays just ahead.
7. **The most honest thing an agent system can do is tell you where it stops.** Silently guessing destroys trust faster than pausing builds it.

---

## Roadmap

See `product-knowledge/ROADMAP.md`. Phase 0 (scaffolding) complete. Phases 1–3 implement the linear pipeline, cross-agent contracts, and full autonomy + excellence (MVP).

---

## Status

Pre-release. Actively under construction. Not ready for production runs until an adapter is filled in and the test-target repo convention is set up (see `product-knowledge/PROJECT_STATUS.md` § Known Issues).
