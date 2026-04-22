# Test-Target Repo Convention

The pipeline does not build into itself. Generated components land in a **separate target repo** — a React + TypeScript + Storybook project where the output can actually compile, run, and be screenshot-tested.

This doc defines what a valid target repo looks like and how the orchestrator discovers it.

---

## Why a separate target repo

Three reasons:

1. **Component code needs a real host.** A generated `<ComponentName>.tsx` imports from `react`, `@floating-ui/react`, design-system tokens, etc. Those need to resolve. The target is where `package.json` lives.
2. **Storybook needs to render.** The Visual Reviewer screenshots stories. That requires a running Storybook — which needs to be wired into an actual project.
3. **The pipeline is the editor, not the editor's substrate.** Mixing Relay DS pipeline code with the code it produces means changes to one accidentally affect the other. Separation is hygiene.

---

## Minimum valid target repo

A target repo must have:

```
<target-repo>/
├── package.json                  # with react, react-dom, typescript, storybook, @floating-ui/react
├── tsconfig.json                 # strict mode recommended
├── .storybook/                   # Storybook config directory
│   ├── main.ts
│   └── preview.ts
├── src/
│   └── components/               # where generated components land
└── <DS adapter's token CSS/JS>   # tokens must be importable/applied at runtime
```

Reasonable deps baseline:

```json
{
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "@floating-ui/react": "^0.26.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@storybook/react-vite": "^8.0.0",
    "@storybook/test": "^8.0.0",
    "@storybook/addon-a11y": "^8.0.0",
    "eslint": "^8.0.0",
    "eslint-plugin-jsx-a11y": "^6.0.0",
    "prettier": "^3.0.0",
    "axe-core": "^4.0.0"
  }
}
```

The exact versions are flexible; the *shape* is not.

---

## How the orchestrator discovers the target repo

The target repo is a path. The orchestrator obtains it one of three ways, in order:

1. **Explicit in the invocation.** If the user's `/relay-ds:build-component` message includes a path (e.g., *"build the Button from … into ~/sds-target"*), parse that.
2. **Session memory.** If a previous command in the current conversation established a target and the user hasn't said otherwise, reuse it.
3. **Ask.** If neither of the above applies, the orchestrator asks: *"Which repo should the generated component land in? (absolute path)"*

There is no environment variable to set. There is no "current working directory" to inherit from. Slash commands run inside Claude Code, not a shell.

---

## Target validation (before anything else runs)

Once a candidate path is resolved, the orchestrator validates it before dispatching any agent:

- `<target>/package.json` exists and declares `react` as a dependency
- `<target>/.storybook/` exists
- `<target>/src/components/` exists (or can be created)
- No existing `<target>/src/components/<ComponentName>/` directory for the component being built (refuse to overwrite)

If any check fails: halt with a specific error and a suggested fix. Do NOT silently fall back to writing somewhere else — the cost of accidentally writing components into the wrong place is higher than the cost of asking the user to confirm.

---

## Starter target for teams without one

If a team doesn't have a target repo yet, a minimal starter:

```
npx create-vite@latest my-ds-target --template react-ts
cd my-ds-target
npx storybook@latest init
npm install @floating-ui/react axe-core
npm install -D eslint-plugin-jsx-a11y prettier
```

Then install the DS's token package or paste the token CSS into `src/index.css`. When running `/relay-ds:build-component`, provide `my-ds-target`'s absolute path when asked (or include it in the command message).

A future `/relay-ds:init-target` command could automate this scaffold; not in v0.1.0 scope.

---

## What the target repo must NOT do

- **Must not have an existing `src/components/<ComponentName>/` directory** for the component being built. The orchestrator refuses to overwrite existing components (safety against destroying in-progress work). If the component already exists, the user picks a different output subpath in conversation or removes the existing directory.
- **Must not be a monorepo root** when pointed at the root. For monorepos, point at the specific workspace where the component should land.
- **Must not lack a Storybook setup** if Phase 3 agents (Visual Reviewer, Story Author interaction tests) will run. Phase 1/2 can operate without Storybook running (Quality Gate just runs tsc + lint + prettier), but the full pipeline needs it.
