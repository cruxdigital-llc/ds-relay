# Test-Target Repo Convention

The pipeline does not build into itself. Generated components land in a **separate target repo** — a React + TypeScript + Storybook project where the output can actually compile, run, and be screenshot-tested.

This doc defines what a valid target repo looks like and how the pipeline connects to it.

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
│   └── components/               # where generated components land (default output path)
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

## How the pipeline connects to the target

Via `RELAY_DS_TARGET_REPO` env var, or the `--out` flag to `/relay-ds:build-component`.

Resolution order:

1. Explicit `--out <path>` flag on the command
2. `RELAY_DS_TARGET_REPO` env var — path to the target repo; components land at `<RELAY_DS_TARGET_REPO>/src/components/<ComponentName>/`
3. Fallback: `./out/<ComponentName>/` inside the current working directory. Not useful for real builds — the Visual Reviewer will fail to screenshot because nothing is installed.

The orchestrator validates target presence before dispatching Code Writer:

- `<target>/package.json` exists and contains `react` as a dependency
- `<target>/.storybook/` exists
- `<target>/src/components/` exists (or is creatable)

If any check fails: halt with a specific error and the fix step ("add a `.storybook/` directory per the template at …", etc.).

---

## Starter target for teams without one

If a team doesn't have a target repo yet, the simplest starter:

```
npx create-vite@latest my-ds-target --template react-ts
cd my-ds-target
npx storybook@latest init
npm install @floating-ui/react axe-core
npm install -D eslint-plugin-jsx-a11y prettier
```

Then install the DS's token package / paste the token CSS into `src/index.css`, and set `RELAY_DS_TARGET_REPO=$(pwd)` before running `/relay-ds:build-component`.

This starter isn't maintained as part of the plugin — it's just a known-good starting point. A future iteration of the plugin could add a `/relay-ds:init-target` command to automate it; not in v0.1.0 scope.

---

## What the target repo must NOT do

- **Must not have an existing `src/components/<ComponentName>/` directory** for the component being built. The pipeline refuses to overwrite existing components (safety against destroying in-progress work). If the component already exists, the user explicitly sets `--out` to a different path or removes the existing directory.
- **Must not be a monorepo root** when `RELAY_DS_TARGET_REPO` points to the root. If the repo is a monorepo, `RELAY_DS_TARGET_REPO` should point to the specific workspace where the component should land.
- **Must not lack a Storybook setup** if Phase 3 agents (Visual Reviewer, Story Author interaction tests) will run. Phase 1/2 can operate without Storybook running (Quality Gate just runs tsc + lint + prettier), but the full pipeline needs it.
