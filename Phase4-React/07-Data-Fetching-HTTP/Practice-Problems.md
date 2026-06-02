# Topic 7: Data Fetching & HTTP — Practice Problems

Five progressive problems that take you from a single `fetch` call to a production-grade search application with auth interceptors, retry/backoff, and MSW-driven tests.

> Public APIs you can use freely:
> - `https://jsonplaceholder.typicode.com` — posts, todos, users
> - `https://api.github.com` — users, repos (60 req/hr unauthenticated)
> - `https://dummyjson.com` — products, carts, auth

---

## Problem 1 — Display a List of Posts (Easy)

**Concept:** `useEffect` + `fetch`, loading / error / data states.

### Requirements
- Fetch `https://jsonplaceholder.typicode.com/posts` on mount.
- Show three distinct UI states: loading spinner, error banner, populated list.
- Render only the first 20 posts; show `id`, `title`, truncated `body`.
- Add a "Reload" button that re-runs the request.
- Cancel the in-flight request on unmount with `AbortController`.

### Expected behavior
- On slow network, the spinner is visible until the response arrives.
- Killing the dev server mid-request shows the error banner; the Reload button recovers.
- Switching to another route mid-flight does **not** trigger a "set state on unmounted component" warning.

### Starter

```tsx
import { useEffect, useState } from 'react';

interface Post { id: number; title: string; body: string }

export default function Posts() {
  const [posts, setPosts]     = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState<Error | null>(null);

  // TODO: fetch with AbortController, handle ok/!ok, cleanup
  return null;
}
```

---

## Problem 2 — Build a `useFetch` Hook and Reuse It (Easy-Medium)

**Concept:** custom hooks, generics, cancellation, refetch.

### Requirements
- Implement `useFetch<T>(url, options?)` returning `{ data, error, loading, refetch }`.
- Cancel previous request when `url` changes or component unmounts.
- Treat any non-2xx as an error and expose the status code on the error object.
- Use the hook in **three** components:
  1. `<UserProfile id={...} />` — `/users/:id`
  2. `<UserPosts id={...} />` — `/users/:id/posts`
  3. `<UserAlbums id={...} />` — `/users/:id/albums`
- A single "Refetch all" button should refetch all three.

### Expected behavior
- Rapidly changing `id` cancels the previous in-flight request — the UI never flashes stale data.
- React StrictMode does not produce duplicate visible requests after the first paint.
- Loading skeletons appear individually for each child while loading.

### Starter

```tsx
export function useFetch<T>(url: string, init?: RequestInit) {
  // TODO: data, error, loading, refetch — return them
}
```

---

## Problem 3 — Todos CRUD with TanStack Query and Optimistic Updates (Medium)

**Concept:** `useQuery`, `useMutation`, `onMutate`, `invalidateQueries`, optimistic UI.

### Requirements
- Use `https://jsonplaceholder.typicode.com/todos?_limit=10` for the list.
- Operations: **add**, **toggle done**, **edit title**, **delete**. (JSONPlaceholder fakes responses, which is fine for the exercise.)
- Each mutation must:
  - Cancel outgoing queries (`qc.cancelQueries`).
  - Snapshot previous cache.
  - Apply optimistic update.
  - On error, roll back to the snapshot and show a toast.
  - On settle, invalidate the `['todos']` query.
- Show a global "saving..." indicator using `useIsFetching()` / `useIsMutating()`.
- Configure `staleTime: 30s`, `retry: 2`, `refetchOnWindowFocus: false`.

### Expected behavior
- Toggling a todo flips instantly — no spinner — and silently reconciles in the background.
- Forcing the API offline rolls each item back and surfaces a toast.
- Devtools panel shows queries transitioning `fresh → fetching → fresh`.

### Starter

```tsx
const todosQuery = useQuery({
  queryKey: ['todos'],
  queryFn: ({ signal }) =>
    fetch('https://jsonplaceholder.typicode.com/todos?_limit=10', { signal }).then(r => r.json()),
});

const toggleMutation = useMutation({
  mutationFn: (todo: Todo) => /* TODO PATCH */ Promise.resolve(todo),
  // TODO: onMutate / onError / onSettled
});
```

---

## Problem 4 — Infinite Scroll Feed (Medium-Hard)

**Concept:** `useInfiniteQuery`, cursor pagination, IntersectionObserver, prefetch.

### Requirements
- Endpoint: `https://dummyjson.com/products?limit=12&skip=<n>` (returns `{ products, total, skip, limit }`).
- Use `useInfiniteQuery` with `getNextPageParam` derived from `skip + limit < total`.
- Render a grid of product cards (image, title, price).
- A sentinel `<div ref={sentinelRef}>` at the bottom triggers `fetchNextPage()` via `IntersectionObserver` — no scroll handlers.
- Show a small spinner only while `isFetchingNextPage` is true.
- Display "You've reached the end" when `!hasNextPage`.
- Cancel the in-flight page request when the user navigates away.

