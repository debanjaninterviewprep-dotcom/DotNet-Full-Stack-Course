# Topic 6: Routing & Navigation — Practice Problems

## Problem 1: Basic Routing Setup (Easy)
**Concept**: Route config, router-outlet, routerLink

### 1a. Create Page Components
Generate these page components:
```bash
ng g c pages/home
ng g c pages/about
ng g c pages/contact
ng g c pages/not-found
```
Each should display its name and a short description.

### 1b. Configure Routes
Set up routes in `app.routes.ts`:
- `/` → HomeComponent
- `/about` → AboutComponent
- `/contact` → ContactComponent
- `/**` → NotFoundComponent

### 1c. Navigation Bar
Create a navbar with `routerLink` for each route:
- Highlight the active link using `routerLinkActive="active"`
- Style the active link (bold, underline, different color)
- Add `[routerLinkActiveOptions]="{ exact: true }"` for the home link

### 1d. Programmatic Navigation
Add a "Go Home" button on the 404 page using `Router.navigate()`.
Add "Back to previous page" functionality using `Location.back()`.

---

## Problem 2: Route Parameters (Easy-Medium)
**Concept**: Path params, query params, reading route data

### 2a. Product Routes
Create:
- `/products` → ProductListComponent (shows all products)
- `/products/:id` → ProductDetailComponent (shows one product)

ProductListComponent:
- Display a list of 5+ mock products with links to detail pages
- Each product links to `/products/:id`

ProductDetailComponent:
- Read the `id` from route params
- Display product details (use mock data or a service)
- "Back to Products" button

### 2b. Search with Query Params
Create `/search` route with query parameters:
- Search input binds to query param `q`
- Category dropdown binds to query param `category`
- Sort option binds to query param `sort`

URL should update as user types: `/search?q=angular&category=books&sort=price`

Navigate to search from navbar with pre-filled params:
```html
<a routerLink="/search" [queryParams]="{ q: 'angular', category: 'all' }">Search</a>
```

### 2c. Observable vs Snapshot
Create a "Next User / Previous User" navigation:
- `/users/:id` with Next/Previous buttons
- Demonstrate that **snapshot** doesn't update but **paramMap observable** does
- Log to console when param changes

### 2d. Static Route Data
Configure routes with static `data`:
```typescript
{ path: 'admin', component: AdminComponent, data: { title: 'Admin Panel', breadcrumb: 'Admin' } }
```
Create a breadcrumb component that reads `data` from the active route.

---

## Problem 3: Child Routes & Layouts (Medium)
**Concept**: Nested routes, router-outlet in parent, layout components

### 3a. User Management Section
Set up nested routes:
```
/users           → UserLayoutComponent > UserListComponent
/users/:id       → UserLayoutComponent > UserDetailComponent
/users/:id/edit  → UserLayoutComponent > UserEditComponent
/users/new       → UserLayoutComponent > UserCreateComponent
```

`UserLayoutComponent` has:
- A header "User Management"
- A sidebar with quick links
- A `<router-outlet>` for the child route

### 3b. Admin Dashboard with Sub-Pages
```
/admin            → AdminLayoutComponent > AdminDashboardComponent
/admin/users      → AdminLayoutComponent > AdminUsersComponent
/admin/products   → AdminLayoutComponent > AdminProductsComponent
/admin/settings   → AdminLayoutComponent > AdminSettingsComponent
```

`AdminLayoutComponent` has:
- Side navigation (Dashboard, Users, Products, Settings)
- Active link highlighting
- Content area with `<router-outlet>`

### 3c. Tab-Based Navigation
Create a product detail page with tabs implemented as child routes:
```
/products/:id            → redirectTo overview
/products/:id/overview   → ProductOverviewComponent
/products/:id/specs      → ProductSpecsComponent
/products/:id/reviews    → ProductReviewsComponent
```

Display tabs styled as navigation with the active tab highlighted.

### 3d. Nested Three Levels
```
/settings                       → SettingsLayoutComponent
/settings/profile               → ProfileSettings
/settings/profile/avatar        → AvatarSettings
/settings/profile/password      → PasswordSettings
/settings/notifications         → NotificationSettings
/settings/notifications/email   → EmailNotificationSettings
/settings/notifications/push    → PushNotificationSettings
```

---

## Problem 4: Lazy Loading & Guards (Medium-Hard)
**Concept**: loadComponent, loadChildren, canActivate, canDeactivate

