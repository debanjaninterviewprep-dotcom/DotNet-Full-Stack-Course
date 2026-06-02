# Topic 7 — Frontend ↔ Backend Integration

> **Goal**: Wire the React shell from Topic 6 to the ASP.NET Core API from Topics 3–5 with TanStack Query, an in-memory access token + HttpOnly refresh cookie, optimistic mutations, MSW for offline dev, and proper error/loading boundaries.

---

## 1. Why TanStack Query (formerly React Query)

Server state is **not** client state — it's owned by the API, can change underneath you, and must be cached, invalidated, deduped, and revalidated. Putting it in `useState` (or even Redux) forces you to re-implement caching, deduplication, retries, refetch-on-focus, and pagination by hand.

TanStack Query gives you:
- Per-key caching with `staleTime` / `gcTime`.
- Automatic deduplication of in-flight requests with the same key.
- `refetchOnWindowFocus`, `refetchOnReconnect`, `refetchInterval`.
- `useMutation` with `onMutate` / `onSuccess` / `onError` / `onSettled` for optimistic updates.
- DevTools that show every cache entry and request lifecycle.

> Rule of thumb: **TanStack Query for server state, Zustand/Context for tiny client state (theme, sidebar collapse, selected board column), URL for filters/pagination.** Avoid Redux unless you have genuine cross-cutting state machines.

---

## 2. QueryClient setup + provider tree

```tsx
// src/app/providers.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,            // 30s before background refetch
      gcTime: 5 * 60_000,           // 5min in cache after no observers
      refetchOnWindowFocus: true,
      retry: (failureCount, error: any) => {
        if ([401, 403, 404].includes(error?.response?.status)) return false;
        return failureCount < 2;
      },
    },
    mutations: { retry: 0 },
  },
});

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ThemeProvider>{children}</ThemeProvider>
      </AuthProvider>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

**Why these defaults?**
- `staleTime: 30s` stops thundering-herd refetches when navigating between routes that share data.
- `retry: 0` for mutations — retrying a non-idempotent POST is dangerous. Use `Idempotency-Key` (Topic 4) if you need it.
- Skip retry for 401/403/404 — they aren't transient.

---

## 3. Query keys factory

Stringly-typed keys (`['projects', id]`) drift over time. Centralize them:

```ts
// src/features/projects/keys.ts
export const projectKeys = {
  all: ['projects'] as const,
  lists: () => [...projectKeys.all, 'list'] as const,
  list: (filters: { search?: string; status?: string }) =>
    [...projectKeys.lists(), filters] as const,
  details: () => [...projectKeys.all, 'detail'] as const,
  detail: (id: string) => [...projectKeys.details(), id] as const,
  members: (id: string) => [...projectKeys.detail(id), 'members'] as const,
};
```

Now `queryClient.invalidateQueries({ queryKey: projectKeys.all })` invalidates everything project-related; `projectKeys.detail(id)` is precise.

---

## 4. Queries

```ts
// src/features/projects/api.ts
import { useQuery } from '@tanstack/react-query';
import { api } from '@api/client';
import { projectKeys } from './keys';
import type { ProjectListItem, ProjectDetail, Page } from './types';

export function useProjects(filters: { search?: string; page?: number } = {}) {
  return useQuery({
    queryKey: projectKeys.list(filters),
    queryFn: async ({ signal }) => {
      const res = await api.get<Page<ProjectListItem>>('/api/v1/projects', {
        params: filters,
        signal,
      });
      return res.data;
    },
    placeholderData: (prev) => prev,                   // keep last page during pagination
  });
}

export function useProject(id: string) {
  return useQuery({
    queryKey: projectKeys.detail(id),
    queryFn: async ({ signal }) => {
      const res = await api.get<ProjectDetail>(`/api/v1/projects/${id}`, { signal });
      return res.data;
    },
    enabled: !!id,
  });
}
```

**Note:** The `signal` from TanStack Query is forwarded to axios — when the component unmounts or the key changes, the in-flight request is aborted.

---

## 5. Mutations

```ts
// src/features/projects/api.ts (continued)
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useCreateProject() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { name: string; description?: string }) => {
      const res = await api.post<ProjectDetail>('/api/v1/projects', payload);
      return res.data;
    },
    onSuccess: (created) => {
      qc.invalidateQueries({ queryKey: projectKeys.lists() });
      qc.setQueryData(projectKeys.detail(created.id), created);   // seed cache
    },
  });
}
```

In a component:

```tsx
const create = useCreateProject();

