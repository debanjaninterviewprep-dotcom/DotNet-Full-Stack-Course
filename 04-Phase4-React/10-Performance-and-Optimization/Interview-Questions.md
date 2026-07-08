# Topic 10: Performance and Optimization — Interview Questions

---

## Q1. What is `React.memo` and how does it work?
**Answer:**
`React.memo` is a HOC that prevents a functional component from re-rendering if its **props haven't changed** (shallow comparison):

```jsx
// Without memo — re-renders every time parent renders
function UserCard({ user, onDelete }) {
  console.log('UserCard rendered');
  return <div onClick={() => onDelete(user.id)}>{user.name}</div>;
}

// With memo — only re-renders when user or onDelete reference changes
const UserCard = React.memo(function UserCard({ user, onDelete }) {
  return <div onClick={() => onDelete(user.id)}>{user.name}</div>;
});

// Custom comparison (for deep equality)
const UserCard = React.memo(UserCard, (prevProps, nextProps) => {
  return prevProps.user.id === nextProps.user.id &&
         prevProps.user.name === nextProps.user.name;
  // return true = skip re-render, false = re-render
});
```

**Common trap:** `React.memo` is useless if parent passes **new function/object references** on every render — pair with `useCallback`/`useMemo`.

---

## Q2. What is the difference between `useMemo` and `useCallback`?
**Answer:**
```jsx
// useMemo — memoizes a COMPUTED VALUE
const filteredList = useMemo(
  () => users.filter(u => u.isActive).sort((a, b) => a.name.localeCompare(b.name)),
  [users] // recompute only when users changes
);

// useCallback — memoizes a FUNCTION REFERENCE
const handleDelete = useCallback(
  (id) => dispatch(deleteUser(id)),
  [dispatch] // new function only when dispatch changes
);

// When to use:
// useMemo  → expensive computation, object/array that's passed as prop to React.memo component
// useCallback → function passed as prop to React.memo child, used in useEffect deps

// WRONG: premature optimization
const add = useMemo(() => a + b, [a, b]); // ❌ arithmetic is not expensive
const fn  = useCallback(() => {}, []);    // ❌ empty function — unnecessary
```

---

## Q3. How do you identify performance problems in React?
**Answer:**
```jsx
// 1. React DevTools Profiler
// - Record interactions, see which components re-rendered and why
// - Flame chart shows render time per component

// 2. React StrictMode — double-renders expose impure components

// 3. why-did-you-render library — logs unnecessary re-renders
import whyDidYouRender from '@welldone-software/why-did-you-render';
whyDidYouRender(React, { trackAllPureComponents: true });

// 4. Performance tab in Chrome DevTools
// - Long tasks > 50ms cause jank
// - Look for "Recalculate Style" and "Layout" operations

// 5. Mark expensive operations
performance.mark('render-start');
// ... expensive work
performance.measure('render', 'render-start');

// React 18 Profiler API
<Profiler id="UserList" onRender={(id, phase, actualDuration) => {
  console.log(`${id} ${phase}: ${actualDuration}ms`);
}}>
  <UserList />
</Profiler>
```

---

## Q4. What is code splitting and how do you implement it?
**Answer:**
Code splitting breaks the bundle into chunks loaded on demand:

```jsx
import { lazy, Suspense } from 'react';

// Lazy load heavy components
const RichTextEditor = lazy(() => import('./RichTextEditor'));
const ChartComponent = lazy(() => import('./ChartComponent'));
const AdminPanel = lazy(() => import('./AdminPanel'));

// Wrap in Suspense
function App() {
  const [showEditor, setShowEditor] = useState(false);
  return (
    <>
      <button onClick={() => setShowEditor(true)}>Open Editor</button>
      {showEditor && (
        <Suspense fallback={<div>Loading editor...</div>}>
          <RichTextEditor />
        </Suspense>
      )}
    </>
  );
}

// Route-based code splitting (most impactful)
const Dashboard = lazy(() => import('./pages/Dashboard')); // own chunk
const Reports   = lazy(() => import('./pages/Reports'));   // own chunk
```

---

## Q5. What is list virtualization and why is it needed?
**Answer:**
Rendering 10,000 rows creates 10,000 DOM nodes — slow to render and scroll. Virtualization only renders **visible items**:

```jsx
import { FixedSizeList } from 'react-window';

function VirtualUserList({ users }) {
  const Row = ({ index, style }) => (
    <div style={style}>  {/* style contains absolute position */}
      <UserCard user={users[index]} />
    </div>
  );

  return (
    <FixedSizeList
      height={600}          // visible window height
      width="100%"
      itemCount={users.length}
      itemSize={60}         // each row height
    >
      {Row}
    </FixedSizeList>
  );
}

// Variable height rows
import { VariableSizeList } from 'react-window';
const getItemSize = (index) => itemHeights[index];

// For tables/grids
import { FixedSizeGrid } from 'react-window';
```

