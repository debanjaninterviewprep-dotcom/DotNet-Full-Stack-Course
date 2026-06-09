# Topic 6 — Frontend Bootstrap & Architecture

> **Goal**: Scaffold the TaskFlow web client with Vite + React 18 + TypeScript, then design a folder layout, routing shell, design-system primitives, HTTP client, and tooling that scales from MVP to a production SaaS.

---

## 1. Why Vite + React + TypeScript

| Concern | Vite | CRA (deprecated) | Next.js |
|---|---|---|---|
| Dev server | esbuild — cold start in ms | Webpack — seconds | Turbopack/Webpack |
| HMR | Native ESM, near-instant | Slow on large trees | Fast, but heavier |
| Bundling | Rollup (prod) | Webpack | Webpack/Turbopack |
| SSR / RSC | Optional (vite-plugin-ssr / Remix) | None | First-class |
| Best for | SPA dashboards, BFF-backed apps | (legacy) | SEO/marketing/RSC apps |

TaskFlow is an **authenticated SaaS dashboard** — no SEO surface, no marketing pages, no streaming SSR requirement. SPA + Vite is the simplest production-grade choice and pairs cleanly with our ASP.NET Core API.

> ADR reminder (Topic 1, ADR-0003): React + Vite chosen over Next.js to keep the auth model (HttpOnly refresh cookie + in-memory access token) simple and avoid the RSC/route-handler split.

---

## 2. Scaffolding the project

```bash
npm create vite@latest taskflow-web -- --template react-ts
cd taskflow-web
npm install
npm run dev
```

Initial dependencies to add:

```bash
npm i react-router-dom axios zod @tanstack/react-query
npm i -D eslint prettier @types/node vite-tsconfig-paths
```

Optional but recommended:

```bash
npm i -D @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-prettier eslint-plugin-react-hooks eslint-plugin-react-refresh
npm i -D msw                       # API mocking in dev/tests (Topic 7)
npm i -D openapi-typescript-codegen # generate typed client from /swagger/v1/swagger.json
```

---

## 3. Project structure (feature-sliced)

```
taskflow-web/
├─ public/                          # static assets copied verbatim
├─ src/
│  ├─ app/                          # app shell (router, providers, layouts)
│  │  ├─ App.tsx
│  │  ├─ router.tsx
│  │  ├─ providers.tsx              # QueryClient, ThemeProvider, AuthProvider
│  │  └─ layouts/
│  │     ├─ PublicLayout.tsx        # for /login, /signup
│  │     └─ AppLayout.tsx           # sidebar + topbar for authenticated routes
│  ├─ features/                     # one folder per bounded UI capability
│  │  ├─ auth/
│  │  │  ├─ api.ts                  # mutations + queries
│  │  │  ├─ AuthProvider.tsx
│  │  │  ├─ LoginPage.tsx
│  │  │  └─ SignupPage.tsx
│  │  ├─ projects/
│  │  │  ├─ api.ts
│  │  │  ├─ ProjectsListPage.tsx
│  │  │  └─ ProjectDetailsPage.tsx
│  │  └─ tasks/
│  │     ├─ api.ts
│  │     ├─ TaskBoardPage.tsx
│  │     └─ components/TaskCard.tsx
│  ├─ shared/                       # cross-feature reusables
│  │  ├─ ui/                        # design system primitives
│  │  │  ├─ Button.tsx
│  │  │  ├─ Input.tsx
│  │  │  ├─ Card.tsx
│  │  │  └─ tokens.css
│  │  ├─ hooks/
│  │  ├─ lib/                       # pure utilities (date, classnames, errors)
│  │  └─ types/                     # global shared types
│  ├─ api/                          # generated + hand-written HTTP client
│  │  ├─ client.ts                  # axios instance + interceptors
│  │  ├─ generated/                 # openapi-typescript-codegen output (gitignored)
│  │  └─ schemas.ts                 # Zod schemas for runtime validation
│  ├─ config/
│  │  ├─ env.ts                     # validated import.meta.env shim
│  │  └─ runtime-config.ts          # /config.json fetched at boot
│  ├─ styles/
│  │  ├─ tokens.css                 # CSS variables (light + dark)
│  │  └─ reset.css
│  ├─ main.tsx                      # entry: ReactDOM.createRoot
│  └─ vite-env.d.ts
├─ index.html
├─ tsconfig.json
├─ tsconfig.node.json
├─ vite.config.ts
├─ .env.example
├─ .eslintrc.cjs
├─ .prettierrc
└─ package.json
```

