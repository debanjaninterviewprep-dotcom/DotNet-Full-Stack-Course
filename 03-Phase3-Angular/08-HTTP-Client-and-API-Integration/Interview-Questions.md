# Topic 08: HTTP Client and API Integration — Interview Questions

---

## Q1. How do you set up `HttpClient` in Angular?
**Answer:**
```typescript
// Standalone app (Angular 17+) — recommended
bootstrapApplication(AppComponent, {
  providers: [provideHttpClient()]
});

// With interceptors
bootstrapApplication(AppComponent, {
  providers: [
    provideHttpClient(withInterceptors([authInterceptor, loggingInterceptor]))
  ]
});

// NgModule approach
@NgModule({ imports: [HttpClientModule] })
export class AppModule {}

// Usage in a service
@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private http: HttpClient) {}
  getUsers(): Observable<User[]> { return this.http.get<User[]>('/api/users'); }
}
```

---

## Q2. What HTTP methods does `HttpClient` support?
**Answer:**
```typescript
// GET — fetch data
this.http.get<User[]>('/api/users');
this.http.get<User>(`/api/users/${id}`);

// POST — create
this.http.post<User>('/api/users', newUser);

// PUT — full update
this.http.put<User>(`/api/users/${id}`, updatedUser);

// PATCH — partial update
this.http.patch<User>(`/api/users/${id}`, { name: 'Alice' });

// DELETE — remove
this.http.delete(`/api/users/${id}`);

// HEAD — headers only
this.http.head('/api/users');

// Request with custom options
this.http.get<User[]>('/api/users', {
  headers: { Authorization: `Bearer ${token}` },
  params:  { page: '1', sort: 'name' },
  observe: 'response' // get full HttpResponse, not just body
});
```

---

## Q3. How do you add headers and query parameters to HTTP requests?
**Answer:**
```typescript
// Headers
const headers = new HttpHeaders({
  'Authorization': `Bearer ${this.authService.getToken()}`,
  'Content-Type': 'application/json',
  'X-API-Version': '2'
});
this.http.get('/api/users', { headers });

// HttpHeaders are immutable — each method returns a new instance
const updated = headers.set('Cache-Control', 'no-cache')
                       .append('Accept', 'application/json');

// Query params
const params = new HttpParams()
  .set('page', '1')
  .set('pageSize', '20')
  .set('sort', 'name');
this.http.get('/api/users', { params });

// Object shorthand
this.http.get('/api/users', {
  params: { page: '1', sort: 'name', active: 'true' }
});
```

---

## Q4. How do you handle HTTP errors?
**Answer:**
```typescript
// catchError — catch and transform errors
getUsers(): Observable<User[]> {
  return this.http.get<User[]>('/api/users').pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) this.authService.logout();
      if (err.status === 404) return of([]); // empty array on 404
      if (err.status === 0)   console.error('Network error');
      return throwError(() => new Error(err.message)); // re-throw
    })
  );
}

// Global error handling in interceptor (preferred)
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) inject(Router).navigate(['/login']);
      inject(NotificationService).showError(err.message);
      return throwError(() => err);
    })
  );
};
```

---

## Q5. What are HTTP interceptors and how do you create one?
**Answer:**
Interceptors sit between the HTTP request/response pipeline and can modify, log, or retry requests:

```typescript
// Functional interceptor (Angular 15+) — recommended
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    const authReq = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` }
    });
    return next(authReq);
  }
  return next(req);
};

// Loading indicator interceptor
export const loadingInterceptor: HttpInterceptorFn = (req, next) => {
  const loading = inject(LoadingService);
  loading.show();
  return next(req).pipe(finalize(() => loading.hide()));
};

// Register interceptors
provideHttpClient(withInterceptors([authInterceptor, loadingInterceptor]))
```

---

## Q6. How do you implement retry logic for HTTP requests?
**Answer:**
```typescript
import { retry, retryWhen, delay, take } from 'rxjs/operators';

// Simple retry (3 attempts)
this.http.get('/api/data').pipe(retry(3));