---

## Q6. What is the `key` prop and why does it affect performance?
**Answer:**
React uses `key` to identify components in a list. Wrong keys cause performance issues and bugs:

```jsx
// ❌ Using index as key — on insert/delete, React remounts ALL subsequent elements
{users.map((user, index) => <UserCard key={index} user={user} />)}

// ✓ Using stable ID — React reuses DOM nodes, only updates changed ones
{users.map(user => <UserCard key={user.id} user={user} />)}

// Performance impact:
// With stable keys: insert at index 0 → only 1 new render
// With index keys:  insert at index 0 → all n elements re-render (wrong index mapping)

// When index key is OK:
// - Static list that never changes
// - No state in list items
// - Items never reordered
```

---

## Q7. What is `useTransition` and when is it used for performance?
**Answer:**
`useTransition` marks state updates as **non-urgent** — React can interrupt them to handle more urgent updates (like user input):

```jsx
function SearchPage() {
  const [query, setQuery]   = useState('');
  const [results, setResults] = useState([]);
  const [isPending, startTransition] = useTransition();

  const handleInput = (e) => {
    const value = e.target.value;
    setQuery(value); // urgent — update input immediately (don't defer)
    startTransition(() => {
      // non-urgent — can be interrupted if user types again
      setResults(filterHugeDataset(value));
    });
  };

  return (
    <>
      <input value={query} onChange={handleInput} />
      {isPending && <div className="loading-indicator" />}
      <ResultList results={results} />
    </>
  );
}

// Use when: a state update causes expensive rendering that shouldn't block input
```

---

## Q8. What is `useDeferredValue` and how does it differ from `useTransition`?
**Answer:**
| | `useTransition` | `useDeferredValue` |
|---|---|---|
| **Controls** | State update | Reading a value |
| **Access to** | `isPending` | Stale value during update |
| **Use when** | You own the state setter | You receive a prop you can't control |

```jsx
// useDeferredValue — when you can't wrap the setState
function SearchResults({ query }) {
  // query prop changes fast (from parent's state)
  const deferredQuery = useDeferredValue(query); // slightly behind during updates
  const isStale = deferredQuery !== query;

  return (
    <div style={{ opacity: isStale ? 0.6 : 1 }}> {/* dim while stale */}
      <HeavyList filter={deferredQuery} />
    </div>
  );
}
```

---

## Q9. How do you avoid unnecessary re-renders?
**Answer:**
```jsx
// 1. React.memo for pure components
const PureComponent = React.memo(Component);

// 2. useCallback for event handlers passed as props
const handleClick = useCallback(() => doSomething(id), [id]);

// 3. useMemo for expensive computations
const sorted = useMemo(() => items.sort(compareFn), [items]);

// 4. Stable context value
const ctx = useMemo(() => ({ theme, toggleTheme }), [theme]);

// 5. Move expensive children OUTSIDE the re-rendering parent
// ❌ InputCount re-renders every time count changes
function Parent() {
  const [count, setCount] = useState(0);
  return <><Counter count={count} /><ExpensiveChild /></>; // ExpensiveChild re-renders!
}

// ✓ Pass as children (prop) — defined outside Parent
function App() {
  return <Parent><ExpensiveChild /></Parent>;
}
function Parent({ children }) {
  const [count, setCount] = useState(0);
  return <><Counter count={count} />{children}</>; // children reference is stable!
}

// 6. Split components — isolate state near usage
function Form() {
  return (
    <>
      <NameInput />  {/* has its own state — doesn't affect EmailInput */}
      <EmailInput /> {/* has its own state */}
    </>
  );
}
```

---

## Q10. What are React Server Components (RSC)?
**Answer:**
React Server Components (Next.js 13+ App Router) render on the server — sending only HTML to the client, not JavaScript:

```jsx
// Server Component (default in Next.js App Router)
async function UserPage({ params }) {
  // Runs on server — can directly access DB, filesystem, etc.
  const user = await db.users.findById(params.id);
  const posts = await db.posts.findByUserId(params.id);

  return (
    <div>
      <h1>{user.name}</h1>          {/* zero JS for this */}
      <PostList posts={posts} />    {/* also server component */}
      <LikeButton postId={post.id} /> {/* 'use client' — sent as JS */}
    </div>
  );
}

// Client Component — requires interactivity
'use client';
function LikeButton({ postId }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(l => !l)}>{liked ? '❤️' : '🤍'}</button>;
}
```

