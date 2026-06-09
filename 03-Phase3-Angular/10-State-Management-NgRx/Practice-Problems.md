# Topic 10: State Management (NgRx Basics) — Practice Problems

## Problem 1: Counter with NgRx (Easy)
**Concept**: Store setup, actions, reducers, selectors, dispatch

### 1a. Basic Counter
Implement a counter using NgRx:
- Actions: `increment`, `decrement`, `reset`, `set(value)`
- State: `{ count: number }`
- Selectors: `selectCount`, `selectDoubleCount`, `selectIsEven`

### 1b. Multiple Counters
Create two independent counters on the same page:
- Counter A (for items in cart)
- Counter B (for page visits)
- Each with its own slice of state
- Display both values and their sum

### 1c. Counter with History
Extend the counter with undo/redo:
- State: `{ count: number, history: number[], historyIndex: number }`
- Actions: `undo`, `redo`
- Selectors: `selectCanUndo`, `selectCanRedo`

### 1d. DevTools Exploration
- Install Redux DevTools extension
- Dispatch several actions
- Inspect state changes
- Try time-travel debugging
- Document what you observe

---

## Problem 2: Todo App with NgRx (Easy-Medium)
**Concept**: CRUD actions, complex reducers, derived selectors

### 2a. Define Todo State
```typescript
interface Todo { id: number; text: string; completed: boolean; priority: 'low' | 'medium' | 'high' }
interface TodoState {
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
  sortBy: 'date' | 'priority' | 'alpha';
  searchText: string;
}
```

### 2b. Actions
Create actions for:
- `addTodo`, `toggleTodo`, `updateTodo`, `deleteTodo`
- `setFilter`, `setSortBy`, `setSearchText`
- `clearCompleted`, `toggleAll`

### 2c. Reducer
Implement reducer handling all actions.
Remember: NEVER mutate state — always return new objects.

### 2d. Selectors
Create:
```typescript
selectAllTodos
selectFilter
selectSearchText
selectFilteredTodos      // Filtered by filter + searchText
selectSortedTodos        // Filtered + sorted
selectTodoStats          // { total, active, completed, highPriority }
selectCompletionPercent  // 0-100
```

### 2e. Component
Build the TodoComponent that:
- Dispatches actions on user interactions
- Subscribes to selectors via async pipe
- Displays filtered/sorted todos
- Shows stats bar

---

## Problem 3: NgRx Effects with API (Medium)
**Concept**: Effects for side effects, loading/error states

### 3a. Product Store with API
Create a full NgRx feature for products:

**Actions:**
```typescript
// Load
loadProducts / loadProductsSuccess / loadProductsFailure
// Create
createProduct / createProductSuccess / createProductFailure
// Update
updateProduct / updateProductSuccess / updateProductFailure
// Delete
deleteProduct / deleteProductSuccess / deleteProductFailure
```

**State:**
```typescript
interface ProductState {
  products: Product[];
  selectedProductId: number | null;
  loading: boolean;
  error: string | null;
}
```

**Effects:**
```typescript
loadProducts$ — GET /api/products → success/failure
createProduct$ — POST /api/products → success/failure
updateProduct$ — PUT /api/products/:id → success/failure
deleteProduct$ — DELETE /api/products/:id → success/failure
```

### 3b. Optimistic Updates
Implement optimistic delete:
1. Remove item from store immediately (optimistic)
2. Send DELETE request
3. If fails → add item back + show error

### 3c. Loading States per Action
Track loading state per operation:
```typescript
interface LoadingState {
  loadAll: boolean;
  create: boolean;
  update: number | null;  // ID of product being updated
  delete: number | null;  // ID of product being deleted
}
```

### 3d. Error Recovery
Implement retry logic in effects:
- Retry 3 times on failure
- Show error notification after final failure
- "Retry" button dispatches the action again

---

## Problem 4: Multi-Feature Store (Medium-Hard)
**Concept**: Multiple feature states, cross-feature selectors

### 4a. E-Commerce Store Structure
Create NgRx features for:
```
AppState
├── auth: AuthState        { user, token, isLoggedIn, loading }
├── products: ProductState { products, selectedId, filter, loading }
├── cart: CartState        { items, total, discount }
└── ui: UiState            { theme, sidebarOpen, notifications }
```

### 4b. Auth Feature
```typescript
// Actions
login / loginSuccess / loginFailure
logout / logoutSuccess
checkAuth

// Effects
login$ → POST /api/auth/login → save token → navigate to dashboard
logout$ → clear token → navigate to login
```

### 4c. Cart Feature
```typescript
// Actions
addToCart / removeFromCart / updateQuantity / clearCart / applyDiscount

// Selectors
selectCartItems
selectCartTotal
selectCartItemCount
selectCartWithProductDetails  // Cross-feature: combine cart items with product data
```