// Retry with delay (exponential backoff)
this.http.get('/api/data').pipe(
  retry({
    count: 3,
    delay: (error, retryCount) => timer(retryCount * 1000) // 1s, 2s, 3s
  })
);

// Only retry on specific errors
this.http.get('/api/data').pipe(
  retry({
    count: 3,
    delay: (error: HttpErrorResponse) => {
      if (error.status === 503) return timer(2000); // retry on service unavailable
      return throwError(() => error);               // don't retry on others
    }
  })
);
```

---

## Q7. What is `observe: 'response'` vs `observe: 'body'`?
**Answer:**
The `observe` option controls what the Observable emits:

```typescript
// observe: 'body' (default) — emits just the response body
this.http.get<User>('/api/users/1').subscribe(user => console.log(user));

// observe: 'response' — emits the full HttpResponse
this.http.get<User>('/api/users/1', { observe: 'response' }).subscribe(response => {
  const totalCount = response.headers.get('X-Total-Count');
  const user = response.body;
  const status = response.status; // 200
});

// observe: 'events' — emits all HttpEvents (upload progress, etc.)
this.http.post('/api/upload', formData, {
  observe: 'events',
  reportProgress: true
}).subscribe(event => {
  if (event.type === HttpEventType.UploadProgress)
    this.progress = Math.round(100 * event.loaded / event.total!);
  if (event.type === HttpEventType.Response)
    console.log('Upload complete', event.body);
});
```

---

## Q8. How do you handle multiple concurrent HTTP requests?
**Answer:**
```typescript
// forkJoin — run in parallel, emit when ALL complete
forkJoin({
  users:    this.http.get<User[]>('/api/users'),
  products: this.http.get<Product[]>('/api/products'),
  config:   this.http.get<Config>('/api/config')
}).subscribe(({ users, products, config }) => {
  this.users = users;
  this.products = products;
});

// combineLatest — emit on every source change
combineLatest([this.users$, this.filter$]).subscribe(([users, filter]) => {
  this.filtered = users.filter(u => u.role === filter);
});

// switchMap — cancel previous, use latest
this.searchTerm$.pipe(
  debounceTime(300),
  switchMap(term => this.http.get<User[]>(`/api/users?q=${term}`))
).subscribe(results => this.results = results);

// mergeMap — run all in parallel, merge results
this.userIds$.pipe(
  mergeMap(id => this.http.get<User>(`/api/users/${id}`))
).subscribe(user => this.users.push(user));
```

---

## Q9. What are `switchMap`, `mergeMap`, `concatMap`, and `exhaustMap`?
**Answer:**
These operators map each source value to an inner Observable:

| Operator | Behaviour | Use case |
|---|---|---|
| `switchMap` | Cancels previous inner observable | Search (latest query wins) |
| `mergeMap` | All run in parallel | Parallel API calls |
| `concatMap` | One at a time, in order | Sequential operations |
| `exhaustMap` | Ignores new values while inner is active | Login button (ignore double-clicks) |

```typescript
// switchMap — search: each new term cancels pending request
searchInput.pipe(
  debounceTime(300),
  switchMap(term => this.api.search(term)) // cancels if user types again
).subscribe();

// concatMap — sequential saves (order matters)
saveClicks.pipe(
  concatMap(() => this.api.save(data)) // waits for each save to complete
).subscribe();

// exhaustMap — login: ignore clicks while request is pending
loginClicks.pipe(
  exhaustMap(() => this.api.login(credentials)) // ignores extra clicks
).subscribe();
```

---

## Q10. How do you implement caching for HTTP requests?
**Answer:**
```typescript
@Injectable({ providedIn: 'root' })
export class UserService {
  private cache = new Map<string, User[]>();

  getUsers(category: string): Observable<User[]> {
    if (this.cache.has(category)) {
      return of(this.cache.get(category)!); // return cached
    }
    return this.http.get<User[]>(`/api/users?cat=${category}`).pipe(
      tap(users => this.cache.set(category, users)) // store in cache
    );
  }
}

