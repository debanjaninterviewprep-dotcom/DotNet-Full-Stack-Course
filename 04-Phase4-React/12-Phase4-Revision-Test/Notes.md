# Topic 12: Phase 4 — Revision Test

## 📘 Revision Summary: React (Basics → Advanced)

This revision test consolidates **all 11 topics** of Phase 4. Use it as a self-assessment before moving to Phase 5 (.NET Core).

- **Time**: untimed; aim for 6–10 hours of focused work spread over 2–4 days
- **Open book**: refer to your notes
- **Grading**: each Part carries the listed weight
- **Goal**: prove you can build a non-trivial, production-shaped React app touching every topic

---

## 🧭 Topic Coverage Map

| # | Topic | Concept Verified |
|---|-------|------------------|
| 1 | React & JSX Fundamentals | JSX rules, conditional & list rendering, fragments, keys |
| 2 | Project Setup & Tooling | Vite + TS, ESLint, Prettier, env vars, scripts |
| 3 | Components & Props | Function components, prop types, composition, children, polymorphic props |
| 4 | State & Lifecycle (Hooks) | `useState`, `useEffect`, `useRef`, `useReducer`, custom hooks, rules of hooks |
| 5 | Events & Forms | Synthetic events, controlled inputs, RHF + Zod, validation, accessibility |
| 6 | Routing & Navigation | `createBrowserRouter`, nested routes, loaders/actions, guards, lazy routes |
| 7 | Data Fetching & HTTP | Fetch + AbortController, axios interceptors, TanStack Query (queries/mutations/invalidation) |
| 8 | Styling & CSS | CSS Modules, Tailwind, theming via CSS variables + Context, animations |
| 9 | State Management | Context + `useReducer`, Redux Toolkit, RTK Query, Zustand |
| 10 | Performance | `React.memo`, `useMemo`, `useCallback`, virtualization, code splitting, `useTransition` |
| 11 | Testing | Vitest/Jest, RTL queries, `userEvent`, MSW, Playwright e2e |

---

## Part A — Theory & Short Answers (20 points)

Answer in your own words (3–6 sentences each, with code snippets where useful).

1. Explain the difference between **render phase** and **commit phase**, and how `useEffect` relates to each.
2. When does **`React.memo`** *not* prevent re-renders? Give two concrete examples.
3. Compare **controlled vs uncontrolled** inputs — when would you use each, and what does the "A component is changing an uncontrolled input to controlled" warning mean?
4. Walk through the lifecycle of a `useQuery` call from **mount** → **stale** → **invalidation** → **refetch**. What is the role of `staleTime` vs `gcTime`?
5. Explain the **Rules of Hooks** and why React enforces them (think: how hooks are matched between renders).
6. What problem does **`useTransition`** solve that `setTimeout` cannot?
7. Why is **index-as-key** dangerous? Show a bug it can cause.
8. Compare **Context + `useReducer`** vs **Redux Toolkit** vs **Zustand** — when would you reach for each?
9. Explain how **MSW** works at a network level and why it's preferable to mocking `fetch`/`axios` directly.
10. Describe the **testing pyramid** for a React app and give one concrete test you'd write at each layer.

---

## Part B — Code Challenges (30 points)

Each challenge is self-contained. Place them in `src/challenges/` of your test project.

### B1 — `useApi` Generic Hook (6 pts)
Build a typed `useApi<T>(url, options)` hook that returns `{ data, error, isLoading, refetch, abort }`, supports `AbortController`, deduplicates concurrent calls to the same key, and caches results in-memory for 30 seconds.

### B2 — `<Pagination/>` Component (6 pts)
Accessible pagination with first/prev/next/last and a window of page numbers (with ellipses), keyboard support, and `aria-current="page"`. Must be controlled via `page`/`onPageChange` props.

### B3 — `<ProtectedRoute/>` (6 pts)
A route guard built on `react-router-dom` v6+ that:
- Redirects unauthenticated users to `/login` and preserves intended destination via `state.from`.
- Supports `roles?: string[]` and shows a 403 page if the role is missing.
- Reads auth from a Context provider you build.

### B4 — Virtualized List (6 pts)
Render a list of 50,000 items with `react-window` (or TanStack Virtual). Each row shows an avatar, name, and action button. Add a search input that filters with `useDeferredValue` so typing stays smooth.

### B5 — Test Suite (6 pts)
Write tests for B1–B4 using Vitest + RTL + MSW. Aim for ≥80% line coverage on the four challenges.

---

## Part C — Build Project: **TaskFlow React** (50 points)

Build a fully working **TaskFlow** frontend that talks to a mock API (MSW or json-server). Must touch every topic.

### Required Features
- **Auth**: login / logout, token in `localStorage`, axios interceptor adds `Authorization`.
- **Dashboard**: list of projects, each with task counts.
- **Project detail**: tasks grouped by status (Todo / In Progress / Done) with drag-and-drop between columns.
- **Task form**: create/edit with React Hook Form + Zod (title, description, due date, priority, assignee).
- **Filters**: by status, priority, assignee — synced to URL search params.
- **Comments**: optimistic UI on add/delete using TanStack Query mutations.
- **Profile page**: avatar upload with preview and progress bar.
- **Theme**: light/dark toggle persisted in `localStorage` via Context + CSS variables.
- **Internationalization** (bonus): English + one other language via `react-i18next`.

### Required Architecture
- **Routing**: `createBrowserRouter` with nested routes, lazy-loaded pages, error boundaries, 404 page.
- **State**: Context for theme + auth, **Zustand** *or* **Redux Toolkit** for UI state (modals, drawer), **TanStack Query** for all server state.
- **Styling**: Tailwind CSS *or* CSS Modules with a design token system.
- **Forms**: RHF + Zod with full a11y (labels, `aria-invalid`, error association).
- **Testing**:
  - 10+ unit tests (hooks, utils)
  - 5+ integration tests (forms, routing, query mutations) with MSW
  - 2 Playwright e2e tests (login → create task → drag to Done)

### Required Polish
- Loading skeletons (no naked spinners)
- Empty states, error states, retry buttons
- Keyboard navigation everywhere; focus trap in modals
- `prefers-reduced-motion` respected
- Lighthouse Performance ≥ 90 on dashboard route
- Bundle analyzer screenshot in `/docs/`

---

## 📊 Grading Rubric

| Section | Points | Threshold |
|---|---|---|
| Part A (Theory) | 20 | 14+ to pass |
| Part B (Challenges) | 30 | 21+ to pass |
| Part C (Project) | 50 | 35+ to pass |
| **Total** | **100** | **70+ to advance** |

### Bonus (+10)
- Server Components or Next.js App Router rebuild
- React Compiler enabled and verified via DevTools
- Storybook for the design system primitives
- CI on GitHub Actions running tests + Playwright

---

## ✅ Self-Assessment Checklist (before submitting)

- [ ] App runs with `npm run dev` after a fresh `npm install`
- [ ] `npm run build` produces a clean production bundle
- [ ] `npm test` passes; coverage ≥ 80%
- [ ] `npm run lint` clean; no `any` types
- [ ] No console errors or warnings in DevTools
- [ ] All routes accessible via keyboard
- [ ] Tested in Chrome, Firefox, Safari
- [ ] README documents architecture decisions

Good luck — and remember, this test exists to surface gaps, not to punish you. Treat any low-scoring section as a focused study target before Phase 5.
