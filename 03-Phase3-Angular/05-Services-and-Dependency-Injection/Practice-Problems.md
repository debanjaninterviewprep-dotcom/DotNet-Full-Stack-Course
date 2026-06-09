# Topic 5: Services & Dependency Injection — Practice Problems

## Problem 1: Basic Services (Easy)
**Concept**: Creating services, injecting into components

### 1a. Logger Service
Create `LoggerService` with methods:
```typescript
info(message: string): void    // Logs with [INFO] prefix + timestamp
warn(message: string): void    // Logs with [WARN] prefix + timestamp
error(message: string): void   // Logs with [ERROR] prefix + timestamp
getHistory(): LogEntry[]       // Returns all log entries
clear(): void                  // Clears log history
```
Inject it into 2 different components and verify they share the same history (singleton).

### 1b. Counter Service
Create `CounterService` (provided in root):
- `value: number` (starts at 0)
- `increment()`, `decrement()`, `reset()`
- `getValue(): number`

Create two components that both use the same counter service. When one increments, both should display the updated value.

### 1c. Theme Service
Create `ThemeService`:
```typescript
currentTheme: 'light' | 'dark'
toggleTheme(): void
getTheme(): string
getThemeColors(): { background: string; text: string; primary: string }
```
Inject into `HeaderComponent` (toggle button) and `AppComponent` (applies theme). Toggling in header changes the entire app's theme.

### 1d. Notification Service
Create `NotificationService`:
```typescript
success(message: string): void
error(message: string): void
warning(message: string): void
info(message: string): void
getNotifications(): Notification[]
dismiss(id: number): void
clearAll(): void
```
Create a `NotificationListComponent` that displays toast-like notifications.

---

## Problem 2: Service Communication (Easy-Medium)
**Concept**: Service-to-service injection, shared state

### 2a. Auth + User Service Chain
Create:
```typescript
// AuthService — manages login state
login(username: string, password: string): boolean
logout(): void
isLoggedIn(): boolean
getCurrentUser(): User | null

// UserService — depends on AuthService
getProfile(): User | null   // Returns current user's profile
updateProfile(changes: Partial<User>): boolean  // Only if logged in
```

UserService should inject AuthService. Create components to demonstrate:
- Login form → calls AuthService
- Profile display → uses UserService which checks AuthService

### 2b. Configuration Service
Create `ConfigService` that loads app configuration:
```typescript
interface AppConfig {
  apiUrl: string;
  appName: string;
  version: string;
  features: { darkMode: boolean; notifications: boolean; analytics: boolean };
}
```
Use an `InjectionToken<AppConfig>` and provide it via `useValue`. Inject in multiple components.

### 2c. Shopping Cart Service
Build a `CartService` with:
```typescript
addItem(product: Product, quantity?: number): void
removeItem(productId: number): void
updateQuantity(productId: number, quantity: number): void
getItems(): CartItem[]
getItemCount(): number
getSubtotal(): number
clear(): void
```

Create:
- `ProductListComponent` — shows products with "Add to Cart" button
- `CartComponent` — shows cart items, quantities, subtotal
- `CartBadgeComponent` — shows item count in header

All share the same CartService.

### 2d. Event Bus Service
Create an `EventBusService` using RxJS Subject:
```typescript
emit(event: AppEvent): void
on(eventName: string): Observable<AppEvent>
```

Demonstrate components communicating without direct parent-child relationship:
- Sidebar emits "category-selected" event
- Product list listens and filters accordingly

---

## Problem 3: Advanced DI Patterns (Medium)
**Concept**: InjectionTokens, factories, hierarchical DI

### 3a. Multiple Implementations
Create an interface and two implementations:
```typescript
// Abstract
interface StorageService {
  get(key: string): string | null;
  set(key: string, value: string): void;
  remove(key: string): void;
  clear(): void;
}

// LocalStorageService — uses localStorage
// SessionStorageService — uses sessionStorage
// MemoryStorageService — uses in-memory Map (for testing)
```

Use `InjectionToken` and `useFactory` to provide the appropriate implementation based on environment.

### 3b. Component-Level Providers
Create a `FormStateService`:
```typescript
@Injectable()  // NOT providedIn: 'root'!
export class FormStateService {
  private isDirty = false;
  markDirty(): void { this.isDirty = true; }
  markClean(): void { this.isDirty = false; }
  get dirty(): boolean { return this.isDirty; }
}
```

Use it in two separate form components, each with their own provider:
```typescript
@Component({
  providers: [FormStateService]  // Each form gets its own instance!
})
```
Verify that each form has independent dirty state.

### 3c. Factory Provider
Create a `DateFormatterService` factory:
```typescript
// Provide different formatters based on locale
{
  provide: DateFormatterService,
  useFactory: (locale: string) => {
    switch (locale) {
      case 'en-US': return new USDateFormatter();
      case 'en-GB': return new UKDateFormatter();
      case 'de-DE': return new GermanDateFormatter();
      default: return new ISODateFormatter();
    }
  },
  deps: [LOCALE_TOKEN]
}
```

