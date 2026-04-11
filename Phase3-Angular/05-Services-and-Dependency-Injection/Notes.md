# Topic 5: Services & Dependency Injection

## What Are Services?

Services are **classes** that encapsulate **shared logic** — data fetching, business rules, state management, utility functions. Components should be thin (only UI logic); services handle everything else.

```
┌──────────────────────────────────────────────────┐
│  Components (UI only)                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ Header   │  │ UserList │  │ UserForm │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│       │              │              │              │
│       └──────────────┼──────────────┘              │
│                      │                              │
│              ┌───────┴───────┐                      │
│              │  UserService  │ ← Shared service     │
│              │  (singleton)  │                      │
│              └───────┬───────┘                      │
│                      │                              │
│              ┌───────┴───────┐                      │
│              │  HttpClient   │ ← Angular service    │
│              └───────────────┘                      │
└──────────────────────────────────────────────────┘
```

---

## Creating Services

### Using CLI

```bash
ng generate service services/user
# Creates:
# services/user.service.ts
# services/user.service.spec.ts
```

### Basic Service

```typescript
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'  // Singleton — available everywhere
})
export class UserService {
  private users: User[] = [
    { id: 1, name: 'Alice', email: 'alice@test.com' },
    { id: 2, name: 'Bob', email: 'bob@test.com' },
    { id: 3, name: 'Charlie', email: 'charlie@test.com' }
  ];
  
  getAll(): User[] {
    return [...this.users];  // Return copy to prevent mutation
  }
  
  getById(id: number): User | undefined {
    return this.users.find(u => u.id === id);
  }
  
  add(user: Omit<User, 'id'>): User {
    const newUser = { ...user, id: this.nextId() };
    this.users.push(newUser);
    return newUser;
  }
  
  update(id: number, changes: Partial<User>): User | undefined {
    const index = this.users.findIndex(u => u.id === id);
    if (index === -1) return undefined;
    this.users[index] = { ...this.users[index], ...changes };
    return this.users[index];
  }
  
  delete(id: number): boolean {
    const index = this.users.findIndex(u => u.id === id);
    if (index === -1) return false;
    this.users.splice(index, 1);
    return true;
  }
  
  private nextId(): number {
    return Math.max(...this.users.map(u => u.id), 0) + 1;
  }
}
```

---

## Dependency Injection (DI)

DI is a design pattern where a class **receives** its dependencies instead of creating them. Angular has a **built-in DI framework**.

```
Without DI (Bad):
class UserComponent {
  private service = new UserService();  // Tightly coupled!
}

With DI (Good):
class UserComponent {
  constructor(private service: UserService) {}  // Angular provides it!
}
```

### How DI Works

```
1. You register a provider (service)
2. Angular creates an injector
3. Component requests the service via constructor
4. Injector provides (or creates) the instance

┌─────────────────────────────────────┐
│           Angular Injector           │
│                                     │
│  ┌─────────────┐                    │
│  │ UserService  │ ← registered      │
│  └──────┬──────┘                    │
│         │                            │
│   ┌─────┴─────┐  ┌─────────────┐   │
│   │Component A │  │Component B  │   │
│   │ inject ←───┤  │ inject ←────┤   │
│   └───────────┘  └─────────────┘   │
│                                     │
│   Same instance! (singleton)         │
└─────────────────────────────────────┘
```

---

## Injecting Services

### Method 1: Constructor Injection (Classic)

```typescript
import { Component, OnInit } from '@angular/core';
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-user-list',
  standalone: true,
  template: `
    @for (user of users; track user.id) {
      <div>{{ user.name }} — {{ user.email }}</div>
    }
  `
})
export class UserListComponent implements OnInit {
  users: User[] = [];
  
  // TypeScript shorthand: private = declares + assigns
  constructor(private userService: UserService) {}
  
  ngOnInit(): void {
    this.users = this.userService.getAll();
  }
}
```

### Method 2: inject() Function (Modern — Angular 14+)