**Slicing rules (enforced by ESLint boundaries):**
- `features/*` may import from `shared/*`, `api/*`, `config/*` — never from sibling features.
- `shared/*` may not import from `features/*` (would create a cycle).
- Cross-feature reuse → promote to `shared/`.

---

## 4. TypeScript config

`tsconfig.json` (key settings):

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    "baseUrl": ".",
    "paths": {
      "@app/*": ["src/app/*"],
      "@features/*": ["src/features/*"],
      "@shared/*": ["src/shared/*"],
      "@api/*": ["src/api/*"],
      "@config/*": ["src/config/*"]
    }
  },
  "include": ["src"]
}
```

Wire path aliases into Vite via `vite-tsconfig-paths`:

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  server: { port: 5173, strictPort: true },
});
```

> `noUncheckedIndexedAccess` is the single biggest payoff — `arr[0]` becomes `T | undefined`, forcing you to handle the empty case. Worth the friction.

---

## 5. Environment variables — build-time vs runtime

Vite exposes only variables prefixed with `VITE_` to the client. They are **inlined at build time** — changing them requires a rebuild.

**Build-time (`.env`, `.env.production`):**

```
VITE_API_BASE_URL=https://localhost:7104
VITE_APP_NAME=TaskFlow
VITE_RELEASE=local
```

**Validate them once at boot** so typos fail fast:

```ts
// src/config/env.ts
import { z } from 'zod';

const schema = z.object({
  VITE_API_BASE_URL: z.string().url(),
  VITE_APP_NAME: z.string().min(1),
  VITE_RELEASE: z.string().default('local'),
});

export const env = schema.parse(import.meta.env);
```

**Runtime config** (so the same Docker image deploys to dev/staging/prod without rebuild) — fetch `/config.json` before `ReactDOM.render`:

```ts
// src/config/runtime-config.ts
export type RuntimeConfig = { apiBaseUrl: string; featureFlags: Record<string, boolean> };
let cached: RuntimeConfig | null = null;
export async function loadRuntimeConfig(): Promise<RuntimeConfig> {
  if (cached) return cached;
  const res = await fetch('/config.json', { cache: 'no-store' });
  cached = await res.json();
  return cached!;
}
```

In `main.tsx`:

```ts
loadRuntimeConfig().then(cfg => {
  ReactDOM.createRoot(document.getElementById('root')!).render(
    <App config={cfg} />
  );
});
```

---

## 6. Routing shell with React Router v6/v7

```ts
// src/app/router.tsx
import { createBrowserRouter, redirect } from 'react-router-dom';
import { PublicLayout } from './layouts/PublicLayout';
import { AppLayout } from './layouts/AppLayout';

export const router = createBrowserRouter([
  {
    element: <PublicLayout />,
    children: [
      { path: '/login', lazy: () => import('@features/auth/LoginPage') },
      { path: '/signup', lazy: () => import('@features/auth/SignupPage') },
    ],
  },
  {
    element: <AppLayout />,
    loader: requireAuth,                                       // redirects to /login if no token
    children: [
      { path: '/', loader: () => redirect('/projects') },
      { path: '/projects', lazy: () => import('@features/projects/ProjectsListPage') },
      { path: '/projects/:id', lazy: () => import('@features/projects/ProjectDetailsPage') },
      { path: '/projects/:id/board', lazy: () => import('@features/tasks/TaskBoardPage') },
    ],
  },
  { path: '*', element: <NotFoundPage /> },
]);

async function requireAuth() {
  const token = getAccessToken();
  if (!token) throw redirect('/login');
  return null;
}
```

**Why `lazy` per route?** Each page becomes its own chunk — initial bundle stays small, navigation prefetches on hover (Router v7 `prefetch="intent"`).

---

## 7. HTTP client — axios with interceptors

```ts
// src/api/client.ts
import axios, { AxiosError } from 'axios';
import { env } from '@config/env';
import { getAccessToken, refreshAccessToken, clearAuth } from '@features/auth/token-store';

export const api = axios.create({
  baseURL: env.VITE_API_BASE_URL,
  timeout: 15_000,
  withCredentials: true,            // send refresh-cookie on /auth endpoints
});

// Request: inject Bearer
api.interceptors.request.use(cfg => {
  const token = getAccessToken();
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  cfg.headers['X-Correlation-Id'] = crypto.randomUUID();
  return cfg;
});

// Response: refresh on 401, queue concurrent retries
let refreshing: Promise<string | null> | null = null;
api.interceptors.response.use(
  r => r,
  async (err: AxiosError) => {
    const original = err.config!;
    if (err.response?.status !== 401 || (original as any)._retried) throw err;
    (original as any)._retried = true;
    refreshing ??= refreshAccessToken().finally(() => { refreshing = null; });
    const newToken = await refreshing;
    if (!newToken) { clearAuth(); throw err; }
    original.headers!.Authorization = `Bearer ${newToken}`;
    return api(original);
  }
);
```

