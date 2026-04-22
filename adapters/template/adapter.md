# Template Adapter

Copy this directory to `adapters/<your-ds-name>/`, then fill in the six files below. This directory is intentionally generic — it documents the shape of an adapter without committing to any specific design system's conventions.

Interface definition: `standards/ds-adapter.md`.

## The six files

| File | Purpose |
|---|---|
| `adapter.md` | This overview. Replace with a description of your DS, its authoritative documentation, and how agents connect to it |
| `tokens.md` | Token prefix rules, resolution MCP tool, forbidden prefixes, typography mapping |
| `components.md` | Component registry access, case-sensitivity gotchas, composition rules, known gaps |
| `editorial-voice.md` | Voice rules beyond the sentence-case baseline |
| `mcp.json` | MCP servers this adapter needs, merged into the plugin's `.mcp.json` at runtime |
| `manual-checks.md` | Manual-test checklist items specific to this DS |

## When to fork vs. when to fill in

Fill in for any real design system, even a public one you're targeting on someone else's behalf. Fork (create a new adapter) when you have meaningfully different conventions — e.g., a DS has v1 and v2 with incompatible token prefixes, or a product uses a customized fork of a parent DS.

## Validating your adapter

After filling in the six files:

1. Run `/relay-ds:build-component` against a small test component (e.g., a button variant or a simple chip).
2. Check the output:
   - Do token references use your DS's actual prefixes?
   - Does `Quality Gate` hard-fail on any forbidden prefix your `tokens.md` lists?
   - Do editorial-voice rules apply to story names and user-facing strings?
   - Are the manual-check items from `manual-checks.md` in the output's PR description?
3. The first few runs will surface adapter gaps — capture those in this adapter's own `workarounds.md` inside the adapter directory.

## Adapter version pin

Declare the ADS pipeline version this adapter targets:

```yaml
# adapter-version.yaml
ads_pipeline: ">=0.1.0 <1.0.0"
```

Breaking pipeline changes bump a major version.
