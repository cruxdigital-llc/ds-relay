# Push-Back Protocol

Agents flag issues in their handoff documents at three severity levels. This turns a one-way handoff pipeline into a structured, asynchronous conversation between agents.

## Severity levels

### `[BLOCKING]`

> The pipeline must stop and get human input before proceeding.

Use when:
- The brief is ambiguous and multiple valid interpretations exist
- The architecture depends on a dependency/hook/API that doesn't exist
- Spec data and Figma bound variables disagree on a token value
- A human gate (motion, hover intent, screen reader) has no spec data available

Example (from Component Architect):
> *"The brief specifies five selection models, but the spec lists checkmarks under both single-select and multi-select sections. Which behavior is intended? Implementing as single-select means only one checkmark at a time, matching native dropdown behavior. Implementing as multi-select means checkmarks work like checkboxes in a list."*

**Pipeline response:** halt at the conversational gate. Present the options in design-language risk tradeoff framing. Propagate the human's resolution to all downstream agents.

### `[CONCERN]`

> The agent proceeds, but includes its rationale for downstream scrutiny.

Use when:
- A design tradeoff is being made that downstream agents should know about
- A workaround is being applied that isn't ideal but ships
- A behavior is intentional but surprising

Example (from Code Writer):
> *"Using `FloatingFocusManager` with `modal={false}` because the menu should not trap focus — but this means Tab leaves the menu entirely. If that's not desired, switch to `modal={true}`."*

**Pipeline response:** record in the handoff. Ship unless a downstream agent escalates it. Visible to the human in the final summary.

### `[SUGGESTION]`

> Optional information for downstream agents; not a block, not a rationale — a pointer.

Use when:
- Another component might benefit from extracting a primitive you built
- A pattern you noticed might apply elsewhere
- A future refactor would improve things but isn't urgent

Example (from Component Architect):
> *"The design uses a custom divider. The DS doesn't have an equivalent. Consider extracting this as a shared primitive if other components need it."*

**Pipeline response:** log. Surface at the review step. Does not block or delay the current run.

## Which agents can push back to which

Any agent can push back to any upstream or downstream agent via its own output artifact. The severity and target are explicit in the marker:

```
[BLOCKING] @component-architect: <message>
[CONCERN] @code-writer: <message>
[SUGGESTION] @story-author: <message>
```

The orchestrator aggregates push-backs into `pipeline-state.yaml` and surfaces them at the appropriate gate or review step.

## Why this exists

One-way handoffs produce agents that execute faithfully but don't think. An agent that finds an inconsistency in its upstream input and silently picks one interpretation is a false-positive-factory — it produces output that looks correct but isn't trustworthy.

Push-back makes uncertainty visible. The human resolves it once, the resolution propagates, and the next run starts with accumulated knowledge.

## Rule of thumb

- `[BLOCKING]` if proceeding requires guessing
- `[CONCERN]` if proceeding requires a tradeoff someone else should know about
- `[SUGGESTION]` if proceeding is fine but future work might benefit
