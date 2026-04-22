# Tokens — <Your DS Name>

## Prefix rules

Fill in one row per token category. Show the exact string prefix and one representative example.

| Category | Prefix | Example |
|---|---|---|
| Color | `--<prefix>-*` | `--<prefix>-surface-default` |
| Spacing | `--<prefix>-*` | `--<prefix>-component-stack-padding-small` |
| Font | `--<prefix>-*` | `--<prefix>-size-body` |
| Radius | `--<prefix>-*` | `--<prefix>-action` |
| Shadow | `--<prefix>-*` | `--<prefix>-overlay` |
| Border width | `--<prefix>-*` | `--<prefix>-thin` |
| Duration | `--<prefix>-*` | `--<prefix>-fade-fast` |

Delete rows your DS doesn't have; add rows for categories this table doesn't cover.

## Forbidden prefixes

List any prefix convention that is plausible to an LLM but *wrong* for your DS. Common examples:

- Namespaced versions of bare prefixes (if your DS uses `--color-*`, list `--<dsname>-color-*` here)
- Legacy prefixes from an older version of the DS
- Prefixes used by a sibling DS in the same company that agents might confuse for this one

Quality Gate hard-fails on any match.

## Resolution tool

**Primary tool:** fill in the MCP tool name (e.g., `<your-ds>-tokens.get_tokens`) and argument shape.

```
Tool: <your-ds>-tokens.get_tokens
Arguments: { category?: string, search?: string }
Returns: [{ name, value, description }, ...]
```

**Forbidden fallback:** agents must never crawl `node_modules/<your-ds-package>/dist/*` or infer token names from source inspection. Reason: source crawling is slow, fragile, may reflect a stale version, and tends to surface internal tokens that aren't part of the public API.

## Typography mapping

Figma usually hardcodes pixel values for typography, while most design systems expose semantic size tokens. Document the mapping.

Example:

| Figma `fontSize` / `lineHeight` | Token |
|---|---|
| `16px` / `20px` | `--<prefix>-size-body` / `--<prefix>-line-height-body` |
| `14px` / `18px` | `--<prefix>-size-small` |

**Rule for unmapped values:** if a Figma pixel value is not in the explicit mapping table AND spec data (Anova or similar) is unavailable, do not guess. Flag `[UNRESOLVED]` in `brief.md`, apply a per-token GIGO penalty, and surface at the conversational gate.

## Token source hierarchy (reminder, applies to all adapters)

1. Spec-data-first (Anova YAML `$token` refs or equivalent) — reliable, explicit
2. Figma bound variables (via Figma Console MCP) — reliable for properties Figma supports natively
3. Figma REST API — last resort, -0.30 GIGO penalty, triggers `[DEGRADED_QUALITY]` markers in output

When sources disagree, flag the conflict and halt. Do not guess.
