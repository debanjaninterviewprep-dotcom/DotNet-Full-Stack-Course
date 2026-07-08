# Topic 09: State Management — Context API and Redux — Interview Questions

---

## Q1. What is the Context API and when should you use it?
**Answer:**
Context provides a way to share values between components **without prop drilling**:

```jsx
// 1. Create context with default value
const UserContext = createContext(null);

// 2. Provide value high in the tree
function App() {
  const [user, setUser] = useState(null);
  return (
    <UserContext.Provider value={{ user, setUser }}>
      <Layout />
    </UserContext.Provider>
  );
}

// 3. Consume anywhere in the tree
function UserMenu() {
  const { user, setUser } = useContext(UserContext);
  return <span onClick={() => setUser(null)}>{user?.name}</span>;
}
```

**Use Context for:** Auth state, theme, locale, small app state.
**Don't use Context for:** High-frequency updates, large/complex state — causes all consumers to re-render.

---

## Q2. How do you prevent unnecessary re-renders with Context?
**Answer:**
Every consumer re-renders when the context **value reference** changes:

```jsx
// ❌ New object on every render — ALL consumers re-render
<UserContext.Provider value={{ user, setUser }}>

// ✓ Memoize the context value
function UserProvider({ children }) {
  const [user, setUser] = useState(null);
  const value = useMemo(() => ({ user, setUser }), [user]); // stable reference
  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
}

// ✓ Split contexts — changes to theme don't re-render user consumers
<ThemeContext.Provider value={theme}>
  <UserContext.Provider value={user}>
    <App />
  </UserContext.Provider>
</ThemeContext.Provider>
```

---

## Q3. What is Redux and what problem does it solve?
**Answer:**
Redux is a **global state management** library based on the Flux architecture pattern:

**Core principles:**
1. **Single source of truth** — entire app state in one Store.
2. **State is read-only** — change only by dispatching Actions.
3. **Changes via pure functions** — Reducers describe how state changes.

**Solves:**
- Prop drilling in deep component trees.
- Shared state between unrelated components.
- Predictable state transitions (debuggable, time-travel).

**When NOT to use Redux:**
- Simple apps with local component state.
- State that only belongs to one component.
- Context API is sufficient.

---

## Q4. What is Redux Toolkit and why is it the recommended approach?
**Answer:**
Redux Toolkit (RTK) is the official, opinionated Redux toolset that eliminates boilerplate:

```jsx
// Old Redux (without RTK) — verbose
const ADD_USER = 'ADD_USER';
function addUser(user) { return { type: ADD_USER, payload: user }; }
function usersReducer(state = [], action) {
  switch(action.type) {
    case ADD_USER: return [...state, action.payload];
    default: return state;
  }
}

// Redux Toolkit — concise
import { createSlice } from '@reduxjs/toolkit';
const usersSlice = createSlice({
  name: 'users',
  initialState: [],
  reducers: {
    addUser: (state, action) => { state.push(action.payload); }, // Immer allows mutation!
    removeUser: (state, action) => state.filter(u => u.id !== action.payload)
  }
});
export const { addUser, removeUser } = usersSlice.actions;
export default usersSlice.reducer;
```

RTK uses **Immer** internally — you can write "mutating" code that is actually immutable.

---

## Q5. How do you set up a Redux Toolkit store?
**Answer:**
```typescript
// store.ts
import { configureStore } from '@reduxjs/toolkit';
import usersReducer from './features/users/usersSlice';
import authReducer  from './features/auth/authSlice';

export const store = configureStore({
  reducer: {
    users: usersReducer,
    auth:  authReducer
  }
  // middleware, devTools auto-configured by RTK
});

export type RootState   = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

// main.tsx
import { Provider } from 'react-redux';
root.render(<Provider store={store}><App /></Provider>);

// Typed hooks
export const useAppSelector = useSelector.withTypes<RootState>();
export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
```

---

