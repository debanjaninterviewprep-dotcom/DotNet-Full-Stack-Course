# Topic 7: Data Fetching & HTTP (fetch / axios / React Query)

Modern React apps spend most of their lifetime talking to HTTP APIs. This topic covers the entire spectrum — from raw `fetch` to fully managed server-state with TanStack Query — including cancellation, caching, optimistic updates, pagination, authentication, file uploads, and testing.

---

## 1. HTTP Basics Recap

Before touching React, the underlying protocol must be second nature.

### Methods

| Method   | Idempotent | Safe | Typical use                          |
|----------|------------|------|--------------------------------------|
| `GET`    | Yes        | Yes  | Read a resource                      |
| `POST`   | No         | No   | Create a resource / non-idempotent ops |
| `PUT`    | Yes        | No   | Replace an entire resource           |
| `PATCH`  | No*        | No   | Partial update                       |
| `DELETE` | Yes        | No   | Remove a resource                    |
| `HEAD`   | Yes        | Yes  | Like GET but headers only            |
| `OPTIONS`| Yes        | Yes  | CORS preflight, capability discovery |

### Status code families

| Range | Meaning        | Common examples                                  |
|-------|----------------|--------------------------------------------------|
| 1xx   | Informational  | 100 Continue, 101 Switching Protocols            |
| 2xx   | Success        | 200 OK, 201 Created, 204 No Content              |
| 3xx   | Redirection    | 301 Moved Permanently, 304 Not Modified          |
| 4xx   | Client error   | 400, 401 Unauthorized, 403, 404, 409, 422, 429   |
| 5xx   | Server error   | 500, 502 Bad Gateway, 503, 504 Gateway Timeout   |

### Headers you'll touch constantly

- `Content-Type`: `application/json`, `multipart/form-data`, `text/plain`
- `Accept`: what the client wants back
- `Authorization`: `Bearer <jwt>` or `Basic ...`
- `Cache-Control`, `ETag`, `If-None-Match`: caching
- `X-Requested-With`, `X-CSRF-Token`: security
- `Cookie` / `Set-Cookie`: session

---

## 2. The Fetch API in Depth

`fetch` is built into every modern browser and Node 18+. It returns a `Promise<Response>` that **only rejects on network errors** — HTTP 4xx/5xx still resolve, so you must check `response.ok` yourself.

### GET

```tsx
const res = await fetch('/api/users');
if (!res.ok) throw new Error(`HTTP ${res.status}`);
const users = await res.json();
```

### POST / PUT / PATCH with JSON body

```tsx
const res = await fetch('/api/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'Ada', email: 'ada@x.io' }),
  credentials: 'include', // send cookies cross-origin
});
```

### DELETE

```tsx
await fetch(`/api/users/${id}`, { method: 'DELETE' });
```

### Reading the response

| Method                | Returns                  |
|-----------------------|--------------------------|
| `res.json()`          | Parsed JSON object       |
| `res.text()`          | Raw string               |
| `res.blob()`          | `Blob` (images, files)   |
| `res.arrayBuffer()`   | Binary buffer            |
| `res.formData()`      | `FormData`               |
| `res.body`            | `ReadableStream` (chunks)|

### Streaming a response

```tsx
const res = await fetch('/api/log-stream');
const reader = res.body!.getReader();
const decoder = new TextDecoder();
while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  console.log(decoder.decode(value));
}
```

### Cancellation with `AbortController`

```tsx
const ctrl = new AbortController();
fetch('/api/slow', { signal: ctrl.signal });
ctrl.abort(); // throws DOMException 'AbortError' inside the fetch
```

---

## 3. The Classic `useEffect + fetch` Pattern

