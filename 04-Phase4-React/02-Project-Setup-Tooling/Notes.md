# Topic 2: Project Setup & Tooling

> Modern React no longer ships with one blessed scaffold. The ecosystem has converged on **Vite** for SPAs and component libraries, **Next.js / Remix** for full-stack apps, and a pile of small tools (ESLint, Prettier, Husky, Vitest) that you compose yourself. This topic walks through every layer — from "why do we need a build tool at all?" to monorepos and CI.

---

## 1. Why a Build Tool?

Browsers cannot run what we write:

- **JSX** (`<App />`) is not valid JavaScript — it must be compiled to `React.createElement(...)` or the new `jsx-runtime`.
- **TypeScript** must be stripped of types.
- **ES modules** in `node_modules` are sometimes CommonJS; the browser only understands ESM.
- **Path aliases** like `@/components/Button` are not resolvable by the browser.
- **CSS Modules, SVG-as-component, image imports** all need a loader.
- **Tree-shaking, minification, code-splitting, asset hashing** for production are not free.

A build tool (Vite, webpack, Parcel, esbuild, Rollup, Turbopack) handles all of this. It runs a **dev server** with Hot Module Replacement (HMR) and produces an optimized **production bundle**.

---

## 2. Choosing a Scaffold — Comparison

| Tool                 | Dev Engine        | Prod Bundler      | SSR/SSG | Routing      | Best For                                | Notes                                  |
| -------------------- | ----------------- | ----------------- | ------- | ------------ | --------------------------------------- | -------------------------------------- |
| **Vite**             | esbuild + native ESM | Rollup         | No (SPA)| Manual       | SPAs, component libs, dashboards        | Fastest cold start; current default    |
| **Create React App** | webpack           | webpack           | No      | Manual       | Legacy projects                         | **Deprecated** (Feb 2025) — do not start new projects |
| **Next.js**          | Turbopack/webpack | webpack/Turbopack | Yes (App Router) | File-based | Full-stack, SEO-heavy, e-commerce | Recommended by React docs              |
| **Remix**            | esbuild           | esbuild           | Yes     | File-based   | Forms-heavy apps, progressive enhancement | Now part of React Router v7         |
| **Parcel**           | SWC               | SWC               | No      | Manual       | Zero-config experiments                 | Less plugin ecosystem than Vite        |

**Rule of thumb**

- Pure SPA (admin, internal tool, dashboard) → **Vite**.
- Public marketing/e-commerce site needing SEO/SSR → **Next.js**.
- Don't start anything new on **CRA**.

---

## 3. Vite Deep Dive

### 3.1 Installation & Templates

```bash
# Latest scaffolder; works with npm/pnpm/yarn/bun
npm create vite@latest my-app
pnpm create vite my-app
yarn create vite my-app
bun create vite my-app
```

Pick a template non-interactively:

```bash
npm create vite@latest my-app -- --template react-ts
```

Available React templates:

| Template          | Compiler | TS  | Notes                                           |
| ----------------- | -------- | --- | ----------------------------------------------- |
| `react`           | Babel    | No  | Plain JS                                        |
| `react-ts`        | Babel    | Yes | Default for most teams                          |
| `react-swc`       | **SWC**  | No  | ~20× faster than Babel for transforms           |
| `react-swc-ts`    | **SWC**  | Yes | Recommended for large TS codebases              |

### 3.2 How the Dev Server Works

1. Vite serves `index.html` directly — it is the entry point, not a generated artifact.
2. When the browser requests `main.tsx`, Vite **transpiles on demand** using esbuild and returns native ESM.
3. Bare imports (`import React from 'react'`) are pre-bundled once with esbuild into `node_modules/.vite/deps` (this is **dependency pre-bundling** / `optimizeDeps`).
4. **HMR** is delivered over a WebSocket; React Refresh preserves component state across edits.

This is why Vite's cold start is sub-second even on huge projects.

### 3.3 Production Build

`vite build` uses **Rollup** (not esbuild) to produce the final bundle — Rollup gives better tree-shaking and code-splitting. Output goes to `dist/`.

