# Topic 4: State & Lifecycle (Hooks)

Hooks are React's mechanism for adding state, lifecycle, and side effects to **function components**. Introduced in React 16.8 (Feb 2019), they replaced almost every reason to write a class component. This topic is foundational — almost everything else in React (forms, data fetching, context, performance, testing) sits on top of `useState`, `useEffect`, and `useRef`. Get the mental model right here and the rest of React becomes mechanical.

---

## 1. The Why — Hooks vs Class Lifecycle

Before hooks, stateful components were classes with lifecycle methods: `constructor`, `componentDidMount`, `componentDidUpdate`, `componentWillUnmount`, `getDerivedStateFromProps`, etc. Three problems:

1. **Logic could not be reused.** Higher-order components and render props worked but produced "wrapper hell."
2. **Related logic was split across methods.** A subscription was set up in `componentDidMount` and torn down in `componentWillUnmount` — far apart, easy to desync.
3. **Classes are confusing.** `this` binding, transpilation cost, and harder static analysis.

Hooks solve all three: logic is colocated, reusable as plain functions, and `this` is gone.

### Class lifecycle → Hook map

| Class method | Hook equivalent |
|---|---|
| `constructor` (initial state) | `useState(initial)` or `useState(() => init())` |
| `componentDidMount` | `useEffect(() => { ... }, [])` |
| `componentDidUpdate(prevProps)` | `useEffect(() => { ... }, [dep])` |
| `componentWillUnmount` | `useEffect(() => { return () => cleanup(); }, [])` |
| `getDerivedStateFromProps` | Compute during render (don't store in state) |
| `shouldComponentUpdate` | `React.memo` + `useMemo`/`useCallback` |
| Instance fields (`this.timerId`) | `useRef(null)` |

> The mental shift: stop thinking *"do this when X happens"* (lifecycle) and start thinking *"keep this synchronized with X"* (effect).

---

## 2. The Rules of Hooks

Two non-negotiable rules, enforced by the `eslint-plugin-react-hooks` package:

1. **Only call hooks at the top level.** Never inside loops, conditions, nested functions, or after early `return`.
2. **Only call hooks from React functions.** Either function components or other custom hooks (whose names start with `use`).

```tsx
// BAD — conditional hook
function Bad({ enabled }) {
  if (enabled) {
    const [x, setX] = useState(0); // breaks call order
  }
}

// GOOD — hook always called, condition inside
function Good({ enabled }) {
  const [x, setX] = useState(0);
  if (!enabled) return null;
}
```

### How React tracks hooks

React stores hook state in a **linked list attached to the fiber** for that component. On every render, hooks are matched by **call order**, not by name. Render 1 calls `useState`, `useState`, `useEffect` → React allocates slots 0, 1, 2. If render 2 skips the first `useState`, slot 0 now points to the second hook's state — chaos. That's why conditional hooks break.

The ESLint rule `react-hooks/rules-of-hooks` catches this statically. Always have it on.

---

## 3. `useState` — Local State

```tsx
const [count, setCount] = useState(0);
```

`useState` returns a tuple: current value + setter. Calling the setter schedules a re-render with the new value.

### Lazy initial state

If the initial value is expensive to compute, pass a **function** — it runs only on the first render.

```tsx
// BAD — runs every render, result discarded after the first
const [tree] = useState(buildHugeTree());

// GOOD — runs once
const [tree] = useState(() => buildHugeTree());
```

### Functional updates — when REQUIRED

When the next state depends on the previous, use the updater form. Direct form captures the value at render time and goes stale inside async callbacks, batched updates, or effects.

```tsx
// BAD — both reads of `count` are 0 from the same render
setCount(count + 1);
setCount(count + 1); // result: 1, not 2

// GOOD
setCount(c => c + 1);
setCount(c => c + 1); // result: 2
```

### State batching (React 18+)

React 18 introduced **automatic batching** — multiple `setState` calls inside the same event, promise, timeout, or native handler are batched into one render. Pre-18, only React event handlers batched.

```tsx
function handleClick() {
  setA(1);
  setB(2);
  setC(3); // ONE re-render, not three
}
```

### Object / array state — replace, don't mutate

```tsx
// BAD — React compares by reference, sees no change, skips render
user.name = 'Ada';
setUser(user);

// GOOD
setUser({ ...user, name: 'Ada' });
setItems([...items, newItem]);
setItems(items.filter(i => i.id !== id));
```

### Split state vs combine

- **Split** when fields update independently (`firstName`, `lastName`).
- **Combine** when fields change together (`{ x, y }` for a position).
- **Reducer** when many fields move as a unit (forms, wizards).

### Derived state should NOT live in state

If a value can be computed from props or other state, **compute it during render**. Storing it duplicates the source of truth and creates desync bugs.

```tsx
// BAD
const [items, setItems] = useState([]);
const [count, setCount] = useState(0); // duplicate
useEffect(() => setCount(items.length), [items]); // extra render

// GOOD
const [items, setItems] = useState([]);
const count = items.length; // derived, free
const expensiveSummary = useMemo(() => summarize(items), [items]);
```

---

## 4. `useEffect` — Synchronization with the Outside World

> **Mental model:** an effect is not a "lifecycle hook." It's a way to *synchronize* a React component with an external system (DOM, network, timers, browser APIs). Whenever inputs change, React re-runs the effect to re-synchronize.

```tsx
useEffect(() => {
  // setup
  const sub = source.subscribe(setData);
  return () => sub.unsubscribe(); // cleanup
}, [source]);
```

### Dependency array rules

| Form | Behavior |
|---|---|
| `useEffect(fn)` (no array) | Runs after every render |
| `useEffect(fn, [])` | Runs after first render only; cleanup on unmount |
| `useEffect(fn, [a, b])` | Runs after first render and whenever `a` or `b` changes (`Object.is`) |

The lint rule `react-hooks/exhaustive-deps` flags any value used inside the effect that isn't in the dep array. **Don't disable it.** If a dep changes too often, the right fix is `useCallback`/`useMemo`, moving the value into a ref, or restructuring — not silencing the lint.

### Cleanup function

Returned function runs **before the next effect** (when deps change) and **on unmount**. This is how you cancel subscriptions, abort fetches, clear timers.

### StrictMode double-invocation (dev only)

In development, `<React.StrictMode>` mounts every component twice: mount → unmount → mount. Effects run twice. **This is intentional** — it surfaces bugs where cleanup is missing or where mounting twice produces wrong results (duplicate subscriptions, double fetches without abort). It does not happen in production.

### Common patterns

**Data fetching with cancellation:**

```tsx
useEffect(() => {
  const ac = new AbortController();
  fetch(`/api/users/${id}`, { signal: ac.signal })
    .then(r => r.json())
    .then(setUser)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });
  return () => ac.abort();
}, [id]);
```

**Subscription:**

```tsx
useEffect(() => {
  const handler = () => setOnline(navigator.onLine);
  window.addEventListener('online', handler);
  window.addEventListener('offline', handler);
  return () => {
    window.removeEventListener('online', handler);
    window.removeEventListener('offline', handler);
  };
}, []);
```

**Timer:**

```tsx
useEffect(() => {
  const id = setInterval(() => setNow(Date.now()), 1000);
  return () => clearInterval(id);
}, []);
```

### "You Might Not Need an Effect"

Five cases where developers reach for an effect but shouldn't:

1. **Transforming data for render** → compute during render or `useMemo`.
2. **Resetting state when a prop changes** → use the `key` prop on the child, or compute in render.
3. **Notifying parent of changes** → call the parent's callback inside the same event handler that produced the change.
4. **Initializing the app once** → run at module top level, or in a guarded module-level flag.
5. **Sending an analytics event on click** → put it in the click handler, not in an effect that watches state.

Effects describe *synchronization*, not *reactions to events*. If logic should run because the user did X, put it in X's handler.

### Anti-patterns

- **Derived state in effect** — store source, compute the rest.
- **Effect chains** — Effect A sets state → Effect B watches that state → Effect C... Each link adds a render. Combine into one.
- **Effect-as-event-handler** — running side effects on state change that was caused by a click belongs in the click handler.

---

## 5. `useLayoutEffect`

Same signature as `useEffect`, but runs **synchronously after DOM mutations and before the browser paints**. Use only when you must read layout (measure DOM) and synchronously re-render before the user sees the intermediate frame — e.g., positioning a tooltip or preventing a flicker.

```tsx
useLayoutEffect(() => {
  const rect = ref.current.getBoundingClientRect();
  setHeight(rect.height);
}, []);
```

| | `useEffect` | `useLayoutEffect` |
|---|---|---|
| Timing | After paint, async | Before paint, sync |
| Blocks paint | No | Yes |
| Use for | Most side effects | DOM measurements, sync DOM mutations |
| SSR | OK (skipped) | Warns (no DOM on server) |

Rule of thumb: default to `useEffect`. Reach for `useLayoutEffect` only to fix a visible flicker.

---

## 6. `useRef` — Mutable Containers

`useRef(initial)` returns a stable object `{ current }`. Mutating `.current` does **not** trigger a re-render and does **not** participate in React's reactivity.

### Three uses

**1. DOM reference**

```tsx
const inputRef = useRef<HTMLInputElement>(null);
useEffect(() => inputRef.current?.focus(), []);
return <input ref={inputRef} />;
```

**2. Mutable instance variable** (timer ids, latest value, prev value)

```tsx
const timerId = useRef<number | null>(null);
const start = () => { timerId.current = window.setInterval(tick, 1000); };
const stop  = () => { if (timerId.current) clearInterval(timerId.current); };
```

**3. Previous value pattern**

```tsx
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => { ref.current = value; }, [value]);
  return ref.current;
}
```

### Forwarding refs (preview)

A function component cannot receive a `ref` prop directly. Wrap with `forwardRef`:

```tsx
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));
```

In React 19, `ref` is just a regular prop on function components; `forwardRef` is no longer needed.

---

## 7. `useReducer` — Reducer-Based State

Prefer `useReducer` over `useState` when:

- State has **multiple sub-values** that change together.
- Next state depends on previous in **non-trivial** ways.
- Update logic is **complex enough to test in isolation**.
- Many components need to dispatch the same actions (pair with context).

```tsx
type State = { count: number };
type Action = { type: 'inc' } | { type: 'dec' } | { type: 'set'; value: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'inc': return { count: state.count + 1 };
    case 'dec': return { count: state.count - 1 };
    case 'set': return { count: action.value };
  }
}

const [state, dispatch] = useReducer(reducer, { count: 0 });
dispatch({ type: 'inc' });
```

### Todo example

```tsx
type Todo = { id: string; text: string; done: boolean };
type Action =
  | { type: 'add'; text: string }
  | { type: 'toggle'; id: string }
  | { type: 'delete'; id: string };

function todos(state: Todo[], action: Action): Todo[] {
  switch (action.type) {
    case 'add':    return [...state, { id: crypto.randomUUID(), text: action.text, done: false }];
    case 'toggle': return state.map(t => t.id === action.id ? { ...t, done: !t.done } : t);
    case 'delete': return state.filter(t => t.id !== action.id);
  }
}
```

### `useState` vs `useReducer`

| | `useState` | `useReducer` |
|---|---|---|
| Best for | Simple, independent values | Complex transitions, multi-field updates |
| Update site | Inline setter calls | Dispatch action → reducer |
| Testability | Test the component | Reducer is pure — test in isolation |
| Debuggability | Hard to trace | Action log is a free changelog |
| Boilerplate | Minimal | Action types + reducer |

---

## 8. `useContext`

Reads a context value provided by the nearest `<Context.Provider>` above.

```tsx
const ThemeContext = createContext<'light' | 'dark'>('light');
const theme = useContext(ThemeContext);
```

**Performance caveat:** every consumer re-renders when the provider's `value` changes by reference. Mitigations:
- Memoize the value: `<Provider value={useMemo(() => ({ a, b }), [a, b])}>`.
- Split contexts (state vs dispatch, theme vs locale).
- For high-frequency updates, use a store (Zustand, Redux) instead.

Full coverage in Topic 9.

---

## 9. `useMemo` & `useCallback`

```tsx
const filtered = useMemo(() => items.filter(matches), [items, matches]);
const onClick  = useCallback((id) => dispatch({ type: 'toggle', id }), []);
```

| Hook | Memoizes | Use when |
|---|---|---|
| `useMemo` | The **result** of a computation | Computation is genuinely expensive, or its identity is a dep elsewhere |
| `useCallback` | A **function reference** | Function is passed to `React.memo` child, or used as effect dep |

Both are **optimizations, not semantics**. Don't sprinkle them everywhere — they have their own cost (allocation, dep comparison) and the React compiler (in 19) will do this automatically.

---

## 10. `useId`

Returns a unique, **SSR-stable** id for accessibility attributes. Don't use for keys.

```tsx
const id = useId();
return (
  <>
    <label htmlFor={id}>Email</label>
    <input id={id} />
  </>
);
```

---

## 11. `useImperativeHandle` + `forwardRef`

Expose an imperative API from a child to its parent. Use sparingly — prefer declarative props.

```tsx
const Modal = forwardRef<{ open: () => void; close: () => void }, Props>((props, ref) => {
  const [open, setOpen] = useState(false);
  useImperativeHandle(ref, () => ({
    open:  () => setOpen(true),
    close: () => setOpen(false),
  }), []);
  // ...
});

// parent
const modalRef = useRef<{ open: () => void } | null>(null);
modalRef.current?.open();
```

---

## 12. Concurrent Hooks (`useTransition`, `useDeferredValue`)

These mark updates as **non-urgent** so React can keep typing/animation responsive.

```tsx
const [isPending, startTransition] = useTransition();
startTransition(() => setQuery(value));

const deferred = useDeferredValue(query); // lags behind during heavy work
```

Full coverage in Topic 10.

---

## 13. `useSyncExternalStore`

Subscribes to an external store with a tear-free read. This is what Redux, Zustand, and Jotai use under the hood.

```tsx
const online = useSyncExternalStore(
  (cb) => { window.addEventListener('online', cb); window.addEventListener('offline', cb); return () => { /* unsub */ }; },
  () => navigator.onLine,            // client snapshot
  () => true,                        // SSR snapshot
);
```

---

## 14. React 19 Hooks (Quick Tour)

| Hook | Purpose |
|---|---|
| `useFormStatus()` | Inside a `<form>` action, exposes `pending`, `data`, `method` |
| `useActionState(action, initial)` | Manages async form action state + result |
| `useOptimistic(state, reducer)` | Show optimistic UI before server confirms |
| `use(promise)` | Suspend on a promise; works in render or with context |

These are deeply tied to Server Components and form actions; treat them as advanced topics for now.

---

## 15. Custom Hooks

A custom hook is just a function whose name starts with `use` and that calls other hooks. It encapsulates and reuses stateful logic.

### Rules

- Name MUST start with `use` — the linter relies on it.
- Can call other hooks, including other custom hooks.
- Each call site gets its **own isolated state** — hooks are not singletons.
- Return shape: tuple `[value, setValue]` (mirrors `useState`) or object `{ x, y }` for 3+ values.

### `usePrevious`

```tsx
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();
  useEffect(() => { ref.current = value; }, [value]);
  return ref.current;
}
```

### `useToggle`

```tsx
function useToggle(initial = false) {
  const [on, setOn] = useState(initial);
  const toggle = useCallback(() => setOn(o => !o), []);
  return [on, toggle, setOn] as const;
}
```

### `useLocalStorage` (with cross-tab sync)

```tsx
function useLocalStorage<T>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => {
    try {
      const raw = localStorage.getItem(key);
      return raw ? (JSON.parse(raw) as T) : initial;
    } catch { return initial; }
  });

  useEffect(() => {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch {}
  }, [key, value]);

  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === key && e.newValue) {
        try { setValue(JSON.parse(e.newValue)); } catch {}
      }
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, [key]);

  return [value, setValue] as const;
}
```

### `useDebouncedValue`

```tsx
function useDebouncedValue<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
```

### `useThrottle`

```tsx
function useThrottle<T>(value: T, delay: number): T {
  const [throttled, setThrottled] = useState(value);
  const lastRun = useRef(Date.now());
  useEffect(() => {
    const elapsed = Date.now() - lastRun.current;
    const id = setTimeout(() => {
      lastRun.current = Date.now();
      setThrottled(value);
    }, Math.max(0, delay - elapsed));
    return () => clearTimeout(id);
  }, [value, delay]);
  return throttled;
}
```

### `useEventListener`

```tsx
function useEventListener<K extends keyof WindowEventMap>(
  event: K, handler: (e: WindowEventMap[K]) => void, target: Window | HTMLElement = window,
) {
  const saved = useRef(handler);
  useEffect(() => { saved.current = handler; }, [handler]);
  useEffect(() => {
    const listener = (e: Event) => saved.current(e as WindowEventMap[K]);
    target.addEventListener(event, listener);
    return () => target.removeEventListener(event, listener);
  }, [event, target]);
}
```

### `useOnClickOutside`

```tsx
function useOnClickOutside(ref: RefObject<HTMLElement>, handler: (e: MouseEvent) => void) {
  useEffect(() => {
    const listener = (e: MouseEvent) => {
      if (!ref.current || ref.current.contains(e.target as Node)) return;
      handler(e);
    };
    document.addEventListener('mousedown', listener);
    return () => document.removeEventListener('mousedown', listener);
  }, [ref, handler]);
}
```

### `useMediaQuery`

```tsx
function useMediaQuery(query: string): boolean {
  const get = () => window.matchMedia(query).matches;
  const [matches, setMatches] = useState(get);
  useEffect(() => {
    const mql = window.matchMedia(query);
    const onChange = () => setMatches(mql.matches);
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [query]);
  return matches;
}
```

### `useInterval` (Dan Abramov pattern — handles stale callback)

```tsx
function useInterval(callback: () => void, delay: number | null) {
  const saved = useRef(callback);
  useEffect(() => { saved.current = callback; }, [callback]);
  useEffect(() => {
    if (delay === null) return;
    const id = setInterval(() => saved.current(), delay);
    return () => clearInterval(id);
  }, [delay]);
}
```

### `useFetch` (with abort)

```tsx
function useFetch<T>(url: string) {
  const [state, setState] = useState<{ data?: T; error?: Error; loading: boolean }>({ loading: true });
  useEffect(() => {
    const ac = new AbortController();
    setState({ loading: true });
    fetch(url, { signal: ac.signal })
      .then(r => r.ok ? r.json() : Promise.reject(new Error(r.statusText)))
      .then(data => setState({ data, loading: false }))
      .catch(error => { if (error.name !== 'AbortError') setState({ error, loading: false }); });
    return () => ac.abort();
  }, [url]);
  return state;
}
```

---

## 16. Stale Closures

A stale closure happens when a function captures a value from an old render and runs later — by then the value is out of date.

```tsx
function Counter() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setCount(count + 1), 1000); // count is always 0!
    return () => clearInterval(id);
  }, []); // empty deps freeze count at 0
}
```

**Three fixes:**

1. **Functional updater** — doesn't read `count` from the closure: `setCount(c => c + 1)`.
2. **Ref-as-mailbox** — store latest value in a ref, read inside callback.
3. **Add to deps** — re-create the interval each tick (often wasteful here, but correct).

---

## 17. TypeScript with Hooks

```tsx
const [user, setUser] = useState<User | null>(null);
const [items, setItems] = useState<Item[]>([]);

const inputRef = useRef<HTMLInputElement>(null);     // for DOM
const timer    = useRef<number | null>(null);        // for mutable
const latest   = useRef<string>('');                 // never null

const [state, dispatch] = useReducer<Reducer<State, Action>>(reducer, initial);

// Context: cast or use a non-null helper to avoid `T | undefined`
const Ctx = createContext<Auth | null>(null);
function useAuth() {
  const v = useContext(Ctx);
  if (!v) throw new Error('useAuth must be used within <AuthProvider>');
  return v;
}
```

---

## 18. Testing Hooks (preview of Topic 11)

```tsx
import { renderHook, act } from '@testing-library/react';

test('useToggle flips', () => {
  const { result } = renderHook(() => useToggle(false));
  expect(result.current[0]).toBe(false);
  act(() => result.current[1]());
  expect(result.current[0]).toBe(true);
});
```

Mock timers with `vi.useFakeTimers()` / `jest.useFakeTimers()` and advance with `vi.advanceTimersByTime(1000)`.

---

## 19. Common Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Missing dep | Stale value in effect | Add to deps, or restructure |
| Mutating state | UI doesn't update | Always create new objects/arrays |
| Non-serializable in state | Hydration / equality bugs | Keep DOM nodes, class instances in refs |
| Infinite render | Effect sets state with new ref each time | Memoize, or guard with equality check |
| Setting state in render | Loop / warning | Move to event handler or effect |
| Conditional hook | "Rendered fewer hooks" error | Always call at top level |
| Reading ref during render | Inconsistency | Read refs in effects/handlers, not render |

---

## 20. Mental Model Summary — The React Timeline

```
 trigger (event / prop change / state set)
    │
    ▼
┌────────┐    ┌────────┐    ┌─────────────────┐    ┌────────┐
│ render │ -> │ commit │ -> │ useLayoutEffect │ -> │ paint  │
│ (pure) │    │ (DOM)  │    │ (sync)          │    │        │
└────────┘    └────────┘    └─────────────────┘    └────────┘
                                                        │
                                                        ▼
                                                  ┌──────────┐
                                                  │ useEffect│
                                                  │  (async) │
                                                  └──────────┘
```

- **Render** must be pure: same inputs → same JSX. No side effects.
- **Commit** applies DOM changes.
- **Layout effects** read/mutate DOM synchronously before paint.
- **Effects** run after paint — most synchronization belongs here.

---

## Key Takeaways

- Hooks colocate stateful logic and make it reusable as plain functions.
- Two rules: top-level only, React functions only — let the linter enforce them.
- `useState` for simple state, `useReducer` for complex transitions; both with **functional updates** when next-depends-on-prev.
- `useEffect` synchronizes with the outside world; **dependencies are not optional**, cleanup is not optional.
- Most "I need an effect" instincts are wrong — derive on render, handle in event handlers, or set initial state.
- `useRef` for anything that must persist across renders without triggering them.
- Custom hooks (`use*`) are how you DRY-up stateful logic — they are just functions.
- Stale closures are the #1 source of "but I set the state!" bugs. Functional updates and refs fix them.
- `useMemo`/`useCallback` are optimizations; default to *not* using them until measurement says otherwise.
- StrictMode double-renders effects in dev to expose missing cleanup — embrace it.
