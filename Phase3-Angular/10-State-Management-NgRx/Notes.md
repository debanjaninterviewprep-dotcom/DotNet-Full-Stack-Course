# Topic 10: State Management (NgRx Basics)

## Why State Management?

As apps grow, managing shared state across components becomes complex. State management libraries provide a **single source of truth** with **predictable** data flow.

```
Without State Management:
Component A → Service → Component B → Service → Component C
(Spaghetti state — hard to track who changed what)

With NgRx:
Component A ──┐                    ┌── Component A (subscribes)
Component B ──┤→ Store (single) ←──┤── Component B (subscribes)
Component C ──┘   source of truth  └── Component C (subscribes)
```

---

## NgRx Overview

NgRx is the Angular implementation of the **Redux pattern** using RxJS Observables.

### Core Concepts

```
┌─────────────────────────────────────────────────┐
│                  NgRx Flow                       │
│                                                  │
│  ┌───────────┐  dispatch   ┌──────────┐         │
│  │ Component │ ──────────→ │ Actions  │         │
│  └─────┬─────┘             └────┬─────┘         │
│        │                        │                │
│   select│                        │                │
│        │                  ┌─────┴─────┐          │
│        │                  │ Reducers  │          │
│        │                  │ (pure fn) │          │
│        │                  └─────┬─────┘          │
│        │                        │                │
│  ┌─────┴─────┐             ┌────┴─────┐         │
│  │ Selectors │ ←───────── │  Store   │         │
│  │ (queries) │             │ (state)  │         │
│  └───────────┘             └────┬─────┘         │
│                                  │                │
│                           ┌──────┴──────┐        │
│                           │   Effects   │        │
│                           │ (side fx)   │        │
│                           └─────────────┘        │
└─────────────────────────────────────────────────┘

1. Component dispatches an ACTION
2. REDUCER processes action and returns NEW state
3. STORE holds the state
4. SELECTORS query specific slices of state
5. Component subscribes to selectors
6. EFFECTS handle side effects (API calls, navigation)
```

| Concept | Purpose | Analogy |
|---|---|---|
| **Store** | Single state container | Database |
| **Actions** | Events that describe what happened | SQL Commands |
| **Reducers** | Pure functions that create new state | Stored procedures |
| **Selectors** | Queries to read state slices | SQL Queries |
| **Effects** | Side effects (API calls, etc.) | Event handlers |

---

## Setup

```bash
# Install NgRx packages
npm install @ngrx/store @ngrx/effects @ngrx/store-devtools

# Or use schematics
ng add @ngrx/store
ng add @ngrx/effects
ng add @ngrx/store-devtools
```

```typescript
// app.config.ts
import { provideStore } from '@ngrx/store';
import { provideEffects } from '@ngrx/effects';
import { provideStoreDevtools } from '@ngrx/store-devtools';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(),
    provideStore({ counter: counterReducer, todos: todosReducer }),
    provideEffects([TodoEffects]),
    provideStoreDevtools({ maxAge: 25, logOnly: false })
  ]
};
```

---

## Step-by-Step: Counter Example

### 1. Define Actions

```typescript
// store/counter/counter.actions.ts
import { createAction, props } from '@ngrx/store';

export const increment = createAction('[Counter] Increment');
export const decrement = createAction('[Counter] Decrement');
export const reset = createAction('[Counter] Reset');
export const set = createAction(
  '[Counter] Set',
  props<{ value: number }>()    // Action with payload
);
```

**Action naming convention:** `[Source] Event Description`
- `[Counter Page] Increment`
- `[User API] Load Users Success`
- `[Auth] Login Failure`

### 2. Define State & Reducer

