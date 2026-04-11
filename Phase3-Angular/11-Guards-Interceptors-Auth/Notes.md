# Topic 11: Guards, Interceptors & Authentication

## Authentication Flow in Angular

```
┌─────────────────────────────────────────────────────────────┐
│                    Authentication Flow                        │
│                                                              │
│  1. User submits login form                                  │
│  2. Angular sends POST /api/auth/login                       │
│  3. Server validates credentials                             │
│  4. Server returns JWT token                                 │
│  5. Angular stores token (localStorage/memory)                │
│  6. All subsequent requests include: Authorization: Bearer <token> │
│  7. Server validates token on each request                    │
│  8. Token expires → user redirected to login                  │
│                                                              │
│  ┌──────┐  POST /login   ┌──────┐                           │
│  │Client│ ──────────────→│Server│                           │
│  │      │ ←──────────────│      │  { token: "eyJ..." }      │
│  │      │                │      │                           │
│  │      │  GET /api/data │      │                           │
│  │      │  Auth: Bearer  │      │                           │
│  │      │ ──────────────→│      │                           │
│  │      │ ←──────────────│      │  { data: [...] }          │
│  └──────┘                └──────┘                           │
└─────────────────────────────────────────────────────────────┘
```

---

## JWT (JSON Web Token)

```
JWT Structure:
Header.Payload.Signature

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.    ← Header (algorithm)
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkRlYmFuamFuIn0.    ← Payload (data)
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c    ← Signature (verification)
```

```typescript
// Decoded payload:
{
  "sub": "1234567890",        // Subject (user ID)
  "name": "Debanjan",
  "email": "deb@test.com",
  "role": "admin",
  "iat": 1714400000,         // Issued at
  "exp": 1714486400          // Expires at
}
```

---

## Auth Service

```typescript
// services/auth.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, map } from 'rxjs';
import { Router } from '@angular/router';

interface LoginResponse {
  token: string;
  user: User;
}

interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'editor' | 'user';
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);
  
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  currentUser$ = this.currentUserSubject.asObservable();
  
  private readonly TOKEN_KEY = 'auth_token';
  
  // Check if user is logged in
  get isLoggedIn(): boolean {
    return !!this.getToken() && !this.isTokenExpired();
  }
  
  get currentUser(): User | null {
    return this.currentUserSubject.value;
  }
  
  // Login
  login(email: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>('/api/auth/login', { email, password }).pipe(
      tap(response => {
        this.setToken(response.token);
        this.currentUserSubject.next(response.user);
      })
    );
  }
  
  // Register
  register(userData: any): Observable<LoginResponse> {
    return this.http.post<LoginResponse>('/api/auth/register', userData).pipe(
      tap(response => {
        this.setToken(response.token);
        this.currentUserSubject.next(response.user);
      })
    );
  }
  
  // Logout
  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    this.currentUserSubject.next(null);
    this.router.navigate(['/login']);
  }
  
  // Token management
  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }
  
  private setToken(token: string): void {
    localStorage.setItem(this.TOKEN_KEY, token);
  }
  
  // Check if token is expired
  private isTokenExpired(): boolean {
    const token = this.getToken();
    if (!token) return true;
    
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.exp * 1000 < Date.now();
    } catch {
      return true;
    }
  }
  
  // Get user role from token
  getUserRole(): string | null {
    const token = this.getToken();
    if (!token) return null;
    
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.role;
    } catch {
      return null;
    }
  }
  
  // Initialize auth state (call on app startup)
  initAuth(): void {
    if (this.isLoggedIn) {
      const token = this.getToken()!;
      const payload = JSON.parse(atob(token.split('.')[1]));
      this.currentUserSubject.next({
        id: payload.sub,
        name: payload.name,
        email: payload.email,
        role: payload.role
      });
    }
  }
}
```

---

## Route Guards

### Auth Guard (canActivate)

```typescript
// guards/auth.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn) {
    return true;
  }
  
  // Save attempted URL for redirect after login
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url }
  });
};
```

### Role Guard