### 4a. Lazy Load Features
Split your app into lazy-loaded features:
```typescript
// app.routes.ts
{ path: 'products', loadChildren: () => import('./products/product.routes').then(m => m.PRODUCT_ROUTES) },
{ path: 'admin', loadComponent: () => import('./admin/admin.component').then(m => m.AdminComponent) }
```

Verify lazy loading:
- Open browser DevTools → Network tab
- Navigate to `/products` → see separate chunk loaded
- Navigate to `/admin` → see another chunk

### 4b. Auth Guard
Create an `AuthService` with mock login/logout.
Create `authGuard` (functional guard):
- Check if user is logged in
- If not → redirect to `/login?returnUrl=/original-path`
- After login → redirect back to `returnUrl`

Apply to routes:
```typescript
{ path: 'dashboard', canActivate: [authGuard], component: DashboardComponent },
{ path: 'profile', canActivate: [authGuard], component: ProfileComponent }
```

### 4c. Unsaved Changes Guard
Create `unsavedChangesGuard` (canDeactivate):
```typescript
export interface HasUnsavedChanges {
  hasUnsavedChanges(): boolean;
}

export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> = (component) => {
  if (component.hasUnsavedChanges()) {
    return confirm('You have unsaved changes. Leave anyway?');
  }
  return true;
};
```

Apply to `UserEditComponent` that implements `HasUnsavedChanges`.

### 4d. Role-Based Guard
Create a guard that checks user roles:
```typescript
export const roleGuard: CanActivateFn = (route) => {
  const requiredRole = route.data['role'];
  // Check if current user has the required role
};

// Usage:
{ path: 'admin', canActivate: [authGuard, roleGuard], data: { role: 'admin' } }
```

---

## Problem 5: Complete Routing Architecture (Hard)
**Concept**: Full application routing with all features combined

### Build an E-Commerce Application Routing

**Route Structure:**
```
/                          → Home (public)
/products                  → Product List (public)
/products/:id              → Product Detail (public)
/cart                      → Shopping Cart (public)
/checkout                  → Checkout (auth required)

/auth/login                → Login
/auth/register             → Register

/account                   → Account Layout (auth required)
/account/profile           → Profile
/account/orders            → Order History
/account/orders/:id        → Order Detail
/account/settings          → Account Settings

/admin                     → Admin Layout (admin role required)
/admin/dashboard           → Admin Dashboard
/admin/products            → Product Management
/admin/products/new        → Add Product (unsaved changes guard)
/admin/products/:id/edit   → Edit Product (unsaved changes guard)
/admin/users               → User Management
/admin/orders              → Order Management

/**                        → 404 Not Found
```

**Features to Implement:**

### 5a. Route Configuration
- Set up all routes with proper hierarchy
- Lazy load admin and account sections
- Configure guards on protected routes

### 5b. Navigation Component
- Public navigation (Home, Products, Cart, Login/Account)
- Show different nav items based on auth state
- Show admin link if user is admin
- Cart badge showing item count
- Active link highlighting

### 5c. Breadcrumb Component
- Auto-generate breadcrumbs from route config
- Each route has `data: { breadcrumb: 'Label' }` 
- Breadcrumbs are clickable links

### 5d. Route Resolver for Product Detail
```typescript
export const productResolver: ResolveFn<Product> = (route) => {
  const productService = inject(ProductService);
  return productService.getById(Number(route.paramMap.get('id')));
};
```

### 5e. Loading Indicator
Subscribe to Router events to show/hide a loading bar during navigation:
- `NavigationStart` → show spinner
- `NavigationEnd` → hide spinner
- `NavigationError` → show error toast

**Expected Output:**
```
URL: /products/42
─────────────────────────────────
[🏠 Home] [📦 Products] [🛒 Cart (3)] [👤 Account ▼]

Breadcrumb: Home > Products > MacBook Pro

┌ MacBook Pro ─────────────────┐
│ $1,999.99                    │
│ ★★★★☆ (4.2) · 128 reviews  │
│                              │
│ [Overview] [Specs] [Reviews] │
│                              │
│ MacBook Pro features the...  │
│                              │
│ [Add to Cart] [Buy Now]      │
└──────────────────────────────┘

URL: /admin (redirected to /login?returnUrl=%2Fadmin)
─────────────────────────────────
⚠️ Please log in to access admin panel.
```

---

### Submission
- Configure all routes in your Angular project
- Implement lazy loading for at least 2 feature areas
- Create auth guard and unsaved changes guard
- Implement breadcrumbs using route data
- Verify navigation works with both routerLink and Router.navigate()
- Tell me "check" when you're ready for review!
