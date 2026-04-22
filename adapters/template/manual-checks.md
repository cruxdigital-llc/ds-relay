# Manual Checks — <Your DS Name>

Items added to every generated component's PR description for a human to test by hand. These are human-gate items — automation cannot reliably verify them.

The pipeline already includes generic manual checks (hover path, screen-reader experience, motion feel, visual pixel verification of custom indicators). List *adapter-specific* items below.

## Template

Copy per item:

```markdown
- [ ] **<short title>** — <what to test, specifically>
  - Why: <why automation can't catch this>
  - How: <step-by-step; include browser/assistive-tech version if relevant>
```

## Example

```markdown
- [ ] **Custom indicator pixel match** — Verify the custom checkbox indicator inside menu items matches the standalone DS Checkbox component at 2x zoom in Figma.
  - Why: This DS has known sub-pixel rounding errors when scaling from 20×20 (standalone) to 16×16 (menu context). Automated screenshot comparison does not reliably catch sub-pixel deviations in stroke weight or inner spacing.
  - How: Open the component in Storybook at 200% zoom. Compare side-by-side with the Figma component frame `<frame-id>`. Focus on border-radius, checkmark stroke weight, and inner padding.
```

## Items to add for this adapter

- [ ] _add items specific to this DS's known gotchas_