**Why a single in-flight refresh?** If 5 components fire requests simultaneously and all see 401, you get one refresh round-trip — not five. The `refreshing` promise is shared.

> **Topic 7** dives deeper into TanStack Query + this client, including optimistic updates, MSW, and an in-memory token store with silent refresh.

---

## 8. Generating a typed API client from Swagger

After Topic 3 wired Swagger, regenerate the client whenever the API changes:

```bash
npx openapi-typescript-codegen \
  --input https://localhost:7104/swagger/v1/swagger.json \
  --output src/api/generated \
  --client axios \
  --useOptions \
  --useUnionTypes
```

Add as an npm script:

```json
"scripts": {
  "api:gen": "openapi-typescript-codegen --input https://localhost:7104/swagger/v1/swagger.json --output src/api/generated --client axios --useOptions --useUnionTypes"
}
```

`src/api/generated/` is **gitignored** — the source of truth is the OpenAPI document the API serves.

---

## 9. Design-system primitives

Skip Material/Chakra for the MVP — own a tiny token-driven primitive layer instead. Easier to theme, smaller bundles, no upgrade churn.

```css
/* src/styles/tokens.css */
:root {
  --color-bg: #ffffff;
  --color-fg: #0b1220;
  --color-muted: #5b6677;
  --color-primary: #2563eb;
  --color-danger: #dc2626;
  --radius-sm: 4px;
  --radius-md: 8px;
  --space-1: 4px; --space-2: 8px; --space-3: 12px; --space-4: 16px;
  --font-sans: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial;
}
[data-theme='dark'] {
  --color-bg: #0b1220;
  --color-fg: #e6eaf2;
  --color-muted: #97a2b6;
  --color-primary: #60a5fa;
}
```

```tsx
// src/shared/ui/Button.tsx
import { ButtonHTMLAttributes, forwardRef } from 'react';
import clsx from 'clsx';
import './Button.css';

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'ghost' | 'danger';
  size?: 'sm' | 'md';
  loading?: boolean;
};

export const Button = forwardRef<HTMLButtonElement, Props>(
  ({ variant = 'primary', size = 'md', loading, className, disabled, children, ...rest }, ref) => (
    <button
      ref={ref}
      className={clsx('tf-btn', `tf-btn--${variant}`, `tf-btn--${size}`, className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {loading ? <span className="tf-btn__spinner" aria-hidden /> : null}
      {children}
    </button>
  )
);
Button.displayName = 'Button';
```

Tokens-only theming means dark mode is a single `data-theme` attribute on `<html>` — no JS-in-CSS gymnastics.

---

## 10. Theme provider + dark mode

```tsx
// src/app/providers.tsx
import { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark' | 'system';
const ThemeCtx = createContext<{ theme: Theme; setTheme: (t: Theme) => void }>(null!);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() =>
    (localStorage.getItem('theme') as Theme) ?? 'system'
  );
  useEffect(() => {
    const resolved = theme === 'system'
      ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      : theme;
    document.documentElement.dataset.theme = resolved;
    localStorage.setItem('theme', theme);
  }, [theme]);
  return <ThemeCtx.Provider value={{ theme, setTheme }}>{children}</ThemeCtx.Provider>;
}
export const useTheme = () => useContext(ThemeCtx);
```

---

## 11. Error boundaries

A top-level boundary catches render-time crashes; a per-route boundary keeps one bad page from killing the shell.

```tsx
// src/shared/ui/ErrorBoundary.tsx
import { Component, ReactNode } from 'react';

export class ErrorBoundary extends Component<
  { fallback: (e: Error) => ReactNode; children: ReactNode },
  { error: Error | null }
> {
  state = { error: null as Error | null };
  static getDerivedStateFromError(error: Error) { return { error }; }
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('UI crash', error, info.componentStack);
    // Topic 11: ship to App Insights / Sentry
  }
  render() { return this.state.error ? this.props.fallback(this.state.error) : this.props.children; }
}
```