```typescript
// guards/role.guard.ts
export const roleGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  const requiredRoles = route.data['roles'] as string[];
  const userRole = authService.getUserRole();
  
  if (userRole && requiredRoles.includes(userRole)) {
    return true;
  }
  
  // Redirect to unauthorized page
  return router.createUrlTree(['/unauthorized']);
};
```

### Unsaved Changes Guard (canDeactivate)

```typescript
// guards/unsaved-changes.guard.ts
export interface HasUnsavedChanges {
  hasUnsavedChanges(): boolean;
}

export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> = (component) => {
  if (component.hasUnsavedChanges()) {
    return confirm('You have unsaved changes. Are you sure you want to leave?');
  }
  return true;
};
```

### No-Auth Guard (Prevent logged-in users from visiting login)

```typescript
export const noAuthGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn) {
    return router.createUrlTree(['/dashboard']);  // Already logged in
  }
  return true;
};
```

### Applying Guards to Routes

```typescript
export const routes: Routes = [
  // Public routes
  { path: '', component: HomeComponent },
  { path: 'login', component: LoginComponent, canActivate: [noAuthGuard] },
  { path: 'register', component: RegisterComponent, canActivate: [noAuthGuard] },
  
  // Authenticated routes
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [authGuard]
  },
  {
    path: 'profile',
    component: ProfileComponent,
    canActivate: [authGuard]
  },
  
  // Role-protected routes
  {
    path: 'admin',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['admin'] },
    children: [
      { path: '', component: AdminDashboardComponent },
      { path: 'users', component: AdminUsersComponent },
      {
        path: 'users/:id/edit',
        component: UserEditComponent,
        canDeactivate: [unsavedChangesGuard]
      }
    ]
  },
  
  // Editor routes
  {
    path: 'editor',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['admin', 'editor'] },
    children: [
      { path: '', component: EditorDashboardComponent }
    ]
  },
  
  { path: 'unauthorized', component: UnauthorizedComponent },
  { path: '**', component: NotFoundComponent }
];
```

---

## HTTP Interceptors for Auth

### Auth Interceptor

```typescript
// interceptors/auth.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  const token = authService.getToken();
  
  // Skip auth header for public endpoints
  const publicUrls = ['/api/auth/login', '/api/auth/register'];
  if (publicUrls.some(url => req.url.includes(url))) {
    return next(req);
  }
  
  // Clone request and add auth header
  let authReq = req;
  if (token) {
    authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }
  
  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        authService.logout();  // Token expired or invalid
      }
      return throwError(() => error);
    })
  );
};
```

### Token Refresh Interceptor

```typescript
export const tokenRefreshInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  
  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401 && !req.url.includes('/auth/refresh')) {
        // Try to refresh token
        return authService.refreshToken().pipe(
          switchMap(newToken => {
            // Retry original request with new token
            const retryReq = req.clone({
              setHeaders: { Authorization: `Bearer ${newToken}` }
            });
            return next(retryReq);
          }),
          catchError(refreshError => {
            // Refresh failed — logout
            authService.logout();
            return throwError(() => refreshError);
          })
        );
      }
      return throwError(() => error);
    })
  );
};
```

### CSRF/XSRF Interceptor

```typescript
export const csrfInterceptor: HttpInterceptorFn = (req, next) => {
  // Angular's HttpClient automatically handles XSRF with cookies
  // But for custom token:
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) {
    const token = getCsrfTokenFromCookie();
    if (token) {
      req = req.clone({
        setHeaders: { 'X-XSRF-TOKEN': token }
      });
    }
  }
  return next(req);
};
```

### Registering All Interceptors

```typescript
// app.config.ts
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([
        authInterceptor,
        tokenRefreshInterceptor,
        loggingInterceptor,
        errorInterceptor
      ])
    )
  ]
};
```

---

## Login Component

