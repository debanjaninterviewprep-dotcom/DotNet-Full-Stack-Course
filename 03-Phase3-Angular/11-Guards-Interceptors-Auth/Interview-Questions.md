# Topic 11: Guards, Interceptors, and Auth — Interview Questions

---

## Q1. What are Angular route guards?
**Answer:**
Route guards are functions or classes that control whether navigation to/from a route is allowed. They return `boolean`, `UrlTree` (redirect), or `Observable<boolean|UrlTree>`:

| Guard Type | Purpose |
|---|---|
| `CanActivate` | Can the user enter this route? |
| `CanActivateChild` | Can the user enter any child route? |
| `CanDeactivate<T>` | Can the user leave this route (unsaved changes)? |
| `CanLoad` | Can this module be lazy-loaded? (legacy) |
| `CanMatch` | Can this route be matched? (replaces CanLoad) |
| `Resolve<T>` | Pre-fetch data before route activates |

---

## Q2. How do you implement a functional auth guard (Angular 14+)?
**Answer:**
Functional guards (preferred over class-based since Angular 14):

```typescript
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router      = inject(Router);

  if (authService.isLoggedIn()) return true;

  // Redirect to login, preserve intended URL
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url }
  });
};

// Route configuration
const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] },
  { path: 'admin',     component: AdminComponent,     canActivate: [authGuard, roleGuard('admin')] }
];
```

---

## Q3. How do you implement role-based access control with guards?
**Answer:**
```typescript
// Role guard factory — parameterized guard
export const roleGuard = (requiredRole: string): CanActivateFn => {
  return (route, state) => {
    const authService = inject(AuthService);
    const router      = inject(Router);

    if (!authService.isLoggedIn())
      return router.createUrlTree(['/login']);

    if (authService.hasRole(requiredRole))
      return true;

    return router.createUrlTree(['/unauthorized']);
  };
};

// Permission guard — check fine-grained permissions
export const permissionGuard = (permission: string): CanActivateFn => {
  return () => {
    const authService = inject(AuthService);
    return authService.hasPermission(permission)
      ? true
      : inject(Router).createUrlTree(['/forbidden']);
  };
};

// Apply multiple guards
{ path: 'reports', canActivate: [authGuard, roleGuard('admin'), permissionGuard('VIEW_REPORTS')] }
```

---

## Q4. How do you implement `CanDeactivate` to prevent unsaved changes?
**Answer:**
```typescript
// Component interface
export interface HasUnsavedChanges {
  hasUnsavedChanges(): boolean;
}

// Guard
export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> =
  (component, currentRoute, currentState, nextState) => {
    if (!component.hasUnsavedChanges()) return true;
    return confirm('You have unsaved changes. Leave anyway?');
    // OR: return inject(DialogService).confirm('Discard changes?');
  };

// Component
@Component({})
export class EditUserComponent implements HasUnsavedChanges {
  form = this.fb.group({ name: '', email: '' });
  originalValues = {};

  ngOnInit() { this.originalValues = this.form.value; }

  hasUnsavedChanges(): boolean {
    return this.form.dirty && JSON.stringify(this.form.value) !== JSON.stringify(this.originalValues);
  }
}

// Route
{ path: 'users/:id/edit', component: EditUserComponent, canDeactivate: [unsavedChangesGuard] }
```

---

## Q5. What is the `CanMatch` guard?
**Answer:**
`CanMatch` decides whether a route **can be matched at all** — if false, Angular skips to the next matching route. Replaces `CanLoad` (deprecated):

```typescript
export const featureFlagGuard: CanMatchFn = (route) => {
  const featureService = inject(FeatureService);
  const feature = route.data?.['feature'];
  return featureService.isEnabled(feature);
};

// Route setup — multiple routes for same path, different conditions
const routes: Routes = [
  // Admin sees the full dashboard
  { path: 'dashboard', canMatch: [roleGuard('admin')], component: AdminDashboardComponent },
  // Regular users see the limited dashboard
  { path: 'dashboard', component: UserDashboardComponent },
];
```

---

## Q6. What is an HTTP interceptor and what are common use cases?
**Answer:**
HTTP interceptors intercept every outgoing request and incoming response, enabling cross-cutting concerns:

