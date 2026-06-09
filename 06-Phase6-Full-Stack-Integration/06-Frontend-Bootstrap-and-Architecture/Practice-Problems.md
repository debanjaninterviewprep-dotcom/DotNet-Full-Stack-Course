# Topic 6 — Practice Problems

> Project: `PracticeProblemsSolutions/` — a Vite + React 18 + TypeScript scaffold. Run `npm install` then `npm run dev`.

---

## P1 — Scaffold the project

**Goal:** Stand up `taskflow-web` with strict TypeScript, ESLint, Prettier, and path aliases.

**Tasks**
1. `npm create vite@latest taskflow-web -- --template react-ts`.
2. Install runtime deps: `react-router-dom`, `axios`, `zod`, `@tanstack/react-query`, `clsx`.
3. Install dev deps: `eslint`, `prettier`, `vite-tsconfig-paths`, `@typescript-eslint/*`, `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`, `eslint-config-prettier`.
4. Enable strict tsconfig flags: `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`.
5. Configure path aliases `@app`, `@features`, `@shared`, `@api`, `@config` in both `tsconfig.json` and `vite.config.ts`.
6. Add npm scripts: `lint`, `lint:fix`, `format`, `typecheck`, `build`.

**Acceptance**
- `npm run dev` serves on `http://localhost:5173` with HMR.
- `npm run typecheck` passes with no errors.
- `import { Button } from '@shared/ui/Button'` resolves at compile and build time.

---

## P2 — Routing shell with public/private layouts

**Goal:** Two-layer routing — `PublicLayout` for `/login`+`/signup`, `AppLayout` (sidebar + topbar) for everything else, with an auth guard.

**Tasks**
1. Build `createBrowserRouter` config with two layout routes.
2. `AppLayout` shows sidebar (Projects / Tasks / Settings) and topbar (theme toggle + user menu).
3. `requireAuth` loader redirects to `/login` if no access token.
4. Routes: `/` → redirect `/projects`; `/projects`, `/projects/:id`, `/projects/:id/board`, `/login`, `/signup`, `*` 404.
5. Lazy-load every page route (`lazy: () => import(...)`).

**Acceptance**
- Visiting `/projects` while logged out redirects to `/login`.
- Each page is a separate JS chunk in `dist/assets/` after `npm run build`.
- 404 catch-all renders without breaking the shell.

---

## P3 — Design-system primitives

**Goal:** A token-driven `Button`, `Input`, and `Card` — reusable across all features.

**Tasks**
1. Author `src/styles/tokens.css` with light + `[data-theme='dark']` palettes (color, radius, spacing, font tokens).
2. `Button`: variants `primary | ghost | danger`, sizes `sm | md`, `loading` prop disables + shows spinner, `aria-busy` set when loading. Forward ref.
3. `Input`: label + helper-text + error slots, `aria-invalid`, `aria-describedby` linking to error/helper id.
4. `Card`: header (title + actions slot) + body + footer.
5. Build a `/styleguide` route that renders every variant for visual diffing (do NOT add to production sidebar).

**Acceptance**
- All primitives are keyboard-accessible (focus rings, real `<button>`/`<input>`).
- Switching `<html data-theme="dark">` re-themes everything via CSS variables — no JS re-render needed.
- TypeScript: `<Button variant="other" />` is a compile error.

---

## P4 — Axios client + 401 refresh interceptor

**Goal:** A singleton `api` axios instance that injects `Authorization: Bearer`, attaches a correlation ID, and handles 401s with a single shared in-flight refresh.

**Tasks**
1. Create `src/api/client.ts` with `baseURL` from validated env, `withCredentials: true`, 15 s timeout.
2. Request interceptor injects `Bearer` and `X-Correlation-Id: <uuid>`.
3. Response interceptor: on 401 (and not already retried), call `refreshAccessToken()`. Five concurrent 401s must trigger exactly **one** refresh.
4. If refresh fails → call `clearAuth()` and reject the original error (router will redirect on next render).
5. Stub `getAccessToken()`, `refreshAccessToken()`, `clearAuth()` in `src/features/auth/token-store.ts` — full implementation comes in Topic 7.

**Acceptance**
- A unit test (Vitest) verifies that 5 parallel `api.get('/x')` calls returning 401 cause **one** call to `refreshAccessToken`.
- Each request carries a unique `X-Correlation-Id` (visible in the API's Serilog log from Topic 3).
- 401-after-refresh-failure does not loop infinitely.

---

## P5 — Typed API client generated from Swagger

**Goal:** Regenerate `src/api/generated/` from the live API's `/swagger/v1/swagger.json` whenever the API changes.

**Tasks**
1. Add dev dep `openapi-typescript-codegen`.
2. Add npm script `api:gen` pointing at `https://localhost:7104/swagger/v1/swagger.json` (Topic 4 API).
3. Add `src/api/generated/` to `.gitignore`.
4. Wire the generated `OpenAPI.BASE`, `OpenAPI.TOKEN`, and request interceptor to the same axios instance from P4 (via `OpenAPI.HTTP_REQUEST` override).
5. Document a fallback: if codegen fails, the app must still build using hand-written types in `src/api/schemas.ts` (Zod).

**Acceptance**
- `npm run api:gen` produces typed services (e.g., `ProjectsService.getApiV1Projects(...)`) with request/response models.
- `git status` after generation shows no tracked file changes (folder is ignored).
- Calling a generated service propagates the Bearer token from P4.

---

## P6 — Dark mode + theme provider

**Goal:** A `ThemeProvider` that supports `light | dark | system`, persists to `localStorage`, and respects OS preference changes live.

**Tasks**
1. Create `ThemeProvider` and `useTheme()` hook.
2. On mount, read saved theme; default to `system`.
3. When `theme === 'system'`, subscribe to `matchMedia('(prefers-color-scheme: dark)')` and update `html[data-theme]` reactively.
4. Build a `ThemeToggle` component in the topbar — cycles light → dark → system.
5. Ensure no FOUC: set the initial `data-theme` in an inline `<script>` in `index.html` before React mounts.

**Acceptance**
- Toggling OS dark mode while the tab is open updates the UI within one frame when `theme === 'system'`.
- Refreshing the page never flashes the wrong theme.
- `useTheme` is type-safe — passing `'blue'` is a compile error.
