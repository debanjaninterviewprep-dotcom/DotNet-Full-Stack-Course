# Topic 9: State Management (Context + Redux Toolkit basics)

State management is the art of deciding **where** a piece of data lives, **who** can read it, and **who** can change it. The wrong choice leads to prop drilling, stale data, mystery re-renders, and bugs that are hard to reproduce. The right choice keeps components simple and the data flow predictable.

This topic walks the full spectrum — from a single `useState` to a fully normalized Redux store with RTK Query — and covers modern alternatives (Zustand, Jotai, Valtio, XState) so you can pick the right tool per feature, not per app.

---

## 1. The State Management Spectrum

State is not a monolith. Most apps have **multiple kinds** of state, each best handled by a different mechanism.

| Layer | Example | Tool |
| --- | --- | --- |
| Local component state | input value, dropdown open/closed | `useState`, `useReducer` |
| Lifted state | a value shared by 2-3 sibling components | lift to nearest common parent |
| Cross-cutting UI state | theme, locale, current user | React Context |
| App-wide client state | cart, filters, multi-step wizard | Redux Toolkit, Zustand, Jotai |
| Server cache (remote data) | list of users from `/api/users` | RTK Query, TanStack Query, SWR |
| URL state | current page, filters in querystring | router (React Router, TanStack Router) |
| Machine / workflow state | checkout flow, video player | XState |

> **Rule of thumb:** start at the bottom (local), move up only when a real need appears (more than two siblings need it, or persistence/caching is required).

---

## 2. When NOT to Reach for Global State

Global state has a real cost: every consumer can change unexpectedly, debugging gets harder, and coupling grows. Avoid it when:

- **Prop drilling is only 1-2 levels deep.** Just pass the prop. Component composition (`children`) often eliminates drilling without any tool.
- **The data is server state.** A cart fetched from `/api/cart` belongs in a server-cache library (RTK Query / TanStack Query), not Redux. You don't want to manually sync, refetch, and invalidate.
- **The data belongs in the URL.** Filters, page numbers, selected tabs — put them in the querystring so links are shareable.
- **Only one component uses it.** That's `useState`, full stop.

---

## 3. React Context — the Built-in Option

`React.createContext` provides a way to pass values down the tree without prop drilling. It is **not** a state manager; it's a **transport mechanism** for values you already have.

```tsx
import { createContext, useContext, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark';
interface ThemeContextValue {
  theme: Theme;
  toggle: () => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');
  const toggle = () => setTheme(t => (t === 'light' ? 'dark' : 'light'));
  return (
    <ThemeContext.Provider value={{ theme, toggle }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used inside <ThemeProvider>');
  return ctx;
}
```

Always wrap `useContext` in a custom hook so consumers get a friendly error instead of `Cannot read properties of undefined`.

---

## 4. The Context Performance Pitfall

When the value passed to a `Provider` changes, **every component that consumes that context re-renders** — even if it only reads a field that didn't change. With a big context object, this means typing in one input can re-render half the app.

### Solutions

1. **Memoize the value** so unrelated parent re-renders don't create a new object reference:
   ```tsx
   const value = useMemo(() => ({ theme, toggle }), [theme]);
   ```
2. **Split contexts** by what changes together. A classic split is **state** vs **dispatch**:
   ```tsx
   <CartStateContext.Provider value={state}>
     <CartDispatchContext.Provider value={dispatch}>
       {children}
     </CartDispatchContext.Provider>
   </CartStateContext.Provider>
   ```
   Components that only dispatch never re-render when state changes.
3. **`use-context-selector`** library — subscribe to a *slice* of the context, like Redux's `useSelector`.
4. **Atom-based libraries** (Jotai, Recoil) — fine-grained reactivity by design; only consumers of changed atoms re-render.

---

## 5. `useReducer` + Context Pattern

For medium-sized apps, `useReducer` + Context gives you Redux-style predictability without the dependency. Great for cart, auth, theme, multi-step forms.

