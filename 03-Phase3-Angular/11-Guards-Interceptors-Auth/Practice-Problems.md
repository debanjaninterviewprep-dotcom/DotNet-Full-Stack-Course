# Topic 11: Guards, Interceptors & Authentication — Practice Problems

## Problem 1: Authentication Service (Easy)
**Concept**: Login/logout, token management, user state

### 1a. Basic Auth Service
Create `AuthService` with:
```typescript
login(email: string, password: string): Observable<LoginResponse>
logout(): void
isLoggedIn(): boolean
getToken(): string | null
getCurrentUser(): User | null
```

Mock the login endpoint (simulate API with delay):
- Email: `admin@test.com`, Password: `admin123` → role: admin
- Email: `user@test.com`, Password: `user123` → role: user
- Any other → 401 error

### 1b. Login Component
Build a login form (reactive):
- Email + password fields with validation
- "Remember me" checkbox (persist token)
- Show error message on failed login
- Redirect to dashboard on success
- Redirect to `returnUrl` if provided

### 1c. Logout & Auth State
- Logout button in navbar
- Clear token and user state
- Redirect to home page
- Show login/register when logged out
- Show user name + logout when logged in

### 1d. Token Inspection
Display decoded JWT payload:
- User name, email, role
- Token expiry time (human-readable)
- Time remaining until expiry
- Auto-logout when token expires

---

## Problem 2: Route Guards (Easy-Medium)
**Concept**: Protecting routes based on auth and roles

### 2a. Auth Guard
Create `authGuard`:
- Check if user is logged in (token exists and not expired)
- If not → redirect to `/login?returnUrl=/original-path`
- After login → redirect back to original URL

Apply to routes: `/dashboard`, `/profile`, `/settings`

### 2b. Role Guard
Create `roleGuard`:
- Read required roles from `route.data['roles']`
- Check if current user has one of the required roles
- If not → redirect to `/unauthorized`

Apply:
```typescript
{ path: 'admin', canActivate: [authGuard, roleGuard], data: { roles: ['admin'] } }
{ path: 'editor', canActivate: [authGuard, roleGuard], data: { roles: ['admin', 'editor'] } }
```

### 2c. Unsaved Changes Guard
Create `unsavedChangesGuard`:
- Check if component has unsaved changes
- Show browser confirm dialog
- Prevent navigation if user cancels
- Allow navigation if user confirms

Apply to edit forms.

### 2d. Auth Guard for Children
Apply `canActivateChild` to protect all admin sub-routes:
```typescript
{
  path: 'admin',
  canActivate: [authGuard],
  canActivateChild: [roleGuard],
  data: { roles: ['admin'] },
  children: [
    { path: '', component: AdminDashboard },
    { path: 'users', component: AdminUsers },
    { path: 'settings', component: AdminSettings }
  ]
}
```

---

## Problem 3: HTTP Interceptors (Medium)
**Concept**: Modifying requests/responses globally

### 3a. Auth Interceptor
Create interceptor that:
- Adds `Authorization: Bearer <token>` to all requests
- Skips public endpoints (`/auth/login`, `/auth/register`)
- On 401 response → call `authService.logout()`

### 3b. Error Interceptor
Create interceptor that shows notifications for errors:
- 400 → "Bad request: " + error details
- 401 → "Session expired. Please login again."
- 403 → "Access denied."
- 404 → "Resource not found."
- 500 → "Server error. Please try again later."
- Network error → "No internet connection."

