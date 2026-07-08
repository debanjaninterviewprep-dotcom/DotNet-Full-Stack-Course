# Topic 07: Data Fetching and HTTP — Interview Questions

---

## Q1. How do you fetch data in React with `useEffect`?
**Answer:**
```jsx
function UserList() {
  const [users, setUsers]   = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]   = useState(null);

  useEffect(() => {
    const controller = new AbortController();

    const fetchUsers = async () => {
      try {
        const res = await fetch('/api/users', { signal: controller.signal });
        if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        const data = await res.json();
        setUsers(data);
      } catch (err) {
        if (err.name !== 'AbortError') setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
    return () => controller.abort(); // cleanup: cancel on unmount
  }, []); // empty deps = fetch on mount

  if (loading) return <Spinner />;
  if (error)   return <ErrorMessage message={error} />;
  return <UserTable users={users} />;
}
```

---

## Q2. What is the race condition problem in data fetching?
**Answer:**
A race condition occurs when multiple requests are in-flight simultaneously and responses arrive out of order:

```jsx
// Problem: user changes userId quickly
// Request 1 (/users/1) starts → Request 2 (/users/2) starts → Request 2 resolves first
// → shows user 2, then Request 1 resolves → overwrites with user 1 (wrong!)
useEffect(() => {
  fetch(`/api/users/${userId}`).then(r => r.json()).then(setUser);
}, [userId]); // ❌ race condition

// Solution 1: AbortController — cancel previous request
useEffect(() => {
  const controller = new AbortController();
  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(r => r.json()).then(setUser)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });
  return () => controller.abort(); // ✓ cancels previous request
}, [userId]);

// Solution 2: Ignore stale results
useEffect(() => {
  let active = true;
  fetch(`/api/users/${userId}`).then(r => r.json()).then(data => {
    if (active) setUser(data); // ✓ only update if still the latest request
  });
  return () => { active = false; };
}, [userId]);
```

---

## Q3. What is TanStack Query (React Query) and why is it popular?
**Answer:**
TanStack Query is a data fetching and caching library that eliminates manual loading/error/cache state management:

```jsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// useQuery — fetch and cache data
function UserDetail({ id }) {
  const { data: user, isLoading, isError, error } = useQuery({
    queryKey: ['user', id],           // cache key
    queryFn: () => fetchUser(id),     // fetch function
    staleTime: 5 * 60 * 1000,         // 5 min — don't refetch if fresh
    retry: 3                          // retry failed requests 3 times
  });

  if (isLoading) return <Spinner />;
  if (isError)   return <p>Error: {error.message}</p>;
  return <UserCard user={user} />;
}

// useMutation — create/update/delete
function DeleteButton({ userId }) {
  const queryClient = useQueryClient();
  const mutation = useMutation({
    mutationFn: (id) => deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] }); // refetch list
    }
  });
  return <button onClick={() => mutation.mutate(userId)}>Delete</button>;
}
```

---

## Q4. What does TanStack Query provide out of the box?
**Answer:**
| Feature | Manual `useEffect` | TanStack Query |
|---|---|---|
| Loading state | Manual | ✓ Automatic |
| Error handling | Manual | ✓ Automatic |
| Caching | Manual | ✓ Automatic (staleTime, gcTime) |
| Background refetch | Manual | ✓ On window focus, network reconnect |
| Request deduplication | Manual | ✓ Same key = one request |
| Optimistic updates | Complex | ✓ Built-in |
| Pagination | Manual | ✓ `useInfiniteQuery` |
| Retry | Manual | ✓ Configurable |
| DevTools | None | ✓ React Query Devtools |

---

## Q5. What is axios and how does it differ from `fetch`?
**Answer:**
| | `fetch` | `axios` |
|---|---|---|
| **Built-in?** | Yes (browser + Node 18+) | No — npm package |
| **JSON auto-parse** | Manual (`.json()`) | ✓ Automatic |
| **Error on 4xx/5xx** | ✗ Only on network failure | ✓ Throws on bad status |
| **Request cancellation** | AbortController | CancelToken + AbortController |
| **Interceptors** | ✗ | ✓ Built-in |
| **Request timeout** | Manual | ✓ `timeout` option |
| **Upload progress** | Manual | ✓ `onUploadProgress` |

