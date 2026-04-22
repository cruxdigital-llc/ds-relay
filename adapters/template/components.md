# Components — <Your DS Name>

## Component lookup tool

```
Tool: <your-ds>-components.get_component
Arguments: { name: string }
Returns: { name, props, variants, composition_notes, ... }
```

## Case-sensitivity gotchas

Document any case conventions and known silent-failure modes. E.g., "lowercase-only" or "camelCase with exact match."

**Rule:** the Library Researcher and Component Architect skills must normalize casing before calling the lookup. Wrong-case lookups that return empty silently are a common source of agents concluding "this component doesn't exist" and building custom.

## Composition rules

One row per primitive the agent might need. Mark whether it exists standalone vs. is embedded only.

| Primitive | Standalone? | Notes |
|---|---|---|
| `Button` | yes / no | |
| `Checkbox` | yes / no | |
| `Radio` | yes / no | |
| `CheckboxIndicator` / `RadioIndicator` | yes / no | (Many DSes do NOT expose indicator primitives separately — if so, custom indicators become a human-gate visual-verification item) |
| `Menu` | yes / no | (If yes, document what it does and doesn't handle — nested submenus, group headers, toggle rows, typeahead, hover-intent) |

## What the DS does NOT provide

List known gaps by category so the Architect can surface build-vs-adopt tradeoffs at the conversational gate. Examples of categories to consider:

- Nested menu patterns (submenus, group headers, toggle rows)
- Hover-intent / safe-polygon primitives
- Typeahead primitives
- Standalone indicator primitives (for embedding inside menu items, etc.)
- Focus-ring tokens (sometimes color tokens exist but no width/offset/style tokens)

For each gap: a custom build means the component owns its own accessibility and maintenance burden. Going with the DS's available primitives means accepting their limitations. The Architect surfaces this tradeoff; the human chooses.

## Icon lookup

```
Tool: <your-ds>-icons.get_icon
Arguments: { name: string }
```

Known limitations to document:

- **Enumeration:** does the icon tool support listing all available icons, or only lookup-by-name? If only lookup-by-name, document the fallback (flag `[UNRESOLVED]` and -0.02 GIGO per unverifiable icon; do not crawl `node_modules`).
- **Concept search:** does the tool support fuzzy/semantic search? If so, agents should use it before declaring an icon missing.
- **Aliases:** are there renamed/legacy icon names? List the canonical source.
