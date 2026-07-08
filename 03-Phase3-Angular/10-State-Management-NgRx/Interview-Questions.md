# Topic 10: State Management with NgRx — Interview Questions

---

## Q1. What is NgRx and why is it used?
**Answer:**
NgRx is a state management library for Angular based on the **Redux pattern** with RxJS. It provides a **single source of truth** for application state.

Core concepts (the four horsemen):
- **Store** — immutable, centralized state container.
- **Actions** — events that describe what happened.
- **Reducers** — pure functions that update state based on actions.
- **Selectors** — pure functions that query/derive data from the store.
- **Effects** — handle side effects (HTTP calls, routing) triggered by actions.

**When to use NgRx:**
- Large apps with complex state shared across many components.
- State that requires time-travel debugging or undo/redo.
- When services become bloated with state management logic.

---

## Q2. What is the Redux pattern and how does NgRx implement it?
**Answer:**
The unidirectional data flow:

```
User Action
    ↓
Component dispatches Action
    ↓
Reducer computes new State (pure function)
    ↓
Store holds new State
    ↓
Selector derives View Model
    ↓
Component template updated
    ↓ (side effects go to Effects)
    ↓
Effect handles async work → dispatches new Action
```

```typescript
// 1. Action
const loadUsers = createAction('[Users] Load Users');
const loadUsersSuccess = createAction('[Users] Load Users Success', props<{ users: User[] }>());

// 2. Reducer (pure function — no side effects)
const reducer = createReducer(
  initialState,
  on(loadUsersSuccess, (state, { users }) => ({ ...state, users, loading: false }))
);

// 3. Selector
const selectUsers = createSelector(selectUsersFeature, state => state.users);

// 4. Effect (side effects)
loadUsers$ = createEffect(() => this.actions$.pipe(
  ofType(loadUsers),
  switchMap(() => this.http.get<User[]>('/api/users').pipe(
    map(users => loadUsersSuccess({ users })),
    catchError(err => of(loadUsersFailure({ error: err.message })))
  ))
));

// 5. Component
this.store.dispatch(loadUsers());
this.users$ = this.store.select(selectUsers);
```

---

## Q3. What is an NgRx Action?
**Answer:**
Actions are plain objects with a `type` string that describe events in the application:

```typescript
import { createAction, props } from '@ngrx/store';

// Simple action (no payload)
const increment = createAction('[Counter] Increment');
const decrement = createAction('[Counter] Decrement');

// Action with payload
const addUser  = createAction('[Users] Add User',    props<{ user: User }>());
const loadById = createAction('[Users] Load By Id',  props<{ id: number }>());
const loadSuccess = createAction('[Users] Load Success', props<{ users: User[] }>());
const loadFailure = createAction('[Users] Load Failure', props<{ error: string }>());

// Dispatch
this.store.dispatch(addUser({ user: { id: 1, name: 'Alice' } }));
this.store.dispatch(increment());

// Type naming convention: '[Feature Area] Event Description'
// Examples: '[Auth] Login', '[Cart] Add Item', '[Products API] Load Products Success'
```

---

## Q4. What is an NgRx Reducer?
**Answer:**
A reducer is a **pure function** `(currentState, action) => newState`. It MUST:
- Not mutate state — return a new object.
- Have no side effects (no API calls, no random values).
- Return the current state for unknown actions.

```typescript
interface UserState {
  users: User[];
  loading: boolean;
  error: string | null;
}

const initialState: UserState = { users: [], loading: false, error: null };

const userReducer = createReducer(
  initialState,
  on(loadUsers,        state => ({ ...state, loading: true, error: null })),
  on(loadUsersSuccess, (state, { users }) => ({ ...state, users, loading: false })),
  on(loadUsersFailure, (state, { error }) => ({ ...state, error, loading: false })),
  on(addUser,          (state, { user }) => ({ ...state, users: [...state.users, user] })),
  on(removeUser,       (state, { id })   => ({
    ...state,
    users: state.users.filter(u => u.id !== id)
  }))
);
```

---

## Q5. What are NgRx Selectors?
**Answer:**
Selectors are pure functions that extract and derive data from the store — with memoization:

```typescript
import { createSelector, createFeatureSelector } from '@ngrx/store';

// Feature selector — gets the feature slice
const selectUsersFeature = createFeatureSelector<UserState>('users');

// Simple selectors
const selectAllUsers  = createSelector(selectUsersFeature, state => state.users);
const selectLoading   = createSelector(selectUsersFeature, state => state.loading);
const selectError     = createSelector(selectUsersFeature, state => state.error);

// Derived selectors — computed from other selectors (memoized)
const selectActiveUsers = createSelector(
  selectAllUsers,
  users => users.filter(u => u.isActive)
);

const selectUserCount = createSelector(selectAllUsers, users => users.length);

// Parameterized selector (factory)
const selectUserById = (id: number) => createSelector(
  selectAllUsers,
  users => users.find(u => u.id === id)
);

// Combined selectors (multiple inputs)
const selectUserViewModel = createSelector(
  selectAllUsers, selectLoading, selectError,
  (users, loading, error) => ({ users, loading, error })
);

// Usage in component
this.users$   = this.store.select(selectAllUsers);
this.vm$      = this.store.select(selectUserViewModel);
this.user$    = this.store.select(selectUserById(42));
```

