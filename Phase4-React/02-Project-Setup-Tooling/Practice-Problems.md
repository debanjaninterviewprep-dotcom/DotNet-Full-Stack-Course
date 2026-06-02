# Topic 2: Project Setup & Tooling — Practice Problems

> Five progressive problems. By problem 5 you will have configured almost every tool a real React team uses. Verify each "Expected output" before moving on.

---

## Problem 1 — Scaffold Vite + React + TS with Path Aliases (Easy)

**Concept tag:** `vite`, `typescript`, `path-aliases`, `HMR`

### Requirements

1. Scaffold a new project with the SWC + TypeScript template:
   ```bash
   pnpm create vite@latest topic2-app -- --template react-swc-ts
   cd topic2-app
   pnpm install
   ```
2. Configure the alias `@` → `src/` in **both** `vite.config.ts` and `tsconfig.app.json`.
3. Create `src/components/Greeting.tsx` that takes a `name: string` prop and renders `<h1>Hello, {name}!</h1>`.
4. Import it from `App.tsx` using the alias: `import { Greeting } from '@/components/Greeting';`.
5. Run `pnpm dev`, change the text in `Greeting.tsx`, and confirm the browser updates **without a full page reload** (HMR).

### Starter Snippets

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@': path.resolve(__dirname, 'src') } },
});
```

```json
// tsconfig.app.json (excerpt)
"compilerOptions": {
  "baseUrl": ".",
  "paths": { "@/*": ["src/*"] }
}
```

### Expected Output

- `pnpm dev` prints `Local: http://localhost:5173/`.
- Browser DevTools → Network shows the changed module fetched as a `200` (not the whole page).
- VS Code resolves `@/components/Greeting` without a red squiggle.

---

## Problem 2 — Quality Gates: ESLint Flat Config + Prettier + Husky + commitlint (Easy-Medium)

**Concept tag:** `eslint-flat-config`, `prettier`, `husky`, `lint-staged`, `commitlint`

### Requirements

1. Install dev deps:
   ```bash
   pnpm add -D eslint @eslint/js typescript-eslint eslint-plugin-react \
     eslint-plugin-react-hooks eslint-plugin-jsx-a11y eslint-config-prettier \
     prettier husky lint-staged @commitlint/cli @commitlint/config-conventional
   ```
2. Create `eslint.config.js` (flat config) with `js.configs.recommended`, the typescript-eslint recommended typed config, react, react-hooks, jsx-a11y, and `prettier` last.
3. Add `.prettierrc` enforcing single quotes, semicolons, `printWidth: 100`, `trailingComma: "all"`.
4. Initialize Husky:
   ```bash
   pnpm exec husky init
   ```
5. Make `.husky/pre-commit` run `pnpm exec lint-staged`.
6. Make `.husky/commit-msg` run `pnpm exec commitlint --edit $1`.
7. Add `lint-staged` config in `package.json`:
   ```json
   "lint-staged": {
     "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
     "*.{json,md,css}": ["prettier --write"]
   }
   ```
8. Add `commitlint.config.js` extending `@commitlint/config-conventional`.

### Verification Steps

- Introduce an unused variable in a component → `pnpm lint` must fail with `no-unused-vars`.
- Try to commit with message `wip` → commit must be **rejected**.
- Commit with `feat: add greeting component` → must succeed, and lint-staged must auto-format the staged files.

### Expected Output

```
✔ Preparing lint-staged...
✔ Running tasks for staged files...
✔ Applying modifications from tasks...
[main 1a2b3c4] feat: add greeting component
```

---

## Problem 3 — Typed Env Vars, Dev API Proxy, Multi-Mode Builds (Medium)

**Concept tag:** `import.meta.env`, `vite-modes`, `server.proxy`, `vite-env.d.ts`

### Requirements