<Button
  loading={create.isPending}
  onClick={() => create.mutate({ name: 'New project' }, { onSuccess: () => navigate('/projects') })}
>
  Create
</Button>
```

---

## 6. Optimistic updates

For status flips (e.g., toggling a task to `Done`), the UI shouldn't wait for a network round-trip.

```ts
export function useUpdateTaskStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: TaskStatus }) =>
      api.patch(`/api/v1/tasks/${id}`, { status }).then((r) => r.data),

    onMutate: async ({ id, status }) => {
      await qc.cancelQueries({ queryKey: taskKeys.detail(id) });
      const previous = qc.getQueryData<TaskDetail>(taskKeys.detail(id));
      qc.setQueryData<TaskDetail>(taskKeys.detail(id), (old) =>
        old ? { ...old, status } : old,
      );
      return { previous };                 // context for onError
    },

    onError: (_err, vars, ctx) => {
      if (ctx?.previous) qc.setQueryData(taskKeys.detail(vars.id), ctx.previous);
    },

    onSettled: (_d, _e, vars) => {
      qc.invalidateQueries({ queryKey: taskKeys.detail(vars.id) });
    },
  });
}
```

The four-step pattern (`cancel → snapshot → optimistic → rollback-on-error → invalidate-on-settle`) is the canonical recipe — memorize it.

---

## 7. Auth flow — login + in-memory access token + refresh cookie

**Storage rules (Topic 5 reminder):**
- **Access token** → in JS memory only (Zustand store / module variable). Never `localStorage` (XSS-readable).
- **Refresh token** → set by API in `HttpOnly; Secure; SameSite=Strict; Path=/auth` cookie. Browser sends it automatically when `withCredentials: true`.

```ts
// src/features/auth/token-store.ts
import { create } from 'zustand';

type AuthState = {
  accessToken: string | null;
  user: { id: string; email: string; roles: string[] } | null;
  setAuth: (t: string, u: AuthState['user']) => void;
  clear: () => void;
};

export const useAuth = create<AuthState>((set) => ({
  accessToken: null,
  user: null,
  setAuth: (accessToken, user) => set({ accessToken, user }),
  clear: () => set({ accessToken: null, user: null }),
}));

// Non-React access used by axios interceptor
export const getAccessToken = () => useAuth.getState().accessToken;
export const setAccessToken = (t: string | null) =>
  useAuth.setState((s) => ({ ...s, accessToken: t }));
```

```ts
// src/features/auth/api.ts
export function useLogin() {
  return useMutation({
    mutationFn: async (creds: { email: string; password: string }) => {
      const res = await api.post<{ accessToken: string; user: User }>(
        '/api/v1/auth/login',
        creds,
      );
      return res.data;                                     // refresh cookie set by server
    },
    onSuccess: (data) => useAuth.getState().setAuth(data.accessToken, data.user),
  });
}

export async function refreshAccessToken(): Promise<string | null> {
  try {
    const res = await api.post<{ accessToken: string }>('/api/v1/auth/refresh');
    setAccessToken(res.data.accessToken);
    return res.data.accessToken;
  } catch {
    useAuth.getState().clear();
    return null;
  }
}
```

---

## 8. Silent refresh + concurrent 401 queue

Topic 6 stubbed `refreshAccessToken`. Now wire it for real with a **single in-flight refresh**:

```ts
// src/api/client.ts
let refreshing: Promise<string | null> | null = null;

