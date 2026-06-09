# frontend/

This is where the Angular 18 SPA lives.

## Quickstart

```pwsh
npm create @angular@18 taskflow-web -- --routing --style=scss --standalone --strict --ssr=false
cd taskflow-web
npm i -D @playwright/test eslint @ngrx/signals
npx playwright install chromium
```

## Expected layout

```
frontend/
├── angular.json
├── package.json
├── src/
│   ├── app/
│   │   ├── core/             (auth, http interceptors, error handler)
│   │   ├── shared/           (UI primitives, pipes, directives)
│   │   ├── features/
│   │   │   ├── board/
│   │   │   └── project/
│   │   └── app.config.ts
│   └── styles/
└── e2e/                       (Playwright)
```

## Rules
- Standalone components only.
- Signals for trivial state; **NgRx Signal Store** for board state.
- Reactive forms (`FormBuilder`) for all input.
- One HTTP service per backend resource; never call `HttpClient` from a component.
- Interceptors: `authInterceptor` (BFF cookie / token), `correlationInterceptor`, `retryInterceptor` (exponential + jitter, max 3 on 5xx/429).
- Lazy-load every feature route; check bundle size after each.
- Tailwind or Angular Material — pick in ADR, then be consistent.

See [Phase 3](../../../03-Phase3-Angular/) for the techniques; see [Build Plan M2](../../02-Build-Plan.md#m2--frontend-skeleton) for the milestone.
