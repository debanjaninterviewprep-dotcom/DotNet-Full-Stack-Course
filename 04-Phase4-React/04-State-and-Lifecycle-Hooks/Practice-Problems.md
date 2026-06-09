# Topic 4: State & Lifecycle (Hooks) — Practice Problems

Six problems progressing from `useState` basics to a generic undo/redo hook. This topic is foundational — work through every problem; do not skip to later topics until custom hooks feel natural.

> Setup: Vite + React + TypeScript (`npm create vite@latest hooks-lab -- --template react-ts`). Add Vitest + `@testing-library/react` for the testing tasks. Keep ESLint's `react-hooks/rules-of-hooks` and `react-hooks/exhaustive-deps` enabled and clean.

---

## Problem 1 (Easy) — Counter with Bounds & Callback

**Concept:** `useState`, functional updates, lazy initial state, derived values.

Build a `<Counter min={0} max={10} step={1} initial={() => readFromStorage()} onChange={n => ...} />` component.

**Requirements:**
- `+` / `−` / `Reset` buttons.
- Disable `+` at `max`, `−` at `min` (compute on render — do **not** store as state).
- Use **functional updates** for both buttons.
- Use **lazy initial state** if `initial` is a function.
- Fire `onChange(value)` whenever the value changes — but only after the change, not during render.
- Bonus: a `Step ×10` button that calls `setCount` ten times in one handler — verify React 18 batching produces a single render (use `useEffect` log or React DevTools Profiler).

**Edge cases to test:**
- Clicking `+` at max does nothing.
- Reset returns to the original `initial` even if `initial` was a function.
- `onChange` is not called on the initial mount.

**Starter:**

```tsx
type Props = {
  min?: number;
  max?: number;
  step?: number;
  initial?: number | (() => number);
  onChange?: (n: number) => void;
};

export function Counter({ min = 0, max = 10, step = 1, initial = 0, onChange }: Props) {
  // your code
}
```

---

## Problem 2 (Easy-Medium) — Stopwatch with Laps

**Concept:** `useEffect` cleanup, `useRef` for timer id, separating display state from timer mechanics.

Build a stopwatch with **Start / Stop / Reset / Lap** buttons that displays elapsed time as `mm:ss.ms` and a list of lap times.

**Requirements:**
- Use `setInterval` (10ms tick) inside `useEffect`; **always clear it in cleanup**.
- Store the interval id in a `useRef`, not state.
- Track `startedAt` (timestamp) + `accumulated` ms — compute `elapsed = running ? Date.now() - startedAt + accumulated : accumulated`. Don't increment a counter (drift!).
- `Lap` pushes the current elapsed onto an array of laps.
- Reset wipes accumulated, laps, and stops.
- The display should update every tick **without** mutating the timer logic on every render.

**Edge cases:**
- Unmounting while running must clear the interval (no console warnings).
- Toggling start/stop rapidly does not double-register intervals.
- StrictMode in dev does not produce two intervals.

**Starter:**

```tsx
export function Stopwatch() {
  const [running, setRunning] = useState(false);
  const [accumulated, setAccumulated] = useState(0);
  const startedAt = useRef<number | null>(null);
  const intervalId = useRef<number | null>(null);
  const [, force] = useReducer(x => x + 1, 0);
  const [laps, setLaps] = useState<number[]>([]);
  // your code
}
```

---

## Problem 3 (Medium) — Fetch with Abort, Retry & Backoff

**Concept:** `useEffect` synchronization, `AbortController`, derived loading state, dependency correctness.

Build a `useApi<T>(url)` hook returning `{ data, error, loading, retry }` plus a `<UserCard userId={id} />` consumer.

**Requirements:**
- Cancel in-flight request when `url` changes or component unmounts (`AbortController`).
- Distinguish abort errors from real errors — abort should not set error state.
- Retry on transient failure (network error or 5xx) up to 3 times with **exponential backoff**: 250ms, 500ms, 1000ms (jitter optional).
- Expose a `retry()` function that resets state and re-fires immediately.
- No `react-hooks/exhaustive-deps` warnings — no `// eslint-disable-next-line`.
- Show loading skeleton, error UI with retry button, and success state.

