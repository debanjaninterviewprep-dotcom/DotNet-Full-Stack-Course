# Topic 05: Services and Dependency Injection — Interview Questions

---

## Q1. What is a service in Angular and why are services used?
**Answer:**
A service is a class decorated with `@Injectable` that encapsulates reusable **business logic, data access, or shared state** — anything not directly related to the view:

```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private users: User[] = [];

  getAll(): Observable<User[]> { return this.http.get<User[]>('/api/users'); }
  getById(id: number): Observable<User> { return this.http.get<User>(`/api/users/${id}`); }
  create(user: User): Observable<User> { return this.http.post<User>('/api/users', user); }

  constructor(private http: HttpClient) {}
}
```

Services are used for:
- HTTP calls and data fetching
- Shared state between components
- Business logic (calculations, transformations)
- Logging, caching, authentication

---

## Q2. What is Dependency Injection (DI) in Angular?
**Answer:**
DI is a design pattern where a class receives its dependencies from an external source rather than creating them itself. Angular's DI container automatically instantiates and provides services:

```typescript
// Without DI — tightly coupled, hard to test
class UserComponent {
  private svc = new UserService(new HttpClient(...)); // manual creation
}

// With DI — loose coupling, testable
@Component({ selector: 'app-user' })
class UserComponent {
  constructor(private svc: UserService) {} // Angular injects automatically
}

// Angular creates UserService once (singleton) and injects it everywhere it's needed
```

DI benefits: loose coupling, testability (inject mocks), separation of concerns, reusability.

---

## Q3. What is `providedIn: 'root'` and how does it differ from module-level providers?
**Answer:**
```typescript
// Root-level — single instance for the entire app (tree-shakable)
@Injectable({ providedIn: 'root' })
export class AuthService {}

// Module-level — instance scoped to the module (NOT tree-shakable)
@NgModule({ providers: [FeatureService] })
export class FeatureModule {}

// Component-level — new instance per component instance
@Component({ providers: [TempService] })
export class MyComponent {}

// 'any' — separate instance per lazy-loaded module
@Injectable({ providedIn: 'any' })
export class PerModuleService {}
```

**Prefer `providedIn: 'root'`** — it enables tree-shaking (unused services are removed from the bundle) and ensures a singleton.

---

## Q4. What is the Angular injector hierarchy?
**Answer:**
Angular has a hierarchical DI system. Each level can override services from parent levels:

```
Application Root Injector (providedIn: 'root' services)
  ├── Module Injector (providers in @NgModule)
  │     └── Lazy Module Injector (each lazy module gets its own)
  └── Element Injector Tree (per component/directive providers)
        ├── AppComponent Injector
        │     ├── NavbarComponent Injector
        │     └── MainComponent Injector
        │           └── UserListComponent Injector
        └── (inherits up the tree if not found locally)
```

When Angular needs to inject `UserService` into a component:
1. Check component's own injector.
2. Walk up to parent components.
3. Check module injector.
4. Check root injector.
5. If not found → `NullInjectorError`.

---

## Q5. What is `InjectionToken` and when is it needed?
**Answer:**
`InjectionToken` provides a unique token for injecting non-class values (strings, objects, functions) or when multiple services share the same interface:

```typescript
// Define tokens
export const API_URL = new InjectionToken<string>('API_URL');
export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');

// Provide tokens
@NgModule({
  providers: [
    { provide: API_URL, useValue: 'https://api.example.com' },
    { provide: APP_CONFIG, useFactory: () => ({ theme: 'dark', pageSize: 20 }) }
  ]
})
export class AppModule {}

// Or with providedIn
export const LOGGER = new InjectionToken<Logger>('LOGGER', {
  providedIn: 'root',
  factory: () => new ConsoleLogger()
});

// Inject token
@Component({ selector: 'app-api' })
export class ApiComponent {
  constructor(@Inject(API_URL) private apiUrl: string) {}
}
```

---

## Q6. What are the different provider types (`useClass`, `useValue`, `useFactory`, `useExisting`)?
**Answer:**
```typescript
@NgModule({
  providers: [
    // useClass — provide a class (default if you just list the class)
    { provide: LoggerService, useClass: FileLoggerService }, // swap implementation

    // useValue — provide a literal value
    { provide: APP_TITLE, useValue: 'My Angular App' },
    { provide: ENVIRONMENT, useValue: environment },

    // useFactory — compute the value with a function
    {
      provide: HttpClient,
      useFactory: (auth: AuthService) => new CustomHttpClient(auth),
      deps: [AuthService] // declare dependencies
    },

    // useExisting — alias — both tokens resolve to the same instance
    { provide: OldService, useExisting: NewService }
  ]
})
```

---

## Q7. What is a singleton service and how is it achieved in Angular?
**Answer:**
A singleton service has only **one instance** shared across the entire application:

```typescript
// Method 1: providedIn: 'root' (recommended)
@Injectable({ providedIn: 'root' })
export class CartService { items: Item[] = []; }

// Method 2: Provide only in AppModule (never in feature modules)
@NgModule({ providers: [CartService] }) // in AppModule only
export class AppModule {}
```

**Common mistake:** Importing `SharedModule` (which provides a service) in both the root module AND a lazy-loaded module creates **two instances** — one per module injector.

**Fix for lazy-loaded modules:**
```typescript
// Use forRoot() pattern
@NgModule({})
export class SharedModule {
  static forRoot(): ModuleWithProviders<SharedModule> {
    return { ngModule: SharedModule, providers: [CartService] };
  }
}
// AppModule: SharedModule.forRoot() — registers service once
// LazyModule: SharedModule — no service registration
```

---