### 3d. Optional Dependencies
Create a component that optionally uses `AnalyticsService`:
- If provided → track page views, button clicks
- If not provided → silently skip tracking
- Use `@Optional()` decorator
- Demonstrate both scenarios

---

## Problem 4: Reactive State Management (Medium-Hard)
**Concept**: BehaviorSubject, Observable-based services

### 4a. Todo State Service
Build a complete state management service:
```typescript
@Injectable({ providedIn: 'root' })
export class TodoStore {
  // State
  private todosSubject = new BehaviorSubject<Todo[]>([]);
  private filterSubject = new BehaviorSubject<TodoFilter>('all');
  
  // Selectors (observables)
  todos$ = this.todosSubject.asObservable();
  filter$ = this.filterSubject.asObservable();
  filteredTodos$: Observable<Todo[]>;   // Derived from todos$ + filter$
  stats$: Observable<TodoStats>;         // Derived from todos$
  
  // Actions
  addTodo(text: string): void;
  toggleTodo(id: number): void;
  removeTodo(id: number): void;
  setFilter(filter: TodoFilter): void;
  clearCompleted(): void;
}
```

Create components that subscribe using `async` pipe:
- `TodoListComponent` — displays filtered todos
- `TodoInputComponent` — adds new todos
- `TodoStatsComponent` — shows completion stats
- `TodoFilterComponent` — filter buttons (All/Active/Completed)

### 4b. Loading State Pattern
Implement a service that manages loading/error states:
```typescript
interface DataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

@Injectable({ providedIn: 'root' })
export class ProductStore {
  private state = new BehaviorSubject<DataState<Product[]>>({
    data: null, loading: false, error: null
  });
  
  state$ = this.state.asObservable();
  
  loadProducts(): void {
    this.state.next({ data: null, loading: true, error: null });
    // Simulate API call...
  }
}
```

### 4c. Cross-Component Communication
Demonstrate 3 sibling components communicating through a shared service:
```
┌─────────────────────────────────────┐
│         AppComponent                 │
│ ┌───────────┐ ┌───────────────────┐ │
│ │ Sidebar   │ │ Content           │ │
│ │ (Category)│ │ ┌───────────────┐ │ │
│ │ • All     │ │ │SearchBar      │ │ │
│ │ • Tech    │ │ └───────────────┘ │ │
│ │ • Science │ │ ┌───────────────┐ │ │
│ │           │ │ │ArticleList    │ │ │
│ │           │ │ │(filtered)     │ │ │
│ └───────────┘ │ └───────────────┘ │ │
│               └───────────────────┘ │
└─────────────────────────────────────┘

- Sidebar selects category → ArticleList filters
- SearchBar types query → ArticleList filters
- Both filters combine through ArticleService
```

---

## Problem 5: Complete Service Architecture (Hard)
**Concept**: Design a full service layer for an application

### Build a Library Management System

Create a complete service architecture:

**Models:**
```typescript
interface Book { id: number; title: string; author: string; isbn: string; category: string; available: boolean; }
interface Member { id: number; name: string; email: string; membership: 'basic' | 'premium'; }
interface Loan { id: number; bookId: number; memberId: number; borrowDate: Date; dueDate: Date; returnDate?: Date; }
```

**Services:**
```typescript
// BookService — CRUD for books, search, filter by category/availability
// MemberService — CRUD for members, check membership status
// LoanService — borrow and return logic, depends on BookService & MemberService
// NotificationService — alerts for overdue books, new arrivals
// StatsService — library stats (total books, active loans, popular categories)
```

**Business Rules:**
1. Basic members: max 3 books at a time
2. Premium members: max 10 books
3. Loan period: 14 days (basic), 30 days (premium)
4. Can't borrow unavailable books
5. Return updates book availability
6. Overdue detection and notification

**Components:**
```
DashboardComponent — inject StatsService → display stats
BookListComponent — inject BookService → search/filter books  
MemberListComponent — inject MemberService → manage members
LoanComponent — inject LoanService → borrow/return
NotificationComponent — inject NotificationService → show alerts
```

**Expected Output:**
```
═══ Library Dashboard ═══

Stats:
  📚 Total Books: 150 | Available: 123 | On Loan: 27
  👥 Members: 45 | Basic: 30 | Premium: 15
  📋 Active Loans: 27 | Overdue: 3

Notifications:
  ⚠️ "Clean Code" is overdue for Alice (3 days late)
  ⚠️ "Design Patterns" is overdue for Bob (1 day late)
  ✅ "The Pragmatic Programmer" returned by Charlie

Recent Loans:
  📖 Alice borrowed "Angular in Action" (due: Apr 25)
  📖 Bob returned "TypeScript Deep Dive"
  📖 Charlie borrowed "Clean Architecture" (due: May 10)
```

---

### Submission
- Create all services with proper DI registration
- Inject services into components (use both constructor and inject())
- Verify singleton behavior (same state across components)
- Test component-level providers (different instances)
- Tell me "check" when you're ready for review!