```typescript
// store/counter/counter.reducer.ts
import { createReducer, on } from '@ngrx/store';
import * as CounterActions from './counter.actions';

// State interface
export interface CounterState {
  count: number;
}

// Initial state
export const initialState: CounterState = {
  count: 0
};

// Reducer — pure function!
export const counterReducer = createReducer(
  initialState,
  on(CounterActions.increment, (state) => ({
    ...state,
    count: state.count + 1       // Return NEW state (never mutate!)
  })),
  on(CounterActions.decrement, (state) => ({
    ...state,
    count: state.count - 1
  })),
  on(CounterActions.reset, (state) => ({
    ...state,
    count: 0
  })),
  on(CounterActions.set, (state, { value }) => ({
    ...state,
    count: value
  }))
);
```

### 3. Define Selectors

```typescript
// store/counter/counter.selectors.ts
import { createFeatureSelector, createSelector } from '@ngrx/store';
import { CounterState } from './counter.reducer';

// Feature selector — selects the counter slice
export const selectCounterState = createFeatureSelector<CounterState>('counter');

// Select specific property
export const selectCount = createSelector(
  selectCounterState,
  (state) => state.count
);

// Derived/computed selectors
export const selectDoubleCount = createSelector(
  selectCount,
  (count) => count * 2
);

export const selectIsPositive = createSelector(
  selectCount,
  (count) => count > 0
);
```

### 4. Use in Component

```typescript
// counter.component.ts
import { Component, inject } from '@angular/core';
import { Store } from '@ngrx/store';
import { AsyncPipe } from '@angular/common';
import * as CounterActions from '../store/counter/counter.actions';
import { selectCount, selectDoubleCount } from '../store/counter/counter.selectors';

@Component({
  selector: 'app-counter',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    <h2>NgRx Counter</h2>
    <p>Count: {{ count$ | async }}</p>
    <p>Double: {{ doubleCount$ | async }}</p>
    
    <button (click)="decrement()">−</button>
    <button (click)="increment()">+</button>
    <button (click)="reset()">Reset</button>
  `
})
export class CounterComponent {
  private store = inject(Store);
  
  // Select state using selectors
  count$ = this.store.select(selectCount);
  doubleCount$ = this.store.select(selectDoubleCount);
  
  // Dispatch actions
  increment(): void {
    this.store.dispatch(CounterActions.increment());
  }
  
  decrement(): void {
    this.store.dispatch(CounterActions.decrement());
  }
  
  reset(): void {
    this.store.dispatch(CounterActions.reset());
  }
}
```

---

## Real-World Example: Todo App with Effects

### Actions

```typescript
// store/todos/todo.actions.ts
import { createAction, props } from '@ngrx/store';
import { Todo } from '../../models/todo.model';

// Load todos
export const loadTodos = createAction('[Todo Page] Load Todos');
export const loadTodosSuccess = createAction(
  '[Todo API] Load Todos Success',
  props<{ todos: Todo[] }>()
);
export const loadTodosFailure = createAction(
  '[Todo API] Load Todos Failure',
  props<{ error: string }>()
);

// Add todo
export const addTodo = createAction(
  '[Todo Page] Add Todo',
  props<{ text: string }>()
);
export const addTodoSuccess = createAction(
  '[Todo API] Add Todo Success',
  props<{ todo: Todo }>()
);

// Toggle todo
export const toggleTodo = createAction(
  '[Todo Page] Toggle Todo',
  props<{ id: number }>()
);

// Delete todo
export const deleteTodo = createAction(
  '[Todo Page] Delete Todo',
  props<{ id: number }>()
);

// Set filter
export const setFilter = createAction(
  '[Todo Page] Set Filter',
  props<{ filter: 'all' | 'active' | 'completed' }>()
);
```

### State & Reducer

```typescript
// store/todos/todo.reducer.ts
export interface TodoState {
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
  loading: boolean;
  error: string | null;
}

export const initialState: TodoState = {
  todos: [],
  filter: 'all',
  loading: false,
  error: null
};