```typescript
import { Component, OnInit, inject } from '@angular/core';
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-user-list',
  standalone: true,
  template: `...`
})
export class UserListComponent implements OnInit {
  private userService = inject(UserService);  // No constructor needed!
  users: User[] = [];
  
  ngOnInit(): void {
    this.users = this.userService.getAll();
  }
}
```

**`inject()` Benefits:**
- Works in functions (not just classes)
- Cleaner for multiple dependencies
- No constructor parameter list explosion
- Can be used in factory functions

---

## Provider Scopes

Where you register a service determines its **scope** (lifetime and availability).

### 1. Root Level — `providedIn: 'root'` (Most Common)

```typescript
@Injectable({
  providedIn: 'root'  // ONE instance for the entire app
})
export class UserService {}
```
- **Singleton** — same instance everywhere
- **Tree-shakable** — removed from bundle if not used
- Use for: data services, auth, state management

### 2. Component Level — `providers` array

```typescript
@Component({
  selector: 'app-user-list',
  providers: [UserService]  // NEW instance for this component
})
export class UserListComponent {
  constructor(private userService: UserService) {}
}
```
- **New instance** per component
- **Destroyed** when component is destroyed
- Use for: component-specific state, unique instances

### 3. Application Config Level

```typescript
// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(),
    { provide: UserService, useClass: UserService }  // Singleton
  ]
};
```

---

## Hierarchical Injection

Angular has a **tree of injectors** matching the component tree.

```
Root Injector (app-wide singletons)
│
├── AppComponent Injector
│   ├── HeaderComponent Injector
│   ├── MainComponent Injector
│   │   ├── UserListComponent Injector ← can have own providers
│   │   └── UserDetailComponent Injector
│   └── FooterComponent Injector
```

When a component requests a service:
1. Check its OWN injector
2. If not found, check PARENT'S injector
3. Keep going UP until Root
4. If not found anywhere → Error!

```typescript
// Scenario: Each UserEditComponent gets its own FormService
@Component({
  selector: 'app-user-edit',
  providers: [FormService]  // Each instance gets its own FormService
})
export class UserEditComponent {
  constructor(private formService: FormService) {}
}
```

---

## Injection Tokens

For injecting values that aren't classes (strings, numbers, configs, interfaces).

### InjectionToken

```typescript
import { InjectionToken } from '@angular/core';

// Define token
export const API_URL = new InjectionToken<string>('API_URL');
export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');

// Interface for config
export interface AppConfig {
  apiUrl: string;
  appName: string;
  debug: boolean;
}

// Register in providers
export const appConfig: ApplicationConfig = {
  providers: [
    { provide: API_URL, useValue: 'https://api.example.com' },
    {
      provide: APP_CONFIG,
      useValue: {
        apiUrl: 'https://api.example.com',
        appName: 'My App',
        debug: false
      }
    }
  ]
};

// Inject
@Component({ ... })
export class AppComponent {
  private apiUrl = inject(API_URL);
  private config = inject(APP_CONFIG);
  
  // OR constructor injection
  constructor(@Inject(API_URL) private apiUrl: string) {}
}
```

---

## Provider Configuration Options

```typescript
// useClass — provide a class (default)
{ provide: UserService, useClass: UserService }

// useClass with substitution (great for testing)
{ provide: UserService, useClass: MockUserService }

// useValue — provide a value
{ provide: API_URL, useValue: 'https://api.example.com' }
{ provide: APP_CONFIG, useValue: { debug: true } }

// useFactory — provide via factory function
{
  provide: LoggerService,
  useFactory: (config: AppConfig) => {
    return config.debug ? new DebugLogger() : new ProdLogger();
  },
  deps: [APP_CONFIG]  // Dependencies for the factory
}

// useExisting — alias one token to another
{ provide: AbstractLogger, useExisting: ConsoleLogger }

// multi — provide multiple values for same token
{ provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
{ provide: HTTP_INTERCEPTORS, useClass: LoggingInterceptor, multi: true }
```

---

## Injection Modifiers

### @Optional()

```typescript
export class UserComponent {
  constructor(
    @Optional() private analytics?: AnalyticsService
    // Won't throw if AnalyticsService isn't provided — just null
  ) {}
  
  trackEvent(name: string): void {
    this.analytics?.track(name);  // Safe — may be null
  }
}
```