### 4d. Cross-Feature Selectors
```typescript
// Cart items enriched with product details
export const selectCartWithDetails = createSelector(
  selectCartItems,
  selectAllProducts,
  (cartItems, products) => cartItems.map(item => ({
    ...item,
    product: products.find(p => p.id === item.productId)!,
    subtotal: item.quantity * (products.find(p => p.id === item.productId)?.price ?? 0)
  }))
);

// Show "Add to Cart" vs "In Cart" based on cart state
export const selectProductAvailability = createSelector(
  selectAllProducts,
  selectCartItems,
  (products, cartItems) => products.map(p => ({
    ...p,
    inCart: cartItems.some(i => i.productId === p.id),
    cartQuantity: cartItems.find(i => i.productId === p.id)?.quantity ?? 0
  }))
);
```

---

## Problem 5: Complete NgRx Application (Hard)
**Concept**: Full application with NgRx managing all state

### Build a Project Management Board

**State Structure:**
```typescript
interface AppState {
  auth: { user: User | null; token: string | null; loading: boolean };
  projects: { list: Project[]; selected: number | null; loading: boolean };
  tasks: { list: Task[]; filter: TaskFilter; loading: boolean };
  team: { members: TeamMember[]; loading: boolean };
  ui: { theme: 'light' | 'dark'; sidebarOpen: boolean; notifications: Notification[] };
}
```

**Implement:**

### 5a. Task Board (Redux-powered Kanban)
- Three columns: Backlog, In Progress, Done
- Tasks stored in NgRx store
- Moving a task dispatches `moveTask` action
- Reducers update task status
- Selectors filter tasks by column

### 5b. Effects for API Integration
```typescript
// Load project → Load tasks for project → Load team members
loadProject$ = createEffect(() =>
  this.actions$.pipe(
    ofType(ProjectActions.loadProject),
    switchMap(({ id }) => this.projectService.getById(id).pipe(
      map(project => ProjectActions.loadProjectSuccess({ project })),
      catchError(error => of(ProjectActions.loadProjectFailure({ error })))
    ))
  )
);

// Chain: After project loads, load its tasks
loadProjectTasks$ = createEffect(() =>
  this.actions$.pipe(
    ofType(ProjectActions.loadProjectSuccess),
    switchMap(({ project }) => this.taskService.getByProject(project.id).pipe(
      map(tasks => TaskActions.loadTasksSuccess({ tasks }))
    ))
  )
);
```

### 5c. Real-Time Selectors
```typescript
// Dashboard stats — computed from multiple feature states
selectDashboardStats = createSelector(
  selectAllTasks,
  selectTeamMembers,
  (tasks, members) => ({
    totalTasks: tasks.length,
    completedTasks: tasks.filter(t => t.status === 'done').length,
    overdueTasks: tasks.filter(t => new Date(t.dueDate) < new Date()).length,
    teamSize: members.length,
    tasksPerMember: tasks.length / (members.length || 1),
    completionRate: tasks.length > 0
      ? (tasks.filter(t => t.status === 'done').length / tasks.length * 100)
      : 0
  })
);
```

### 5d. Notifications via Effects
```typescript
// Show notification on action success/failure
notifySuccess$ = createEffect(() =>
  this.actions$.pipe(
    ofType(
      TaskActions.createTaskSuccess,
      TaskActions.updateTaskSuccess,
      TaskActions.deleteTaskSuccess
    ),
    map(action => UiActions.showNotification({
      type: 'success',
      message: 'Operation completed successfully'
    }))
  )
);
```

**Expected Output:**
```
═══ Project Board (NgRx) ═══

[Projects ▼] Current: Angular E-Commerce | 👥 5 members

── Dashboard Stats ──
Tasks: 24 | Done: 12 (50%) | Overdue: 2 ⚠️

┌─ Backlog (8) ────┐ ┌─ In Progress (4) ┐ ┌─ Done (12) ──────┐
│ • Setup CI/CD    │ │ • User Auth      │ │ ✓ Project Setup   │
│ • Payment API    │ │ • Product List   │ │ ✓ Database Design │
│ • Email Service  │ │ • Cart Feature   │ │ ✓ API Endpoints   │
│ • ...            │ │ • Search         │ │ ✓ ...             │
└──────────────────┘ └──────────────────┘ └──────────────────┘

[Redux DevTools: 47 actions dispatched]
```

---

### Submission
- Install NgRx packages in your Angular project
- Implement at least 2 feature states
- Create actions, reducers, selectors, and effects
- Use async pipe with selectors in components
- Test with Redux DevTools
- Tell me "check" when you're ready for review!