## Q6. How do you read state and dispatch actions from components?
**Answer:**
```tsx
import { useSelector, useDispatch } from 'react-redux';
import { addUser, removeUser } from './usersSlice';

function UserList() {
  const dispatch = useDispatch();
  const users    = useSelector((state: RootState) => state.users);
  // OR with typed hook:
  const users    = useAppSelector(state => state.users);

  return (
    <>
      {users.map(user => (
        <div key={user.id}>
          <span>{user.name}</span>
          <button onClick={() => dispatch(removeUser(user.id))}>Delete</button>
        </div>
      ))}
      <button onClick={() => dispatch(addUser({ id: Date.now(), name: 'New User' }))}>
        Add User
      </button>
    </>
  );
}
```

---

## Q7. What is `createAsyncThunk` and how do you handle async operations?
**Answer:**
```typescript
import { createAsyncThunk, createSlice } from '@reduxjs/toolkit';

// Async thunk — handles async operations with pending/fulfilled/rejected actions
export const fetchUsers = createAsyncThunk('users/fetchAll', async (_, { rejectWithValue }) => {
  try {
    const res = await fetch('/api/users');
    if (!res.ok) throw new Error(res.statusText);
    return await res.json();
  } catch (err) {
    return rejectWithValue(err.message);
  }
});

const usersSlice = createSlice({
  name: 'users',
  initialState: { users: [], loading: false, error: null },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending,   (state)          => { state.loading = true; state.error = null; })
      .addCase(fetchUsers.fulfilled, (state, action)  => { state.loading = false; state.users = action.payload; })
      .addCase(fetchUsers.rejected,  (state, action)  => { state.loading = false; state.error = action.payload; });
  }
});

// Dispatch in component
const dispatch = useAppDispatch();
useEffect(() => { dispatch(fetchUsers()); }, []);
```

---

## Q8. What are RTK Query's `createApi` and how does it differ from `createAsyncThunk`?
**Answer:**
RTK Query is a data fetching layer built into Redux Toolkit — think React Query but integrated with the Redux store:

```typescript
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const usersApi = createApi({
  reducerPath: 'usersApi',
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }),
  tagTypes: ['User'],
  endpoints: (builder) => ({
    getUsers:    builder.query<User[], void>({ query: () => '/users', providesTags: ['User'] }),
    getUserById: builder.query<User, number>({ query: (id) => `/users/${id}` }),
    createUser:  builder.mutation<User, Partial<User>>({
      query: (body) => ({ url: '/users', method: 'POST', body }),
      invalidatesTags: ['User'] // auto-refetch users list after creation
    })
  })
});

export const { useGetUsersQuery, useGetUserByIdQuery, useCreateUserMutation } = usersApi;

// In component — just like React Query
function UserList() {
  const { data: users, isLoading } = useGetUsersQuery();
  const [createUser] = useCreateUserMutation();
  // ...
}
```

---

## Q9. What is Zustand and how does it compare to Redux?
**Answer:**
Zustand is a **minimal, flexible state management** library with a much simpler API than Redux:

```jsx
import { create } from 'zustand';

// Store definition
const useUserStore = create((set, get) => ({
  users: [],
  loading: false,

  fetchUsers: async () => {
    set({ loading: true });
    const users = await fetchUsersApi();
    set({ users, loading: false });
  },

  addUser: (user) => set(state => ({ users: [...state.users, user] })),
  removeUser: (id) => set(state => ({ users: state.users.filter(u => u.id !== id) })),
  getUserById: (id) => get().users.find(u => u.id === id) // read from get()
}));

// Usage — no Provider needed!
function UserList() {
  const { users, loading, fetchUsers, removeUser } = useUserStore();
  useEffect(() => { fetchUsers(); }, [fetchUsers]);
  return <ul>{users.map(u => <li key={u.id} onClick={() => removeUser(u.id)}>{u.name}</li>)}</ul>;
}
```

**Zustand vs Redux:**
- Zustand: minimal boilerplate, no Provider, simpler async, great for medium-complexity.
- Redux: better DevTools, strict patterns, better for large teams/apps requiring auditability.

---

## Q10. What are selectors in Redux and why do they matter for performance?
**Answer:**
Selectors are functions that derive data from the store. Memoized selectors avoid re-renders when unrelated state changes:

```typescript
import { createSelector } from '@reduxjs/toolkit';

// Simple selector (not memoized)
const selectUsers = (state: RootState) => state.users.users;

// Memoized selector — only recomputes when selectUsers result changes
const selectActiveUsers = createSelector(
  selectUsers,
  (users) => users.filter(u => u.isActive)
);

// Multiple inputs
const selectUserById = createSelector(
  selectUsers,
  (_: RootState, id: number) => id,
  (users, id) => users.find(u => u.id === id)
);

// In component — selectActiveUsers returns same reference if users didn't change
const activeUsers = useAppSelector(selectActiveUsers); // no re-render if same result
```