1. Create three env files:
   ```env
   # .env.development
   VITE_API_BASE_URL=/api
   VITE_FEATURE_BETA=true

   # .env.staging
   VITE_API_BASE_URL=https://staging.api.example.com
   VITE_FEATURE_BETA=true

   # .env.production
   VITE_API_BASE_URL=https://api.example.com
   VITE_FEATURE_BETA=false
   ```
2. In `src/vite-env.d.ts`, type `ImportMetaEnv` so `VITE_FEATURE_BETA` is `'true' | 'false'`.
3. In `vite.config.ts`, proxy `/api/*` to `http://localhost:5000` in dev only.
4. Add scripts:
   ```json
   "scripts": {
     "dev": "vite",
     "build:staging": "vite build --mode staging",
     "build:prod":    "vite build --mode production"
   }
   ```
5. Stand up a quick stub backend so the proxy resolves:
   ```bash
   pnpm dlx json-server db.json --port 5000
   ```
   with `db.json`:
   ```json
   { "users": [{ "id": 1, "name": "Ada" }] }
   ```
6. From `App.tsx`, fetch `${import.meta.env.VITE_API_BASE_URL}/users` and render the list.

### Verification Steps

- `pnpm dev` → fetch goes to `/api/users` (proxied to `:5000`) — no CORS error.
- `pnpm build:staging` → in the built `dist/assets/*.js`, the staging URL is inlined.
- `pnpm build:prod` → the production URL is inlined.
- Removing the `VITE_` prefix from a variable → `import.meta.env` returns `undefined`.

### Expected Output

```
> vite build --mode staging

vite v5.x building for staging...
✓ 38 modules transformed.
dist/index.html                   0.46 kB
dist/assets/index-DEf12abc.js   142.35 kB │ gzip: 45.8 kB
✓ built in 1.21s
```

---

## Problem 4 — Migrate a CRA Project to Vite (Medium-Hard)

**Concept tag:** `cra-to-vite`, `migration`, `bundle-size`

You are given a small CRA app with `react-scripts`, a `proxy` field in `package.json`, and `REACT_APP_*` env vars.

### Migration Checklist

1. Scaffold a sibling Vite project:
   ```bash
   pnpm create vite@latest cra-migrated -- --template react-ts
   ```
2. Copy `src/` and `public/` from the CRA project.
3. Move `public/index.html` → project root; replace `%PUBLIC_URL%/favicon.ico` with `/favicon.ico`; add:
   ```html
   <script type="module" src="/src/main.tsx"></script>
   ```
4. Rename env vars: `REACT_APP_API_URL` → `VITE_API_URL`. Update every reference: `process.env.REACT_APP_API_URL` → `import.meta.env.VITE_API_URL`.
5. Move the `proxy` value from `package.json` into `vite.config.ts`:
   ```ts
   server: { proxy: { '/api': 'http://localhost:4000' } }
   ```
6. Replace `import { ReactComponent as Logo } from './logo.svg'` with `import Logo from './logo.svg?react'` and install `vite-plugin-svgr`.
7. Replace Jest with Vitest:
   ```bash
   pnpm add -D vitest @testing-library/react @testing-library/jest-dom jsdom
   ```
   Replace `jest.fn()` with `vi.fn()`.
8. Remove `react-scripts`, `react-app-rewired`, and any `@craco/*` packages.
9. Run `pnpm build` and `pnpm preview`.

### Verification — Record Both

| Metric              | CRA           | Vite          |
| ------------------- | ------------- | ------------- |
| Cold dev-server start | _measure_   | _measure_     |
| `dist` JS size (gzipped) | _measure_ | _measure_     |
| `pnpm build` time   | _measure_     | _measure_     |

You should see roughly **5-10× faster** dev start and **20-40 % smaller** bundles.

### Expected Output

`pnpm preview` serves the migrated app at `http://localhost:4173/` with identical visual output to the CRA version, all routes working, and no `process.env` references in the client bundle.

---

## Problem 5 — pnpm + Turborepo Monorepo with a Shared UI Package (Hard)

