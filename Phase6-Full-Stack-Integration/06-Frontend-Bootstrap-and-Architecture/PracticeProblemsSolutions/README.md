# Topic 6 — Practice Problems Solutions

Vite + React 18 + TypeScript scaffold for the TaskFlow web client.

## Setup

```bash
npm install
npm run dev
```

Visit http://localhost:5173.

Copy `.env.example` to `.env` and adjust `VITE_API_BASE_URL` if your Topic 4 API is on a different port.

## Scripts

- `npm run dev` — Vite dev server (port 5173, strict)
- `npm run build` — type-check + production build to `dist/`
- `npm run preview` — preview the production build
- `npm run lint` / `lint:fix` — ESLint
- `npm run format` — Prettier
- `npm run typecheck` — `tsc --noEmit`
- `npm run api:gen` — regenerate `src/api/generated/` from the API's OpenAPI document

## Where to start

Each problem (P1–P6) has TODO markers in the relevant file:

| Problem | Files |
|---|---|
| P1 Scaffold | `package.json`, `tsconfig.json`, `vite.config.ts`, `.eslintrc.cjs` |
| P2 Routing shell | `src/app/router.tsx` (replace placeholder), add `src/app/layouts/` |
| P3 Design system | `src/shared/ui/Button.tsx` (extend), add `Input.tsx`, `Card.tsx`, `Button.css` |
| P4 Axios + 401 refresh | `src/api/client.ts`, `src/features/auth/token-store.ts` |
| P5 Codegen client | run `npm run api:gen` once Topic 4 API is up |
| P6 Theme | `src/app/providers.tsx`, add `src/shared/ui/ThemeToggle.tsx` |