---

## Q11. What is the Context API + `useReducer` pattern?
**Answer:**
Combining `useReducer` with Context provides a Redux-like pattern without the library:

```jsx
const StoreContext = createContext(null);
const DispatchContext = createContext(null);

function storeReducer(state, action) {
  switch (action.type) {
    case 'ADD_TODO':    return { ...state, todos: [...state.todos, action.payload] };
    case 'REMOVE_TODO': return { ...state, todos: state.todos.filter(t => t.id !== action.payload) };
    default:            return state;
  }
}

function StoreProvider({ children }) {
  const [state, dispatch] = useReducer(storeReducer, { todos: [] });
  return (
    <StoreContext.Provider value={state}>
      <DispatchContext.Provider value={dispatch}>  {/* separate context = stable dispatch */}
        {children}
      </DispatchContext.Provider>
    </StoreContext.Provider>
  );
}

// Custom hooks
const useStore    = () => useContext(StoreContext);
const useDispatch = () => useContext(DispatchContext);
```

---

## Q12. When should you choose Context, Zustand, or Redux?
**Answer:**
| Scenario | Recommendation |
|---|---|
| Theme, locale, auth (read-mostly) | Context API |
| Small-medium app, simple state | Zustand |
| Large app, complex state, large team | Redux Toolkit |
| Server state (caching, fetching) | React Query / RTK Query |
| Form state | React Hook Form (local) |
| Simple component state | `useState` / `useReducer` |

**Rule:** Start with `useState` → lift to context when needed → add Zustand/Redux when context becomes unwieldy.

---

## Q13. What is the Flux architecture pattern?
**Answer:**
Flux is a unidirectional data flow pattern that Redux is based on:

```
Action → Dispatcher → Store → View → (User interaction) → Action
```

```
User clicks button
    ↓
Action created: { type: 'DELETE_USER', payload: { id: 42 } }
    ↓
Action dispatched to Store
    ↓
Reducer computes new state (pure function)
    ↓
Store updates
    ↓
Subscribed components re-render
    ↓
(Cycle repeats)
```

Key constraint: **Views never mutate state directly** — they dispatch actions. This makes state changes predictable and debuggable.

---

## Q14. What is middleware in Redux and how does it work?
**Answer:**
Middleware intercepts dispatched actions before they reach the reducer:

```
dispatch(action) → Middleware 1 → Middleware 2 → Reducer → New State
```

```javascript
// Custom middleware
const loggerMiddleware = store => next => action => {
  console.log('dispatching:', action);
  const result = next(action); // pass to next middleware or reducer
  console.log('new state:', store.getState());
  return result;
};

// RTK includes:
// - redux-thunk (default) — enables async action creators
// - serializability check middleware (dev only)
configureStore({
  reducer: rootReducer,
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(loggerMiddleware)
});
```

`redux-thunk` allows dispatching functions (instead of plain objects) for async operations.

---

## Q15. What is the `useSelector` hook and how does it avoid re-renders?
**Answer:**
`useSelector` subscribes to the Redux store and returns derived state. It uses **strict equality (`===`)** to determine if re-render is needed:

```tsx
// Re-renders when selected value changes (reference equality)
const users = useSelector(state => state.users.users);
// ✓ if same array reference → no re-render
// ❌ if new array [] (even if same content) → re-render

// Problem: selector computes new object each time
const config = useSelector(state => ({
  isAdmin: state.auth.role === 'admin',
  userId:  state.auth.userId
})); // ❌ new object each render → ALWAYS re-renders

// Solutions:
// 1. Select primitives separately
const isAdmin = useSelector(state => state.auth.role === 'admin');
const userId  = useSelector(state => state.auth.userId);

// 2. Use memoized selector
const config = useSelector(selectConfig); // createSelector memoizes

// 3. shallowEqual comparator
import { shallowEqual } from 'react-redux';
const config = useSelector(state => ({ isAdmin, userId }), shallowEqual);
```