### @Self(), @SkipSelf(), @Host()

```typescript
// @Self() — only look in THIS component's injector
constructor(@Self() private service: MyService) {}

// @SkipSelf() — skip this component, look in PARENT's injector
constructor(@SkipSelf() private service: MyService) {}

// @Host() — look up to the host component only
constructor(@Host() private service: MyService) {}
```

---

## Service-to-Service Communication

Services can inject other services.

```typescript
@Injectable({ providedIn: 'root' })
export class LoggerService {
  log(message: string): void {
    console.log(`[LOG ${new Date().toISOString()}] ${message}`);
  }
  
  error(message: string): void {
    console.error(`[ERROR ${new Date().toISOString()}] ${message}`);
  }
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private logger = inject(LoggerService);  // Service injecting service!
  private users: User[] = [];
  
  getAll(): User[] {
    this.logger.log('Fetching all users');
    return [...this.users];
  }
  
  delete(id: number): boolean {
    const result = /* delete logic */;
    if (result) this.logger.log(`Deleted user ${id}`);
    else this.logger.error(`Failed to delete user ${id}`);
    return result;
  }
}
```

---

## Service with State (Simple Store Pattern)

```typescript
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class CartService {
  // BehaviorSubject — holds current value, emits to new subscribers
  private itemsSubject = new BehaviorSubject<CartItem[]>([]);
  
  // Expose as Observable (read-only to consumers)
  items$: Observable<CartItem[]> = this.itemsSubject.asObservable();
  
  get items(): CartItem[] {
    return this.itemsSubject.value;
  }
  
  get totalItems(): number {
    return this.items.reduce((sum, item) => sum + item.quantity, 0);
  }
  
  get totalPrice(): number {
    return this.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }
  
  addItem(product: Product): void {
    const current = this.items;
    const existing = current.find(i => i.productId === product.id);
    
    if (existing) {
      existing.quantity++;
    } else {
      current.push({
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: 1
      });
    }
    
    this.itemsSubject.next([...current]);  // Emit new state
  }
  
  removeItem(productId: number): void {
    const updated = this.items.filter(i => i.productId !== productId);
    this.itemsSubject.next(updated);
  }
  
  clear(): void {
    this.itemsSubject.next([]);
  }
}
```

```typescript
// Component subscribes to state changes
@Component({
  template: `
    <div>Cart Items: {{ cartService.totalItems }}</div>
    <div>Total: {{ cartService.totalPrice | currency }}</div>
    
    <!-- Or with async pipe (auto-subscribes and unsubscribes) -->
    @for (item of items$ | async; track item.productId) {
      <div>{{ item.name }} × {{ item.quantity }}</div>
    }
  `
})
export class CartComponent {
  cartService = inject(CartService);
  items$ = this.cartService.items$;
}
```

---

## Testing Services

```typescript
// user.service.spec.ts
import { TestBed } from '@angular/core/testing';
import { UserService } from './user.service';

describe('UserService', () => {
  let service: UserService;
  
  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(UserService);
  });
  
  it('should be created', () => {
    expect(service).toBeTruthy();
  });
  
  it('should return all users', () => {
    const users = service.getAll();
    expect(users.length).toBeGreaterThan(0);
  });
  
  it('should add a user', () => {
    const initial = service.getAll().length;
    service.add({ name: 'Test', email: 'test@test.com' });
    expect(service.getAll().length).toBe(initial + 1);
  });
});
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Service | Shared logic class with `@Injectable` |
| `providedIn: 'root'` | Singleton for entire app (most common) |
| Constructor injection | `constructor(private svc: MyService)` |
| `inject()` function | Modern alternative: `svc = inject(MyService)` |
| Hierarchical DI | Component tree = injector tree |
| InjectionToken | Inject non-class values (configs, URLs) |
| useClass / useValue / useFactory | Different ways to provide |
| @Optional | Don't throw if service not found |
| BehaviorSubject | Simple state management in services |
| async pipe | Auto-subscribe in templates |

---

*Next Topic: Routing & Navigation →*
