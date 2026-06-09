# Topic 10: Performance & Optimization

> "Premature optimization is the root of all evil." — Knuth. In React, this is doubly true: most apps are fast enough without `memo`/`useMemo`/`useCallback`. **Measure first, then optimize.**

---

## 1. The React Rendering Model (Recap)

React work happens in two phases:

| Phase      | What happens                                                                                | Side effects? |
| ---------- | ------------------------------------------------------------------------------------------- | ------------- |
| **Render** | React calls your components, builds a new virtual DOM (Fiber tree), diffs vs previous tree. | No — pure     |
| **Commit** | React applies DOM mutations, runs refs, then `useLayoutEffect`, then `useEffect`.           | Yes           |

**Reconciliation** is the diffing algorithm. **Fiber** is the data structure that represents the tree as a linked list of work units, allowing React to pause, resume, and prioritize rendering (the foundation of concurrent features).

### When does a component re-render?

A component re-renders when **any** of the following happens:

1. Its **state** changes (`useState`, `useReducer`).
2. Its **parent re-renders** (default cascade — props changing is *not* required).
3. A **context** it consumes changes value.
4. A **subscribed external store** (`useSyncExternalStore`) emits.

> Misconception: "Components only re-render when props change." False. By default, a parent re-render re-renders all children, regardless of whether their props are referentially equal.

---

## 2. Common Causes of Unnecessary Re-renders