---

## Q6. What are NgRx Effects and how do they work?
**Answer:**
Effects listen to actions and perform **side effects** (API calls, routing, local storage), then dispatch new actions:

```typescript
@Injectable()
export class UserEffects {
  // Inject dependencies
  constructor(
    private actions$: Actions,
    private userService: UserService,
    private router: Router
  ) {}

  loadUsers$ = createEffect(() =>
    this.actions$.pipe(
      ofType(UserActions.loadUsers),        // listen for this action
      switchMap(() =>
        this.userService.getAll().pipe(
          map(users => UserActions.loadUsersSuccess({ users })),
          catchError(err => of(UserActions.loadUsersFailure({ error: err.message })))
        )
      )
    )
  );

  // Non-dispatching effect (side effect only)
  navigateOnLogin$ = createEffect(() =>
    this.actions$.pipe(
      ofType(AuthActions.loginSuccess),
      tap(() => this.router.navigate(['/dashboard']))
    ),
    { dispatch: false } // don't dispatch a new action
  );
}
```

---

## Q7. How do you set up NgRx store in an Angular application?
**Answer:**
```typescript
// Install: npm install @ngrx/store @ngrx/effects @ngrx/store-devtools

// Standalone app (Angular 17+)
bootstrapApplication(AppComponent, {
  providers: [
    provideStore({ users: userReducer, auth: authReducer }),
    provideEffects([UserEffects, AuthEffects]),
    provideStoreDevtools({ maxAge: 25, logOnly: !isDevMode() })
  ]
});

// NgModule approach
@NgModule({
  imports: [
    StoreModule.forRoot({ users: userReducer }),
    EffectsModule.forRoot([UserEffects]),
    StoreDevtoolsModule.instrument({ maxAge: 25 })
  ]
})

// Feature module (lazy loaded)
StoreModule.forFeature('products', productReducer),
EffectsModule.forFeature([ProductEffects])
```

---

## Q8. What is NgRx Entity and why is it used?
**Answer:**
`@ngrx/entity` provides utilities to manage collections of entities (normalized state) — eliminating boilerplate for CRUD operations:

```typescript
import { EntityState, EntityAdapter, createEntityAdapter } from '@ngrx/entity';

interface User { id: number; name: string; }

// Entity state: { ids: number[], entities: { [id]: User } }
interface UserState extends EntityState<User> {
  loading: boolean;
  selectedId: number | null;
}

const adapter: EntityAdapter<User> = createEntityAdapter<User>();

const initialState: UserState = adapter.getInitialState({
  loading: false, selectedId: null
});

const reducer = createReducer(
  initialState,
  on(loadUsersSuccess, (state, { users }) => adapter.setAll(users, state)),
  on(addUser,          (state, { user  }) => adapter.addOne(user, state)),
  on(updateUser,       (state, { update}) => adapter.updateOne(update, state)),
  on(deleteUser,       (state, { id   }) => adapter.removeOne(id, state))
);

// Auto-generated selectors
const { selectAll, selectEntities, selectIds, selectTotal } = adapter.getSelectors();
const selectAllUsers = createSelector(selectUsersFeature, selectAll);
```

---

## Q9. What is the difference between NgRx `Store` and a simple service with `BehaviorSubject`?
**Answer:**
| | `BehaviorSubject` Service | NgRx Store |
|---|---|---|
| **Complexity** | Low | High |
| **Boilerplate** | Minimal | Significant |
| **DevTools** | No | ✓ Time-travel debugging |
| **State sharing** | Between a few components | App-wide |
| **Side effects** | Inline | Separated (Effects) |
| **Testing** | Easy | More setup required |
| **Best for** | Feature-level state | App-level state |

```typescript
// Simple BehaviorSubject service — good for small features
@Injectable({ providedIn: 'root' })
export class CartService {
  private items$ = new BehaviorSubject<CartItem[]>([]);
  cart$ = this.items$.asObservable();
  addItem(item: CartItem) { this.items$.next([...this.items$.value, item]); }
}
```

**Rule of thumb:** Use `BehaviorSubject` for feature-scoped state. Use NgRx when state needs to be shared app-wide, debugged with DevTools, or when the team is large.

---

## Q10. What is NgRx SignalStore?
**Answer:**
NgRx SignalStore (`@ngrx/signals`) is a lightweight state management solution using Angular Signals (Angular 17+):