**Concept tag:** `monorepo`, `pnpm-workspaces`, `turborepo`, `shared-tsconfig`, `ci`

### Target Structure

```
my-monorepo/
├── apps/
│   └── web/                # Vite + React + TS app
├── packages/
│   ├── ui/                 # shared component library (Button, Card)
│   └── tsconfig/           # shared tsconfig presets
├── pnpm-workspace.yaml
├── turbo.json
├── package.json            # private root
└── .github/workflows/ci.yml
```

### Requirements

1. **Workspace bootstrap**:
   ```yaml
   # pnpm-workspace.yaml
   packages:
     - 'apps/*'
     - 'packages/*'
   ```
   Root `package.json`:
   ```json
   {
     "name": "my-monorepo",
     "private": true,
     "packageManager": "pnpm@9.0.0",
     "scripts": {
       "build": "turbo run build",
       "lint":  "turbo run lint",
       "dev":   "turbo run dev --parallel"
     },
     "devDependencies": { "turbo": "^2.0.0", "typescript": "^5.5.0" }
   }
   ```

2. **`packages/tsconfig`** exports `base.json` and `react-lib.json`. Other packages do `"extends": "@repo/tsconfig/react-lib.json"`.

3. **`packages/ui`** (`@repo/ui`):
   - Exposes `Button` and `Card` components.
   - `package.json` `exports` field points to source `./src/index.ts` (no build step needed thanks to Vite's bundler resolution).
   - Lists `react` as a `peerDependency`.

4. **`apps/web`** (`@repo/web`):
   - A Vite + React + TS app.
   - Depends on `@repo/ui` via `"@repo/ui": "workspace:*"`.
   - Imports `import { Button } from '@repo/ui'` and renders it.

5. **`turbo.json`**:
   ```json
   {
     "$schema": "https://turbo.build/schema.json",
     "tasks": {
       "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
       "lint":  {},
       "dev":   { "cache": false, "persistent": true }
     }
   }
   ```

6. **CI** (`.github/workflows/ci.yml`):
   ```yaml
   name: CI
   on: [push, pull_request]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: pnpm/action-setup@v4
           with: { version: 9 }
         - uses: actions/setup-node@v4
           with: { node-version: 20, cache: 'pnpm' }
         - run: pnpm install --frozen-lockfile
         - run: pnpm lint
         - run: pnpm build
         - uses: actions/cache@v4
           with:
             path: .turbo
             key: turbo-${{ github.sha }}
             restore-keys: turbo-
   ```

### Verification Steps

- `pnpm install` from the root installs all workspaces.
- `pnpm dev` starts the `web` app; a change to `packages/ui/src/Button.tsx` HMR-reloads in the browser **without a manual rebuild** of `ui`.
- `pnpm build` builds `ui` first, then `web` (Turbo prints `cache miss` first run, `FULL TURBO` second run).
- Importing a non-exported member from `@repo/ui` is a TS error.

### Expected Output

```
• Packages in scope: @repo/ui, @repo/web
• Running build in 2 packages
@repo/ui:build:  ✓ built in 380ms
@repo/web:build: vite v5.x building for production...
@repo/web:build:  ✓ built in 1.92s

 Tasks:    2 successful, 2 total
Cached:    0 cached, 2 total
  Time:    2.4s
```

Re-run:

```
 Tasks:    2 successful, 2 total
Cached:    2 cached, 2 total
  Time:    180ms >>> FULL TURBO
```

---

## Submission Checklist

For each problem submit:

- [ ] Final `package.json` (scripts + devDependencies)
- [ ] Config files touched (`vite.config.ts`, `tsconfig.*.json`, `eslint.config.js`, `.prettierrc`, `turbo.json`, etc.)
- [ ] Screenshot or terminal log demonstrating the **Expected Output**
- [ ] One-paragraph reflection on what surprised you (especially in problems 4 and 5)