```tsx
type CartItem = { id: string; name: string; qty: number; price: number };
type State = { items: CartItem[] };
type Action =
  | { type: 'add'; item: CartItem }
  | { type: 'remove'; id: string }
  | { type: 'setQty'; id: string; qty: number }
  | { type: 'clear' };

const initial: State = { items: [] };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'add': {
      const existing = state.items.find(i => i.id === action.item.id);
      if (existing) {
        return {
          items: state.items.map(i =>
            i.id === action.item.id ? { ...i, qty: i.qty + action.item.qty } : i
          ),
        };
      }
      return { items: [...state.items, action.item] };
    }
    case 'remove':
      return { items: state.items.filter(i => i.id !== action.id) };
    case 'setQty':
      return {
        items: state.items.map(i =>
          i.id === action.id ? { ...i, qty: Math.max(1, action.qty) } : i
        ),
      };
    case 'clear':
      return initial;
  }
}

const StateCtx = createContext<State | undefined>(undefined);
const DispatchCtx = createContext<React.Dispatch<Action> | undefined>(undefined);

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, initial);
  return (
    <StateCtx.Provider value={state}>
      <DispatchCtx.Provider value={dispatch}>{children}</DispatchCtx.Provider>
    </StateCtx.Provider>
  );
}

export const useCartState = () => {
  const c = useContext(StateCtx);
  if (!c) throw new Error('useCartState requires <CartProvider>');
  return c;
};
export const useCartDispatch = () => {
  const c = useContext(DispatchCtx);
  if (!c) throw new Error('useCartDispatch requires <CartProvider>');
  return c;
};
```

Combining multiple slices (`theme`, `auth`, `cart`) is a matter of nesting providers in `App.tsx`. Once you have 4-5 of these, consider Redux Toolkit or Zustand.

---

## 6. Redux Core Concepts

Redux is a predictable state container built on three principles:

1. **Single source of truth** — one store for the whole app.
2. **State is read-only** — the only way to change it is to dispatch an action.
3. **Changes are made by pure functions** — reducers `(state, action) => newState`.

```text
                ┌─────────────┐
   dispatch     │             │   subscribe
  ┌────────────►│   STORE     │◄────────────┐
  │             │  (state)    │             │
  │             └──────┬──────┘             │
  │                    │                    │
┌─┴────────┐    ┌──────▼──────┐      ┌──────┴──────┐
│  Action  │───►│   Reducer   │      │ Components  │
│ {type,   │    │ (state, a)  │      │ (useSelector│
│ payload} │    │ => newState │      │  + dispatch)│
└──────────┘    └─────────────┘      └─────────────┘
```

- **Action** — plain object describing *what happened*: `{ type: 'todos/added', payload: {...} }`.
- **Reducer** — pure function returning the next state. Must not mutate.
- **Store** — holds state, accepts dispatched actions, notifies subscribers.
- **Selector** — function that derives data from state: `state => state.todos.items`.
- **Immutability** — required so React can detect changes via reference equality.

---

## 7. Redux Toolkit (RTK) — the Modern Way

Plain Redux is verbose. **Redux Toolkit** is the official, recommended way to write Redux. It bundles best practices, removes boilerplate, and ships with Immer (so you can "mutate" inside reducers).

```ts
// store.ts
import { configureStore } from '@reduxjs/toolkit';
import todosReducer from './features/todos/todosSlice';
import authReducer from './features/auth/authSlice';

export const store = configureStore({
  reducer: {
    todos: todosReducer,
    auth: authReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

```ts
// features/todos/todosSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';

export interface Todo { id: string; text: string; done: boolean }
interface TodosState { items: Todo[]; status: 'idle' | 'loading' | 'failed' }

const initialState: TodosState = { items: [], status: 'idle' };

export const fetchTodos = createAsyncThunk('todos/fetch', async () => {
  const res = await fetch('/api/todos');
  return (await res.json()) as Todo[];
});

const todosSlice = createSlice({
  name: 'todos',
  initialState,
  reducers: {
    added: (state, action: PayloadAction<Todo>) => {
      state.items.push(action.payload); // Immer makes this safe
    },
    toggled: (state, action: PayloadAction<string>) => {
      const t = state.items.find(t => t.id === action.payload);
      if (t) t.done = !t.done;
    },
    removed: (state, action: PayloadAction<string>) => {
      state.items = state.items.filter(t => t.id !== action.payload);
    },
  },
  extraReducers: builder => {
    builder
      .addCase(fetchTodos.pending, s => { s.status = 'loading'; })
      .addCase(fetchTodos.fulfilled, (s, a) => { s.status = 'idle'; s.items = a.payload; })
      .addCase(fetchTodos.rejected, s => { s.status = 'failed'; });
  },
});

export const { added, toggled, removed } = todosSlice.actions;
export default todosSlice.reducer;
```

Notice:
- `createSlice` auto-generates action creators and action types.
- Inside reducers, you can write mutating syntax — Immer produces an immutable result.
- `createAsyncThunk` standardizes async flows with `pending` / `fulfilled` / `rejected`.

---

## 8. React-Redux Hooks

```tsx
// hooks.ts — typed hooks (do this once, use everywhere)
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

