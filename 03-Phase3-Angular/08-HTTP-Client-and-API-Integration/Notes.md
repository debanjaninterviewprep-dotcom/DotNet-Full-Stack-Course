# Topic 8: HTTP Client & API Integration

## Angular HttpClient

Angular's `HttpClient` makes HTTP requests and returns **Observables**. It handles JSON serialization, headers, error handling, and interceptors.

```
Component → Service → HttpClient → Backend API
                ↓
         Observable<T>
                ↓
    Component subscribes and displays data
```

---

## Setup

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient()  // Enable HttpClient
  ]
};
```

---

## Basic HTTP Methods

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  private apiUrl = 'https://api.example.com/users';
  
  // GET all
  getAll(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl);
  }
  
  // GET one
  getById(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/${id}`);
  }
  
  // POST (create)
  create(user: CreateUserDto): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }
  
  // PUT (full update)
  update(id: number, user: User): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/${id}`, user);
  }
  
  // PATCH (partial update)
  partialUpdate(id: number, changes: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}`, changes);
  }
  
  // DELETE
  delete(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
```

---

## Subscribing in Components

### Manual Subscribe

```typescript
@Component({
  template: `
    @if (loading) { <p>Loading...</p> }
    @if (error) { <p class="error">{{ error }}</p> }
    @for (user of users; track user.id) {
      <div>{{ user.name }}</div>
    }
  `
})
export class UserListComponent implements OnInit {
  private userService = inject(UserService);
  users: User[] = [];
  loading = false;
  error: string | null = null;
  
  ngOnInit(): void {
    this.loading = true;
    this.userService.getAll().subscribe({
      next: (users) => {
        this.users = users;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load users';
        this.loading = false;
        console.error(err);
      }
    });
  }
}
```

### Async Pipe (Recommended)

```typescript
@Component({
  standalone: true,
  imports: [AsyncPipe],
  template: `
    @if (users$ | async; as users) {
      @for (user of users; track user.id) {
        <div>{{ user.name }}</div>
      }
    } @else {
      <p>Loading...</p>
    }
  `
})
export class UserListComponent {
  private userService = inject(UserService);
  users$ = this.userService.getAll();
  // async pipe subscribes AND unsubscribes automatically!
}
```

---

## Request Options

### Headers

```typescript
import { HttpHeaders } from '@angular/common/http';

const headers = new HttpHeaders({
  'Content-Type': 'application/json',
  'Authorization': 'Bearer my-token-here'
});

this.http.get<User[]>(url, { headers });

// Add headers fluently
const headers = new HttpHeaders()
  .set('Authorization', 'Bearer token')
  .set('Accept', 'application/json');
```

### Query Parameters

```typescript
import { HttpParams } from '@angular/common/http';

// Method 1: HttpParams
const params = new HttpParams()
  .set('page', '1')
  .set('limit', '10')
  .set('sort', 'name');

this.http.get<User[]>(url, { params });
// → GET /users?page=1&limit=10&sort=name

// Method 2: Object shorthand
this.http.get<User[]>(url, {
  params: { page: 1, limit: 10, sort: 'name' }
});
```

### Response Type Options

```typescript
// Default: JSON body
this.http.get<User[]>(url);

// Full response (headers, status, body)
this.http.get<User[]>(url, { observe: 'response' }).subscribe(response => {
  console.log(response.status);          // 200
  console.log(response.headers);         // HttpHeaders
  console.log(response.body);            // User[]
});

// Text response
this.http.get(url, { responseType: 'text' });

// Blob (file download)
this.http.get(url, { responseType: 'blob' });
```

---

## Error Handling

### In Service (RxJS Operators)

```typescript
import { catchError, retry, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class UserService {
  private http = inject(HttpClient);
  
  getAll(): Observable<User[]> {
    return this.http.get<User[]>(this.apiUrl).pipe(
      retry(2),                           // Retry up to 2 times
      catchError(this.handleError)        // Then handle error
    );
  }
  
  private handleError(error: HttpErrorResponse): Observable<never> {
    let message = 'An error occurred';
    
    if (error.status === 0) {
      // Client-side or network error
      message = 'Network error — please check your connection';
    } else if (error.status === 404) {
      message = 'Resource not found';
    } else if (error.status === 401) {
      message = 'Unauthorized — please log in';
    } else if (error.status === 403) {
      message = 'Forbidden — insufficient permissions';
    } else if (error.status === 500) {
      message = 'Server error — please try again later';
    } else {
      message = `Error ${error.status}: ${error.message}`;
    }
    
    console.error(message, error);
    return throwError(() => new Error(message));
  }
}
```

---

## RxJS Operators for HTTP

### Common Patterns

```typescript
import { map, tap, switchMap, debounceTime, distinctUntilChanged, catchError, finalize } from 'rxjs';

// map — transform response
getFullNames(): Observable<string[]> {
  return this.http.get<User[]>(this.apiUrl).pipe(
    map(users => users.map(u => `${u.firstName} ${u.lastName}`))
  );
}

// tap — side effects (logging)
getAll(): Observable<User[]> {
  return this.http.get<User[]>(this.apiUrl).pipe(
    tap(users => console.log(`Fetched ${users.length} users`))
  );
}

// switchMap — chain HTTP calls (cancels previous)
getUserWithPosts(id: number): Observable<{ user: User; posts: Post[] }> {
  return this.http.get<User>(`${this.apiUrl}/${id}`).pipe(
    switchMap(user =>
      this.http.get<Post[]>(`${this.apiUrl}/${id}/posts`).pipe(
        map(posts => ({ user, posts }))
      )
    )
  );
}

// Parallel requests
import { forkJoin } from 'rxjs';

getDashboardData(): Observable<DashboardData> {
  return forkJoin({
    users: this.http.get<User[]>('/api/users'),
    products: this.http.get<Product[]>('/api/products'),
    orders: this.http.get<Order[]>('/api/orders')
  });
}

// finalize — always runs (loading spinner)
getAll(): Observable<User[]> {
  this.loading = true;
  return this.http.get<User[]>(this.apiUrl).pipe(
    finalize(() => this.loading = false)  // Runs on complete or error
  );
}
```

### Search with Debounce

```typescript
// Component
searchTerm = new FormControl('');

results$ = this.searchTerm.valueChanges.pipe(
  debounceTime(300),           // Wait 300ms after last keystroke
  distinctUntilChanged(),      // Only if value changed
  filter(term => term.length >= 2),  // Min 2 chars
  switchMap(term =>            // Cancel previous request
    this.searchService.search(term).pipe(
      catchError(() => of([]))  // Return empty on error
    )
  )
);
```

```html
<input [formControl]="searchTerm" placeholder="Search..." />
@for (result of results$ | async; track result.id) {
  <div>{{ result.name }}</div>
}
```

---

## HTTP Interceptors

Interceptors sit between HttpClient and the network. They can modify **every** request or response.

```
Request:  Component → Service → Interceptor(s) → Network
Response: Network → Interceptor(s) → Service → Component
```

### Functional Interceptor (Modern — Angular 15+)

```typescript
// auth.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();
  
  if (token) {
    const authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
    return next(authReq);
  }
  
  return next(req);
};
```

### Logging Interceptor

```typescript
import { tap } from 'rxjs';

export const loggingInterceptor: HttpInterceptorFn = (req, next) => {
  const started = Date.now();
  
  return next(req).pipe(
    tap({
      next: (event) => {
        if (event instanceof HttpResponse) {
          const elapsed = Date.now() - started;
          console.log(`${req.method} ${req.url} → ${event.status} (${elapsed}ms)`);
        }
      },
      error: (error) => {
        const elapsed = Date.now() - started;
        console.error(`${req.method} ${req.url} → ERROR (${elapsed}ms)`, error);
      }
    })
  );
};
```

### Error Handling Interceptor

```typescript
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Redirect to login
        inject(Router).navigate(['/login']);
      }
      if (error.status === 403) {
        inject(NotificationService).error('Access denied');
      }
      return throwError(() => error);
    })
  );
};
```

### Registering Interceptors

```typescript
// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(
      withInterceptors([
        authInterceptor,     // Runs first
        loggingInterceptor,  // Runs second
        errorInterceptor     // Runs third
      ])
    )
  ]
};
```

---

## File Upload

```typescript
uploadFile(file: File): Observable<HttpEvent<any>> {
  const formData = new FormData();
  formData.append('file', file, file.name);
  
  return this.http.post('/api/upload', formData, {
    reportProgress: true,
    observe: 'events'
  });
}
```

```typescript
// Component
onFileSelected(event: Event): void {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;
  
  this.uploadService.uploadFile(file).subscribe(event => {
    if (event.type === HttpEventType.UploadProgress && event.total) {
      this.progress = Math.round(100 * event.loaded / event.total);
    } else if (event instanceof HttpResponse) {
      console.log('Upload complete!', event.body);
    }
  });
}
```

---

## Caching Pattern

```typescript
@Injectable({ providedIn: 'root' })
export class ProductService {
  private http = inject(HttpClient);
  private cache$ = new Map<string, Observable<any>>();
  
  getProducts(): Observable<Product[]> {
    const url = '/api/products';
    
    if (!this.cache$.has(url)) {
      this.cache$.set(url,
        this.http.get<Product[]>(url).pipe(
          shareReplay(1)  // Cache the last emission
        )
      );
    }
    
    return this.cache$.get(url)!;
  }
  
  clearCache(): void {
    this.cache$.clear();
  }
}
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| HttpClient | Angular's HTTP service — returns Observables |
| `provideHttpClient()` | Enable in app config |
| `get<T>()` / `post<T>()` | Typed HTTP methods |
| Async pipe | Auto-subscribe in template (`data$ \| async`) |
| Error handling | `catchError()`, `retry()` in pipe |
| `switchMap` | Chain requests, cancel previous |
| `forkJoin` | Parallel requests |
| `debounceTime` | Delay search input |
| Interceptors | Modify all requests/responses (auth, logging) |
| `shareReplay(1)` | Cache HTTP responses |

---

*Next Topic: Pipes & Custom Pipes →*