> Render errors only — does **not** catch async/event-handler errors. For those, surface via TanStack Query `onError` (Topic 7).

---

## 12. ESLint + Prettier

`.eslintrc.cjs`:

```js
module.exports = {
  root: true,
  env: { browser: true, es2022: true },
  parser: '@typescript-eslint/parser',
  parserOptions: { ecmaVersion: 2022, sourceType: 'module', project: './tsconfig.json' },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended-type-checked',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  plugins: ['react-refresh'],
  rules: {
    'react-refresh/only-export-components': 'warn',
    '@typescript-eslint/consistent-type-imports': 'error',
    '@typescript-eslint/no-floating-promises': 'error',
    'no-restricted-imports': ['error', { patterns: ['../../*'] }],   // force aliases
  },
};
```

`.prettierrc`:

```json
{ "singleQuote": true, "semi": true, "printWidth": 100, "trailingComma": "all" }
```

Add `npm scripts`: `lint`, `lint:fix`, `format`, `typecheck`.

---

## 13. Accessibility baselines

- Every interactive element is a real `<button>` or `<a>` (no `<div onClick>`).
- Labels via `<label htmlFor>` or `aria-label`. Visible focus rings (`:focus-visible`).
- Color-contrast ≥ 4.5:1 for body text.
- Live region for toast/error announcements: `<div role="status" aria-live="polite">`.
- Keyboard nav: Tab order must match visual order; Esc closes modals.
- Test with `eslint-plugin-jsx-a11y` and Lighthouse in CI (Topic 12).

---

## 14. Storybook (optional)

```bash
npx storybook@latest init --type vite
```

Use it to iterate on `shared/ui/*` primitives in isolation. Skip for features (slower payoff).

---

## 15. Bundle hygiene

- `npm run build` produces `dist/` with hashed chunks.
- Inspect with `npx vite-bundle-visualizer`.
- Targets: initial JS < 200 KB gz, route chunks < 80 KB gz.
- Defer non-critical libs (charts, rich-text editors) with `React.lazy` + `Suspense`.

---

## 16. Common pitfalls

| Pitfall | Fix |
|---|---|
| Importing `process.env.X` | Vite uses `import.meta.env` — and only `VITE_` prefix is exposed. |
| `Cannot find module '@features/...'` at build | Add `vite-tsconfig-paths` plugin, not just tsconfig `paths`. |
| Putting JWT in `localStorage` | XSS-readable. Use in-memory access token + HttpOnly refresh cookie (Topic 5/7). |
| Heavy `index.tsx` waterfall | Move providers into `providers.tsx`, lazy-load every route. |
| Tailwind/CSS-in-JS bloat | Tokens + plain CSS modules cover 90% of the design system at fraction of the size. |
| Forgetting `strictPort: true` | Vite silently grabs another port; auth cookies tied to `:5173` break. |

---

## 17. 10 Q&A

1. **Why Vite over CRA / Webpack?** ESM-native dev server (instant HMR), Rollup-based prod bundler, zero-config TS, smaller deps. CRA is unmaintained.
2. **Why prefix env vars with `VITE_`?** Vite refuses to expose any other variables to client code — prevents leaking server-side secrets.
3. **Build-time vs runtime config — when do I need runtime?** When the same artifact ships to multiple environments. Otherwise build-time is simpler and faster.
4. **Why feature folders instead of `components/` + `pages/`?** Co-locates code that changes together; deletion is one folder; cross-feature coupling is visible at the import line.
5. **Why path aliases (`@features/*`)?** Stable imports across moves, no `../../../` noise, ESLint can ban relative parent imports.
6. **Why `noUncheckedIndexedAccess`?** Forces `arr[i]` to be `T | undefined`. Catches a huge class of off-by-one bugs at compile time.
7. **Why a single shared in-flight refresh promise?** Prevents N parallel 401s from triggering N refresh round-trips and rotating the refresh token N times.
8. **Why `withCredentials: true`?** Required for the browser to send the HttpOnly refresh cookie on `/auth/*`. Pair with API CORS `AllowCredentials`.
9. **Why a token-driven design system over Material/Chakra?** Smaller bundle, no upgrade churn, full theming control via CSS variables. Trade-off: you build your own components.
10. **Why error boundaries per route?** A crash in `/projects/123` shouldn't blank the whole shell — the sidebar/topbar stays alive, the route shows a recovery UI.
