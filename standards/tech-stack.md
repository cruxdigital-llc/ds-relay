# Tech Stack — operative standards

Concrete versions and conventions. Mirrors `product-knowledge/TECH_STACK.md` but is the document agents actually check at runtime.

## Output target (MVP)

| Layer | Choice | Notes |
|---|---|---|
| Framework | React 18+ | Hooks-first, no class components |
| Language | TypeScript 5+ (strict) | `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes` |
| Styles | CSS Modules | Scoped per component; one `.module.css` per `.tsx` |
| Tokens | CSS custom properties | **`var(--token-name)` only. Never `var(--x, fallback)`.** If a token resolves to nothing, that is a bug to fix, not paper over. |
| Behavior | `@floating-ui/react` | Reference hooks: `useListNavigation`, `useTypeahead`, `useDismiss`, `useRole`, `FloatingFocusManager`, `FloatingTree`, `FloatingList`, `safePolygon` |
| Stories | Storybook 8+ | CSF Factories format. One story per variant, state, and edge case |
| Tests | Storybook `play` + Playwright | Interaction tests are regressions, not demos |
| A11y | ESLint `jsx-a11y`, axe-core, Storybook a11y addon, Playwright+axe | Plus manual VoiceOver/NVDA checklist in output |
| Build | `tsc` + ESLint + Prettier | Quality Gate's sole mechanical checks |

## Token rules

1. **No fallbacks.** `var(--x, #333)` is forbidden. The fallback hides a missing token and desynchronizes on theme change.
2. **No hardcoded values in JS.** When JavaScript needs a spacing value (e.g., a pixel offset for positioning middleware), read the CSS custom property at runtime via `getComputedStyle`.
3. **Token source hierarchy:** Anova `$token` references (YAML in Figma frames) → Figma bound variables (via Console MCP) → Figma REST API (REST triggers `-0.30` GIGO penalty). If sources disagree, flag the conflict — do not guess.

## File layout (output component)

```
<ComponentName>/
├── index.ts                    # barrel export
├── <ComponentName>.tsx         # main component
├── <ComponentName>.module.css  # scoped styles
├── <ComponentName>.stories.tsx # CSF Factories stories
├── <ComponentName>.test.tsx    # (optional) unit tests
└── types.ts                    # prop interfaces (only if file gets large)
```

## Naming

- Components: `PascalCase`
- Hooks: `useCamelCase`
- Props interfaces: `<ComponentName>Props`
- CSS classes in modules: `camelCase` (since they're JS property access)
- Story names: sentence case (matches editorial voice)

## Editorial voice

- **Sentence case** on all user-facing strings: labels, buttons, placeholder text, dialog titles, descriptions, story names.
- Proper nouns and acronyms keep their native casing.
- LLMs default to title case. Agents must consciously override.
- DS adapters may add voice rules on top of this baseline.