### 3.4 `vite.config.ts` Walkthrough

```ts
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react-swc';
import svgr from 'vite-plugin-svgr';
import path from 'node:path';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  return {
    plugins: [react(), svgr()],

    // Public base path. Use '/my-app/' when deploying to GitHub Pages subpath.
    base: '/',

    resolve: {
      alias: { '@': path.resolve(__dirname, 'src') },
    },

    server: {
      port: 5173,
      open: true,
      strictPort: true,
      proxy: {
        '/api': {
          target: env.VITE_API_PROXY ?? 'http://localhost:5000',
          changeOrigin: true,
          secure: false,
        },
      },
    },

    build: {
      outDir: 'dist',
      sourcemap: mode !== 'production',
      target: 'es2022',
      rollupOptions: {
        output: {
          manualChunks: {
            react: ['react', 'react-dom'],
            router: ['react-router-dom'],
          },
        },
      },
    },

    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
    },

    css: {
      modules: { localsConvention: 'camelCaseOnly' },
      devSourcemap: true,
    },
  };
});
```

---

## 4. Project Structure

```
my-app/
├── public/                # served as-is at site root
│   └── favicon.svg
├── src/
│   ├── assets/            # imported assets (hashed at build)
│   ├── components/
│   ├── pages/
│   ├── App.tsx
│   ├── main.tsx           # entry — calls createRoot
│   └── vite-env.d.ts      # ambient types for import.meta.env
├── index.html             # the HTML entry; Vite injects scripts
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── vite.config.ts
└── eslint.config.js
```

`index.html` contains the only `<script type="module" src="/src/main.tsx">` — Vite walks from there.

`main.tsx` (entry):

```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
```

---

## 5. Public vs Imported Assets

| Use case                           | Put it in        | Reference                              |
| ---------------------------------- | ---------------- | -------------------------------------- |
| File needs a stable URL (`robots.txt`, `og-image.png`) | `public/`        | `/og-image.png`                        |
| Asset that should be **hashed & tree-shaken** | `src/assets/` | `import logo from './assets/logo.svg'` |
| SVG as a React component           | anywhere in `src/` | `import { ReactComponent as Icon } from './icon.svg?react'` (with `vite-plugin-svgr`) |

Rule: anything in `public/` is copied verbatim — no hashing, no optimization, no transform. Use it sparingly.

---

## 6. Environment Variables

Vite reads `.env*` files at build time. **Only variables prefixed with `VITE_`** are exposed to client code.

| File                | Loaded when                          | Commit?      |
| ------------------- | ------------------------------------ | ------------ |
| `.env`              | always                               | yes          |
| `.env.local`        | always (overrides `.env`)            | **no** (gitignore) |
| `.env.development`  | `vite` / `vite --mode development`   | yes          |
| `.env.production`   | `vite build`                         | yes          |
| `.env.staging`      | `vite build --mode staging`          | yes          |

```env
# .env
VITE_API_BASE_URL=https://api.example.com
VITE_FEATURE_FLAG_BETA=true
SECRET_KEY=do-not-leak  # NOT exposed (no VITE_ prefix)
```

```ts
const base = import.meta.env.VITE_API_BASE_URL;
const isDev = import.meta.env.DEV;       // built-in boolean
const mode  = import.meta.env.MODE;      // 'development' | 'production' | ...
```

### Type-Safe Env (`src/vite-env.d.ts`)

```ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_FEATURE_FLAG_BETA: 'true' | 'false';
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

Now `import.meta.env.VITE_FOO` is fully autocompleted and typed.

---

## 7. TypeScript Configuration

Modern Vite scaffolds split tsconfig in three:

| File                  | Purpose                                                     |
| --------------------- | ----------------------------------------------------------- |
| `tsconfig.json`       | Root, references the other two. No `compilerOptions`.       |
| `tsconfig.app.json`   | Compiles `src/**` for the browser (`DOM` lib, `jsx: react-jsx`). |
| `tsconfig.node.json`  | Compiles `vite.config.ts`, `eslint.config.js` (Node lib).   |

```json
// tsconfig.app.json (key options)
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "resolveJsonModule": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
```

Key options:

- **`strict`** — enables all strict family flags. Always on for new code.
- **`jsx: "react-jsx"`** — modern automatic runtime; no need to `import React`.
- **`moduleResolution: "bundler"`** — matches how Vite/webpack actually resolve.
- **`isolatedModules`** — required because Vite transpiles file-by-file.
- **`skipLibCheck`** — skips checks of `.d.ts` in `node_modules`; speeds builds.

---

## 8. Path Aliases

Aliases must be configured in **two places** — the bundler (Vite) and the type-checker (TS).

```ts
// vite.config.ts
resolve: { alias: { '@': path.resolve(__dirname, 'src') } }
```

```json
// tsconfig.app.json
"baseUrl": ".",
"paths": { "@/*": ["src/*"] }
```

Now `import Button from '@/components/Button'` works in editor, build, and tests.

---

## 9. Package Managers

| Manager  | Lockfile           | Speed   | Disk Use | Monorepo                | Notes                                        |
| -------- | ------------------ | ------- | -------- | ----------------------- | -------------------------------------------- |
| **npm**  | `package-lock.json`| Medium  | Worst (flat) | Workspaces (basic)  | Default, ubiquitous                          |
| **pnpm** | `pnpm-lock.yaml`   | Fast    | Best (CAS, hard links) | Workspaces (best) | Strict — no phantom deps. Recommended.   |
| **yarn** | `yarn.lock`        | Fast    | Medium   | Workspaces (good)       | v1 vs Berry; PnP is divisive                 |
| **bun**  | `bun.lockb`        | Fastest | Good     | Workspaces (newer)      | Also a runtime; ecosystem still maturing     |

**Pick once and stick to it.** Mixing managers produces lockfile churn and broken installs. Add `"packageManager": "pnpm@9.0.0"` in `package.json` and use **Corepack** (`corepack enable`) to enforce the version.

---

## 10. `package.json` Scripts Pattern

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview --port 4173",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write \"**/*.{ts,tsx,js,json,md,css}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,json,md,css}\"",
    "type-check": "tsc -b --noEmit",
    "test": "vitest",
    "test:ci": "vitest run --coverage",
    "test:e2e": "playwright test",
    "prepare": "husky"
  }
}
```

`tsc -b && vite build` runs the type-checker first so `vite build` only fails on real bundling errors.

---

## 11. ESLint — Flat Config (v9+)

ESLint v9 dropped `.eslintrc.*` in favor of `eslint.config.js` (flat config).

```js
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import jsxA11y from 'eslint-plugin-jsx-a11y';
import importPlugin from 'eslint-plugin-import';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  { ignores: ['dist', 'node_modules', 'coverage'] },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parserOptions: { project: ['./tsconfig.app.json', './tsconfig.node.json'] },
    },
    plugins: {
      react,
      'react-hooks': reactHooks,
      'jsx-a11y': jsxA11y,
      import: importPlugin,
    },
    settings: { react: { version: 'detect' } },
    rules: {
      ...react.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      'react/react-in-jsx-scope': 'off',
      'react/prop-types': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  },
  prettier, // must be LAST — disables stylistic rules that conflict with Prettier
);
```

---

## 12. Prettier

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
```

```
# .prettierignore
dist
coverage
pnpm-lock.yaml
```

Install `eslint-config-prettier` (above) so ESLint and Prettier never disagree on whitespace.

---

## 13. Editor Integration

```jsonc
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": { "source.fixAll.eslint": "explicit" },
  "typescript.tsdk": "node_modules/typescript/lib",
  "eslint.useFlatConfig": true
}
```

```jsonc
// .vscode/extensions.json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-playwright.playwright"
  ]
}
```

---

## 14. Git Hooks: Husky + lint-staged + commitlint

```bash
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
pnpm exec husky init
echo "pnpm exec lint-staged" > .husky/pre-commit
echo "pnpm exec commitlint --edit \$1" > .husky/commit-msg
```

