# Editorial Voice — <Your DS Name>

The baseline (applies to all adapters): sentence case on all user-facing strings — labels, buttons, placeholder text, dialog titles, descriptions, story names. Proper nouns and acronyms keep their native casing.

Document voice rules that go beyond the baseline here.

## Case exceptions

Any words your DS's voice guide capitalizes that normally wouldn't be (e.g., product names, internal brand terms).

## Required phrasings

Examples:
- "Mark as read" (not "Toggle read state")
- "Save changes" (not "Save")

Rules that say "prefer X over Y" — LLMs tend to use Y by default, so listing X explicitly prevents drift.

## Disallowed words

Words the voice guide bans (jargon, slang, outdated terms).

## Pluralization

How your DS handles counts. E.g.,
- Always use numerals for counts (`3 items`, not `three items`)
- Singular form at 0 or 1 (`0 items`, `1 item`)

## Tone

One or two sentences describing the tone — e.g., "direct and active. Avoid passive constructions. No hedging ('might,' 'consider,' 'perhaps') in action prompts."

## Applied to

Story names, button labels, form placeholder text, aria-labels, error messages, empty states. Agents check each string category against these rules before emitting the component.
