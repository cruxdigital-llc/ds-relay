---
description: Scaffold a new design-system adapter with auto-detection from tokens/components/MCP sources. Fills what it can, emits structured questions for what it can't.
argument-hint: <adapter-name> [--tokens <path>] [--components <source>] [--mcp <command>] [--voice <url>] [--from-package <pkg>]
---

# /relay-ds:onboard-adapter

Walk a team through creating a new DS adapter. Auto-fills everything detectable; leaves structured, pointed questions for the rest.

## Usage

```
/relay-ds:onboard-adapter <adapter-name>
/relay-ds:onboard-adapter <adapter-name> --tokens ./design-tokens.css
/relay-ds:onboard-adapter <adapter-name> --from-package @your-co/design-system --mcp "npx -y @your-co/ds-mcp"
/relay-ds:onboard-adapter <adapter-name> --tokens https://example.com/tokens.json --components https://storybook.example.com --voice https://confluence.example.com/voice
```

### Required

- `<adapter-name>` — directory name under `adapters/`. kebab-case. Cannot already exist.

### Optional (at least one source recommended)

- `--tokens <path-or-url>` — tokens source. Supported:
  - CSS file with custom properties (`--color-primary: ...`)
  - JSON file in W3C Design Tokens format
  - npm package name (look for `dist/tokens.css`, `dist/tokens.json`, `index.css`)
  - URL to any of the above
- `--components <source>` — component list source. Supported:
  - Storybook URL (fetches `stories.json` / `index.json`)
  - npm package name (reads exports)
  - GitHub repo URL (reads structure)
- `--mcp <command>` — the DS's MCP server command, if one exists. Wired into the adapter's `mcp.json`
- `--voice <url-or-path>` — voice guide reference. Linked in `editorial-voice.md`; not auto-parsed (voice is a judgment call)
- `--from-package <npm-package>` — shortcut: use this npm package as both the `--tokens` and `--components` source if not otherwise specified

## Orchestrator flow

Follow this precisely. The onboarder produces files; you (the orchestrator) validate and report.

### 1. Validate inputs

- If `adapters/<adapter-name>/` already exists, **refuse** — do not overwrite. Ask the user to pick a different name or delete the existing directory.
- If no sources were provided (no `--tokens`, `--components`, `--mcp`, `--voice`, `--from-package`), confirm with the user — they can still proceed and fill everything by hand, but this is unusual.
- Normalize `--from-package` into the other flags if they weren't explicitly set.

### 2. Ask clarifying questions (interactive)

Before dispatching the subagent, use **AskUserQuestion** to fill the most important gaps. Questions to ask (skip any already answered via flags):

- **DS name (display)** — e.g., "Acme Design System" — used in docs
- **Token-prefix style** — if `--tokens` wasn't provided, ask: bare (`--color-*`) / namespaced (`--acme-color-*`) / something else
- **Component library distribution** — if `--components` wasn't provided: Storybook URL / npm package / GitHub repo / "I'll fill this in later"
- **Editorial voice baseline** — title case, sentence case, or custom convention? Any voice guide URL?

Keep the question set small (3-4 max). The point is to enable auto-detection, not to conduct an interview.

### 3. Scaffold

- `cp -r adapters/template adapters/<adapter-name>`
- Delete `adapters/template/`-specific placeholder language that no longer applies (the onboarder handles this)

### 4. Dispatch `adapter-onboarder` subagent

Pass all inputs — the flags, the answers to interactive questions, the adapter directory path — to the subagent. The subagent does the deterministic work:

- Parse the tokens source
- Populate `tokens.md` with real prefixes and a proposed forbidden-prefix list
- Populate `mcp.json` with real server config
- Fetch component list if possible, populate `components.md` with real entries
- Leave `editorial-voice.md` and `manual-checks.md` as pointed-prompt stubs
- Write `adapter.md` with overview + source links
- Emit `adapters/<adapter-name>/onboarding-report.md` with confidence per section

### 5. Review with user

Read `onboarding-report.md`. Report to the user:

- What was filled automatically (with confidence)
- What still needs manual input (specific files, specific sections)
- Any detection warnings (e.g., "the tokens source had both `--color-*` and `--acme-color-*` — which is canonical?")
- Suggested next step: either fill remaining sections now, or run `/relay-ds:build-component` against a small test component to see what breaks

### 6. Offer to proceed

Ask whether the user wants to:
- Fill the remaining `[NEEDS_INPUT]` sections now (you walk them through each)
- Stop here and let them fill manually
- Run a test build to stress-test the adapter (pick a simple component like a button variant)

## Failure modes

- **Adapter already exists:** refuse, do not overwrite.
- **Tokens source unreachable** (404, file not found): report, continue with other sources, leave `tokens.md` as a stub with `[NEEDS_INPUT]` markers.
- **Tokens source format unrecognized:** report the format, leave `tokens.md` as a stub with a note about the attempted format.
- **Component source unreachable:** report, leave `components.md` as a stub.
- **Everything fails:** you still have a valid (empty) adapter directory and an onboarding-report.md explaining what went wrong. User can fix inputs and re-run with `--force` (not implemented in v0.1 — for now, delete the adapter and retry).

## What the onboarder does NOT do

- **Does not fill editorial-voice.md with specifics.** Voice is a judgment call. The onboarder populates structure and pointed questions; humans fill content.
- **Does not fill manual-checks.md with specifics.** Same reason.
- **Does not validate the adapter against a real component.** That's what `/relay-ds:build-component` against a small test component is for — the onboarder's output is an untested starting point.
- **Does not fabricate detection.** If something can't be detected, the file gets a `[NEEDS_INPUT]` marker with a specific question, not a plausible guess.