```json
// package.json
"lint-staged": {
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{json,md,css}": ["prettier --write"]
}
```

```js
// commitlint.config.js
export default { extends: ['@commitlint/config-conventional'] };
```

This rejects commits like `wip stuff` and accepts `feat(auth): add JWT refresh`.

---

## 15. Conventional Commits & Changesets

- **Conventional Commits**: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`. Enables auto-versioning.
- **Changesets** (`@changesets/cli`): the canonical way to do versioning + changelogs in monorepos. Each PR adds a markdown file describing the change; release CI consumes them.

---

## 16. Bundle Analysis

```bash
pnpm add -D rollup-plugin-visualizer
```

```ts
// vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';
plugins: [react(), visualizer({ open: true, filename: 'dist/stats.html', gzipSize: true })],
```

Or zero-config: `npx vite-bundle-visualizer`.

Look for: duplicate React copies, full-icon libraries imported wholesale, moment.js (replace with `date-fns` or `dayjs`).

---

## 17. Code Splitting & Dynamic Imports

```tsx
const Settings = lazy(() => import('./pages/Settings'));

<Suspense fallback={<Spinner />}>
  <Settings />
</Suspense>
```

Vite/Rollup automatically emit a separate chunk for every dynamic `import()`. Combine with `manualChunks` to keep vendor libs cacheable across deployments.

---

## 18. CSS in Vite

| Style                 | Setup                                                              |
| --------------------- | ------------------------------------------------------------------ |
| Global CSS            | `import './index.css'` in `main.tsx`                               |
| CSS Modules           | Name file `Button.module.css`; `import styles from '...'`          |
| Sass / SCSS           | `pnpm add -D sass`; rename to `.scss`                              |
| PostCSS               | Add `postcss.config.js`; auto-detected                             |
| **Tailwind**          | `pnpm add -D tailwindcss postcss autoprefixer && npx tailwindcss init -p` |
| CSS-in-JS (Emotion)   | `pnpm add @emotion/react`; configure `jsxImportSource` in tsconfig |

---

## 19. SVG as Component

```bash
pnpm add -D vite-plugin-svgr
```

```ts
plugins: [react(), svgr()];
```

```tsx
import Logo from '@/assets/logo.svg?react';
<Logo width={32} fill="currentColor" />;
```

---

## 20. Dev API Proxy

When the React app runs at `:5173` and the API at `:5000`, the browser blocks cross-origin requests. Proxy them:

```ts
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:5000',
      changeOrigin: true,
      rewrite: (p) => p.replace(/^\/api/, ''),
    },
  },
}
```

Now `fetch('/api/users')` works from the browser without CORS configuration.

---

## 21. Mocking the Backend

- **MSW (Mock Service Worker)** — intercepts `fetch`/XHR via a Service Worker. Same handlers in dev, tests, and Storybook.
- **json-server** — `npx json-server db.json --port 5000`. Fastest way to stub REST.

---

## 22. Production Build Pitfalls

1. **Subpath deployment** (e.g. GitHub Pages at `/my-app/`) → set `base: '/my-app/'` in `vite.config.ts`.
2. **Asset paths in `public/`** are not rewritten — use root-relative URLs (`/foo.png`) or `import.meta.env.BASE_URL`.
3. **Asset hashing** is automatic for imported assets; don't disable unless behind an immutable CDN.
4. **`process.env`** does not exist in client code — use `import.meta.env`.
5. **Mixed CommonJS/ESM** packages may need `optimizeDeps.include`.

---

## 23. Deployment Targets

| Target                    | How                                                       |
| ------------------------- | --------------------------------------------------------- |
| **Vercel**                | `vercel` CLI; auto-detects Vite                           |
| **Netlify**               | Build command `pnpm build`, publish dir `dist`            |
| **GitHub Pages**          | `actions/deploy-pages` action; set `base: '/repo/'`       |
| **Azure Static Web Apps** | `Azure/static-web-apps-deploy@v1` GH Action               |
| **AWS S3 + CloudFront**   | `aws s3 sync dist/ s3://bucket --delete`                  |
| **Docker (Nginx)**        | Multi-stage build; copy `dist` into `nginx:alpine`        |

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