### 3c. Loading Interceptor
Create interceptor + `LoadingService`:
- Track active request count
- Show loading bar when count > 0
- Hide when count === 0
- Handle concurrent requests (don't hide until ALL done)

Display a top loading bar in AppComponent:
```html
@if (loadingService.isLoading$ | async) {
  <div class="loading-bar"></div>
}
```

### 3d. Retry Interceptor
Create interceptor that:
- Retries failed requests up to 3 times
- Only retries for GET requests (not POST/PUT/DELETE)
- Exponential backoff: 1s, 2s, 4s
- Skips retry for 4xx errors (client errors)

---

## Problem 4: Advanced Auth Patterns (Medium-Hard)
**Concept**: Token refresh, role-based UI, session management

### 4a. Token Refresh Flow
Implement automatic token refresh:
1. Access token expires in 15 minutes
2. Refresh token stored securely
3. When 401 received:
   - Pause all requests
   - Call `/auth/refresh` with refresh token
   - Get new access token
   - Retry all paused requests with new token
   - If refresh fails → logout

### 4b. Role-Based Navigation
Build a navigation component that changes based on role:
```
Guest:     [Home] [Products] [Login] [Register]
User:      [Home] [Products] [My Orders] [Profile] [Logout]
Editor:    [Home] [Products] [My Orders] [Content Editor] [Profile] [Logout]
Admin:     [Home] [Products] [Admin Panel] [Profile] [Logout]
```

### 4c. Session Timeout
Implement:
- Track user activity (clicks, keystrokes, mouse movement)
- Show warning modal after 25 minutes of inactivity
- Auto-logout after 30 minutes of inactivity
- "Stay logged in" button in warning modal
- Reset timer on any user activity

### 4d. Remember Me / Persistent Login
- "Remember me" checkbox on login
- If checked → store token in localStorage (survives browser close)
- If not checked → store in sessionStorage (cleared on tab close)
- On app init → check for existing token → auto-login

---

## Problem 5: Complete Auth System (Hard)
**Concept**: Build a full authentication system for a web application

### Build a Secure Dashboard Application

**Components:**
- Login page with email/password
- Register page with form validation
- Forgot password page
- Dashboard (auth required)
- Admin panel (admin role required)
- User profile (auth required)
- Unauthorized page

**Services:**
```typescript
AuthService — login, register, logout, refreshToken, forgotPassword
TokenService — get/set/remove token, decode, isExpired
UserService — getProfile, updateProfile
```

**Guards:**
```typescript
authGuard — must be authenticated
noAuthGuard — must NOT be authenticated (login/register pages)
roleGuard — must have required role
unsavedChangesGuard — warn before leaving form
```

**Interceptors:**
```typescript
authInterceptor — attach token
refreshInterceptor — handle 401 with refresh
loadingInterceptor — global loading bar
errorInterceptor — global error notifications
```

### 5a. Registration Flow
```
Register Form → Validate → POST /auth/register → 
  Success: Auto-login + redirect to dashboard
  Failure: Show error (email taken, weak password)
```
Fields: name, email, password, confirm password
Custom validators: password match, strong password, async email check

### 5b. Login Flow
```
Login Form → POST /auth/login →
  Success: Save token + redirect (to returnUrl or dashboard)
  Failure: Show error
```
Support "Remember me" persistence option.

### 5c. Protected Dashboard
- Shows user's name and role
- Different content based on role
- Admin sees: user management, system stats
- User sees: personal stats, settings

### 5d. Profile Page
- Display user info from token
- Edit profile form (canDeactivate guard)
- Change password form

### 5e. Complete Route Configuration
```typescript
const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'login', component: LoginComponent, canActivate: [noAuthGuard] },
  { path: 'register', component: RegisterComponent, canActivate: [noAuthGuard] },
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] },
  { path: 'profile', component: ProfileComponent, canActivate: [authGuard], canDeactivate: [unsavedChangesGuard] },
  {
    path: 'admin',
    canActivate: [authGuard, roleGuard],
    data: { roles: ['admin'] },
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES)
  },
  { path: 'unauthorized', component: UnauthorizedComponent },
  { path: '**', component: NotFoundComponent }
];
```

**Expected Output:**
```
═══ Login Page ═══
Email: [admin@test.com    ]
Password: [**********       ]
☑ Remember me
[Login]

→ POST /api/auth/login (200 OK)
→ Token saved to localStorage
→ Redirect to /dashboard

═══ Dashboard (Admin) ═══
Welcome back, Debanjan! (Role: Admin)

[Admin Panel] [Products] [Users] [Profile] [Logout]

── System Stats ──
Users: 1,234 | Active Today: 89 | New This Week: 12

── Quick Actions ──
[Manage Users] [View Reports] [System Settings]

═══ Unauthorized Page ═══
🚫 Access Denied
You don't have permission to view this page.
Your role: "user" | Required: "admin"
[Go to Dashboard] [Contact Admin]
```

---

### Submission
- Implement AuthService with login/logout/token management
- Create and apply all guard types
- Build at least 3 interceptors
- Implement login/register components
- Test the complete auth flow (login → protected route → logout)
- Tell me "check" when you're ready for review!
