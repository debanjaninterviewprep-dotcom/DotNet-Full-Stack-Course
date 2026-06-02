# Topic 7 — Practice Problems

> Project: `PracticeProblemsSolutions/` — Vite + React + TS scaffold extending Topic 6 with TanStack Query, Zustand, MSW. Run `npm install` then `npm run dev`.

---

## P1 — TanStack Query setup + DevTools

**Goal:** Wire `QueryClient` with sensible defaults and the DevTools panel.

**Tasks**
1. Install `@tanstack/react-query` and `@tanstack/react-query-devtools`.
2. Configure `QueryClient` with `staleTime: 30_000`, `gcTime: 5min`, `refetchOnWindowFocus: true`, mutation retry 0, query retry skipped on 401/403/404.
3. Centralize errors via `QueryCache.onError` and `MutationCache.onError` to a `toastError` helper that reads RFC 7807 `ProblemDetails` (`title`, `detail`, `traceId`).
4. Add `<ReactQueryDevtools />` only in dev (`import.meta.env.DEV`).
5. Build a `projectKeys` query-keys factory with `all / lists / list(filters) / details / detail(id) / members(id)`.

**Acceptance**
- `useQuery({ queryKey: projectKeys.detail('p1') })` is correctly invalidated by `invalidateQueries({ queryKey: projectKeys.all })`.
- A failed mutation triggers exactly one toast carrying the API's `traceId`.
- DevTools is absent from the production bundle (verify in `dist/`).

---

## P2 — Login mutation + in-memory token store (Zustand)

**Goal:** Authenticate against `/api/v1/auth/login`, store the access token in memory, and treat the refresh cookie as the persistence layer.

**Tasks**
1. Build a Zustand store `useAuth` with `{ accessToken, user, setAuth, clear }`.
2. Implement `useLogin()` mutation that POSTs credentials, stores the result, and seeds `qc.setQueryData(['me'], user)`.
3. Implement `useLogout()` that POSTs `/auth/logout`, calls `useAuth.getState().clear()`, runs `qc.clear()`, then `window.location.href = '/login'`.
4. Build a `LoginPage` with `react-hook-form` + Zod (`email`, `password ≥ 8`).
5. After login, navigate to the URL the user was originally requesting (use the React Router `from` location state).

**Acceptance**
- The access token is **never** written to `localStorage` or `sessionStorage` (grep + ESLint rule).
- Logging out from tab A and reloading tab B shows `/login` (because the refresh cookie was revoked server-side and the silent refresh fails).
- Submitting the form twice in 200 ms triggers exactly one POST (mutation gating).

---

## P3 — Silent refresh interceptor with concurrency queue

**Goal:** Make the axios 401 interceptor robust under concurrent requests.

**Tasks**
1. Implement `refreshAccessToken()` that POSTs `/api/v1/auth/refresh` (cookie sent automatically), updates the auth store, returns the new token, or returns `null` and clears auth on failure.
2. In the response interceptor: on 401, if not already retried and not a `/auth/*` URL, share a single in-flight `refreshing` promise across all callers; replay the original request with the new Bearer.
3. On cold app load, attempt one silent refresh in `requireAuth` before redirecting to `/login`.
4. Write a Vitest test that fires 5 parallel `api.get` calls, all returning 401 once, and asserts `refreshAccessToken` is called exactly once.
5. Write a second test that asserts a 401 from `/auth/login` is **not** retried.

**Acceptance**
- Both Vitest tests pass.
- Reloading the page while logged in keeps the user logged in without a flash of `/login`.
- A revoked refresh cookie gracefully redirects to `/login` (no infinite loops in the network panel).

---

## P4 — Optimistic update for task status

**Goal:** Toggle a task's status with zero perceived latency and correct rollback.

**Tasks**
1. Build `useUpdateTaskStatus()` using the four-step recipe: `cancelQueries → snapshot → setQueryData → return context → onError rollback → onSettled invalidate`.
2. Update both the task detail key (`taskKeys.detail(id)`) **and** the list key (`taskKeys.list(filters)`) optimistically.
3. Build a `TaskCard` component with a status select that calls the mutation.
4. Simulate a server failure with MSW (P5) and verify rollback restores the previous status visually.
5. Show a tiny "saving…" indicator while `mutation.isPending` is true, but do **not** disable the control.

**Acceptance**
- The UI updates within one frame on `onMutate`.
- A 500 from the API rolls back to the previous status and shows an error toast.
- After settle, a refetch confirms the cache matches the server.

---

## P5 — MSW handlers for offline development

**Goal:** Run the entire app without the API for design/dev work.

**Tasks**
1. Install `msw` (already in dev deps from Topic 6 plan).
2. Author `src/mocks/handlers.ts` for: `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /projects` (paged), `POST /projects`, `GET /projects/:id`, `PATCH /tasks/:id` (with a 30% random failure when `VITE_MSW_FAIL=true`).
3. Activate the worker only when `import.meta.env.DEV && import.meta.env.VITE_USE_MOCKS === 'true'`.
4. Add a "Demo mode" banner shown when MSW is active.
5. Document how to switch between live API and mocks via `.env.local`.

**Acceptance**
- `VITE_USE_MOCKS=true npm run dev` runs the app with no API contact (verify with offline DevTools network throttle).
- `npm run build` does **not** ship the MSW worker file (`mockServiceWorker.js` is dev-only).
- The 30% failure mode exercises the optimistic-rollback path from P4.

---

## P6 — Infinite scroll for project activity

**Goal:** Use `useInfiniteQuery` with the keyset cursor from Topic 4 P6.

**Tasks**
1. Build `useProjectActivity(projectId)` returning paginated activity entries with `getNextPageParam: (last) => last.nextCursor ?? undefined`.
2. In `ProjectActivityFeed`, render all loaded pages and a sentinel `<div ref={loadMoreRef}>` watched by `IntersectionObserver` to call `fetchNextPage()`.
3. Show a skeleton row on first load and a small spinner on subsequent loads.
4. Guard with `hasNextPage && !isFetchingNextPage` to avoid double-firing.
5. Bonus: when SignalR (Topic 8) emits `ActivityCreated`, prepend to the first page via `qc.setQueryData(['activity', projectId], (old) => ...)`.

**Acceptance**
- Scrolling fires one request per page, never duplicated.
- Reaching the end stops the IntersectionObserver from firing.
- The component remains responsive at 100+ loaded entries (no jank).
