# Topic 10: Performance & Optimization — Practice Problems

> Five progressive problems. Each requires you to **measure before and after** with the React DevTools Profiler and/or Chrome Performance tab. "It feels faster" is not an answer — record numbers.

---

## Problem 1 — Profile a Slow List & Fix With `React.memo` + `useCallback` (Easy)

**Concept tag:** `React.memo` · `useCallback` · Profiler

Given a list of 500 contacts, every keystroke in an unrelated header search box re-renders every row. Find why and fix it.

### Requirements

- Open the React DevTools Profiler. Record one keystroke. Note: total commit duration, number of `<Row>` instances rendered, and the "Why did this render?" reason for each.
- Wrap `<Row>` with `React.memo`.
- Stabilize any callback props (`onSelect`, `onDelete`) using `useCallback`.
- Stabilize any inline-object props using `useMemo` or by hoisting constants.
- Re-record. The header keystroke must produce **0** `<Row>` re-renders.

### Before / After expectations

| Metric                               | Before     | After   |
| ------------------------------------ | ---------- | ------- |
| `<Row>` renders per keystroke        | 500        | **0**   |
| Commit duration (mid-tier laptop)    | ~30–60 ms  | < 5 ms  |
| Header input feels                   | janky      | instant |

### Starter

```tsx
function App() {
  const [query, setQuery] = useState('')
  const [contacts, setContacts] = useState(seed())

  // BUG: inline arrow → new ref every render
  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <ul>
        {contacts.map(c => (
          <Row
            key={c.id}
            contact={c}
            onSelect={(id) => console.log(id)}
          />
        ))}
      </ul>
    </>
  )
}

function Row({ contact, onSelect }) {
  return <li onClick={() => onSelect(contact.id)}>{contact.name}</li>
}
```

---

## Problem 2 — Debounced Search with `useDeferredValue` + `useTransition` (Easy-Medium)

**Concept tag:** Concurrent React · `useDeferredValue` · `useTransition` · `useDebounce`

Build a typeahead over 5,000 records. Typing must remain at 60 fps even when the result list is expensive to render (artificially slow each row by ~0.5 ms).

### Requirements

- Implement a `useDebounce(value, ms)` hook (300 ms) for the API-call key.
- Use `useDeferredValue` so the visible input never lags behind keystrokes.
- Wrap any state update that triggers a heavy re-filter in `startTransition`; show an "Updating…" indicator while `isPending`.
- Highlight matched substrings in each result row.
- Cancel inflight network requests with `AbortController` when the query changes.

### Before / After expectations

| Metric                             | Before      | After                           |
| ---------------------------------- | ----------- | ------------------------------- |
| INP while typing fast              | > 500 ms    | < 200 ms                        |
| Long tasks during typing           | many        | none on the input update path   |
| Network requests in flight         | unbounded   | only the latest is kept         |

### Starter

```tsx
function Search() {
  const [query, setQuery] = useState('')
  // 1. const debouncedKey = useDebounce(query, 300)
  // 2. const deferredQuery = useDeferredValue(query)
  // 3. const [isPending, startTransition] = useTransition()
  // 4. fetch on debouncedKey, render results filtered by deferredQuery
  return null
}
```

---

## Problem 3 — Virtualize a 10,000-Row Sortable, Filterable Table (Medium)

**Concept tag:** Virtualization · `react-window` · TanStack Table

Render a 10,000-row table of orders (id, customer, total, status, createdAt). Without virtualization the page freezes for seconds on mount. Make it instant.

### Requirements

- Use `react-window`'s `FixedSizeList` (or `VariableSizeList` if rows wrap) to render only visible rows.
- A sticky header with click-to-sort on every column.
- A free-text filter input across all string columns; a status dropdown filter.
- Sorting/filtering must be memoized (`useMemo`) so re-keying doesn't re-sort.
- Keyboard accessible (focusable rows, Up/Down/PageUp/PageDown).
- Optional: integrate `@tanstack/react-table` for the model layer + `react-window` for the view.

### Before / After expectations

| Metric                          | Before      | After             |
| ------------------------------- | ----------- | ----------------- |
| Initial mount time              | ~2–4 s      | < 100 ms          |
| Scroll FPS                      | < 20        | ~60               |
| DOM nodes for the table         | 10,000+     | ~30 (window size) |
| Sort/filter latency             | > 500 ms    | < 50 ms           |

### Starter

```tsx
import { FixedSizeList } from 'react-window'

function OrdersTable({ orders }: { orders: Order[] }) {
  // 1. const [sort, setSort] = useState<SortState>(...)
  // 2. const [filter, setFilter] = useState('')
  // 3. const visible = useMemo(() => sortAndFilter(orders, sort, filter),
  //                            [orders, sort, filter])
  // 4. <FixedSizeList itemCount={visible.length} itemSize={36} ...>
  return null
}
```

---

## Problem 4 — Code-Split a Dashboard with Route Lazy Loading (Medium-Hard)

**Concept tag:** `React.lazy` · `Suspense` · Bundle analysis · Skeletons

You inherit a 1.4 MB single-bundle dashboard. Routes: `/`, `/analytics` (uses Recharts), `/editor` (uses Monaco), `/settings`. The user almost always lands on `/` first.