```tsx
function UserList() {
  const [data, setData]       = useState<User[] | null>(null);
  const [error, setError]     = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const ctrl = new AbortController();
    setLoading(true);
    fetch('/api/users', { signal: ctrl.signal })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then(setData)
      .catch(err => {
        if (err.name !== 'AbortError') setError(err);
      })
      .finally(() => setLoading(false));
    return () => ctrl.abort();
  }, []);

  if (loading) return <Spinner />;
  if (error)   return <p role="alert">{error.message}</p>;
  return <ul>{data!.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

---

## 4. Race Conditions

If a query parameter changes quickly (e.g. typing in a search box), responses can arrive **out of order** and the older one overwrites the newer one.

### Fix A — `AbortController`

```tsx
useEffect(() => {
  const ctrl = new AbortController();
  fetch(`/api/search?q=${q}`, { signal: ctrl.signal })
    .then(r => r.json()).then(setResults)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });
  return () => ctrl.abort();
}, [q]);
```

### Fix B — `ignore` flag (works even without abort support)

```tsx
useEffect(() => {
  let ignore = false;
  fetch(`/api/search?q=${q}`).then(r => r.json()).then(d => {
    if (!ignore) setResults(d);
  });
  return () => { ignore = true; };
}, [q]);
```

---

## 5. Axios

Axios is a small library that wraps XHR/fetch with a nicer API: automatic JSON, interceptors, request/response transforms, timeout, upload progress, and consistent error objects.

### Instance with defaults

```tsx
import axios from 'axios';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 10_000,
  headers: { 'X-Client': 'web' },
});
```

### Request & response interceptors

```tsx
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  res => res,
  async err => {
    if (err.response?.status === 401) { await refreshToken(); /* retry */ }
    return Promise.reject(err);
  },
);
```

### Error handling

```tsx
try {
  const { data } = await api.get<User>('/users/1');
} catch (e) {
  if (axios.isAxiosError(e)) {
    console.error(e.response?.status, e.response?.data);
  }
}
```

### Cancellation

Legacy `CancelToken` is deprecated. Use `AbortController` — axios v1 supports it natively:

```tsx
const ctrl = new AbortController();
api.get('/slow', { signal: ctrl.signal });
ctrl.abort();
```

### `transformRequest` / `transformResponse`

```tsx
api.defaults.transformResponse = [(data) => {
  const parsed = JSON.parse(data);
  return { ...parsed, fetchedAt: Date.now() };
}];
```

---

## 6. Fetch vs Axios

| Feature                    | Fetch                     | Axios                          |
|----------------------------|---------------------------|--------------------------------|
| Built-in                   | Yes                       | No (npm install)               |
| JSON parsing               | Manual `.json()`          | Automatic                      |
| HTTP error → reject        | No (`res.ok` check)       | Yes (rejects on 4xx/5xx)       |
| Request/response intercept | Manual wrapper            | First-class                    |
| Timeout                    | Manual via `AbortController` | `timeout` option            |
| Upload progress            | Via streams (hard)        | `onUploadProgress` callback    |
| Download progress          | Via `ReadableStream`      | `onDownloadProgress` callback  |
| Bundle size                | 0 KB                      | ~13 KB gzipped                 |
| Node support               | 18+ native                | Yes                            |

---

## 7. Custom Data Fetching Hooks

### `useFetch` — minimal, with cancellation & refetch

```tsx
export function useFetch<T>(url: string, opts?: RequestInit) {
  const [data, setData]       = useState<T | null>(null);
  const [error, setError]     = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);
  const [version, setVersion] = useState(0);

  useEffect(() => {
    const ctrl = new AbortController();
    setLoading(true);
    fetch(url, { ...opts, signal: ctrl.signal })
      .then(r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
      .then((d: T) => setData(d))
      .catch(e => { if (e.name !== 'AbortError') setError(e); })
      .finally(() => setLoading(false));
    return () => ctrl.abort();
  }, [url, version]);

  return { data, error, loading, refetch: () => setVersion(v => v + 1) };
}
```

### `useApi` — generic axios-based hook

```tsx
export function useApi<T>(config: AxiosRequestConfig, deps: unknown[] = []) {
  const [state, setState] = useState<{ data: T | null; error: unknown; loading: boolean }>({
    data: null, error: null, loading: true,
  });

  useEffect(() => {
    const ctrl = new AbortController();
    setState(s => ({ ...s, loading: true }));
    api.request<T>({ ...config, signal: ctrl.signal })
      .then(res => setState({ data: res.data, error: null, loading: false }))
      .catch(err => {
        if (!axios.isCancel(err))
          setState({ data: null, error: err, loading: false });
      });
    return () => ctrl.abort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  return state;
}
```

### `useAsync` — generic async runner

```tsx
type Status = 'idle' | 'pending' | 'success' | 'error';

export function useAsync<T, Args extends unknown[]>(fn: (...a: Args) => Promise<T>) {
  const [state, setState] = useState<{ status: Status; data?: T; error?: Error }>({ status: 'idle' });
  const run = useCallback(async (...args: Args) => {
    setState({ status: 'pending' });
    try   { setState({ status: 'success', data: await fn(...args) }); }
    catch (e) { setState({ status: 'error', error: e as Error }); }
  }, [fn]);
  return { ...state, run };
}
```

---

## 8. Caching, Deduplication, Stale-While-Revalidate

- **Caching**: keep a previous response and return it instantly on next request.
- **Deduplication**: if two components request `/api/user/1` at the same time, fire **one** network call and share the result.
- **Stale-While-Revalidate (SWR)**: serve cached data immediately (stale), then refetch in the background and update when fresh data arrives.

Implementing this by hand quickly turns into a library — which is exactly what TanStack Query and SWR are.

---

## 9. TanStack Query (React Query v5)

The de-facto standard for **server state** in React.

### Setup

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 2, refetchOnWindowFocus: true },
  },
});

<QueryClientProvider client={queryClient}>
  <App />
  <ReactQueryDevtools initialIsOpen={false} />
</QueryClientProvider>
```

### `useQuery`

```tsx
const { data, error, isLoading, isFetching, refetch } = useQuery({
  queryKey: ['user', userId],
  queryFn: ({ signal }) => api.get(`/users/${userId}`, { signal }).then(r => r.data),
  enabled: !!userId,         // dependent query
  staleTime: 60_000,         // ms before considered stale
  gcTime: 5 * 60_000,        // ms in cache after no observers (was cacheTime)
  refetchOnWindowFocus: false,
  retry: 3,
  select: (u) => ({ id: u.id, fullName: `${u.first} ${u.last}` }),
});
```

### `useMutation` + optimistic update + invalidation

```tsx
const qc = useQueryClient();

const toggleTodo = useMutation({
  mutationFn: (todo: Todo) => api.patch(`/todos/${todo.id}`, { done: !todo.done }),
  onMutate: async (todo) => {
    await qc.cancelQueries({ queryKey: ['todos'] });
    const prev = qc.getQueryData<Todo[]>(['todos']);
    qc.setQueryData<Todo[]>(['todos'], old =>
      old?.map(t => t.id === todo.id ? { ...t, done: !t.done } : t) ?? []);
    return { prev };
  },
  onError: (_e, _v, ctx) => qc.setQueryData(['todos'], ctx?.prev),
  onSettled: () => qc.invalidateQueries({ queryKey: ['todos'] }),
});
```

### `useInfiniteQuery`

```tsx
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
  queryKey: ['feed'],
  queryFn: ({ pageParam = 1, signal }) =>
    api.get(`/feed?page=${pageParam}`, { signal }).then(r => r.data),
  initialPageParam: 1,
  getNextPageParam: (last) => last.nextPage ?? undefined,
});
```

### Parallel & dependent queries

```tsx
const u = useQuery({ queryKey: ['user', id], queryFn: getUser });
const p = useQuery({
  queryKey: ['posts', u.data?.id],
  queryFn: () => getPosts(u.data!.id),
  enabled: !!u.data,
});
```

### Prefetching

```tsx
await queryClient.prefetchQuery({
  queryKey: ['user', id],
  queryFn: () => getUser(id),
});
```

Query cancellation works automatically when you accept a `signal` parameter and pass it to `fetch`/`axios`.

---

## 10. SWR — Brief Comparison

```tsx
const { data, error, isLoading, mutate } = useSWR('/api/user', fetcher);
```

| Aspect            | TanStack Query              | SWR (Vercel)                  |
|-------------------|-----------------------------|-------------------------------|
| Mental model      | Query/mutation/cache        | Key-based stale-while-revalidate |
| Mutations         | First-class `useMutation`   | Manual `mutate()`             |
| Devtools          | Excellent                   | Basic                         |
| Infinite queries  | `useInfiniteQuery`          | `useSWRInfinite`              |
| Bundle size       | Larger                      | Smaller                       |
| Best for          | Complex CRUD apps           | Simple read-heavy apps        |

---

## 11. Server State vs Client State

| Server state                        | Client state                  |
|-------------------------------------|-------------------------------|
| Owned by the server                 | Owned by the UI               |
| Asynchronous, can become stale      | Synchronous, always fresh     |
| Shared between users                | Local to a session            |
| Example: list of todos              | Example: which modal is open  |
| Tool: TanStack Query / SWR          | Tool: useState / Redux / Zustand |

Mixing them in one store (Redux) is the #1 cause of complexity in legacy React apps.

---

## 12. Error Handling Patterns

- **Error Boundaries**: catch render-time errors. Pair with `useQueryErrorResetBoundary`.
- **Retry with exponential backoff**: `retryDelay: attempt => Math.min(1000 * 2 ** attempt, 30_000)`.
- **User-friendly messages**: map status codes to UI strings (`401 → "Please sign in"`, `5xx → "Service unavailable"`).
- **Toast notifications** for non-blocking errors (e.g. `react-hot-toast`).
- **Global error handler** via `QueryCache({ onError })`.

---

## 13. Loading UX

- **Spinners** for short waits (<1 s).
- **Skeleton screens** for predictable shapes — feels faster than spinners.
- **`Suspense`** for declarative loading boundaries.
- **`useDeferredValue` / `useTransition`** to keep the UI responsive during expensive renders.

---

## 14. Pagination

### Offset

```tsx
useQuery({ queryKey: ['users', page], queryFn: () => api.get(`/users?page=${page}`) });
```

### Cursor

```tsx
useInfiniteQuery({
  queryKey: ['feed'],
  queryFn: ({ pageParam }) => api.get(`/feed?cursor=${pageParam ?? ''}`),
  initialPageParam: '',
  getNextPageParam: last => last.nextCursor,
});
```

### Infinite scroll with IntersectionObserver

```tsx
const sentinelRef = useRef<HTMLDivElement>(null);
useEffect(() => {
  const io = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting && hasNextPage && !isFetchingNextPage) fetchNextPage();
  });
  if (sentinelRef.current) io.observe(sentinelRef.current);
  return () => io.disconnect();
}, [hasNextPage, isFetchingNextPage, fetchNextPage]);
```

---

## 15. Polling and Real-Time

- **Polling**: `useQuery({ ..., refetchInterval: 5000 })`.
- **WebSockets**: open a socket, `qc.setQueryData` on each message to keep the cache in sync.
- **Server-Sent Events**: `new EventSource('/api/stream')` for one-way push.

---

## 16. Authentication Flows

```tsx
api.interceptors.request.use(cfg => {
  cfg.headers.Authorization = `Bearer ${getAccessToken()}`;
  return cfg;
});

let refreshing: Promise<string> | null = null;
api.interceptors.response.use(undefined, async (err) => {
  if (err.response?.status !== 401 || err.config._retry) throw err;
  err.config._retry = true;
  refreshing ??= refreshAccessToken().finally(() => { refreshing = null; });
  const newToken = await refreshing;
  err.config.headers.Authorization = `Bearer ${newToken}`;
  return api.request(err.config);
});
```

Key points: queue concurrent 401s onto a single refresh promise, mark `_retry` to avoid loops, log out on refresh failure.

---

## 17. File Upload Progress

### Axios

```tsx
await api.post('/files', formData, {
  onUploadProgress: e => setPct(Math.round((e.loaded / (e.total ?? 1)) * 100)),
});
```

### Fetch (no native progress; use streams)

```tsx
const stream = file.stream().pipeThrough(new TransformStream({
  transform(chunk, ctrl) { sent += chunk.length; setPct(sent / file.size * 100); ctrl.enqueue(chunk); },
}));
await fetch('/files', { method: 'POST', body: stream, duplex: 'half' });
```

---

## 18. React 18+ Suspense for Data & React 19 `use()`

```tsx
// React 19
function User({ promise }: { promise: Promise<User> }) {
  const user = use(promise);          // suspends until resolved
  return <h1>{user.name}</h1>;
}

<Suspense fallback={<Spinner />}>
  <User promise={getUser(1)} />
</Suspense>
```

`use()` works inside conditionals/loops (unlike other hooks), unwraps promises and contexts, and integrates with concurrent rendering.

---

## 19. TypeScript

```tsx
interface User { id: number; name: string; email: string }

async function getJson<T>(url: string, init?: RequestInit): Promise<T> {
  const r = await fetch(url, init);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json() as Promise<T>;
}

const user = await getJson<User>('/api/users/1');
```

### Runtime validation with zod

```tsx
import { z } from 'zod';
const UserSchema = z.object({ id: z.number(), name: z.string(), email: z.string().email() });
type User = z.infer<typeof UserSchema>;

const user = UserSchema.parse(await getJson('/api/users/1'));
```

Static types lie if the server lies — zod (or valibot) verifies at runtime.

---

## 20. Common Pitfalls

| Pitfall                                  | Symptom                                  | Fix                              |
|------------------------------------------|------------------------------------------|----------------------------------|
| Missing dep in `useEffect`               | Stale data after props change            | Add the dep / use a query lib    |
| Stale closure capturing old state        | Mutation uses outdated value             | Functional updater / refs        |
| No cancellation                          | Race conditions, memory leaks            | `AbortController`                |
| `JSON.parse` on empty / non-JSON body    | `Unexpected end of JSON input`           | Check `res.ok` and `content-type`|
| Double-invocation in StrictMode          | Two requests in dev                      | Idempotent effects + cancellation|
| Treating server state as client state    | Manual cache, bugs                       | Use TanStack Query               |
| Forgetting `credentials: 'include'`      | Cookies not sent cross-origin            | Set the option                   |

---

## 21. Testing Data Fetching with MSW

Mock Service Worker intercepts at the network layer, so your components run unchanged.

```tsx
// handlers.ts
import { http, HttpResponse } from 'msw';
export const handlers = [
  http.get('/api/users', () => HttpResponse.json([{ id: 1, name: 'Ada' }])),
  http.get('/api/users/error', () => new HttpResponse(null, { status: 500 })),
];

// setup
import { setupServer } from 'msw/node';
export const server = setupServer(...handlers);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Per-test override:

```tsx
server.use(http.get('/api/users', () => new HttpResponse(null, { status: 500 })));
```

---

## Key Takeaways

- `fetch` resolves on HTTP errors — always check `res.ok`.
- Always cancel in-flight requests on unmount or dep change to avoid races.
- Reach for **TanStack Query** the moment you have caching, refetching, or mutations — don't reinvent it.
- Treat **server state** as a separate beast from client state.
- Optimistic updates need a rollback path; pair them with invalidation on settle.
- Use `AbortController` everywhere — fetch, axios, and TanStack Query all support it.
- Validate API responses at runtime (zod) when types matter.
- Mock the network with **MSW** for realistic, resilient tests.
- StrictMode double-invokes effects in dev — your code must be idempotent.
- Skeletons + Suspense + `useDeferredValue` give a snappier UX than spinners alone.
