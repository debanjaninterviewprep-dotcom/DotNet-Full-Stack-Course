# Topic 04: State and Lifecycle Hooks — Interview Questions

---

## Q1. What are the Rules of Hooks?
**Answer:**
React enforces two rules for hooks:

1. **Only call hooks at the top level** — not inside loops, conditions, or nested functions.
2. **Only call hooks from React functions** — functional components or custom hooks.

```jsx
// ❌ Violates Rule 1 — conditional hook call
function BadComponent({ isLoggedIn }) {
  if (isLoggedIn) {
    const [user, setUser] = useState(null); // inside condition!
  }
}

// ✓ Correct — always call unconditionally
function GoodComponent({ isLoggedIn }) {
  const [user, setUser] = useState(null); // always called
  if (!isLoggedIn) return null;
}
```

Why? React tracks hook calls by their **order** in the function. Conditional calls break the order between renders, causing state to be assigned to the wrong hook.

---

## Q2. What is `useState` and how does it work?
**Answer:**
`useState` declares a state variable. React re-renders the component when the state changes:

```jsx
const [count, setCount] = useState(0);      // initial value
const [user, setUser]   = useState(null);   // nullable
const [items, setItems] = useState([]);     // array
const [form, setForm]   = useState({ name: '', email: '' }); // object

// Update — schedule a re-render
setCount(5);                                // direct value
setCount(prev => prev + 1);                 // functional update (safe for batched updates)

// Object state — must spread existing state (useState doesn't merge automatically)
setForm(prev => ({ ...prev, name: 'Alice' })); // merge manually

// Array state
setItems(prev => [...prev, newItem]);       // add
setItems(prev => prev.filter(i => i.id !== id)); // remove
setItems(prev => prev.map(i => i.id === id ? { ...i, ...changes } : i)); // update
```

---

## Q3. What is `useEffect` and when does it run?
**Answer:**
`useEffect` runs **after the render** is committed to the DOM. It replaces `componentDidMount`, `componentDidUpdate`, and `componentWillUnmount`:

```jsx
// No deps — runs after EVERY render
useEffect(() => { console.log('Rendered'); });

// Empty deps [] — runs ONCE on mount (componentDidMount equivalent)
useEffect(() => {
  fetchData();
}, []);

// With deps — runs when deps change (componentDidUpdate equivalent)
useEffect(() => {
  fetchUser(userId);
}, [userId]);

// With cleanup — runs on unmount and before next effect (componentWillUnmount)
useEffect(() => {
  const sub = api.subscribe(callback);
  return () => sub.unsubscribe(); // cleanup function
}, []);

// Timer example
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000);
  return () => clearInterval(id); // cleanup: cancel timer
}, []);
```

---

## Q4. What are common `useEffect` mistakes?
**Answer:**
```jsx
// ❌ Missing dependency — stale closure bug
const [count, setCount] = useState(0);
useEffect(() => {
  const id = setInterval(() => {
    setCount(count + 1); // 'count' captured at mount is always 0!
  }, 1000);
  return () => clearInterval(id);
}, []); // count is missing from deps

// ✓ Fix: functional update or add to deps
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000); // doesn't need count in deps
  return () => clearInterval(id);
}, []);

// ❌ Fetching without cleanup — race condition
useEffect(() => {
  fetch(`/api/user/${id}`).then(r => r.json()).then(setUser);
}, [id]);

// ✓ Fix: abort controller
useEffect(() => {
  const controller = new AbortController();
  fetch(`/api/user/${id}`, { signal: controller.signal })
    .then(r => r.json()).then(setUser)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });
  return () => controller.abort();
}, [id]);

// ❌ Infinite loop — object/function created in render added to deps
useEffect(() => { fetchData(options); }, [options]); // options = {} recreated every render
```

---

## Q5. What is `useRef` and what are its use cases?
**Answer:**
`useRef` returns a mutable object `{ current: value }` that **persists across renders** without causing re-renders when changed:

```jsx
// 1. DOM access
const inputRef = useRef(null);
<input ref={inputRef} />
inputRef.current.focus(); // imperative DOM access

// 2. Storing mutable values without triggering re-render
const timerRef = useRef(null);
timerRef.current = setInterval(...); // doesn't cause re-render
clearInterval(timerRef.current);

// 3. Tracking previous value
function usePrevious(value) {
  const ref = useRef();
  useEffect(() => { ref.current = value; }, [value]);
  return ref.current; // previous value
}

// 4. Avoiding stale closures in event handlers
const onClickRef = useRef(onClick);
useEffect(() => { onClickRef.current = onClick; }, [onClick]);
// Use onClickRef.current() inside an event listener for always-fresh value
```

