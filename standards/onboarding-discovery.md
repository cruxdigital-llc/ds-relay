# Onboarding Discovery Protocol

How the `adapter-onboarder` auto-detects what it can from the inputs `/relay-ds:onboard-adapter` gathers. This doc is the contract the onboarder implements, so the human knows what's being attempted (and why some things won't succeed).

---

## Tokens source — supported formats

Given `--tokens <path-or-url>`, the onboarder tries in order:

### 1. CSS with custom properties

**Trigger:** `.css` extension, or URL returns `text/css`, or content starts with CSS rules containing `--[a-z][a-z0-9-]*:`.

**What's extracted:**
- Every custom property name → grouped by leading segment(s)
- One representative example per category
- Probable categories (color / space / font / radius / shadow / border / duration) from segment keywords

**What's inferred:**
- **Prefix convention** — bare (`--color-*`) or namespaced (`--<ds>-color-*`)
- **Forbidden-prefix list** — the *other* form than what was detected, flagged for Quality Gate hard-fails

**Confidence:** HIGH if ≥4 categories detected; MEDIUM if 1-3; LOW otherwise.

### 2. JSON in W3C Design Tokens format

**Trigger:** `.json` extension, structure contains `$type` / `$value` keys at leaves.

**What's extracted:**
- Token paths (e.g., `color.surface.primary`)
- Resolved values (for humans to reference; not used by agents at runtime)

**What's inferred:**
- Custom-property prefix convention — usually by flattening paths (e.g., `color.surface.primary` → `--color-surface-primary`)

**Confidence:** HIGH if structure is canonical W3C; MEDIUM if structure is W3C-like but non-standard keys appear.

### 3. npm package

**Trigger:** input looks like `@org/pkg` or `pkg` (no URL scheme, no file extension).

**Discovery sequence:**
- Try `<pkg>/dist/tokens.css` → parse as CSS
- Try `<pkg>/dist/tokens.json` → parse as W3C JSON
- Try `<pkg>/index.css` → parse as CSS
- Try `<pkg>/dist/index.css` → parse as CSS

**If all fail:** record the attempts in `onboarding-report.md`, write `tokens.md` as a stub.

**Confidence:** as per the format that succeeded; LOW if the package exists but none of the standard paths contained tokens.

### 4. Unrecognized

If the format doesn't match any of the above, record in `onboarding-report.md` with the attempt details. Do NOT try to parse unknown formats heuristically — the risk of fabricating prefixes from a non-tokens file is higher than the value of a half-guess.

---

## Components source — supported formats

Given `--components <source>`, the onboarder tries:

### 1. Storybook URL

**Trigger:** URL with `/index.json` reachable OR `/stories.json` reachable OR URL title contains "Storybook".

**What's extracted:**
- Full list of stories → grouped by component (story titles usually follow `ComponentName/VariantName`)
- Unique component names

**Gaps that remain:**
- Composition rules (standalone vs. embedded) — not in story metadata; flagged `[CONFIRM]` per component
- What the DS does NOT provide — never in story metadata; flagged `[NEEDS_INPUT]`

**Confidence:** HIGH for component names; LOW for composition/gaps (those are always human-filled).

### 2. npm package

**Trigger:** same pattern as tokens — `@org/pkg` or `pkg`.

**Discovery:**
- Read the package's `exports` map from `package.json`
- Extract names that look like components (TitleCase, exported from identifiable sub-paths)

**Confidence:** MEDIUM — exports include utilities, not just components; some filtering is heuristic.

### 3. GitHub repo URL

**Trigger:** `github.com/<org>/<repo>` URL.

**Discovery:**
- WebFetch repo README
- Try to extract a components list from the README or a linked docs URL

**Confidence:** LOW — README parsing is noisy.

### 4. Not provided

`components.md` becomes a structured stub with pointed questions. The agent does not guess.

---

## MCP config

Given `--mcp <command>`:

- Split on whitespace → first token is `command`, rest is `args`
- Default server name: `<adapter-name>-tokens`. If the command references components explicitly, also add `<adapter-name>-components`
- Default `env: {}`
- Description auto-filled with a note about what the server provides

If not provided: `mcp.json` is a stub with a `[NEEDS_INPUT]` comment.

---

## Voice guide

Given `--voice <url-or-path>`:

- Store as a reference link in `editorial-voice.md`
- Do NOT auto-parse. Voice guides are prose-heavy, full of examples with context, and prone to auto-extraction producing plausible-but-wrong rules.

The onboarder's job here is to make the voice guide easy to find when the human fills in the stub — not to fill in the stub itself.

---

## What the onboarder NEVER does

- Guess at prefixes when the tokens source is unreachable or unrecognized
- Fill editorial voice content from any source
- Fill manual-check items from any source
- Assume composition rules (standalone / embedded / gaps) without explicit data
- Fabricate forbidden-prefix lists without a detected prefix to contrast against
- Write adapter files that don't have at least one confidence-rated section in `onboarding-report.md`

---

## Extending discovery (future)

As more token formats and component registries appear, add detection branches here. Each branch follows the same shape:

- **Trigger:** how to recognize the format
- **What's extracted:** concrete data that goes into adapter files
- **What's inferred:** derived data with a confidence rating
- **Confidence:** HIGH / MEDIUM / LOW rubric
- **Failure mode:** what happens when the source is partial or unreachable

Keep detection branches small and specific. Generic heuristics invite fabrication.