**Edge cases:**
- Rapidly switching `userId` does not cause out-of-order writes (older response landing after newer one).
- 404 should NOT retry (only 5xx + network).
- Manual retry while a request is pending cancels the pending one.

**Starter:**

```tsx
type ApiState<T> = { data?: T; error?: Error; loading: boolean };

export function useApi<T>(url: string) {
  // your code
}
```

---

## Problem 4 (Medium-Hard) — Five Custom Hooks + Demo Page

**Concept:** Custom hook authoring, return shapes, isolation, cross-tab sync.

Implement these five hooks (each in its own file under `src/hooks/`) plus a `<HooksDemo />` page that exercises them all.

1. **`useToggle(initial?: boolean)`** → `[on, toggle, set] as const`.
2. **`useLocalStorage<T>(key, initial)`** → `[value, setValue]` — JSON serialize, swallow quota errors, **listen to the `storage` event** so two tabs stay in sync.
3. **`useDebouncedValue<T>(value, delay)`** → `T` — clears timer on every change.
4. **`useOnClickOutside(ref, handler)`** — uses `mousedown` + `touchstart`; ignores clicks inside `ref.current`.
5. **`useMediaQuery(query)`** → `boolean` — re-subscribes when `query` changes; uses `matchMedia.addEventListener('change', ...)` (not the deprecated `addListener`).

**Demo page must show:**
- A toggle button driving a panel's visibility.
- A counter persisted in `localStorage` under key `demo:count` — open in two tabs and confirm they stay in sync.
- A search input that displays its **debounced** value (1s).
- A dropdown that closes when clicking outside.
- A pill that reads `Mobile` / `Desktop` based on `(min-width: 768px)`.

**Edge cases:**
- `useLocalStorage` initial value: corrupt JSON in storage falls back to `initial` without throwing.
- `useDebouncedValue` returns the **latest** value if `delay` changes mid-flight.
- `useOnClickOutside` does not fire when handler is null/undefined.
- All hooks pass `renderHook` tests with no `act` warnings.

**Starter:**

```tsx
// src/hooks/useLocalStorage.ts
export function useLocalStorage<T>(key: string, initial: T) {
  // your code
}
```

---

## Problem 5 (Hard) — Todo App with `useReducer`, History & Persistence

**Concept:** Reducer design, action types, undo/redo via state snapshots, composing `useLocalStorage`.

Build a todo app whose entire state lives in a single reducer.

**State:**

```tsx
type Todo = { id: string; text: string; done: boolean; createdAt: number };
type TodoState = { todos: Todo[]; filter: 'all' | 'active' | 'done' };
type Snapshot = TodoState;
type AppState = { past: Snapshot[]; present: TodoState; future: Snapshot[] };
```

**Actions:**
- `add(text)`, `toggle(id)`, `edit(id, text)`, `delete(id)`, `clearCompleted()`, `setFilter(f)`
- `undo()`, `redo()`

**Requirements:**
- Every mutating action pushes the previous `present` onto `past` and clears `future`.
- `undo` pops `past` → moves `present` onto `future`.
- `redo` pops `future` → pushes `present` onto `past`.
- Filter changes should NOT participate in undo history (decide and document).
- Persist `present` only to `localStorage` (not the history) via your `useLocalStorage` hook.
- Reducer is **pure** — unit-test transitions with no React rendering.

**Edge cases:**
- `undo` with empty `past` is a no-op.
- Editing to empty string deletes the todo (or rejects — choose & test).
- Adding a todo with whitespace-only text is rejected.
- Reload preserves todos but resets undo history.

**Starter:**