export const todoReducer = createReducer(
  initialState,
  
  // Load
  on(TodoActions.loadTodos, (state) => ({
    ...state, loading: true, error: null
  })),
  on(TodoActions.loadTodosSuccess, (state, { todos }) => ({
    ...state, todos, loading: false
  })),
  on(TodoActions.loadTodosFailure, (state, { error }) => ({
    ...state, loading: false, error
  })),
  
  // Add
  on(TodoActions.addTodoSuccess, (state, { todo }) => ({
    ...state, todos: [...state.todos, todo]
  })),
  
  // Toggle
  on(TodoActions.toggleTodo, (state, { id }) => ({
    ...state,
    todos: state.todos.map(t =>
      t.id === id ? { ...t, completed: !t.completed } : t
    )
  })),
  
  // Delete
  on(TodoActions.deleteTodo, (state, { id }) => ({
    ...state,
    todos: state.todos.filter(t => t.id !== id)
  })),
  
  // Filter
  on(TodoActions.setFilter, (state, { filter }) => ({
    ...state, filter
  }))
);
```

### Selectors

```typescript
// store/todos/todo.selectors.ts
export const selectTodoState = createFeatureSelector<TodoState>('todos');

export const selectAllTodos = createSelector(
  selectTodoState, state => state.todos
);

export const selectFilter = createSelector(
  selectTodoState, state => state.filter
);

export const selectLoading = createSelector(
  selectTodoState, state => state.loading
);

export const selectError = createSelector(
  selectTodoState, state => state.error
);

// Filtered todos (derived)
export const selectFilteredTodos = createSelector(
  selectAllTodos,
  selectFilter,
  (todos, filter) => {
    switch (filter) {
      case 'active': return todos.filter(t => !t.completed);
      case 'completed': return todos.filter(t => t.completed);
      default: return todos;
    }
  }
);