**Key difference from `useState`:** Mutating `ref.current` does **not** trigger a re-render.

---

## Q6. What is `useMemo` and when should you use it?
**Answer:**
`useMemo` memoizes the result of a computation — only recalculates when dependencies change:

```jsx
// Expensive computation
const sortedUsers = useMemo(
  () => [...users].sort((a, b) => a.name.localeCompare(b.name)),
  [users] // only re-sort when users array changes
);

// Memoize an object to maintain stable reference
const chartConfig = useMemo(
  () => ({ type: 'bar', data: chartData, options: { responsive: true } }),
  [chartData]
);

// When NOT to use useMemo:
const fullName = `${firstName} ${lastName}`; // ❌ too cheap to memoize
const [count, setCount] = useState(0);
const doubled = count * 2; // ❌ trivial calculation
```

**Rule:** Only use `useMemo` when:
1. The computation is measurably expensive.
2. The result is used as a prop that prevents re-renders via `React.memo`.

---

## Q7. What is `useCallback` and how does it differ from `useMemo`?
**Answer:**
`useCallback` memoizes a **function reference** — returns the same function instance across renders:

```jsx
// useMemo — memoizes the RESULT of a function
const expensiveValue = useMemo(() => computeExpensiveValue(x), [x]);

// useCallback — memoizes the FUNCTION ITSELF
const handleClick = useCallback(() => { doSomething(id); }, [id]);

// Without useCallback — new function reference on every render
// → child re-renders even with React.memo (because prop changed)
const handleClick = () => doSomething(id);

// With useCallback — same reference if deps don't change
// → child with React.memo won't re-render unnecessarily
const handleClick = useCallback(() => doSomething(id), [id]);

// Common pattern: stable callback for effects
useEffect(() => {
  fetchData(handleSuccess); // if handleSuccess isn't memoized, effect runs on every render
}, [handleSuccess]);
```

---

## Q8. What is `useReducer` and when is it better than `useState`?
**Answer:**
`useReducer` is an alternative to `useState` for complex state logic — similar to Redux's pattern:

```jsx
const initialState = { count: 0, status: 'idle', error: null };

function reducer(state, action) {
  switch (action.type) {
    case 'INCREMENT':  return { ...state, count: state.count + 1 };
    case 'DECREMENT':  return { ...state, count: state.count - 1 };
    case 'RESET':      return initialState;
    case 'SET_ERROR':  return { ...state, error: action.payload, status: 'error' };
    default:           return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, initialState);
  return (
    <>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'INCREMENT' })}>+</button>
      <button onClick={() => dispatch({ type: 'RESET' })}>Reset</button>
    </>
  );
}
```

**Use `useReducer` when:**
- Multiple related state values that change together.
- Next state depends on previous state in complex ways.
- State transitions are complex enough to benefit from explicit actions.

---

## Q9. What is the component lifecycle equivalent using hooks?
**Answer:**
```jsx
function LifecycleComponent({ id }) {
  const [data, setData] = useState(null);

  // componentDidMount — runs once on mount
  useEffect(() => {
    initializeAnalytics();
  }, []);

  // componentDidUpdate (for id changes) — runs when id changes
  useEffect(() => {
    fetchData(id).then(setData);
  }, [id]);

  // componentWillUnmount — cleanup function
  useEffect(() => {
    return () => {
      cleanupAnalytics();
    };
  }, []);

  // Combined: mount + update + unmount
  useEffect(() => {
    const sub = subscribe(id);
    return () => sub.unsubscribe(); // cleanup before next effect + on unmount
  }, [id]);

  // shouldComponentUpdate equivalent — use React.memo
  // componentDidUpdate for ALL updates
  useEffect(() => {
    console.log('Component updated');
  }); // no deps array = every render
}
```

---

## Q10. What is `useContext` and how is it used?
**Answer:**
`useContext` consumes a React context value without wrapping in a Consumer component:

```jsx
// 1. Create context
const ThemeContext = createContext('light');

// 2. Provide value at a high level
function App() {
  const [theme, setTheme] = useState('light');
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      <Main />
    </ThemeContext.Provider>
  );
}

// 3. Consume anywhere in the tree
function Button() {
  const { theme, setTheme } = useContext(ThemeContext);
  return (
    <button
      className={`btn-${theme}`}
      onClick={() => setTheme(t => t === 'light' ? 'dark' : 'light')}
    >
      Toggle
    </button>
  );
}
```