### Requirements

- Run `vite-bundle-visualizer` (or `source-map-explorer` for CRA). Screenshot/record initial bundle composition.
- Convert each route to `React.lazy(() => import('./routes/...'))`.
- Wrap the routed area in `<Suspense fallback={<RouteSkeleton />}>`. Each route gets a skeleton matching its layout (don't show a generic spinner).
- Preload the analytics chunk on hover of the `/analytics` link (`<link rel="prefetch">` or `import('./routes/Analytics')`).
- Add an Error Boundary around `<Suspense>` so a failed chunk download shows a "Reload" button.
- Re-run the bundle analyzer. Document chunk sizes.

### Before / After expectations

| Metric                              | Before    | After                                     |
| ----------------------------------- | --------- | ----------------------------------------- |
| Initial JS (gzipped)                | ~450 KB   | < 150 KB for `/`                          |
| Number of chunks                    | 1         | ≥ 4 (vendor + per-route)                  |
| LCP on `/` (slow 3G simulated)      | > 6 s     | < 3 s                                     |
| Monaco/Recharts loaded on `/`       | yes       | **no** (only when their route is opened)  |

### Starter

```tsx
import { lazy, Suspense } from 'react'
import { Routes, Route } from 'react-router-dom'

const Home      = lazy(() => import('./routes/Home'))
const Analytics = lazy(() => import('./routes/Analytics'))
const Editor    = lazy(() => import('./routes/Editor'))
const Settings  = lazy(() => import('./routes/Settings'))

export function App() {
  return (
    <ErrorBoundary>
      <Suspense fallback={<RouteSkeleton />}>
        <Routes>
          <Route path="/"          element={<Home />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/editor"    element={<Editor />} />
          <Route path="/settings"  element={<Settings />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  )
}
```

---

## Problem 5 — Optimize a Real-World Feed App (Hard)

**Concept tag:** Image optimization · Infinite scroll virtualization · Web Workers · Performance budgets

Build (or fix) a Twitter-like feed that loads pages of posts (each with a user avatar, an image, and text). With 1,000+ posts loaded, scrolling janks, the heap grows unboundedly, and a client-side keyword filter blocks the main thread for seconds.

### Requirements

1. **Image optimization**
   - All `<img>` use `loading="lazy"` and `decoding="async"`.
   - Avatars served as WebP with `width`/`height` set to prevent CLS.
   - Hero post images use `srcset` + `sizes` for responsive delivery.
   - Show a blurhash (or solid color) placeholder until the image decodes.

2. **Infinite scroll + virtualization**
   - Use `IntersectionObserver` (or `@tanstack/react-virtual`) to load the next page when the user is ~3 screens from the bottom.
   - Virtualize the feed (variable row heights) so DOM nodes stay bounded regardless of how far the user has scrolled.
   - Recycle/discard data that is far above the viewport (or keep but ensure DOM is unmounted).

3. **Web worker for filtering**
   - Move the keyword/filter computation into a Web Worker (use **Comlink** for ergonomics).
   - Debounce the filter input (250 ms) before posting to the worker.
   - Worker must be terminated on unmount.

4. **Performance budgets (validate in CI)**
   - Initial JS ≤ 170 KB gzipped.
   - LCP ≤ 2.5 s on simulated Fast 3G + 4× CPU throttle.
   - INP ≤ 200 ms while scrolling and typing in the filter box.
   - CLS ≤ 0.05.
   - Add a Lighthouse CI step (or `lighthouse --budget-path budget.json`) failing the build if any budget is exceeded.

5. **Monitoring**
   - Wire `web-vitals` to send LCP/INP/CLS to a (mock) `/metrics` endpoint.

### Before / After expectations

| Metric                                          | Before          | After              |
| ----------------------------------------------- | --------------- | ------------------ |
| DOM nodes after scrolling 100 pages             | 50,000+         | < 500              |
| Heap size growth                                | unbounded       | flat               |
| Filter input INP                                | > 1,000 ms      | < 200 ms           |
| Main-thread blocked by filter                   | yes (seconds)   | no (worker)        |
| LCP on first load (Fast 3G + 4× CPU)            | > 6 s           | < 2.5 s            |
| Lighthouse Performance score                    | ~40             | ≥ 90               |

### Hints

```ts
// worker.ts
import * as Comlink from 'comlink'
const api = {
  filter(posts: Post[], query: string) {
    const q = query.toLowerCase()
    return posts.filter(p => p.text.toLowerCase().includes(q))
  },
}
Comlink.expose(api)
```

```tsx
// useWorker.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url), { type: 'module' })
const api = Comlink.wrap<typeof import('./worker').default>(worker)
const filtered = await api.filter(posts, debouncedQuery)
```

---

## Submission Checklist

- [ ] Profiler recordings (or screenshots) for **before** and **after** every problem.
- [ ] Numbers in a table — no vague "feels faster".
- [ ] Bundle analyzer output for Problem 4 and Problem 5.
- [ ] Lighthouse report for Problem 5 (mobile, throttled).
- [ ] All effects clean up on unmount (no leaked workers, observers, fetches).
