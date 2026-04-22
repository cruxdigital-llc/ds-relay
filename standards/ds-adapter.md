# Design System Adapter Interface

The ADS pipeline is generic. Everything design-system-specific lives in a pluggable adapter at `adapters/<name>/`. A generic template ships at `adapters/template/` for teams to copy.

## Why adapters exist

Language models will confidently generate plausible-but-wrong token names for any design system. If agents are given `--brand-color-primary` to work with but the DS actually uses `--color-primary`, every token reference in the output will resolve to nothing — and tests will still pass because tests check behavior, not visual appearance. Every design system has idiosyncrasies like this. Baking them into agent prompts is how you lose portability. Adapters hold them.

## What an adapter provides

An adapter is a directory with these files:

```
adapters/<name>/
├── adapter.md              # human-readable adapter overview
├── tokens.md               # token prefix rules + lookup instructions
├── components.md           # component registry access
├── editorial-voice.md      # voice rules beyond the sentence-case baseline
├── mcp.json                # additional MCP servers this adapter requires
└── manual-checks.md        # adapter-specific manual test checklist items
```

The pipeline loads `adapters/<name>/` based on a per-run config (`pipeline-config.yaml`, `ds_adapter: <name>`).

## Required sections per file

### `tokens.md`

- **Prefix rules.** Exact string prefixes for each token category, e.g., `--color-*`, `--space-*`, `--radius-*`, `--font-*`, `--shadow-*`. Some systems use a namespace prefix (`--brand-color-*`); some use bare categories.
- **Resolution tool.** The MCP tool (or local command) that returns the authoritative token list. Agents MUST call this — never crawl `node_modules`, never infer.
- **Forbidden prefixes.** Plausible-but-wrong conventions the LLM will default to if unconstrained. If your DS uses bare `--color-*` but a naive LLM would write `--mydsname-color-*`, list the namespaced form here so Quality Gate can hard-fail on any match.
- **Typography mapping.** How raw pixel values from Figma map to semantic tokens (e.g., `16px → --font-size-component-medium`). Typography is the hardest case because Figma hardcodes pixel values while most DSes use semantic size tokens.

### `components.md`

- **Component lookup tool.** The MCP tool that returns the DS's component registry.
- **Case sensitivity.** Note any gotchas (some lookups silently fail on wrong case).
- **Composition rules.** Which primitives exist standalone vs. embedded (e.g., does the DS provide a standalone checkbox *indicator*, or only the full checkbox control?).
- **What the DS does NOT provide.** Gaps the component will need to build custom, by category. Helps the Architect surface build-vs-adopt tradeoffs at the gate.

### `editorial-voice.md`

Rules beyond sentence case. E.g., specific phrasing conventions, disallowed words, pluralization rules, tone.

### `mcp.json`

MCP server entries that get merged into the plugin's `.mcp.json` at runtime when this adapter is active. Example shape:

```json
{
  "mcpServers": {
    "<ds>-tokens": { "command": "...", "args": [...] },
    "<ds>-components": { "command": "...", "args": [...] }
  }
}
```

### `manual-checks.md`

Items to include in the output's manual-test checklist that are specific to this DS (e.g., "Verify custom indicators against the DS Figma component at 2x zoom — this DS has known sub-pixel rounding issues in scaled indicators").

## Adapter versioning

Each adapter declares the ADS pipeline version it was written against. Breaking pipeline changes bump a major version; adapters are expected to pin to a range.

## Building a new adapter

Copy `adapters/template/`, rename, fill in the six files. Validate by running `/relay-ds:build-component` against a test component and checking the output against this DS's conventions. The first few runs will surface adapter gaps — those become the adapter's own workarounds log.