```typescript
import { signalStore, withState, withMethods, withComputed } from '@ngrx/signals';

interface UserState { users: User[]; loading: boolean; error: string | null; }

export const UserStore = signalStore(
  { providedIn: 'root' },
  withState<UserState>({ users: [], loading: false, error: null }),

  withComputed(({ users }) => ({
    activeUsers: computed(() => users().filter(u => u.isActive)),
    userCount:   computed(() => users().length)
  })),

  withMethods((store, userService = inject(UserService)) => ({
    async loadUsers(): Promise<void> {
      patchState(store, { loading: true });
      try {
        const users = await firstValueFrom(userService.getAll());
        patchState(store, { users, loading: false });
      } catch (error) {
        patchState(store, { error: String(error), loading: false });
      }
    }
  }))
);

// Usage in component
@Component({ providers: [UserStore] })
class UsersComponent {
  store = inject(UserStore);
  // store.users()      — signal
  // store.loading()    — signal
  // store.userCount()  — computed signal
  // store.loadUsers()  — method
}
```

---

## Q11. What is the NgRx action hygiene pattern?
**Answer:**
Group actions into namespaced objects to prevent naming conflicts and improve discoverability:

```typescript
// Feature-specific action files
export const UserApiActions = {
  loadUsers:        createAction('[Users API] Load Users'),
  loadUsersSuccess: createAction('[Users API] Load Success', props<{ users: User[] }>()),
  loadUsersFailure: createAction('[Users API] Load Failure', props<{ error: string }>()),
};

export const UserPageActions = {
  enter:      createAction('[Users Page] Enter'),
  searchTerm: createAction('[Users Page] Set Search Term', props<{ term: string }>()),
};

// Source prefix tells you WHERE the action came from:
// [Users API] — from HTTP effects
// [Users Page] — from user interaction
// [Users WS] — from WebSocket
```

---

## Q12. How do you select state in a component?
**Answer:**
```typescript
@Component({})
export class UsersComponent implements OnInit {
  // Observable approach
  users$    = this.store.select(selectAllUsers);
  loading$  = this.store.select(selectLoading);
  vm$       = this.store.select(selectUserViewModel); // combined

  // Signal approach (Angular 17+)
  users     = toSignal(this.store.select(selectAllUsers), { initialValue: [] });
  loading   = toSignal(this.store.select(selectLoading),  { initialValue: false });

  constructor(private store: Store) {}

  ngOnInit() { this.store.dispatch(loadUsers()); }
  delete(id: number) { this.store.dispatch(deleteUser({ id })); }
}
```

---

## Q13. What is the `StoreDevtools` module and what does it provide?
**Answer:**
NgRx StoreDevtools integrates with the **Redux DevTools browser extension** for powerful debugging:

Features:
- **Time-travel** — replay, reset, or jump to any previous state.
- **Action log** — see every dispatched action and its payload.
- **State diff** — see what changed between states.
- **Import/export** — save and restore application state.

```typescript
provideStoreDevtools({
  maxAge: 25,                          // keep last 25 states
  logOnly: !isDevMode(),               // read-only in production
  autoPause: true,                     // pause when window is hidden
  trace: false,                        // include stack trace (performance hit)
  traceLimit: 75
})
```

---

## Q14. What is the immutability principle in NgRx and why does it matter?
**Answer:**
NgRx state MUST be **immutable** — reducers return new objects, never mutate existing ones:

```typescript
// BAD — mutating state directly
on(addUser, (state, { user }) => {
  state.users.push(user); // ❌ mutates original array
  return state;
})

// GOOD — return new objects
on(addUser, (state, { user }) => ({
  ...state,
  users: [...state.users, user] // ✓ new array
}))

// For nested state — spread at each level
on(updateUser, (state, { id, changes }) => ({
  ...state,
  users: state.users.map(u => u.id === id ? { ...u, ...changes } : u)
}))
```

Why? Selectors use **reference equality** for memoization — if you mutate the object, the reference doesn't change and the selector won't recompute. Also enables time-travel debugging.

---

## Q15. How do you handle optimistic updates in NgRx?
**Answer:**
Optimistic updates immediately update the UI, then roll back on failure:

```typescript
// Actions
const deleteUser         = createAction('[Users] Delete User',          props<{ id: number }>());
const deleteUserSuccess  = createAction('[Users] Delete User Success',   props<{ id: number }>());
const deleteUserFailure  = createAction('[Users] Delete User Failure',   props<{ id: number; error: string }>());

// Reducer — optimistic: remove immediately
on(deleteUser,        (state, { id }) => adapter.removeOne(id, state)),
on(deleteUserFailure, (state, { id, user }) => adapter.addOne(user, state)) // rollback

// Effect
deleteUser$ = createEffect(() =>
  this.actions$.pipe(
    ofType(deleteUser),
    // Store original user BEFORE dispatch for rollback
    mergeMap(({ id }) =>
      this.userService.delete(id).pipe(
        map(()  => deleteUserSuccess({ id })),
        catchError(err => of(deleteUserFailure({ id, error: err.message })))
      )
    )
  )
);
```
