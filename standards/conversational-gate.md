# Conversational Architecture Gate

The Component Architect's exit is not a timer. It's a conversation.

When the Architect produces `architecture.md` with any `[BLOCKING]` issue or any section scored `LOW` confidence, the pipeline pauses. The human sees the context, resolves the issues, and the pipeline resumes — exiting only on explicit "proceed."

---

## What triggers the gate

The gate activates when any of these is present in `architecture.md`:

- A `[BLOCKING]` marker
- A section with self-confidence `LOW`
- A DS divergence (the component must do something the active design system doesn't support)
- A Figma-data gap (e.g., motion, detached frame, missing variant)
- An accessibility tradeoff (e.g., `modal={true}` vs. `modal={false}` for focus trap)
- A motion or animation decision
- A case where multiple valid approaches exist

Sections with self-confidence `HIGH` auto-approve silently. The gate only surfaces what genuinely needs human judgment.

---

## What the gate presents

Not a technical dump. A **risk tradeoff in design language.**

Bad (technical dump):
> *"Using `FloatingFocusManager` with `modal={false}`. Tab will not trap in the menu. `aria-disabled` vs. native `disabled` attribute question unresolved."*

Good (design-language tradeoff):
> *"This menu handles focus in a way that lets users Tab out to the rest of the page without pressing Escape — which is usually what users expect in a dropdown menu. The tradeoff: keyboard users can't Shift-Tab back into the menu without going through the trigger again. If the menu is a primary navigation surface, we should flip this to trap focus; if it's a secondary action menu, this is fine. Which is it?"*

The framing names the concrete user behavior on both sides of the decision.

---

## The menu the human sees

After the blocking issues are resolved, the gate offers three options (not two, not one):

1. **Explore other sections** — browse the auto-approved parts of the architecture, discuss any of them. Resolving `[BLOCKING]` issues doesn't force exit; the human may want to scrutinize what was auto-approved.
2. **Self-review** — the Architect re-examines its own work, which may surface new issues that get resolved conversationally. This catches cases where the confidence score was miscalibrated.
3. **Proceed to Code Writer** — exit the gate, continue the pipeline.

The loop persists until the human explicitly says **proceed.** The gate is resolved, not elapsed. There is no countdown, no automatic progression.

---

## Decision propagation

Once the human decides, the resolution propagates:

1. The decision is appended to `brief.md` as a "Human-resolved decision" section — so downstream agents see it as brief content, not as architecture metadata.
2. The Code Writer implements the specified behavior.
3. The Story Author writes stories for that behavior.
4. The Accessibility Auditor validates ARIA semantics for that behavior.
5. The Visual Reviewer's acceptable-deviations list includes any visual tradeoffs the human accepted.

One decision, one place, consistent everywhere. No agent independently guesses after the human has spoken.

---

## What auto-approves

The Architect marks sections `HIGH` when:

- Figma data was unambiguous
- Spec data (Anova or equivalent) agreed with Figma bound variables
- Only one reasonable approach exists
- The `component-rules.md` rules are specific enough to determine the approach

These sections are available to browse (option 1 above) but don't block.

---

## What does NOT auto-approve (always surfaces)

Regardless of confidence, these always surface:

- DS-divergence decisions (build custom vs. use DS primitive)
- Any Figma data gap
- Any accessibility tradeoff
- Any motion or animation decision
- Any case where multiple valid approaches exist

These are structurally the kind of decision that benefits from human judgment even when the agent thinks it knows the answer.

---

## Why the gate exists

The difference between "correct" and "excellent" is the question never asked. An agent that confidently picks one side of a Figma-vs-spec conflict without surfacing it produces output that looks correct but isn't trustworthy.

The gate is the structural place for the question to happen. Not a fallback for when automation fails — a design choice about where human judgment produces the most leverage.

---

## What the gate is not

- **Not a review step.** The Visual Reviewer and Accessibility Auditor are separate.
- **Not a final approval.** The pipeline continues after the gate. More gates may surface downstream (e.g., motion spec gate).
- **Not optional.** A pipeline that silently skips the gate is a pipeline that silently guesses.