```jsx
// Fetch — manual JSON parsing + error handling
const res = await fetch('/api/users');
if (!res.ok) throw new Error(res.statusText);
const data = await res.json();

// Axios — cleaner
const { data } = await axios.get('/api/users');

// Axios instance with base URL and interceptors
const api = axios.create({ baseURL: '/api', timeout: 10000 });
api.interceptors.request.use(cfg => {
  cfg.headers.Authorization = `Bearer ${getToken()}`;
  return cfg;
});
```

---

## Q6. What is SWR and how does it compare to React Query?
**Answer:**
SWR (stale-while-revalidate) is Vercel's lighter data fetching library:

```jsx
import useSWR from 'swr';

const fetcher = (url) => fetch(url).then(r => r.json());

function UserProfile() {
  const { data, error, isLoading } = useSWR('/api/user', fetcher, {
    revalidateOnFocus: true,       // refetch when window gains focus
    refreshInterval: 30000,        // poll every 30s
    dedupingInterval: 2000,        // deduplicate same key requests within 2s
  });
  if (isLoading) return <Spinner />;
  if (error)     return <p>Error</p>;
  return <p>{data.name}</p>;
}
```

**SWR vs React Query:**
- SWR is simpler and lighter — good for read-heavy apps.
- React Query is more feature-rich — better for mutations, complex caching, optimistic updates.

---

## Q7. What is infinite scrolling / pagination with React Query?
**Answer:**
```jsx
import { useInfiniteQuery } from '@tanstack/react-query';

function InfiniteUserList() {
  const {
    data, fetchNextPage, hasNextPage, isFetchingNextPage
  } = useInfiniteQuery({
    queryKey: ['users'],
    queryFn: ({ pageParam = 1 }) => fetchUsers({ page: pageParam, limit: 20 }),
    getNextPageParam: (lastPage, pages) => lastPage.hasMore ? pages.length + 1 : undefined
  });

  // Intersection Observer to auto-load next page
  const loaderRef = useRef(null);
  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => { if (entries[0].isIntersecting && hasNextPage) fetchNextPage(); }
    );
    if (loaderRef.current) observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [hasNextPage, fetchNextPage]);

  return (
    <>
      {data?.pages.flatMap(page => page.users).map(u => <UserCard key={u.id} user={u} />)}
      <div ref={loaderRef}>{isFetchingNextPage && <Spinner />}</div>
    </>
  );
}
```

---

## Q8. What is optimistic updating?
**Answer:**
Update the UI immediately before the server responds — roll back if the request fails:

```jsx
const queryClient = useQueryClient();

const updateUser = useMutation({
  mutationFn: (updatedUser) => axios.put(`/api/users/${updatedUser.id}`, updatedUser),

  onMutate: async (updatedUser) => {
    await queryClient.cancelQueries({ queryKey: ['users'] }); // cancel outgoing refetches
    const previousUsers = queryClient.getQueryData(['users']); // snapshot

    // Optimistically update
    queryClient.setQueryData(['users'], old =>
      old.map(u => u.id === updatedUser.id ? updatedUser : u)
    );

    return { previousUsers }; // context for rollback
  },

  onError: (err, _, context) => {
    queryClient.setQueryData(['users'], context.previousUsers); // rollback
  },

  onSettled: () => {
    queryClient.invalidateQueries({ queryKey: ['users'] }); // refetch to sync
  }
});
```

---

## Q9. How do you handle authentication tokens in HTTP requests?
**Answer:**
```jsx
// Approach 1: axios interceptor
const api = axios.create({ baseURL: import.meta.env.VITE_API_URL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  response => response,
  async (error) => {
    if (error.response?.status === 401) {
      // try refresh token
      const newToken = await refreshToken();
      if (newToken) {
        error.config.headers.Authorization = `Bearer ${newToken}`;
        return api.request(error.config); // retry
      }
      logout();
    }
    return Promise.reject(error);
  }
);

// Approach 2: React Query default query function
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: ({ queryKey }) =>
        api.get(queryKey[0]).then(r => r.data) // use api instance with interceptors
    }
  }
});
```

---

## Q10. What is the Suspense boundary for data fetching?
**Answer:**
React Suspense allows components to suspend rendering while data loads — requires a data-fetching library that supports it:

```jsx
// With React Query (suspense mode)
const { data } = useSuspenseQuery({
  queryKey: ['user', id],
  queryFn: () => fetchUser(id)
});
// No isLoading check needed — component suspends until data is ready

// Wrap in Suspense boundary
function App() {
  return (
    <Suspense fallback={<UserSkeleton />}>
      <ErrorBoundary fallback={<ErrorPage />}>
        <UserProfile id={1} />  {/* suspends until data loads */}
      </ErrorBoundary>
    </Suspense>
  );
}
```