```typescript
@Component({
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
    <div class="login-container">
      <h2>Login</h2>
      
      @if (errorMessage) {
        <div class="alert error">{{ errorMessage }}</div>
      }
      
      <form [formGroup]="loginForm" (ngSubmit)="onLogin()">
        <div class="form-group">
          <label>Email</label>
          <input formControlName="email" type="email" />
        </div>
        
        <div class="form-group">
          <label>Password</label>
          <input formControlName="password" type="password" />
        </div>
        
        <button type="submit" [disabled]="loginForm.invalid || isLoading">
          {{ isLoading ? 'Logging in...' : 'Login' }}
        </button>
      </form>
      
      <p>Don't have an account? <a routerLink="/register">Register</a></p>
    </div>
  `
})
export class LoginComponent {
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private fb = inject(FormBuilder);
  
  loginForm = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });
  
  isLoading = false;
  errorMessage: string | null = null;
  
  onLogin(): void {
    if (this.loginForm.invalid) return;
    
    this.isLoading = true;
    this.errorMessage = null;
    
    const { email, password } = this.loginForm.value;
    
    this.authService.login(email!, password!).subscribe({
      next: () => {
        const returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
        this.router.navigateByUrl(returnUrl);
      },
      error: (err) => {
        this.isLoading = false;
        this.errorMessage = err.status === 401
          ? 'Invalid email or password'
          : 'An error occurred. Please try again.';
      }
    });
  }
}
```

---

## Protecting the UI

### Show/Hide Based on Auth State

```typescript
@Component({
  template: `
    <nav>
      <a routerLink="/">Home</a>
      
      @if (isLoggedIn$ | async) {
        <a routerLink="/dashboard">Dashboard</a>
        @if (isAdmin$ | async) {
          <a routerLink="/admin">Admin</a>
        }
        <button (click)="logout()">Logout</button>
        <span>{{ (user$ | async)?.name }}</span>
      } @else {
        <a routerLink="/login">Login</a>
        <a routerLink="/register">Register</a>
      }
    </nav>
  `
})
export class NavComponent {
  private authService = inject(AuthService);
  
  user$ = this.authService.currentUser$;
  isLoggedIn$ = this.user$.pipe(map(u => !!u));
  isAdmin$ = this.user$.pipe(map(u => u?.role === 'admin'));
  
  logout(): void { this.authService.logout(); }
}
```

### Structural Directive for Roles

```typescript
@Directive({
  selector: '[appHasRole]',
  standalone: true
})
export class HasRoleDirective {
  private authService = inject(AuthService);
  private templateRef = inject(TemplateRef<any>);
  private viewContainer = inject(ViewContainerRef);
  private hasView = false;
  
  @Input() set appHasRole(roles: string[]) {
    const userRole = this.authService.getUserRole();
    const hasRole = userRole ? roles.includes(userRole) : false;
    
    if (hasRole && !this.hasView) {
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (!hasRole && this.hasView) {
      this.viewContainer.clear();
      this.hasView = false;
    }
  }
}
```

```html
<button *appHasRole="['admin']">Delete All</button>
<div *appHasRole="['admin', 'editor']">Edit Content</div>
```

---

## Security Best Practices

| Practice | Why |
|---|---|
| Store tokens in memory/httpOnly cookies | Prevent XSS token theft |
| Use short token expiry (15 min) | Limit window of compromise |
| Implement refresh tokens | Seamless re-authentication |
| Validate tokens server-side | Client validation is bypassable |
| Use HTTPS everywhere | Prevent token interception |
| Sanitize inputs (Angular does this) | Prevent XSS |
| CSRF tokens for state changes | Prevent cross-site forgery |
| Hide sensitive UI but ENFORCE on server | UI hiding is not security |
| Don't store sensitive data in JWT | JWT payload is base64, not encrypted |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| JWT | Token-based auth: Header.Payload.Signature |
| AuthService | Login/logout, token management, user state |
| authGuard | Protect routes — redirect to login if not authenticated |
| roleGuard | Check user roles against route requirements |
| canDeactivate | Warn about unsaved changes |
| Auth interceptor | Auto-add Bearer token to HTTP requests |
| Token refresh | Handle 401 by refreshing token and retrying |
| `*appHasRole` | Show/hide UI based on user role |
| Security | Validate server-side; client guards are UX only |

---

*Next Topic: Phase 3 Revision Test →*