// Stats (derived)
export const selectTodoStats = createSelector(
  selectAllTodos,
  (todos) => ({
    total: todos.length,
    completed: todos.filter(t => t.completed).length,
    active: todos.filter(t => !t.completed).length
  })
);
```

### Effects (Side Effects)

```typescript
// store/todos/todo.effects.ts
import { Injectable, inject } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { map, exhaustMap, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

@Injectable()
export class TodoEffects {
  private actions$ = inject(Actions);
  private todoService = inject(TodoService);
  
  // Load todos effect
  loadTodos$ = createEffect(() =>
    this.actions$.pipe(
      ofType(TodoActions.loadTodos),              // Listen for this action
      exhaustMap(() =>
        this.todoService.getAll().pipe(            // Call API
          map(todos => TodoActions.loadTodosSuccess({ todos })),  // Success
          catchError(error =>
            of(TodoActions.loadTodosFailure({ error: error.message }))  // Failure
          )
        )
      )
    )
  );
  
  // Add todo effect
  addTodo$ = createEffect(() =>
    this.actions$.pipe(
      ofType(TodoActions.addTodo),
      exhaustMap(({ text }) =>
        this.todoService.create(text).pipe(
          map(todo => TodoActions.addTodoSuccess({ todo })),
          catchError(error => of(TodoActions.loadTodosFailure({ error: error.message })))
        )
      )
    )
  );
}
```

### Component

```typescript
@Component({
  standalone: true,
  imports: [AsyncPipe, ReactiveFormsModule],
  template: `
    <h2>Todo App (NgRx)</h2>
    
    <!-- Add todo -->
    <input #todoInput (keyup.enter)="addTodo(todoInput)" />
    
    <!-- Filter -->
    <div>
      <button (click)="setFilter('all')" [class.active]="(filter$ | async) === 'all'">All</button>
      <button (click)="setFilter('active')" [class.active]="(filter$ | async) === 'active'">Active</button>
      <button (click)="setFilter('completed')" [class.active]="(filter$ | async) === 'completed'">Completed</button>
    </div>
    
    <!-- Loading -->
    @if (loading$ | async) { <p>Loading...</p> }
    
    <!-- Error -->
    @if (error$ | async; as error) { <p class="error">{{ error }}</p> }
    
    <!-- Todo list -->
    @for (todo of filteredTodos$ | async; track todo.id) {
      <div [class.completed]="todo.completed">
        <input type="checkbox" [checked]="todo.completed" (change)="toggle(todo.id)" />
        {{ todo.text }}
        <button (click)="delete(todo.id)">✕</button>
      </div>
    }
    
    <!-- Stats -->
    @if (stats$ | async; as stats) {
      <p>{{ stats.active }} items left · {{ stats.completed }} completed</p>
    }
  `
})
export class TodoComponent implements OnInit {
  private store = inject(Store);
  
  filteredTodos$ = this.store.select(selectFilteredTodos);
  filter$ = this.store.select(selectFilter);
  loading$ = this.store.select(selectLoading);
  error$ = this.store.select(selectError);
  stats$ = this.store.select(selectTodoStats);
  
  ngOnInit(): void {
    this.store.dispatch(TodoActions.loadTodos());
  }
  
  addTodo(input: HTMLInputElement): void {
    if (input.value.trim()) {
      this.store.dispatch(TodoActions.addTodo({ text: input.value }));
      input.value = '';
    }
  }
  
  toggle(id: number): void {
    this.store.dispatch(TodoActions.toggleTodo({ id }));
  }
  
  delete(id: number): void {
    this.store.dispatch(TodoActions.deleteTodo({ id }));
  }
  
  setFilter(filter: 'all' | 'active' | 'completed'): void {
    this.store.dispatch(TodoActions.setFilter({ filter }));
  }
}
```

---

## NgRx DevTools

Install the **Redux DevTools** browser extension to:
- See all dispatched actions in order
- Inspect state at any point
- Time-travel debugging (go back to previous state)
- Diff between states

```typescript
provideStoreDevtools({
  maxAge: 25,          // Keep last 25 actions
  logOnly: false,      // Set true in production
  autoPause: true      // Pause when extension not open
})
```

---

## When to Use NgRx vs Services

| Scenario | Use Service | Use NgRx |
|---|---|---|
| Simple state | ✅ BehaviorSubject | Overkill |
| Shared by 2-3 components | ✅ | Overkill |
| Complex data flow | ❌ Gets messy | ✅ |
| Time-travel debugging needed | ❌ | ✅ |
| Large team / large app | Gets inconsistent | ✅ Enforces patterns |
| Undo/redo | Hard | ✅ Built-in |
| Caching / offline | Custom | ✅ Effects handle well |

**Rule of thumb:** Start with services. Migrate to NgRx when state complexity warrants it.

---

## Lightweight Alternative: Signals (Angular 17+)

Angular Signals provide a simpler reactive primitive:

```typescript
import { signal, computed } from '@angular/core';

@Component({ ... })
export class CounterComponent {
  count = signal(0);
  doubleCount = computed(() => this.count() * 2);
  
  increment() { this.count.update(c => c + 1); }
  decrement() { this.count.update(c => c - 1); }
  reset() { this.count.set(0); }
}
```

```html
<p>Count: {{ count() }}</p>
<p>Double: {{ doubleCount() }}</p>
```

Signals are great for component-local state. NgRx is for complex global state.

---

## Key Takeaways

| Concept | Summary |
|---|---|
| NgRx | Redux pattern for Angular with RxJS |
| Store | Single source of truth for app state |
| Actions | Events describing what happened |
| Reducers | Pure functions that produce new state |
| Selectors | Memoized queries for state slices |
| Effects | Handle side effects (API, navigation) |
| DevTools | Time-travel debugging |
| Signals | Lightweight alternative for simple state |
| Best practice | Start with services, migrate to NgRx when needed |

---

*Next Topic: Guards, Interceptors & Auth →*