```typescript
// Functional interceptor (Angular 15+)
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken();
  return next(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req);
};

// Common use cases:
// 1. Auth token injection
// 2. Request logging
// 3. Loading indicators
// 4. Error handling / global error notification
// 5. Response transformation / caching
// 6. Retry on failure
// 7. Request deduplication
```

---

## Q7. How do you implement a loading interceptor?
**Answer:**
```typescript
@Injectable({ providedIn: 'root' })
export class LoadingService {
  private requestCount = 0;
  loading$ = new BehaviorSubject<boolean>(false);

  show() { if (++this.requestCount === 1) this.loading$.next(true); }
  hide() { if (--this.requestCount === 0) this.loading$.next(false); }
}

export const loadingInterceptor: HttpInterceptorFn = (req, next) => {
  const loadingService = inject(LoadingService);

  // Skip loading for certain requests
  if (req.context.get(SKIP_LOADING)) return next(req);

  loadingService.show();
  return next(req).pipe(
    finalize(() => loadingService.hide()) // always hide on complete/error
  );
};

// Template
// <app-spinner *ngIf="loadingService.loading$ | async"></app-spinner>
```

---

## Q8. How do you implement JWT authentication in Angular?
**Answer:**
```typescript
// AuthService
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly TOKEN_KEY = 'auth_token';

  login(credentials: Credentials): Observable<void> {
    return this.http.post<{ token: string }>('/api/auth/login', credentials).pipe(
      tap(({ token }) => localStorage.setItem(this.TOKEN_KEY, token)),
      map(() => void 0)
    );
  }

  logout() {
    localStorage.removeItem(this.TOKEN_KEY);
    this.router.navigate(['/login']);
  }

  getToken(): string | null { return localStorage.getItem(this.TOKEN_KEY); }

  isLoggedIn(): boolean {
    const token = this.getToken();
    if (!token) return false;
    return !this.isTokenExpired(token);
  }

  private isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.exp < Date.now() / 1000;
    } catch { return true; }
  }

  getUser(): TokenPayload | null {
    const token = this.getToken();
    if (!token) return null;
    return JSON.parse(atob(token.split('.')[1]));
  }
}
```

---

## Q9. How do you handle token refresh (refresh token flow)?
**Answer:**
```typescript
export const tokenRefreshInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const http        = inject(HttpClient);

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      // Only handle 401 errors (not for login/refresh endpoints)
      if (err.status !== 401 || req.url.includes('/auth/')) {
        return throwError(() => err);
      }

      // Try to refresh the token
      return authService.refreshToken().pipe(
        switchMap((newToken) => {
          // Retry original request with new token
          const retryReq = req.clone({
            setHeaders: { Authorization: `Bearer ${newToken}` }
          });
          return next(retryReq);
        }),
        catchError(() => {
          // Refresh failed — logout
          authService.logout();
          return throwError(() => err);
        })
      );
    })
  );
};
```

---

## Q10. How do you protect routes based on user roles stored in a JWT?
**Answer:**
```typescript
// Auth service reads roles from JWT payload
getUser(): JwtPayload | null {
  const token = this.getToken();
  if (!token) return null;
  return JSON.parse(atob(token.split('.')[1])) as JwtPayload;
}

hasRole(role: string): boolean {
  return this.getUser()?.roles?.includes(role) ?? false;
}

// Guard using roles
export const roleGuard = (role: string): CanActivateFn => () => {
  const auth   = inject(AuthService);
  const router = inject(Router);
  if (auth.hasRole(role)) return true;
  return router.createUrlTree(['/unauthorized']);
};

// Route config
{ path: 'admin', canActivate: [authGuard, roleGuard('ADMIN')], component: AdminComponent }

// Display based on role in template
@if (authService.hasRole('ADMIN')) { <a routerLink="/admin">Admin Panel</a> }
```

---

## Q11. What is CSRF protection and how is it handled in Angular?
**Answer:**
CSRF (Cross-Site Request Forgery) tricks a victim's browser into making authenticated requests to another site.