---

## Q11. What is an Error Boundary and why is it needed for data fetching?
**Answer:**
Error Boundaries catch JavaScript errors in the component tree and display fallback UI instead of crashing:

```jsx
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div>
      <p>Something went wrong: {error.message}</p>
      <button onClick={resetErrorBoundary}>Try Again</button>
    </div>
  );
}

function App() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback} onReset={() => queryClient.clear()}>
      <Suspense fallback={<Spinner />}>
        <DataDrivenComponent />
      </Suspense>
    </ErrorBoundary>
  );
}
```

**Important:** Error Boundaries only catch render errors and Suspense errors — not errors in event handlers or async code (those need try/catch).

---

## Q12. What is polling and how do you implement it?
**Answer:**
Polling repeatedly fetches data at a fixed interval to simulate real-time updates:

```jsx
// Manual polling with useEffect
function LivePrice({ symbol }) {
  const [price, setPrice] = useState(null);

  useEffect(() => {
    const fetchPrice = () => fetch(`/api/price/${symbol}`).then(r => r.json()).then(setPrice);
    fetchPrice(); // immediate fetch on mount
    const id = setInterval(fetchPrice, 5000); // then every 5 seconds
    return () => clearInterval(id);
  }, [symbol]);

  return <span>{price}</span>;
}

// With React Query — refreshInterval option
const { data } = useQuery({
  queryKey: ['price', symbol],
  queryFn: () => fetchPrice(symbol),
  refetchInterval: 5000,             // poll every 5s
  refetchIntervalInBackground: false // only when tab is active
});
```

---

## Q13. What is WebSocket integration in React?
**Answer:**
```jsx
function useWebSocket(url) {
  const [messages, setMessages] = useState([]);
  const wsRef = useRef(null);

  useEffect(() => {
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen    = () => console.log('Connected');
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      setMessages(prev => [...prev, msg]);
    };
    ws.onerror   = (err) => console.error('WS Error:', err);
    ws.onclose   = () => console.log('Disconnected');

    return () => ws.close(); // cleanup on unmount
  }, [url]);

  const send = useCallback((data) => {
    if (wsRef.current?.readyState === WebSocket.OPEN)
      wsRef.current.send(JSON.stringify(data));
  }, []);

  return { messages, send };
}

// Usage
function Chat() {
  const { messages, send } = useWebSocket('wss://chat.example.com');
  return (
    <>
      {messages.map((m, i) => <p key={i}>{m.text}</p>)}
      <button onClick={() => send({ text: 'Hello!' })}>Send</button>
    </>
  );
}
```

---

## Q14. What is the stale-while-revalidate caching strategy?
**Answer:**
Stale-While-Revalidate (SWR) serves **stale (cached) data immediately** while fetching fresh data in the background:

```
1. User visits page → show cached data instantly (no loading spinner)
2. Simultaneously fetch fresh data from server
3. When fresh data arrives → update UI silently
```

```jsx
// React Query implements SWR via staleTime
useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
  staleTime: 5 * 60 * 1000, // data is "fresh" for 5 minutes
  // After 5 min: data is "stale" — show immediately but refetch in background
  gcTime: 10 * 60 * 1000    // remove from cache after 10 min of inactivity
});
```

Benefits: instant navigation (no loading states), always eventually consistent, great for UX.

---

## Q15. How do you handle concurrent requests with `Promise.all`?
**Answer:**
```jsx
// Fetch multiple resources simultaneously
function Dashboard() {
  const [state, setState] = useState({ users: [], products: [], stats: null, loading: true });

  useEffect(() => {
    const controller = new AbortController();
    const { signal } = controller;

    Promise.all([
      fetch('/api/users',    { signal }).then(r => r.json()),
      fetch('/api/products', { signal }).then(r => r.json()),
      fetch('/api/stats',    { signal }).then(r => r.json())
    ])
      .then(([users, products, stats]) => setState({ users, products, stats, loading: false }))
      .catch(err => { if (err.name !== 'AbortError') setState(prev => ({ ...prev, loading: false, error: err.message })); });

    return () => controller.abort();
  }, []);

  // With React Query — cleaner
  const [usersQ, productsQ, statsQ] = useQueries({
    queries: [
      { queryKey: ['users'],    queryFn: fetchUsers },
      { queryKey: ['products'], queryFn: fetchProducts },
      { queryKey: ['stats'],    queryFn: fetchStats }
    ]
  });
}
```