## Q8. What is the difference between `@Self`, `@SkipSelf`, `@Optional`, and `@Host` decorators?
**Answer:**
These decorators modify how Angular searches for dependencies in the injector hierarchy:

```typescript
// @Self — only look in the current injector (component's own providers)
constructor(@Self() private svc: UserService) {}

// @SkipSelf — skip current injector, look in parent
constructor(@SkipSelf() private parentSvc: UserService) {}

// @Optional — return null if not found (no error)
constructor(@Optional() private logSvc: LogService) {
  this.logSvc?.log('init'); // may be null
}

// @Host — look from current injector up to the host component injector
constructor(@Host() private formDir: NgForm) {}

// Combined
constructor(@Optional() @SkipSelf() private cache: CacheService) {}
```

---

## Q9. What is the `forwardRef` function and when is it needed?
**Answer:**
`forwardRef` resolves **circular reference** issues where a class needs to reference itself or a class defined later in the file:

```typescript
// Problem: NG_VALUE_ACCESSOR needs to reference the component class,
// but the class isn't fully defined yet when the providers array is evaluated
@Component({
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => MyInputComponent), // forward reference
    multi: true
  }]
})
export class MyInputComponent implements ControlValueAccessor { ... }
```

Also used in circular dependency scenarios (A depends on B, B depends on A).

---

## Q10. What is multi-provider and how is it used?
**Answer:**
`multi: true` allows multiple providers for the same token — they're collected into an array:

```typescript
// Define multiple handlers for the same token
export const HTTP_INTERCEPTORS: InjectionToken<HttpInterceptor[]> = ...;

providers: [
  { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor,    multi: true },
  { provide: HTTP_INTERCEPTORS, useClass: LoggingInterceptor, multi: true },
  { provide: HTTP_INTERCEPTORS, useClass: CacheInterceptor,   multi: true }
]

// Angular collects all multi-providers into an array:
// [AuthInterceptor, LoggingInterceptor, CacheInterceptor]
```

Built-in multi-tokens: `HTTP_INTERCEPTORS`, `NG_VALIDATORS`, `NG_VALUE_ACCESSOR`, `APP_INITIALIZER`.

---

## Q11. What is `APP_INITIALIZER` and how is it used?
**Answer:**
`APP_INITIALIZER` runs functions during app initialization — before the app is fully loaded:

```typescript
export function initializeApp(configService: ConfigService) {
  return () => configService.loadConfig(); // returns a Promise or Observable
}

@NgModule({
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initializeApp,
      deps: [ConfigService],
      multi: true
    }
  ]
})
export class AppModule {}
```

Angular waits for all `APP_INITIALIZER` Promises/Observables to resolve before rendering. Use for: loading remote config, setting up auth tokens, initializing analytics.

---

## Q12. How do you test a service with dependencies?
**Answer:**
Use `TestBed` to set up the DI environment and inject mocks:

```typescript
describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService]
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should fetch users', () => {
    service.getAll().subscribe(users => expect(users.length).toBe(2));
    const req = httpMock.expectOne('/api/users');
    req.flush([{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]);
  });

  afterEach(() => httpMock.verify());
});
```

---

## Q13. What is the `DestroyRef` and `takeUntilDestroyed` pattern?
**Answer:**
`DestroyRef` (Angular 16+) provides a hook to run cleanup when the injector context is destroyed, eliminating the boilerplate `Subject`-based teardown:

```typescript
// Old pattern — boilerplate
@Component({})
class OldComponent implements OnDestroy {
  private destroyed$ = new Subject<void>();
  ngOnInit() { this.svc.data$.pipe(takeUntil(this.destroyed$)).subscribe(); }
  ngOnDestroy() { this.destroyed$.next(); this.destroyed$.complete(); }
}

// New pattern — Angular 16+
@Component({})
class NewComponent {
  constructor() {
    this.svc.data$.pipe(takeUntilDestroyed()).subscribe(); // auto-cleanup
  }
}

// With DestroyRef explicitly
@Component({})
class AnotherComponent {
  private destroyRef = inject(DestroyRef);
  constructor() {
    this.destroyRef.onDestroy(() => console.log('Cleaned up!'));
  }
}
```

---

## Q14. What is the `inject()` function?
**Answer:**
`inject()` is a functional alternative to constructor injection — available in injection context (constructor, class fields, factory functions):

```typescript
// Traditional constructor injection
@Component({})
class TraditionalComponent {
  constructor(private userSvc: UserService, private router: Router) {}
}

// Functional inject() — cleaner for complex components
@Component({})
class FunctionalComponent {
  private userSvc = inject(UserService);
  private router = inject(Router);
  private destroyRef = inject(DestroyRef);
  private apiUrl = inject(API_URL);

  // Can be used in class fields initialization
  users$ = inject(UserService).getAll();
}

// In factory functions for providedIn
const MY_SERVICE = new InjectionToken<string>('my', {
  factory: () => inject(ConfigService).get('myKey')
});
```

---

## Q15. What is the difference between `providedIn: 'root'` and `providedIn: 'platform'`?
**Answer:**
| | `providedIn: 'root'` | `providedIn: 'platform'` |
|---|---|---|
| **Scope** | Single Angular application | Shared across multiple Angular apps on the same page |
| **Use case** | Standard singleton services | Micro-frontend / multiple-app scenarios |
| **Common** | ✓ Most services | ✗ Rarely needed |

```typescript
// Root — one instance per Angular app bootstrapped
@Injectable({ providedIn: 'root' })
export class AuthService {}

// Platform — one instance even if multiple Angular apps are bootstrapped
@Injectable({ providedIn: 'platform' })
export class SharedStateService {}
```

`providedIn: 'platform'` is used in micro-frontend architectures where multiple Angular apps run in the same browser context and need to share state.
