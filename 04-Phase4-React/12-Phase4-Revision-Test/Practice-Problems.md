# Topic 12: Phase 4 Revision Test — Practice Problems

This file is the **submission tracker** for the Phase 4 React revision test.
The full task list, grading rubric, and architectural requirements live in [`Notes.md`](Notes.md).

---

## 📂 Suggested Repository Layout

```
taskflow-react/
├─ src/
│  ├─ app/                # router config, providers
│  ├─ challenges/         # B1–B4 code challenges
│  ├─ features/           # auth, projects, tasks, profile
│  ├─ components/         # ui primitives
│  ├─ hooks/              # custom hooks
│  ├─ lib/                # axios, query client, msw handlers
│  └─ test/               # test utilities, setup
├─ e2e/                   # Playwright specs
├─ docs/                  # bundle analyzer, architecture diagrams
└─ README.md
```

---

## ✅ Submission Checklist

### Part A — Theory (20 pts)
- [ ] Q1 — render vs commit phase
- [ ] Q2 — `React.memo` failure cases
- [ ] Q3 — controlled vs uncontrolled
- [ ] Q4 — TanStack Query lifecycle
- [ ] Q5 — Rules of Hooks
- [ ] Q6 — `useTransition` purpose
- [ ] Q7 — index-as-key bug
- [ ] Q8 — Context vs RTK vs Zustand
- [ ] Q9 — MSW vs direct mocking
- [ ] Q10 — testing pyramid

> Place answers in `docs/PartA-Theory.md`.

### Part B — Code Challenges (30 pts)
- [ ] B1 — `useApi` generic hook + tests
- [ ] B2 — `<Pagination/>` component + tests
- [ ] B3 — `<ProtectedRoute/>` with role guards + tests
- [ ] B4 — Virtualized list with deferred-value search
- [ ] B5 — Coverage ≥ 80% on B1–B4

### Part C — TaskFlow React (50 pts)

**Auth & shell**
- [ ] Login / logout with token persistence
- [ ] Axios interceptor for `Authorization` and 401 → redirect to `/login`
- [ ] Protected layout with sidebar nav and theme toggle

**Projects & tasks**
- [ ] Projects list with task counts
- [ ] Project detail with kanban columns
- [ ] Drag-and-drop reordering with optimistic mutation
- [ ] Task create/edit form (RHF + Zod)
- [ ] Filters synced to URL search params

**Comments & profile**
- [ ] Optimistic add/delete comments
- [ ] Avatar upload with preview + progress bar

**Cross-cutting**
- [ ] Light/dark theme via Context + CSS variables
- [ ] Loading skeletons everywhere
- [ ] Empty / error states with retry
- [ ] Full keyboard navigation
- [ ] Focus trap in modals
- [ ] `prefers-reduced-motion` respected
- [ ] Lighthouse Performance ≥ 90

**Routing & state**
- [ ] `createBrowserRouter` with nested routes
- [ ] Lazy-loaded pages
- [ ] Route-level error boundaries
- [ ] 404 page
- [ ] Zustand or RTK for UI state
- [ ] TanStack Query for server state

**Testing**
- [ ] 10+ unit tests (hooks, utils)
- [ ] 5+ integration tests with MSW
- [ ] 2+ Playwright e2e tests
- [ ] CI green on push

### Bonus (+10)
- [ ] Next.js App Router rebuild OR React Compiler enabled
- [ ] Storybook for design system
- [ ] GitHub Actions CI

---

## 📤 Submission

1. Push the repository to GitHub.
2. Include a `README.md` with:
   - Architecture overview (diagram or bullet list)
   - How to run dev / build / test / e2e
   - Trade-offs and what you'd do differently
3. Open `docs/PartA-Theory.md` and `docs/Bundle-Analysis.png`.
4. Tag the commit `phase4-revision-v1`.

> Self-grade against the rubric in [`Notes.md`](Notes.md). If any section scores below the threshold, revisit the corresponding topic notes before starting Phase 5.