```tsx
// TodoList.tsx
import { shallowEqual } from 'react-redux';
import { useAppSelector, useAppDispatch } from './hooks';
import { added, toggled, removed } from './todosSlice';

export function TodoList() {
  const items = useAppSelector(s => s.todos.items, shallowEqual);
  const dispatch = useAppDispatch();
  return (
    <ul>
      {items.map(t => (
        <li key={t.id} onClick={() => dispatch(toggled(t.id))}>
          {t.done ? '✓' : '○'} {t.text}
          <button onClick={() => dispatch(removed(t.id))}>x</button>
        </li>
      ))}
    </ul>
  );
}
```

`shallowEqual` prevents re-renders when a selector returns a new array/object with identical contents. For a single primitive value (`s => s.user.name`), the default `===` is fine.

Wrap the app once:
```tsx
import { Provider } from 'react-redux';
<Provider store={store}><App /></Provider>
```

---

## 9. RTK Query — Server State, Done Right

**RTK Query** is built into Redux Toolkit. It handles fetching, caching, deduplication, refetching, polling, and invalidation — the things you'd otherwise build by hand.

```ts
// services/blogApi.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export interface Post { id: string; title: string; body: string }

export const blogApi = createApi({
  reducerPath: 'blogApi',
  baseQuery: fetchBaseQuery({ baseUrl: '/api/' }),
  tagTypes: ['Post'],
  endpoints: build => ({
    getPosts: build.query<Post[], void>({
      query: () => 'posts',
      providesTags: result =>
        result
          ? [...result.map(p => ({ type: 'Post' as const, id: p.id })), { type: 'Post', id: 'LIST' }]
          : [{ type: 'Post', id: 'LIST' }],
    }),
    getPost: build.query<Post, string>({
      query: id => `posts/${id}`,
      providesTags: (_r, _e, id) => [{ type: 'Post', id }],
    }),
    addPost: build.mutation<Post, Partial<Post>>({
      query: body => ({ url: 'posts', method: 'POST', body }),
      invalidatesTags: [{ type: 'Post', id: 'LIST' }],
    }),
    updatePost: build.mutation<Post, Post>({
      query: post => ({ url: `posts/${post.id}`, method: 'PUT', body: post }),
      invalidatesTags: (_r, _e, post) => [{ type: 'Post', id: post.id }],
      // Optimistic update
      async onQueryStarted(post, { dispatch, queryFulfilled }) {
        const patch = dispatch(
          blogApi.util.updateQueryData('getPost', post.id, draft => {
            Object.assign(draft, post);
          })
        );
        try { await queryFulfilled; } catch { patch.undo(); }
      },
    }),
    deletePost: build.mutation<void, string>({
      query: id => ({ url: `posts/${id}`, method: 'DELETE' }),
      invalidatesTags: (_r, _e, id) => [{ type: 'Post', id }, { type: 'Post', id: 'LIST' }],
    }),
  }),
});

export const {
  useGetPostsQuery, useGetPostQuery,
  useAddPostMutation, useUpdatePostMutation, useDeletePostMutation,
} = blogApi;
```

Register it in the store:
```ts
configureStore({
  reducer: { [blogApi.reducerPath]: blogApi.reducer, /* ... */ },
  middleware: gdm => gdm().concat(blogApi.middleware),
});
```

Use it in a component:
```tsx
const { data, isLoading, error } = useGetPostsQuery();
const [addPost, { isLoading: adding }] = useAddPostMutation();
```

You also get **polling** (`{ pollingInterval: 5000 }`), **prefetching** (`api.usePrefetch('getPost')`), and automatic refetch on focus / reconnect.

---

## 10. Redux DevTools

`configureStore` enables the Redux DevTools browser extension automatically in development. You get:

- Full action log with payloads.
- **Time-travel debugging** — jump back to any previous state.
- Action replay, state diffing, dispatching custom actions.
- Import/export sessions to reproduce bugs.

This is one of Redux's biggest practical advantages over alternatives.

---

## 11. Middleware

Middleware sits between `dispatch` and the reducer. RTK includes sensible defaults; you can add more.

| Middleware | Use Case |
| --- | --- |
| `redux-thunk` | Functions as actions. Built into RTK. Good for most async. |
| `redux-saga` | Generator-based; complex flows, cancellation, racing, channels. |
| `redux-observable` | RxJS streams; reactive, declarative async pipelines. |
| `redux-logger` | Logs every action (dev-only; DevTools usually replaces it). |

Most apps need only thunks (or RTK Query). Reach for sagas/observables when you have **long-running, cancellable, multi-step** async logic.

---