---

## Q11. What are custom hooks and how do you create them?
**Answer:**
Custom hooks extract reusable stateful logic. They must start with `use`:

```jsx
// Custom hook — reusable data fetching
function useFetch(url) {
  const [data, setData]     = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]   = useState(null);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    fetch(url, { signal: controller.signal })
      .then(r => { if (!r.ok) throw new Error(r.statusText); return r.json(); })
      .then(d => { setData(d); setLoading(false); })
      .catch(e => { if (e.name !== 'AbortError') setError(e.message); setLoading(false); });
    return () => controller.abort();
  }, [url]);

  return { data, loading, error };
}

// Usage
function UserList() {
  const { data, loading, error } = useFetch('/api/users');
  if (loading) return <Spinner />;
  if (error)   return <Error msg={error} />;
  return <ul>{data.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

---

## Q12. What is `useLayoutEffect` and how does it differ from `useEffect`?
**Answer:**
| | `useEffect` | `useLayoutEffect` |
|---|---|---|
| **Timing** | After paint (async) | After DOM mutations, before paint (sync) |
| **Blocks paint?** | No | Yes — runs synchronously |
| **Use case** | Data fetching, subscriptions | DOM measurements, animations |
| **SSR** | Safe | Warning (no DOM on server) |

```jsx
// useLayoutEffect — measure DOM before browser paints (no flicker)
function Tooltip({ text, targetRef }) {
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const tooltipRef = useRef(null);

  useLayoutEffect(() => {
    const target  = targetRef.current.getBoundingClientRect();
    const tooltip = tooltipRef.current.getBoundingClientRect();
    setPosition({ top: target.bottom, left: target.left - tooltip.width / 2 });
  }); // runs synchronously before paint — no flash

  return <div ref={tooltipRef} style={position}>{text}</div>;
}
```

**Rule:** Start with `useEffect`. Only switch to `useLayoutEffect` if you see visual flickering from DOM measurements.

---

## Q13. What is the `useId` hook (React 18)?
**Answer:**
`useId` generates a stable, unique ID for each component instance — useful for accessibility attributes:

```jsx
function LabeledInput({ label }) {
  const id = useId(); // stable across renders, unique per component instance

  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input id={id} type="text" />
    </>
  );
}

// Multiple ids in one component
function Form() {
  const nameId  = useId();
  const emailId = useId();
  return (
    <>
      <label htmlFor={nameId}>Name</label>
      <input id={nameId} />
      <label htmlFor={emailId}>Email</label>
      <input id={emailId} />
    </>
  );
}
```

`useId` generates IDs that are consistent between server and client renders (avoids SSR hydration mismatches).

---

## Q14. What is `useTransition` and `useDeferredValue`?
**Answer:**
Both are React 18 concurrent features to keep UI responsive during heavy updates:

```jsx
// useTransition — mark state update as non-urgent
function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [isPending, startTransition] = useTransition();

  const handleSearch = (e) => {
    setQuery(e.target.value); // urgent — update input immediately
    startTransition(() => {
      setResults(filterLargeList(e.target.value)); // non-urgent — can be deferred
    });
  };

  return (
    <>
      <input onChange={handleSearch} value={query} />
      {isPending && <Spinner />}
      <ResultList results={results} />
    </>
  );
}

// useDeferredValue — defer rendering of expensive child
function App() {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query); // lags behind query during heavy renders
  return (
    <>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      <HeavyList filter={deferredQuery} /> {/* renders with slightly stale value */}
    </>
  );
}
```

---

## Q15. What is state batching and how does React 18 improve it?
**Answer:**
**Batching** — React groups multiple state updates into a single re-render:

```jsx
// React 17: batching ONLY in React event handlers
function handleClick() {
  setA(1); // these batch into one re-render
  setB(2); // ✓ batched in event handler
}

// React 17: no batching in async contexts
setTimeout(() => {
  setA(1); // two separate re-renders ❌
  setB(2);
}, 1000);

// React 18: AUTOMATIC BATCHING everywhere
setTimeout(() => {
  setA(1); // ✓ batched into one re-render even in setTimeout
  setB(2);
}, 1000);

// React 18: even in Promises and native event handlers
fetch('/api').then(() => {
  setA(1); // ✓ batched
  setB(2);
});

// Opt out of batching (rare — avoid)
import { flushSync } from 'react-dom';
flushSync(() => setA(1)); // forces immediate re-render
flushSync(() => setB(2)); // another immediate re-render
```