```tsx
function rootReducer(state: AppState, action: Action): AppState {
  if (action.type === 'undo') { /* ... */ }
  if (action.type === 'redo') { /* ... */ }
  const next = todoReducer(state.present, action);
  if (next === state.present) return state;
  return { past: [...state.past, state.present], present: next, future: [] };
}
```

---

## Problem 6 (Advanced) — `useUndo` + `useFormState`

**Concept:** Generic custom hooks, reducer composition, validation as data.

### Part A — `useUndo<T>(initial: T)`

Generic history hook usable for any value.

**API:**

```tsx
const { state, set, reset, undo, redo, canUndo, canRedo, history } = useUndo<DrawingDoc>(emptyDoc);
```

**Requirements:**
- Internally uses `useReducer`.
- `set(next)` (or `set(prev => next)`) pushes onto past; `undo`/`redo` move between stacks.
- Optional `limit` (default 50) — drops oldest past entries when exceeded.
- Optional `equals` comparator (default `Object.is`) — `set` is a no-op if the new value equals the current.
- Fully typed — no `any`.

### Part B — `useFormState<Values>(config)`

A form hook combining a reducer with declarative validation.

**Config shape:**

```tsx
type Validator<V> = (value: V, all: Values) => string | undefined;

const form = useFormState({
  initial: { email: '', password: '' },
  validators: {
    email:    (v) => !v ? 'Required' : /^\S+@\S+$/.test(v) ? undefined : 'Invalid email',
    password: (v) => v.length < 8 ? 'Min 8 chars' : undefined,
  },
  onSubmit: async (values) => { await api.signup(values); },
});

form.values; form.errors; form.touched; form.isSubmitting; form.isValid;
form.handleChange('email'); form.handleBlur('email'); form.handleSubmit;
form.reset();
```

**Requirements:**
- Validation runs on `change`, `blur`, and `submit` — but errors are only **shown** for fields that have been touched (or after submit attempt).
- `isValid` is derived from running all validators on current values (no stale flag).
- `handleSubmit(e)` prevents default, marks all touched, runs all validators, and only calls `onSubmit` if valid.
- `isSubmitting` is true while `onSubmit`'s returned promise is pending; errors thrown by `onSubmit` are caught and exposed as `form.submitError`.
- Reducer-based — write at least 6 unit tests against the reducer in isolation (not the hook).

**Demo:** a signup form using `useFormState` whose live "preview" panel is wrapped by `useUndo` so the user can step backward through every keystroke. (Yes, this is overkill. That's the point — composition is free.)

---

## Global Checklist

- [ ] No `react-hooks/exhaustive-deps` warnings anywhere; no `// eslint-disable` for hook lints.
- [ ] No `react-hooks/rules-of-hooks` warnings.
- [ ] No conditional or in-loop hook calls.
- [ ] All `setInterval` / `setTimeout` / event listeners / fetches have cleanup.
- [ ] `useEffect` does not contain logic that should live in an event handler.
- [ ] No mutated state — all updates produce new objects/arrays.
- [ ] No derived value stored in `useState`.
- [ ] Functional updaters used wherever next state depends on previous.
- [ ] Lazy initializers used for expensive `useState` defaults.
- [ ] Custom hooks named `useX` and return either a tuple (1–2 values) or a typed object (3+).
- [ ] Each custom hook has at least one `renderHook` test, with fake timers where relevant.
- [ ] StrictMode is on in dev — components mount cleanly twice with no duplicate side effects.
- [ ] No `any` in TypeScript hook signatures; all `useState`/`useRef`/`useReducer` are explicitly typed when inference is insufficient.
- [ ] Reducers are pure and tested without rendering.

---

## Stretch Goals

- Replace your `useFetch` with `@tanstack/react-query` and compare ergonomics, cache, and devtools.
- Add a `useWorker(fn)` hook that offloads expensive work to a Web Worker and returns a stable `run(input)` API.
- Migrate the Todo app's reducer to a state machine using XState; observe how illegal transitions become impossible to express.