## 12. Redux Best Practices

- **Normalize collections.** Store entities by id, keep an `ids` array for order.
- Use **`createEntityAdapter`** — it generates CRUD reducers and selectors for normalized state.
- **Feature-based folders** (`features/todos/`, `features/auth/`) over type-based (`reducers/`, `actions/`).
- **Slices over ducks.** RTK's `createSlice` is the modern evolution of the ducks pattern.
- Keep selectors **co-located** with the slice. Use `reselect` (`createSelector`) for memoized derived data.
- Don't store **derived state** — compute it in selectors.

```ts
import { createEntityAdapter, createSlice } from '@reduxjs/toolkit';

const adapter = createEntityAdapter<Todo>();
const slice = createSlice({
  name: 'todos',
  initialState: adapter.getInitialState({ status: 'idle' }),
  reducers: {
    added: adapter.addOne,
    updated: adapter.updateOne,
    removed: adapter.removeOne,
  },
});
export const todosSelectors = adapter.getSelectors((s: RootState) => s.todos);
```

---

## 13. Persistence

- **`redux-persist`** — saves slices to `localStorage` / `AsyncStorage`, rehydrates on boot. Supports whitelist/blacklist for selective persistence.
- **Custom middleware** — write `state => localStorage.setItem(...)` after every action; simple and dependency-free.
- **RTK Query** — for server data, rely on the cache; persist only auth tokens/UI prefs.

```ts
// minimal localStorage middleware
const persist: Middleware = store => next => action => {
  const result = next(action);
  localStorage.setItem('app', JSON.stringify(store.getState().preferences));
  return result;
};
```

---

## 14. TypeScript with Redux

- Type your **`RootState`** and **`AppDispatch`** from the store, not by hand.
- Use **`PayloadAction<T>`** in reducers.
- Create typed hooks (`useAppSelector`, `useAppDispatch`) once and reuse.
- For thunks: `createAsyncThunk<Returned, Arg, { state: RootState }>`.

This setup gives you full inference: `state.todos.items[0].text` is fully typed, and dispatching a wrong payload is a compile error.

---

## 15. Comparison of State Libraries

| Library | Bundle | API style | Boilerplate | DevTools | Best for |
| --- | --- | --- | --- | --- | --- |
| **Redux Toolkit** | ~13 KB | Flux + slices | Low (with RTK) | Excellent | Large apps, teams, audit trails |
| **Zustand** | ~1 KB | Hook-based store | Minimal | Yes (devtools middleware) | Most apps, fast prototyping |
| **Jotai** | ~3 KB | Atoms (Recoil-like) | Low | Yes | Fine-grained reactivity, derived state |
| **Recoil** | ~20 KB | Atoms + selectors | Low | Yes | Similar to Jotai; Meta-backed but less active |
| **Valtio** | ~3 KB | Mutable proxies | Very low | Yes | Devs who like mutable syntax |
| **MobX** | ~16 KB | Observables + classes | Medium | Yes | OOP codebases |
| **XState** | ~15 KB | State machines | Medium | Inspector | Complex workflows, finite states |

---

## 16. Zustand — the Pragmatic Choice

Zustand is a tiny, hook-based store. Reducers, providers, and action types are optional.

```ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface BearStore {
  bears: number;
  increase: () => void;
  reset: () => void;
}

export const useBears = create<BearStore>()(
  devtools(
    persist(
      immer(set => ({
        bears: 0,
        increase: () => set(s => { s.bears += 1; }),
        reset: () => set({ bears: 0 }),
      })),
      { name: 'bears' }
    )
  )
);

// in a component
const bears = useBears(s => s.bears);
const increase = useBears(s => s.increase);
```

**Slices pattern** lets you split a big store into modules and combine them, similar to Redux slices, but without the ceremony.

---

## 17. Jotai — Atom-Based

Atoms are tiny, independently subscribable units of state. Only components reading a changed atom re-render.

```ts
import { atom, useAtom } from 'jotai';

const countAtom = atom(0);
const doubledAtom = atom(get => get(countAtom) * 2); // derived

function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const [doubled] = useAtom(doubledAtom);
  return <button onClick={() => setCount(c => c + 1)}>{count} / {doubled}</button>;
}
```

`atomFamily` creates parameterized atoms (e.g. one atom per todo id) — perfect for normalized lists with fine-grained updates.

---

## 18. Recoil and Valtio — Brief Mentions

- **Recoil** — Meta's atom-based library, very similar to Jotai. Development has slowed; new projects usually prefer Jotai.
- **Valtio** — uses a JavaScript Proxy so you mutate state directly: `state.count++`. Reads are tracked automatically. Great for game-like UIs and devs who dislike functional updates.