### Expected behavior
- Scrolling smoothly loads more pages without duplicate fetches.
- Throttling the network to "Slow 3G" still produces a stable UI — sentinel doesn't fire 10× while a request is in flight.
- Resizing the window (sentinel briefly off-screen) does not break loading.

### Starter

```tsx
const {
  data, fetchNextPage, hasNextPage, isFetchingNextPage,
} = useInfiniteQuery({
  queryKey: ['products'],
  queryFn: ({ pageParam = 0, signal }) =>
    fetch(`https://dummyjson.com/products?limit=12&skip=${pageParam}`, { signal }).then(r => r.json()),
  initialPageParam: 0,
  getNextPageParam: (last) => /* TODO */ undefined,
});

// TODO: IntersectionObserver wired to sentinelRef
```

---

## Problem 5 — GitHub User Search App (Hard)

**Concept:** debounced input, paginated query, axios interceptors, retry with exponential backoff, MSW-based tests.

### Requirements

**Search & pagination**
- Search box for GitHub username; debounce input by 400 ms (don't fire while typing).
- Endpoint: `GET https://api.github.com/search/users?q=<q>&per_page=10&page=<n>`.
- Show paginated results with Prev / Next buttons (disable appropriately based on `total_count`).
- Show empty-state ("No users match `<q>`") and idle-state (before any search) distinctly.

**Axios setup**
- Create an `api` instance with `baseURL: 'https://api.github.com'` and a 10 s timeout.
- Request interceptor injects `Authorization: Bearer <token>` if `localStorage.token` exists.
- Response interceptor:
  - On `401`: clear token, redirect to `/login`.
  - On `403` rate-limit: surface a friendly "API rate limit reached, try again in N s" using the `X-RateLimit-Reset` header.
- Retry policy via TanStack Query: `retry: 3`, `retryDelay: attempt => Math.min(1000 * 2 ** attempt, 8000)` — but **do not** retry 4xx errors.

**Per-result detail**
- Clicking a result fetches `GET /users/:login` and shows name, bio, public repos, followers, avatar.
- Use a dependent query (`enabled: !!selectedLogin`).

**Testing with MSW**
- Set up MSW handlers for `/search/users` and `/users/:login`.
- Write three tests with React Testing Library:
  1. **Happy path**: typing "octo" eventually shows at least one result row.
  2. **Empty state**: server returns `{ items: [], total_count: 0 }` → "No users match" appears.
  3. **Error state**: server returns 500 → an error message renders, and the retry button re-fires the request (MSW handler updated mid-test to succeed).

### Expected behavior
- Typing rapidly fires **one** request after 400 ms of silence.
- Switching pages cancels the previous in-flight request.
- A simulated 500 retries up to 3 times with growing delays, then surfaces an error.
- Token in `localStorage` is reflected in the `Authorization` header on every request (verify in MSW handler).

### Starter

```tsx
// api.ts
import axios from 'axios';
export const api = axios.create({ baseURL: 'https://api.github.com', timeout: 10_000 });
api.interceptors.request.use(/* TODO inject bearer */);
api.interceptors.response.use(undefined, /* TODO 401 / 403 handling */);

// useDebounced.ts
export function useDebounced<T>(value: T, ms = 400): T { /* TODO */ return value; }

// SearchUsers.tsx
const debounced = useDebounced(q);
const search = useQuery({
  queryKey: ['gh-search', debounced, page],
  queryFn: ({ signal }) =>
    api.get('/search/users', { params: { q: debounced, page, per_page: 10 }, signal }).then(r => r.data),
  enabled: debounced.length > 0,
  retry: (failureCount, err) =>
    failureCount < 3 && !(axios.isAxiosError(err) && err.response && err.response.status < 500),
  retryDelay: attempt => Math.min(1000 * 2 ** attempt, 8000),
});
```

### Stretch goals
- Persist the last query to the URL (`?q=octo&page=2`) so refreshes work.
- Add a **prefetch on hover** for user-detail to make the click feel instant.
- Add a global error boundary using `useQueryErrorResetBoundary`.
- Add a toast notification system for non-blocking errors.

---

## Submission checklist

- [ ] Every fetch is cancelable (AbortController or query `signal`).
- [ ] No `setState` warnings in StrictMode.
- [ ] Loading, error, empty, and success states all reachable in the UI.
- [ ] Optimistic mutations roll back on error.
- [ ] At least one MSW-based test for each non-trivial component in Problem 5.
- [ ] No `any` in TypeScript code — use generics or `unknown` + narrowing.