**Benefits:** Zero client JS for static content, direct database access, smaller bundles, better Core Web Vitals.

---

## Q11. What is memoization and when does it hurt performance?
**Answer:**
Memoization caches results to avoid recomputation. It can **hurt** performance when used incorrectly:

```jsx
// Memoization COSTS:
// - Memory: cached value stored
// - CPU: dependency comparison on every render
// - Code complexity

// When memoization HURTS:
const add = useMemo(() => a + b, [a, b]); // ❌ faster without memo (comparison > addition)
const fn  = useCallback(() => onClick(), [onClick]); // ❌ if component isn't memo'd

// When memoization HELPS:
const sorted = useMemo(() => largeArray.sort(complexCompareFn), [largeArray]); // ✓ expensive
const handler = useCallback(complexHandler, [deps]); // ✓ passed to React.memo child

// Rule of thumb:
// 1. Profile first — don't optimize prematurely
// 2. Add memo/useCallback only when profiler shows unnecessary renders
// 3. Keep memoization close to the problem (not everywhere)
```

---

## Q12. How does React's `Suspense` improve perceived performance?
**Answer:**
`Suspense` shows fallback UI while content is loading — preventing layout shifts and blank states:

```jsx
// Without Suspense — entire page blank while loading
function App() {
  if (isLoading) return <Spinner />; // blocks entire page
  return <Dashboard data={data} />;
}

// With Suspense — granular loading states
function App() {
  return (
    <>
      <Header />                    {/* always visible */}
      <Suspense fallback={<NavSkeleton />}>
        <NavBar />                  {/* loads independently */}
      </Suspense>
      <Suspense fallback={<ContentSkeleton />}>
        <MainContent />             {/* loads independently */}
      </Suspense>
    </>
  );
}

// Nested Suspense boundaries — isolate failures
<Suspense fallback={<PageSkeleton />}>
  <UserProfile />        {/* waits here if loading */}
  <Suspense fallback={<PostsSkeleton />}>
    <UserPosts />         {/* waits independently */}
  </Suspense>
</Suspense>
```

---

## Q13. What is `React.lazy` and what are its limitations?
**Answer:**
```jsx
// React.lazy — dynamically import a component
const HeavyChart = React.lazy(() => import('./HeavyChart'));

// Limitations:
// ❌ Named exports NOT supported (only default exports)
import('./MyComponent') // must export as default

// Workaround for named exports:
const Modal = React.lazy(() =>
  import('./components').then(module => ({ default: module.Modal }))
);

// ❌ Doesn't work outside Suspense
<HeavyChart />  // ❌ Error: must be wrapped in Suspense

// ✓ Works inside Suspense
<Suspense fallback={<Skeleton />}>
  <HeavyChart />
</Suspense>

// ❌ SSR — React.lazy has limited SSR support
// Use next/dynamic for SSR-compatible lazy loading in Next.js
import dynamic from 'next/dynamic';
const NoSSRChart = dynamic(() => import('./Chart'), { ssr: false });
```

---

## Q14. What is the `window` function pattern for expensive initial state?
**Answer:**
```jsx
// ❌ useState initializer runs on EVERY render
const [data, setData] = useState(expensiveComputation()); // called every render!

// ✓ Lazy initializer — only runs ONCE on mount
const [data, setData] = useState(() => expensiveComputation()); // function form

// ✓ Also for reading from localStorage
const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light');
const [user,  setUser]  = useState(() => JSON.parse(localStorage.getItem('user') || 'null'));

// ✓ For expensive initial calculations
const [sortedList, setSortedList] = useState(() =>
  [...initialItems].sort(complexCompareFn)
);
```

---

## Q15. What are the Core Web Vitals and how does React affect them?
**Answer:**
Core Web Vitals are Google's metrics for user experience:

| Metric | Measures | Good |
|---|---|---|
| **LCP** (Largest Contentful Paint) | Loading performance | < 2.5s |
| **FID** (First Input Delay) → **INP** (Interaction to Next Paint) | Interactivity | < 200ms |
| **CLS** (Cumulative Layout Shift) | Visual stability | < 0.1 |

**React's impact:**
```
LCP — large JS bundle delays first paint
  → Fix: code splitting, lazy loading, SSR/RSC

INP — long React renders block the main thread
  → Fix: useTransition, useDeferredValue, avoid synchronous heavy renders

CLS — async content causes layout shifts (images without dimensions, font swaps)
  → Fix: specify image dimensions, skeleton screens, font preloading
```

Tools: Lighthouse, Web Vitals Chrome extension, `web-vitals` npm package.
