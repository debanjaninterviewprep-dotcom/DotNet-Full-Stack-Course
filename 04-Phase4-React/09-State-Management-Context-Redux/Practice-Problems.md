# Topic 9: State Management — Practice Problems

Five progressive problems take you from a hand-rolled Context to Redux Toolkit, RTK Query, Zustand, and a small XState machine. Build them in order — each reinforces concepts from the previous and from `Notes.md`.

> Setup hint: scaffold with `npm create vite@latest -- --template react-ts`. Install per problem: `@reduxjs/toolkit react-redux`, `zustand`, `xstate @xstate/react`, `msw` (for mocking).

---

## Problem 1 — Theme + Auth Context with Custom Hooks (Easy)

**Concepts:** `createContext`, `useContext`, custom hooks, provider composition, the "split state vs dispatch" pattern.

### Requirements
- Create a `ThemeProvider` exposing `{ theme: 'light' | 'dark', toggle: () => void }`.
- Create an `AuthProvider` exposing `{ user: User | null, login(creds), logout() }`.
- Each provider must export a custom hook (`useTheme`, `useAuth`) that **throws** if used outside its provider.
- Compose both providers in `App.tsx` and consume them in two unrelated components (a `Header` showing user + theme toggle, and a `Settings` page).
- Memoize the provider values with `useMemo` so unrelated re-renders don't propagate.

### Expected behavior
- Toggling theme updates `<body>` class instantly across the app.
- `login('alice', 'pw')` resolves after 300ms and updates the user in the header.
- Unmounting the provider and rendering a consumer logs the friendly error from the custom hook.

### Starter
```tsx
// theme/ThemeContext.tsx
export type Theme = 'light' | 'dark';
interface ThemeContextValue { theme: Theme; toggle: () => void }
// TODO: createContext, ThemeProvider with useState + useMemo, useTheme hook
```

---

## Problem 2 — useReducer + Context Shopping Cart (Easy-Medium)

**Concepts:** `useReducer`, action types, immutable updates, split contexts (state vs dispatch), derived selectors.

### Requirements
- Cart item: `{ id: string; name: string; price: number; qty: number }`.
- Actions: `add`, `remove`, `setQty`, `clear`. `add` must increment qty if the item already exists.
- Use **two contexts** — `CartStateContext` and `CartDispatchContext` — so components that only dispatch don't re-render on state changes.
- Provide custom hooks: `useCart()`, `useCartDispatch()`, and a derived `useCartTotal()` (memoized) returning `{ count, subtotal }`.
- Persist the cart to `localStorage`. Hydrate on mount.

### Expected behavior
- Adding the same item twice increases qty rather than duplicating.
- A `<CartIcon>` that only reads `count` does **not** re-render when an unrelated detail (e.g. `name`) changes.
- Refreshing the page restores the cart.

### Starter
```ts
type CartItem = { id: string; name: string; price: number; qty: number };
type CartAction =
  | { type: 'add'; item: Omit<CartItem, 'qty'> & { qty?: number } }
  | { type: 'remove'; id: string }
  | { type: 'setQty'; id: string; qty: number }
  | { type: 'clear' };
// TODO: reducer + provider + hooks + localStorage sync
```

---

## Problem 3 — Redux Toolkit Todos with Async Persistence (Medium)

**Concepts:** `configureStore`, `createSlice`, `createAsyncThunk`, typed hooks, selectors, `extraReducers`.

### Requirements
- Slice `todos`: state shape `{ items: Todo[]; status: 'idle'|'loading'|'failed'; error?: string }`.
- Reducers: `added`, `toggled`, `removed`, `edited`.
- Two thunks:
  - `loadTodos` → reads from `/api/todos` (mock with MSW) on app start.
  - `saveTodos` → POSTs the current items list; dispatched after every mutating action via a small middleware **or** a `useEffect` that watches the items.
- Provide typed `useAppSelector` and `useAppDispatch`.
- Selectors: `selectAllTodos`, `selectActiveCount`, `selectCompletedCount` (use `createSelector` for memoization).
- Wire to a `<TodoApp>` UI: input, list, toggle, delete, "clear completed" button.

### Expected behavior
- On reload, the saved list reappears (verify in MSW handlers).
- Failing the network call sets `status === 'failed'` and shows an error banner.
- DevTools shows actions like `todos/added`, `todos/loadTodos/pending|fulfilled|rejected`.