api.interceptors.response.use(
  (r) => r,
  async (err: AxiosError) => {
    const original = err.config!;
    const status = err.response?.status;
    const isAuthEndpoint = original.url?.startsWith('/api/v1/auth/');
    if (status !== 401 || (original as any)._retried || isAuthEndpoint) throw err;
    (original as any)._retried = true;

    refreshing ??= refreshAccessToken().finally(() => { refreshing = null; });
    const newToken = await refreshing;
    if (!newToken) throw err;

    original.headers!.Authorization = `Bearer ${newToken}`;
    return api(original);
  },
);
```

**Why exclude `/auth/*`?** A 401 from `/auth/login` is a real failure — refreshing would cause an infinite loop. Same for `/auth/refresh` itself.

**Why a shared promise?** When 5 queries fire in parallel and all 401, you get **one** refresh round-trip and **one** new access token applied to all 5 retries.

---

## 9. Auth-aware route guards

```tsx
// src/app/router.tsx
import { redirect } from 'react-router-dom';
import { useAuth } from '@features/auth/token-store';

async function requireAuth() {
  let token = useAuth.getState().accessToken;
  if (!token) {
    // Try silent refresh on cold load (we have the cookie but no JS state)
    token = await refreshAccessToken();
    if (!token) throw redirect('/login');
  }
  return null;
}
```

This single line — *attempt silent refresh on cold load* — is what makes "stay logged in across page reloads" work without putting the access token in localStorage.

---

## 10. Logout

```ts
export function useLogout() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => api.post('/api/v1/auth/logout'),    // server clears + revokes refresh
    onSettled: () => {
      useAuth.getState().clear();
      qc.clear();                                         // wipe all cached server state
      window.location.href = '/login';                    // hard reload to clear in-memory state
    },
  });
}
```

`qc.clear()` is critical — otherwise the next user might see the previous user's cached data.

---

## 11. Error boundaries + Suspense + toasts

Three layers of error handling:

| Layer | Catches | Where |
|---|---|---|
| Axios interceptor | Network/HTTP errors | `src/api/client.ts` (logs, refreshes, normalizes ProblemDetails) |
| TanStack Query `onError` | Mutation/query failures with UX implications | per-feature hook |
| `<ErrorBoundary>` | Render-time crashes | per-route in router config |

Toast helper:

```ts
// src/shared/lib/toast.ts
export function toastError(err: unknown) {
  const pd = (err as any)?.response?.data;       // ASP.NET ProblemDetails
  const title = pd?.title ?? 'Something went wrong';
  const detail = pd?.detail ?? (err as Error).message;
  // push to global toast store (Sonner / react-hot-toast / your own)
  console.error(title, detail, pd?.traceId);
}
```

Use `QueryCache`-level `onError` to centralize:

```ts
const queryClient = new QueryClient({
  queryCache: new QueryCache({ onError: toastError }),
  mutationCache: new MutationCache({ onError: toastError }),
});
```

---

## 12. Forms — controlled + Zod validation

```tsx
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export function LoginPage() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } =
    useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) });
  const login = useLogin();

  return (
    <form onSubmit={handleSubmit((vals) => login.mutate(vals))}>
      <Input label="Email" {...register('email')} error={errors.email?.message} />
      <Input label="Password" type="password" {...register('password')}
             error={errors.password?.message} />
      <Button loading={isSubmitting || login.isPending}>Sign in</Button>
      {login.error ? <p role="alert">Invalid credentials</p> : null}
    </form>
  );
}
```

**Why Zod?** Same schema validates user input *and* parses API responses (`schema.parse(res.data)`), so the type system + runtime are aligned.

---

## 13. Pagination patterns

| Pattern | When to use | Hook |
|---|---|---|
| **Offset** (`page`/`pageSize`) | Admin tables, search results | `useQuery` + `placeholderData: prev` |
| **Cursor / keyset** | Activity logs, infinite scroll | `useInfiniteQuery` |
| **Polling** | Notification count, live counters | `refetchInterval: 5000` |

Infinite query example:

```ts
useInfiniteQuery({
  queryKey: ['activity', projectId],
  queryFn: ({ pageParam, signal }) =>
    api.get('/api/v1/projects/' + projectId + '/activity', { params: { cursor: pageParam }, signal })
       .then(r => r.data),
  initialPageParam: null as string | null,
  getNextPageParam: (last) => last.nextCursor ?? undefined,
});
```

The cursor format matches the keyset cursor from Topic 4 P6.

---

## 14. MSW — mock the API for dev + tests

Mock Service Worker intercepts real `fetch`/`XHR` calls in the browser, so the same axios code runs unchanged.

```ts
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = await request.json() as any;
    if (body.email !== 'demo@taskflow.dev') return HttpResponse.json({ title: 'Invalid' }, { status: 401 });
    return HttpResponse.json({
      accessToken: 'fake.jwt.token',
      user: { id: 'u1', email: body.email, roles: ['Member'] },
    });
  }),
  http.get('/api/v1/projects', () => HttpResponse.json({
    items: [{ id: 'p1', name: 'Demo project' }],
    total: 1, page: 1, pageSize: 20,
  })),
];
```

```ts
// src/mocks/browser.ts
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';
export const worker = setupWorker(...handlers);
```

Activate only in dev when `VITE_USE_MOCKS=true`:

```ts
if (import.meta.env.DEV && import.meta.env.VITE_USE_MOCKS === 'true') {
  await worker.start({ onUnhandledRequest: 'bypass' });
}
```

> Topic 10 reuses these handlers in Vitest (`setupServer` instead of `setupWorker`) for component tests.

---

## 15. Prefetching on navigation intent

```ts
// On link hover, warm the cache
const qc = useQueryClient();
<Link
  to={`/projects/${id}`}
  onMouseEnter={() =>
    qc.prefetchQuery({
      queryKey: projectKeys.detail(id),
      queryFn: () => api.get(`/api/v1/projects/${id}`).then(r => r.data),
      staleTime: 30_000,
    })
  }
>
  {name}
</Link>
```

Pair with React Router v7's `prefetch="intent"` for route-chunk preloading.

---

## 16. Real-time preview (full coverage in Topic 8)

For values that should update reactively (task moved on a board, comment added), TanStack Query pairs with SignalR:

```ts
useEffect(() => {
  hub.on('TaskUpdated', (task: TaskDetail) => {
    qc.setQueryData(taskKeys.detail(task.id), task);
  });
}, [qc]);
```

The cache becomes the integration point: HTTP fetches *and* WebSocket pushes write to the same key, components re-render automatically.

---

## 17. Performance & UX checklist

- ✅ Use `placeholderData: (prev) => prev` for paginated tables to avoid layout flicker.
- ✅ Show skeletons (not spinners) on first load; spinners only for refetches.
- ✅ Debounce search inputs (`useDebouncedValue` 300 ms) before passing to `queryKey`.
- ✅ Show `isFetching` (background refetch) differently from `isLoading` (no data yet).
- ✅ Use `enabled: !!param` to avoid firing queries with undefined IDs.
- ✅ Cancel pending queries on key change (free — TanStack Query does this).
- ✅ Set `refetchOnWindowFocus: false` only for queries that are heavy AND non-time-sensitive.

---

## 18. Common pitfalls

| Pitfall | Fix |
|---|---|
| Token in `localStorage` | XSS-readable. Memory + HttpOnly refresh cookie. |
| 5 simultaneous refresh calls on app boot | Shared in-flight promise (section 8). |
| Query key drift (`['project', id]` vs `['projects', id]`) | Keys factory (section 3). |
| Mutation success but stale list view | `invalidateQueries` on the list key. |
| Cold reload kicks user to /login despite valid refresh cookie | `requireAuth` must attempt silent refresh first. |
| Optimistic update sticks after error | Forgot `onError` rollback or `onSettled` invalidate. |
| Toast spam from background refetches | Use `QueryCache.onError` only for `meta.showToast: true` queries. |
| MSW worker not reset between tests | Call `server.resetHandlers()` in `afterEach`. |

---

## 19. 10 Q&A

1. **Why TanStack Query over Redux for server data?** Server state needs caching, deduping, refetching, and invalidation — Redux makes you build all of it. TanStack Query gives it for free.
2. **Why store the access token in memory and not localStorage?** localStorage is readable by any script — one XSS leaks the token. Memory + HttpOnly refresh cookie limits blast radius.
3. **Why a single in-flight refresh promise?** Prevents N parallel 401s from rotating the refresh token N times and causing reuse-detection to revoke the family.
4. **Why exclude `/auth/*` URLs from the 401 interceptor?** A 401 from `/auth/refresh` means the refresh failed — retrying would loop infinitely. A 401 from `/auth/login` is a real credential error, not a token expiry.
5. **What is `placeholderData: (prev) => prev` for?** Keeps the previous page's data visible during pagination so the layout doesn't flicker.
6. **When do you prefer `useInfiniteQuery` over `useQuery` with offset?** When the data is append-only (activity logs, comment threads) and you can't drop into the middle of a result set. Pairs with keyset pagination.
7. **What's the optimistic update recipe?** `cancelQueries` → `getQueryData` snapshot → `setQueryData` optimistic value → return context → on error rollback → on settled invalidate.
8. **Why `qc.clear()` on logout?** Cached server state is per-user. The next user (or anonymous session) must not see the previous user's data.
9. **Why MSW over jest mocks of axios?** MSW intercepts at the network layer — your component code, axios setup, and interceptors all run unchanged. Mocking axios bypasses the integration code you actually want to test.
10. **When to choose Zustand vs Context vs nothing?** Zustand for cross-cutting client state (auth, theme), Context for tree-scoped state (form context, theme provider), nothing for state that belongs in the URL or the server cache.