// With shareReplay — share and replay last emission to late subscribers
@Injectable({ providedIn: 'root' })
export class ConfigService {
  config$ = this.http.get<Config>('/api/config').pipe(
    shareReplay(1) // cache + share single HTTP call for all subscribers
  );
}
```

---

## Q11. What is `HttpContext` and when is it used?
**Answer:**
`HttpContext` passes metadata through interceptors without modifying the request:

```typescript
// Define a token
const SKIP_AUTH = new HttpContextToken<boolean>(() => false);
const SKIP_LOADING = new HttpContextToken<boolean>(() => false);

// Use in interceptor
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (req.context.get(SKIP_AUTH)) return next(req); // skip this request
  return next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }));
};

// Mark a request to skip auth
this.http.get('/api/public-data', {
  context: new HttpContext().set(SKIP_AUTH, true).set(SKIP_LOADING, true)
});
```

---

## Q12. How do you cancel an HTTP request?
**Answer:**
```typescript
// Approach 1: switchMap (automatic cancellation on new value)
this.searchTerm$.pipe(
  switchMap(term => this.http.get(`/api/search?q=${term}`))
).subscribe(); // previous request cancelled when new search term arrives

// Approach 2: takeUntil with Subject
const cancel$ = new Subject<void>();

this.http.get('/api/data').pipe(
  takeUntil(cancel$)
).subscribe();

// Cancel manually
cancelButton.click(() => cancel$.next());

// Approach 3: AbortController (low-level)
const controller = new AbortController();
// Not directly usable in Angular HttpClient — use switchMap/takeUntil
```

---

## Q13. What is CORS and how is it handled in Angular?
**Answer:**
CORS (Cross-Origin Resource Sharing) is a browser security policy that blocks requests to a different domain unless the server explicitly allows it.

Angular **does not handle CORS** — it's a server-side configuration:

```
Client: http://localhost:4200 → Request → Server: http://api.example.com
Browser checks: Response headers include Access-Control-Allow-Origin?
If yes → request succeeds
If no → browser blocks response (CORS error)
```

**During development** — use Angular CLI proxy:
```json
// proxy.conf.json
{
  "/api": {
    "target": "http://localhost:3000",
    "changeOrigin": true,
    "secure": false
  }
}
```
```bash
ng serve --proxy-config proxy.conf.json
```

**In production** — configure the server to return correct CORS headers.

---

## Q14. What is the difference between `HttpClient.get()` and `fetch()`?
**Answer:**
| | Angular `HttpClient` | Browser `fetch()` |
|---|---|---|
| **Return type** | Observable | Promise |
| **Interceptors** | ✓ Yes | ✗ No |
| **Type safety** | ✓ Generic `get<T>()` | ✗ `any` unless cast |
| **Retry/cancel** | ✓ RxJS operators | Manual |
| **Progress** | ✓ `reportProgress` | `ReadableStream` |
| **Testing** | ✓ `HttpTestingController` | Harder to mock |
| **Angular zone** | ✓ Notifies Angular CD | Needs manual zone.run() |

**Use `HttpClient`** in Angular applications — it integrates seamlessly with the Angular ecosystem.

---

## Q15. How do you type API responses with interfaces?
**Answer:**
```typescript
// Define interfaces matching the API response shape
interface ApiResponse<T> {
  data: T;
  total: number;
  page: number;
  errors?: string[];
}

interface User {
  id: number;
  name: string;
  email: string;
  createdAt: string; // ISO date string from API
}

@Injectable({ providedIn: 'root' })
export class UserService {
  // Fully typed — compiler knows the shape
  getUsers(page: number): Observable<ApiResponse<User[]>> {
    return this.http.get<ApiResponse<User[]>>('/api/users', {
      params: { page: page.toString() }
    });
  }

  // Transform API shape to domain model
  getUsersWithDate(page: number): Observable<User[]> {
    return this.getUsers(page).pipe(
      map(res => res.data.map(u => ({
        ...u,
        createdAt: new Date(u.createdAt) // string → Date
      })))
    );
  }
}
```