---

## 19. XState — State Machines for Workflows

When state has clear, distinct *modes* with rules about which transitions are legal (a checkout flow, video player, form wizard), a **finite state machine** is more correct than booleans.

```ts
import { createMachine } from 'xstate';

const checkoutMachine = createMachine({
  id: 'checkout',
  initial: 'idle',
  states: {
    idle:     { on: { START: 'cart' } },
    cart:     { on: { NEXT: 'shipping', CANCEL: 'idle' } },
    shipping: { on: { NEXT: 'payment',  BACK: 'cart' } },
    payment:  { on: { NEXT: 'confirm',  BACK: 'shipping' } },
    confirm:  { on: { SUBMIT: 'success', FAIL: 'failure' } },
    success:  { type: 'final' },
    failure:  { on: { RETRY: 'payment' } },
  },
});
```

Impossible states (`isLoading && isError`) cannot exist by construction. The XState inspector visualizes the machine and current state live.

---

## 20. Server State vs Client State (Reprise)

| | Client/UI state | Server state |
| --- | --- | --- |
| Owner | the browser | the database |
| Examples | theme, modal open, form draft | users, posts, orders |
| Tools | Redux, Zustand, Jotai, Context | RTK Query, TanStack Query, SWR |
| Pain points | re-renders, persistence | caching, staleness, refetching |

Mixing them in one Redux slice is a common mistake — manually re-implementing a cache. Use a server-cache library for server data, a client-state library for UI state.

---

## 21. Migration Paths as the App Grows

```text
useState              // toy / single component
   │
   ▼
useReducer + Context  // 5-15 components share state
   │
   ▼
Zustand (or Jotai)    // app-wide, low ceremony
   │
   ▼
Redux Toolkit + RTK Q // large app, multiple teams, audit needed
```

You rarely need to "rewrite" — start small, lift state up only when pain appears.

---

## 22. Common Pitfalls

- **Storing derived state.** If `total` can be computed from `items`, don't store it. Use a selector.
- **Mutating Redux state outside Immer.** `state.items.push(x)` outside a slice reducer breaks reference equality and DevTools.
- **One giant context.** Every consumer re-renders on every change. Split it.
- **Useless re-renders from new object identities.** `value={{ a, b }}` in a Provider creates a new object every render — memoize it.
- **Stale closures in event handlers.** A `setTimeout` capturing `state` reads the old value. Use a ref or the functional updater.
- **Mixing server and client state.** Don't load `/api/users` into a Redux slice manually if RTK Query/TanStack Query exists.

---

## 23. Testing

- **Reducers / slices** — pure functions, test directly:
  ```ts
  expect(reducer(initial, added(todo))).toEqual({ items: [todo], status: 'idle' });
  ```
- **Selectors** — call with a sample state and assert.
- **Async thunks** — mock fetch (MSW), dispatch, await, assert resulting state.
- **Components with Provider** — render with a real store seeded for the test:
  ```tsx
  function renderWithStore(ui: React.ReactElement, preloaded?: PreloadedState<RootState>) {
    const store = configureStore({ reducer, preloadedState: preloaded });
    return render(<Provider store={store}>{ui}</Provider>);
  }
  ```
- **Zustand** — reset stores between tests by exporting an `initialState` and calling `useStore.setState(initialState, true)`.

---

## 24. Choosing the Right Tool — Decision Flow

```text
is the data from the server?
  ├─ yes → RTK Query / TanStack Query
  └─ no
      └─ does it belong in the URL?
          ├─ yes → router state (querystring)
          └─ no
              └─ used by 1 component?         → useState
              └─ used by 2-3 close kin?       → lift state
              └─ used across the tree?
                  ├─ small + simple shape     → Context (+ useReducer)
                  ├─ medium app, low ceremony → Zustand or Jotai
                  ├─ large app, audit/team    → Redux Toolkit
                  └─ workflow with modes      → XState
```

---

## 25. Key Takeaways

- There is no single "state management" — pick a tool **per kind of state**.
- **Local first.** Most state should live in a component.
- **Context is a transport, not a store.** Beware re-renders; split or memoize.
- **Redux Toolkit** is modern Redux — slices, Immer, thunks, no boilerplate.
- **RTK Query / TanStack Query** own server state. Don't reinvent caching.
- **Zustand** is the pragmatic middle ground; **Jotai** for fine-grained atoms.
- **XState** when state is a machine with rules, not a bag of flags.
- Normalize, memoize selectors, type your hooks, and lean on DevTools.