For SPAs, `nginx.conf` must rewrite unknown routes to `index.html`:

```nginx
location / { try_files $uri $uri/ /index.html; }
```

---

## 24. CI/CD with GitHub Actions

```yaml
# .github/workflows/ci.yml
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
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm type-check
      - run: pnpm test:ci
      - run: pnpm build
      - uses: actions/upload-artifact@v4
        with: { name: dist, path: dist }
```

`cache: 'pnpm'` reuses the pnpm store across runs and shaves minutes off CI.

---

## 25. Monorepos

Use a monorepo when you ship 2+ deployables that share code (e.g. `web`, `admin`, `mobile`, `ui-kit`).

| Tool          | Strength                                                |
| ------------- | ------------------------------------------------------- |
| **pnpm workspaces** | Native; just a `pnpm-workspace.yaml`              |
| **Turborepo** | Remote build cache, task pipelines, very fast           |
| **Nx**        | Heavier; great for large enterprise polyglot repos      |

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// turbo.json
{
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "lint":  {},
    "test":  { "dependsOn": ["^build"] }
  }
}
```

---

## 26. Migrating CRA → Vite

1. `pnpm create vite@latest my-app -- --template react-ts` (in a sibling folder).
2. Copy `src/` and `public/` over.
3. Move `index.html` from `public/` to project root; replace `%PUBLIC_URL%` with `/`; add `<script type="module" src="/src/main.tsx"></script>`.
4. Rename `REACT_APP_*` env vars to `VITE_*`. Replace `process.env.REACT_APP_X` with `import.meta.env.VITE_X`.
5. Replace `react-scripts` deps with `vite`, `@vitejs/plugin-react`, `vitest`.
6. Move CRA `proxy` field from `package.json` to `server.proxy` in `vite.config.ts`.
7. Convert Jest to Vitest (`vi` instead of `jest`, almost drop-in).
8. Verify `pnpm build` and check bundle size — typically 20-40 % smaller.

---

## 27. Common Pitfalls

| Pitfall                                                      | Fix                                                              |
| ------------------------------------------------------------ | ---------------------------------------------------------------- |
| `process.env.NODE_ENV is not defined` in client              | Use `import.meta.env.MODE` / `import.meta.env.DEV`               |
| Env var read as `undefined`                                  | Missing `VITE_` prefix or wrong `.env` for the active mode       |
| `Failed to resolve import "@/foo"`                           | Alias missing in `vite.config.ts` **or** `tsconfig.paths`        |
| JSX in `.js` files breaks                                    | Rename to `.jsx`/`.tsx`; Vite needs the right extension          |
| CSS from `node_modules` not applied                          | Import explicitly: `import 'package/dist/style.css'`             |
| Blank page after deploy to subpath                           | Set `base` in `vite.config.ts`                                   |
| Husky hook didn't run                                        | Run `pnpm prepare` once after install                            |

---

## 28. Performance Notes

- **Cold start**: Vite typically <1s for medium apps. If slower, audit `optimizeDeps.include` for CJS-only packages.
- **HMR**: Should be <50 ms. If sluggish, check for circular imports and giant barrel files (`index.ts` re-exporting hundreds of modules).
- **Build time**: Mostly TS checking. Use `tsc -b` (project references) and `skipLibCheck: true`.
- **Dependency pre-bundling**: One-time cost on first `pnpm dev`; cached in `node_modules/.vite`.

---

## Key Takeaways

- Use **Vite** for new SPAs; CRA is end-of-life.
- **TypeScript + strict mode + path aliases** from day one — retrofitting hurts.
- Lock down quality with **flat ESLint config + Prettier + Husky + commitlint**.
- Master **`import.meta.env`** and the `VITE_` prefix before deploying anywhere.
- Set **`base`** correctly when deploying to a subpath; this catches almost everyone once.
- Reach for a **monorepo** only when you have a real shared package — not "in case".
- CI should run **install → lint → type-check → test → build** on every PR.