**Angular's CSRF protection (`HttpClientXsrfModule`):**
```typescript
// Automatic CSRF handling (reads XSRF-TOKEN cookie, sends X-XSRF-TOKEN header)
provideHttpClient(withXsrfConfiguration({
  cookieName: 'XSRF-TOKEN',   // cookie name set by server
  headerName: 'X-XSRF-TOKEN' // header Angular sends to server
}))

// The server sets XSRF-TOKEN cookie; Angular reads it and sends as X-XSRF-TOKEN header
// The server validates that the header matches the cookie
```

Angular's XSRF protection only applies to mutating requests (POST, PUT, PATCH, DELETE).

---

## Q12. How do you store authentication state across page refreshes?
**Answer:**
```typescript
// localStorage — persists across sessions (survives browser close)
localStorage.setItem('token', token);     // store
localStorage.getItem('token');            // read
localStorage.removeItem('token');         // clear

// sessionStorage — cleared when tab/window closes
sessionStorage.setItem('token', token);

// Cookie — can be HttpOnly (not accessible via JS — most secure)
// Must be set by server with Set-Cookie: token=abc; HttpOnly; Secure; SameSite=Strict

// Security considerations:
// - HttpOnly cookies: immune to XSS (JS can't read them) — best for tokens
// - localStorage: vulnerable to XSS attacks — can be read by injected scripts
// - Never store sensitive data in sessionStorage/localStorage if XSS is a concern

// Initialize auth state on app start
@Injectable({ providedIn: 'root' })
export class AuthService {
  private isAuth$ = new BehaviorSubject<boolean>(this.isLoggedIn());
  // Initialized from localStorage — persists across refreshes
}
```

---

## Q13. What is OAuth2 / OpenID Connect and how does Angular integrate with it?
**Answer:**
- **OAuth2** — authorization framework (grants access to resources without sharing passwords).
- **OpenID Connect (OIDC)** — identity layer on top of OAuth2 (provides user info).

**Angular libraries:**
- **angular-oauth2-oidc** (`npm install angular-oauth2-oidc`) — most popular
- **@auth0/auth0-angular** — for Auth0

```typescript
// Configure with angular-oauth2-oidc
OAuthModule.forRoot({
  resourceServer: {
    allowedUrls: ['https://api.example.com'],
    sendAccessToken: true
  }
})

// Auth service
this.oauthService.configure({
  issuer: 'https://accounts.google.com',
  clientId: 'your-client-id',
  scope: 'openid profile email',
  redirectUri: window.location.origin + '/callback'
});
this.oauthService.loadDiscoveryDocumentAndLogin();
```

---

## Q14. What is Content Security Policy (CSP) and how does it relate to Angular?
**Answer:**
CSP is an HTTP response header that restricts which resources a browser can load — prevents XSS attacks:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';  // allow only nonce-tagged scripts
  style-src 'self' 'unsafe-inline';    // Angular needs inline styles
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
```

**Angular and CSP:**
- Angular CLI builds can use nonces for inline scripts (Angular 16+).
- Configure `ng build --output-hashing=all` for fingerprinted assets.
- Avoid `innerHTML` and `bypassSecurityTrust*` methods (bypasses Angular's sanitization).

---

## Q15. What is Angular's built-in security sanitization?
**Answer:**
Angular automatically **sanitizes** untrusted values to prevent XSS attacks:

```typescript
// Angular auto-sanitizes these contexts:
// HTML — strips dangerous tags
// Style — strips dangerous CSS
// URL — validates URLs
// Resource URL — restricts to trusted origins

// DANGEROUS — bypasses security (avoid unless absolutely necessary)
import { DomSanitizer } from '@angular/platform-browser';

@Component({})
export class UnsafeComponent {
  dangerousHtml: SafeHtml;
  constructor(private sanitizer: DomSanitizer) {
    // Only use this for TRUSTED content from YOUR OWN backend
    this.dangerousHtml = this.sanitizer.bypassSecurityTrustHtml('<b>Bold</b>');
  }
}

// Safe alternative — mark what's safe
<div [innerHTML]="trustedContent"></div> // Angular sanitizes automatically
// Angular keeps <b>, <i>, etc. but removes <script>, onerror=, etc.

// Never do:
<div [innerHTML]="userInput"></div> // if userInput comes from user — XSS risk
```