- **Parent re-renders** cascading down (the #1 cause).
- **New object/array/function references** created inline on every render — break `React.memo` and dependency arrays.
- **Context value identity changes** — every consumer re-renders, even if they only read one field.
- **State lifted too high** — a high-level state change re-renders the entire subtree.
- **Inline component definitions** (`function Inner() {}` inside the parent body) — re-created each render, identity changes, child re-mounts and loses state.

```tsx
// BAD: new object literal each render breaks memo
<Child config={{ size: 10 }} />

// BAD: Inner is redefined every render → all descendants remount
function Parent() {
  function Inner() { return <div /> } // ← move this OUT
  return <Inner />
}
```

---

## 3. Measuring: React DevTools Profiler

Install React DevTools (browser extension). Open the **Profiler** tab.

1. Click the record (●) button.
2. Interact with the app (click, type, scroll).
3. Click stop. You get one **commit** per recorded render.

**Views:**

| View              | Use it for                                                                          |
| ----------------- | ----------------------------------------------------------------------------------- |
| **Flame graph**   | See the component tree for one commit. Width = time spent rendering that component. |
| **Ranked chart**  | Same data sorted by render time — fastest way to spot the heaviest component.       |
| **Timeline**      | Shows commits across time, scheduled work, suspense, transitions (React 18+).       |
| **Component**     | Inspect props/state/hooks of any component live.                                    |

Enable **"Record why each component rendered"** in Profiler settings — invaluable for finding stale-prop / context-induced re-renders.

---

## 4. Browser Performance Tools

- **Chrome DevTools → Performance tab**: low-level CPU/main-thread flame chart, layout/paint, long tasks (>50ms).
- **Lighthouse**: automated audit of performance, accessibility, best practices, SEO.
- **Web Vitals** — Google's user-experience metrics:

| Metric   | Meaning                                                  | Good     | Poor    |
| -------- | -------------------------------------------------------- | -------- | ------- |
| **LCP**  | Largest Contentful Paint — when main content is visible. | ≤ 2.5 s  | > 4.0 s |
| **INP**  | Interaction to Next Paint (replaced FID in 2024).        | ≤ 200 ms | > 500 ms |
| **CLS**  | Cumulative Layout Shift — visual stability.              | ≤ 0.1    | > 0.25  |
| **TTFB** | Time to First Byte — server response speed.              | ≤ 0.8 s  | > 1.8 s |

- **`web-vitals` npm package** — measure in production and report to analytics.
- **React Scan** — paints a colored highlight around components that re-render, with no setup. Great for live debugging.

---

## 5. `React.memo` — Skipping Re-renders

`React.memo` wraps a component and **shallow-compares** new props vs previous. If equal, React skips the render.

```tsx
const Row = React.memo(function Row({ user, onSelect }: Props) {
  return <li onClick={() => onSelect(user.id)}>{user.name}</li>
})

// Custom comparator (rare):
const Heavy = React.memo(Heavy, (prev, next) => prev.id === next.id)
```

**When it helps:** the component renders often with the same props, and rendering is non-trivial.

**When it doesn't:** the parent passes a new object/function ref every render — shallow comparison fails, memo is wasted CPU. Pair with `useMemo`/`useCallback` or move state down.

---

## 6. `useMemo` — Memoizing Values

```tsx
const sorted = useMemo(
  () => bigList.sort((a, b) => a.score - b.score),
  [bigList],
)
```

**Use it for:**
- Expensive computations (sorting/filtering thousands of items, parsing).
- Stable object/array refs passed to memoized children or used in deps arrays.

**Common misuse:** memoizing primitives or trivially cheap expressions. The bookkeeping costs more than the work.

```tsx
// USELESS:
const total = useMemo(() => a + b, [a, b])
```

---

## 7. `useCallback` — Stable Function References

```tsx
const handleSelect = useCallback(
  (id: string) => setSelected(id),
  [],
)
```

**Use it when:**
1. The function is passed as a prop to a `React.memo`-wrapped child.
2. The function is a dependency of `useEffect` / `useMemo` / `useCallback`.

Otherwise it's noise. A regular function declaration is faster than `useCallback`.

---

## 8. The Rule

> **Don't memoize first. Profile, identify the bottleneck, then memoize.**

Order of operations:
1. Build it simply.
2. If it feels slow, open the Profiler.
3. Find the hot path.
4. Apply the smallest fix (state colocation > memo > virtualization > algorithm change).

---

## 9. React Compiler ("Forget")

The React Compiler is an opt-in build-time tool (stable in 2024+) that auto-memoizes components and values. With it enabled, manual `useMemo`/`useCallback`/`React.memo` become largely unnecessary. Configure via Babel/SWC plugin and the `react-compiler` ESLint rule.

---

## 10. Keys — The Silent Performance Bug

Keys must be **stable, unique, and predictable**.

```tsx
// BAD: index as key when list reorders/inserts/deletes
{items.map((it, i) => <Row key={i} item={it} />)}

// GOOD:
{items.map(it => <Row key={it.id} item={it} />)}
```

With index keys, inserting at the front causes React to think every row's data changed → re-renders all rows, loses input focus, breaks animations.

Index keys are OK only when the list is **static, append-only, and items have no internal state**.

---

## 11. List Virtualization

Render only the rows visible in the viewport. Essential for >1000 items.

Libraries: **`react-window`** (small, simple), **`react-virtualized`** (older, heavier), **TanStack Virtual** (headless, flexible).

```tsx
import { FixedSizeList } from 'react-window'

function BigList({ items }: { items: string[] }) {
  return (
    <FixedSizeList
      height={500}
      itemCount={items.length}
      itemSize={32}
      width="100%"
    >
      {({ index, style }) => (
        <div style={style}>{items[index]}</div>
      )}
    </FixedSizeList>
  )
}
```

For variable heights use `VariableSizeList`. For grids, `FixedSizeGrid`.

---

## 12. Lazy Loading & Code Splitting

```tsx
import { lazy, Suspense } from 'react'

const Settings = lazy(() => import('./Settings'))

<Suspense fallback={<Skeleton />}>
  <Settings />
</Suspense>
```

**Strategies:**

| Strategy            | Where to split                                | Trade-off                                |
| ------------------- | --------------------------------------------- | ---------------------------------------- |
| **Route-based**     | One chunk per route.                          | Easy, big wins. Default for most apps.   |
| **Component-based** | Modal, drawer, chart, rich editor.            | Defers heavy code until user opens it.   |
| **Vendor splitting**| Separate `node_modules` from app code.        | Long-term caching: vendor bundle stable. |

Dynamic imports work for libraries too:

```tsx
async function openEditor() {
  const { default: Editor } = await import('@monaco-editor/react')
  // ...
}
```

---

## 13. Bundle Analysis

| Tool                          | Stack         | Output                                         |
| ----------------------------- | ------------- | ---------------------------------------------- |
| `source-map-explorer`         | Any           | Treemap of bundle by source file.              |
| `vite-bundle-visualizer`      | Vite          | Rollup-based interactive treemap.              |
| `webpack-bundle-analyzer`     | Webpack/CRA   | Hover boxes showing parsed/gzip/raw sizes.     |
| `rollup-plugin-visualizer`    | Rollup/Vite   | HTML treemap.                                  |

Look for: duplicated libs, full lodash imports, moment.js, large polyfills, accidentally bundled dev tooling.

---

## 14. Tree Shaking

ES modules (`import`/`export`) let bundlers eliminate unused exports. Pitfalls:

- **CommonJS** (`require`) modules cannot be tree-shaken.
- **`sideEffects: false`** in `package.json` tells the bundler the package is pure (or list specific files: `"sideEffects": ["./src/polyfill.js", "*.css"]`).
- Import **specific symbols**, not whole namespaces:

```tsx
// BAD
import _ from 'lodash'
// GOOD
import debounce from 'lodash/debounce'
// BEST
import { debounce } from 'lodash-es'
```

---

## 15. Image Optimization

```html
<img src="hero.webp" loading="lazy" decoding="async" width="800" height="450"
     srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1600.webp 1600w"
     sizes="(max-width: 600px) 100vw, 800px"
     alt="..." />
```

- `loading="lazy"` — defer offscreen images.
- `srcset` + `sizes` — responsive images.
- Modern formats: **WebP** (~30% smaller than JPEG), **AVIF** (~50% smaller).
- `<picture>` — art direction / format fallbacks.
- **Blurhash / LQIP** — show a tiny blurred placeholder while the full image loads.
- Always set `width`/`height` to prevent CLS.

---

## 16. Font Optimization

```html
<link rel="preload" as="font" type="font/woff2" href="/inter.woff2" crossorigin />
```

```css
@font-face {
  font-family: 'Inter';
  src: url(/inter.woff2) format('woff2');
  font-display: swap; /* show fallback immediately, swap when loaded */
}
```

- **Subset** fonts to the characters you use (latin only, etc.).
- Use **variable fonts** to ship one file for many weights.
- `font-display: swap` avoids invisible text (FOIT).

---

## 17. Inline Objects/Functions — When It Matters

Inline allocations are fine **most** of the time. They matter when:

- Passed as a prop to a `React.memo` child.
- Used as a `useEffect` dependency.
- Inside a hot loop with thousands of items.

For a button onClick on a single component, `() => doX()` is perfectly fine. Don't over-optimize.

---

## 18. Debounce & Throttle

```tsx
// useDebounce — return a value that updates only after `delay` ms of quiet
import { useEffect, useState } from 'react'

export function useDebounce<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(id)
  }, [value, delay])
  return debounced
}
```

```tsx
// useThrottle — limit invocations to once per `delay` ms
import { useRef, useCallback } from 'react'

export function useThrottle<A extends unknown[]>(
  fn: (...args: A) => void,
  delay = 200,
) {
  const last = useRef(0)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)

  return useCallback((...args: A) => {
    const now = Date.now()
    const remaining = delay - (now - last.current)
    if (remaining <= 0) {
      last.current = now
      fn(...args)
    } else if (!timer.current) {
      timer.current = setTimeout(() => {
        last.current = Date.now()
        timer.current = null
        fn(...args)
      }, remaining)
    }
  }, [fn, delay])
}
```

| Technique  | Behavior                                              | Use for                       |
| ---------- | ----------------------------------------------------- | ----------------------------- |
| Debounce   | Wait until events stop, then fire once.               | Search input, autosave.       |
| Throttle   | Fire at most once per interval, regardless of bursts. | Scroll, mousemove, resize.    |

---

## 19. Concurrent React: `useDeferredValue` & `useTransition`

```tsx
// Typeahead: the input stays snappy, the heavy list lags behind.
function Typeahead() {
  const [query, setQuery] = useState('')
  const deferredQuery = useDeferredValue(query)
  const isStale = query !== deferredQuery

  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <div style={{ opacity: isStale ? 0.5 : 1 }}>
        <Results query={deferredQuery} />
      </div>
    </>
  )
}
```

```tsx
function Tabs() {
  const [tab, setTab] = useState('home')
  const [isPending, startTransition] = useTransition()

  function select(next: string) {
    startTransition(() => setTab(next)) // marks update as non-urgent
  }
  return (
    <>
      <Buttons onSelect={select} />
      {isPending && <Spinner />}
      <TabPanel name={tab} />
    </>
  )
}
```

- **`useDeferredValue(value)`** — returns a "lagging" copy; React re-renders eagerly with the old value, then catches up.
- **`useTransition`** — marks state updates as non-urgent so urgent updates (typing, clicks) interrupt them.
- **`startTransition`** — same, outside a component.

---

## 20. `useId`

```tsx
const id = useId()
return <><label htmlFor={id}>Name</label><input id={id} /></>
```

SSR-safe stable IDs. Don't use `Math.random()` — it mismatches between server and client.

---

## 21. Suspense for Data Fetching

In React 18+ (with frameworks like Next.js, Remix, Relay, or `react-query` `suspense: true`), components can suspend on data:

```tsx
<Suspense fallback={<Skeleton />}>
  <UserProfile id={id} />
</Suspense>
```

Combined with **streaming SSR**, the server flushes HTML as each Suspense boundary resolves.

---

## 22. Server Components & Streaming SSR (overview)

- **React Server Components (RSC)** run only on the server, ship zero JS for that component, can read DB/filesystem directly. Available in Next.js App Router, Remix (experimental), Waku.
- **Streaming SSR** sends HTML in chunks — first paint before all data is ready.
- Net effect: smaller bundles, faster TTFB and LCP, simpler data fetching.

---

## 23. Context Performance

Every consumer re-renders when the context **value** identity changes — even if they only read one field.

Mitigations:

1. **Split contexts** by concern (`AuthContext`, `ThemeContext`, `CartContext` — not one big "AppContext").
2. **Memoize the value**: `<Ctx.Provider value={useMemo(() => ({ user, login }), [user])}>`.
3. **Selector pattern** — use a state library (Zustand, Jotai, Redux) or `use-context-selector` so consumers subscribe to slices.
4. Move state down (colocation) — context isn't always the right tool.

---

## 24. State Colocation

> Keep state as close to where it's used as possible.

If only `<SearchBar>` cares about the query, the query lives in `<SearchBar>` — not in `<App>`. Hoisting state up causes large subtrees to re-render on every keystroke.

---

## 25. Avoiding Prop Drilling Without Overusing Context

- **Component composition**: pass JSX as `children` instead of forwarding props through 5 layers.
- **Compound components**: `<Tabs><TabList>…</TabList></Tabs>`.
- Context is appropriate for *truly global* concerns (theme, auth, locale).

---

## 26. Web Workers for Heavy Computation

Move CPU-bound work off the main thread:

```ts
// worker.ts
self.onmessage = (e) => {
  const result = heavyFilter(e.data)
  self.postMessage(result)
}
```

```tsx
const workerRef = useRef<Worker>()
useEffect(() => {
  workerRef.current = new Worker(new URL('./worker.ts', import.meta.url),
    { type: 'module' })
  workerRef.current.onmessage = (e) => setResults(e.data)
  return () => workerRef.current?.terminate()
}, [])
```

- **Comlink** (Google) — wraps `postMessage` so the worker looks like an async object: `await api.filter(items)`.
- **OffscreenCanvas** — render canvas/WebGL on a worker thread.

---

## 27. Automatic Batching

In React 18, **all** state updates inside the same tick are batched — including those inside promises, setTimeouts, native event handlers. Pre-18 only React event handlers were batched.

```tsx
fetch(url).then(() => {
  setLoading(false)
  setData(d) // → one re-render in React 18 (two in React 17)
})
```

Opt out with `flushSync(() => setX(...))` when you need a synchronous DOM update.

---

## 28. Memory Leaks

```tsx
useEffect(() => {
  const ctrl = new AbortController()
  fetch(url, { signal: ctrl.signal })
    .then(r => r.json())
    .then(setData)
    .catch(e => { if (e.name !== 'AbortError') console.error(e) })

  return () => ctrl.abort()      // ← cleanup on unmount / dep change
}, [url])
```

Always cleanup: `setTimeout`, `setInterval`, event listeners, subscriptions, sockets, RAF, observers. Setting state on an unmounted component is harmless in React 18 but indicates leaked work still running.

---

## 29. Network Optimization

- **HTTP caching**: `Cache-Control: public, max-age=31536000, immutable` for hashed assets.
- **Service Workers** (Workbox) — offline support, runtime caching strategies (cache-first, network-first, stale-while-revalidate).
- **HTTP/2 & HTTP/3** — multiplexing, header compression.
- **Preconnect / dns-prefetch / preload** for critical third-party origins.
- **Compression**: Brotli > gzip.

---

## 30. Common Pitfalls

| Pitfall                                              | Fix                                                                  |
| ---------------------------------------------------- | -------------------------------------------------------------------- |
| Premature optimization                               | Profile first.                                                       |
| Memoizing primitives                                 | Drop the `useMemo`.                                                  |
| `useEffect` chains driving derived state             | Compute during render or use `useMemo`.                              |
| Layout thrashing (read-write-read DOM in a loop)     | Batch reads, then writes.                                            |
| Inline component definition causes remount           | Define components at module scope.                                   |
| `key={index}` on a reorderable list                  | Use a stable id.                                                     |
| Big context value re-renders the whole tree          | Split, selector, or external store.                                  |
| Importing the whole lodash                           | `import debounce from 'lodash/debounce'`.                            |

---

## 31. Production Performance Checklist

- [ ] Bundle analyzed; no duplicated/unused libs.
- [ ] Route-level code splitting in place.
- [ ] Heavy components (charts, editors, modals) lazy-loaded.
- [ ] Lists with > ~200 rows virtualized.
- [ ] Images: `loading="lazy"`, modern formats, `width`/`height` set, `srcset` for hero images.
- [ ] Fonts: `font-display: swap`, preloaded, subsetted.
- [ ] Web Vitals (LCP/INP/CLS) within "Good" thresholds on real user data.
- [ ] Long tasks (> 50 ms) eliminated or moved to a worker / `useTransition`.
- [ ] Memoization applied **only** at proven hot spots.
- [ ] No memory leaks (cleanup on every effect).
- [ ] HTTP caching headers set; static assets immutable.
- [ ] Lighthouse score ≥ 90 on representative pages.
- [ ] Error & performance monitoring in production (Sentry, Datadog RUM, web-vitals → analytics).

---

## Key Takeaways

1. **Measure, then optimize.** The Profiler and Performance tab are your eyes.
2. The default cascade re-renders children whenever the parent renders — that's usually fine.
3. `React.memo` / `useMemo` / `useCallback` are surgical tools, not defaults. The React Compiler will make most manual memoization obsolete.
4. **Virtualize** long lists. **Code-split** heavy routes. **Lazy-load** heavy components and images.
5. Concurrent features (`useTransition`, `useDeferredValue`, Suspense) keep the UI responsive without manual juggling.
6. Bundle size, image weight, and main-thread time are the three biggest levers for real-world performance.
7. A green Lighthouse score is a starting point — real-user Web Vitals are the truth.