### Starter
```ts
// features/todos/todosSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
export interface Todo { id: string; text: string; done: boolean }
// TODO: initialState, thunks, slice with reducers + extraReducers
```

---

## Problem 4 — RTK Query Blog with Optimistic Updates (Medium-Hard)

**Concepts:** `createApi`, `query` vs `mutation` endpoints, `tagTypes`, `providesTags` / `invalidatesTags`, optimistic `onQueryStarted`, polling, prefetching.

### Requirements
- `blogApi` with endpoints:
  - `getPosts` (list, provides `Post LIST` and per-id tags).
  - `getPost(id)` (provides per-id tag).
  - `addPost` (invalidates `LIST`).
  - `updatePost` — must perform an **optimistic update** with `updateQueryData`; rollback on failure.
  - `deletePost` (invalidates the id and `LIST`).
- Use `useGetPostsQuery` with `pollingInterval: 10000` on the list page.
- On hovering a post in the list, `usePrefetch('getPost')` for snappy navigation.
- Build pages: `/posts`, `/posts/:id`, `/posts/new`, `/posts/:id/edit`.
- Show loading skeletons via `isLoading` / `isFetching`, errors via `error`.
- Use MSW for the mock API with realistic latency (~500ms).

### Expected behavior
- Editing a post title updates the UI instantly; if the mock returns a 500, the title reverts within a second and a toast appears.
- Deleting a post removes it from the list without a manual refetch.
- Detail page loads from cache when navigated to from a hovered link.

### Starter
```ts
// services/blogApi.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
export interface Post { id: string; title: string; body: string }
// TODO: createApi with tagTypes: ['Post'], endpoints, optimistic update
```

---

## Problem 5 — Context → Zustand Refactor + XState Checkout Machine (Hard)

**Concepts:** Zustand stores + slices + middleware, migrating away from Context, finite state machines, `@xstate/react`.

This is two linked tasks; build them in the same app.

### Part A — Refactor the cart from Problem 2 to Zustand
- Replace the two contexts and reducer with a Zustand store.
- Use the **slices pattern**: `createCartSlice`, `createUiSlice` (e.g. `isCartOpen`), combined into one root store.
- Apply middleware: `devtools`, `persist` (only persist the cart slice, not UI state — selective `partialize`), `immer` for ergonomic updates.
- Subscribe selectively: `<CartIcon>` selects `count`, `<CartDrawer>` selects items — assert with React DevTools profiler that `<CartIcon>` doesn't re-render on item edits.

### Part B — Checkout flow as an XState machine
- Build a machine with states: `idle → cart → shipping → payment → confirm → (success | failure)`.
- Events: `START`, `NEXT`, `BACK`, `CANCEL`, `SUBMIT`, `RETRY`.
- `confirm.SUBMIT` invokes a service that resolves or rejects randomly (50/50). On reject, transition to `failure`; `RETRY` returns to `payment`.
- Use `@xstate/react`'s `useMachine` in a `<Checkout>` component. Render only the screen for the current state — there should be **no booleans like `isShipping` or `isPaying`**.
- Disable the "Next" button when `state.matches('confirm')`; show a spinner while the invoked service is pending.
- Wire it to the Zustand cart: `cart` state of the machine reads items from Zustand; `confirm.SUBMIT` clears the Zustand cart on success.

### Expected behavior
- The cart still works exactly as before from a user's perspective; only the implementation changed.
- Reloading the page keeps cart contents but **resets** UI state (drawer closed) and the machine to `idle`.
- Impossible states (e.g. "on the payment screen but cart is empty") cannot occur — the machine refuses the transition.
- The XState inspector (or a simple debug overlay showing `state.value`) reflects every transition.

### Starter
```ts
// store/useAppStore.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
// TODO: type slices, createCartSlice, createUiSlice, combine, partialize
```

```ts
// machines/checkoutMachine.ts
import { createMachine, assign } from 'xstate';
// TODO: states idle/cart/shipping/payment/confirm/success/failure with transitions
```

---

## Stretch Goals

- **Problem 3+:** add `createEntityAdapter` to normalize todos and replace hand-written selectors.
- **Problem 4+:** add infinite scroll using `merge` in the `getPosts` endpoint.
- **Problem 5+:** model the machine's `confirm` service with `fromPromise` and visualize the machine in Stately.ai.
