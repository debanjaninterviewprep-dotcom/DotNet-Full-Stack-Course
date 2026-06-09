# Topic 6: Routing & Navigation

## What is Routing?

Routing maps **URLs** to **components**. When the user navigates to `/users`, Angular shows `UserListComponent`. When they navigate to `/users/42`, it shows `UserDetailComponent` with that user's data.

```
URL                    →  Component
/                      →  HomeComponent
/about                 →  AboutComponent
/users                 →  UserListComponent
/users/42              →  UserDetailComponent (id=42)
/users/42/edit         →  UserEditComponent
/admin/dashboard       →  AdminDashboardComponent (lazy loaded)
```

---

## Setting Up Routing

### Route Configuration

```typescript
// app.routes.ts
import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { AboutComponent } from './pages/about/about.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },               // Default
  { path: 'about', component: AboutComponent },
  { path: 'users', component: UserListComponent },
  { path: 'users/:id', component: UserDetailComponent }, // Route param
  { path: '**', component: NotFoundComponent }           // Wildcard (404)
];
```

### Providing the Router

```typescript
// app.config.ts
import { provideRouter } from '@angular/router';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes)
  ]
};
```

### Router Outlet

```typescript
// app.component.ts
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, HeaderComponent, FooterComponent],
  template: `
    <app-header />
    <main>
      <router-outlet />   <!-- Routed component renders HERE -->
    </main>
    <app-footer />
  `
})
export class AppComponent {}
```

---

## Navigation

### Template-Based Navigation (routerLink)

```html
<!-- Import RouterLink, RouterLinkActive -->
<nav>
  <!-- Simple links -->
  <a routerLink="/">Home</a>
  <a routerLink="/about">About</a>
  <a routerLink="/users">Users</a>
  
  <!-- With parameters -->
  <a [routerLink]="['/users', user.id]">{{ user.name }}</a>
  <!-- Generates: /users/42 -->
  
  <!-- With query params -->
  <a routerLink="/users" [queryParams]="{ page: 1, sort: 'name' }">
    Users (Page 1)
  </a>
  <!-- Generates: /users?page=1&sort=name -->
  
  <!-- Active link styling -->
  <a routerLink="/users" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">
    Users
  </a>
</nav>
```

```typescript
@Component({
  imports: [RouterLink, RouterLinkActive]
})
```

### Programmatic Navigation (Router Service)

```typescript
import { Router } from '@angular/router';

@Component({ ... })
export class UserListComponent {
  private router = inject(Router);
  
  goToUser(id: number): void {
    this.router.navigate(['/users', id]);
    // Navigates to: /users/42
  }
  
  goToUsersWithQuery(): void {
    this.router.navigate(['/users'], {
      queryParams: { page: 2, sort: 'name' }
    });
    // Navigates to: /users?page=2&sort=name
  }
  
  goBack(): void {
    this.router.navigate(['..'], { relativeTo: this.route });
    // Navigate up one level
  }
  
  replaceUrl(): void {
    this.router.navigate(['/dashboard'], { replaceUrl: true });
    // Replaces current URL in history (no back button)
  }
}
```

---

## Route Parameters

### Path Parameters (`:id`)

```typescript
// Route config
{ path: 'users/:id', component: UserDetailComponent }
```

```typescript
// Reading params — UserDetailComponent
import { ActivatedRoute } from '@angular/router';

@Component({
  template: `
    <h2>User #{{ userId }}</h2>
    @if (user) {
      <p>{{ user.name }} — {{ user.email }}</p>
    }
  `
})
export class UserDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private userService = inject(UserService);
  userId!: number;
  user?: User;
  
  ngOnInit(): void {
    // Method 1: Snapshot (reads once — doesn't react to param changes)
    this.userId = Number(this.route.snapshot.paramMap.get('id'));
    this.user = this.userService.getById(this.userId);
    
    // Method 2: Observable (reacts to param changes — recommended)
    this.route.paramMap.subscribe(params => {
      this.userId = Number(params.get('id'));
      this.user = this.userService.getById(this.userId);
    });
  }
}
```

**When to use each:**
- **Snapshot**: Component is destroyed when navigating away (different path)
- **Observable**: Component is reused when param changes (same path, different id)

### Query Parameters

```typescript
// URL: /users?page=2&sort=name&filter=active

@Component({ ... })
export class UserListComponent implements OnInit {
  private route = inject(ActivatedRoute);
  
  ngOnInit(): void {
    // Snapshot
    const page = this.route.snapshot.queryParamMap.get('page');
    const sort = this.route.snapshot.queryParamMap.get('sort');
    
    // Observable
    this.route.queryParamMap.subscribe(params => {
      const page = Number(params.get('page') ?? 1);
      const sort = params.get('sort') ?? 'name';
      const filter = params.get('filter');
      this.loadUsers(page, sort, filter);
    });
  }
}
```

### Optional Route Data

```typescript
// Static data in route config
{
  path: 'admin',
  component: AdminComponent,
  data: { title: 'Admin Panel', role: 'admin' }
}

// Reading static data
export class AdminComponent implements OnInit {
  private route = inject(ActivatedRoute);
  
  ngOnInit(): void {
    const title = this.route.snapshot.data['title'];
    const role = this.route.snapshot.data['role'];
  }
}
```

---

## Child Routes (Nested Routing)

```typescript
// Routes with children
export const routes: Routes = [
  {
    path: 'users',
    component: UserLayoutComponent,    // Parent layout
    children: [
      { path: '', component: UserListComponent },        // /users
      { path: ':id', component: UserDetailComponent },    // /users/42
      { path: ':id/edit', component: UserEditComponent }  // /users/42/edit
    ]
  }
];
```

```typescript
// user-layout.component.ts — Parent with its own <router-outlet>
@Component({
  standalone: true,
  imports: [RouterOutlet],
  template: `
    <div class="user-layout">
      <h1>User Management</h1>
      <router-outlet />   <!-- Child routes render here -->
    </div>
  `
})
export class UserLayoutComponent {}
```

```
URL Structure:
/users           → UserLayoutComponent > UserListComponent
/users/42        → UserLayoutComponent > UserDetailComponent
/users/42/edit   → UserLayoutComponent > UserEditComponent
```

---

## Lazy Loading

Load feature modules **on demand** instead of upfront. Critical for large apps.

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', component: HomeComponent },
  
  // Lazy loaded — separate bundle, loaded only when user navigates here
  {
    path: 'admin',
    loadComponent: () => import('./admin/admin.component')
      .then(m => m.AdminComponent)
  },
  
  // Lazy loaded with child routes
  {
    path: 'products',
    loadChildren: () => import('./products/product.routes')
      .then(m => m.PRODUCT_ROUTES)
  }
];
```

```typescript
// products/product.routes.ts
import { Routes } from '@angular/router';

export const PRODUCT_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => import('./product-list/product-list.component')
      .then(m => m.ProductListComponent)
  },
  {
    path: ':id',
    loadComponent: () => import('./product-detail/product-detail.component')
      .then(m => m.ProductDetailComponent)
  }
];
```

```
Without lazy loading:
  main.js — 2MB (everything loaded upfront)

With lazy loading:
  main.js — 500KB (core only)
  admin.js — 200KB (loaded when user visits /admin)
  products.js — 300KB (loaded when user visits /products)
```

---

## Route Guards

Control access to routes.

```typescript
// auth.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isLoggedIn()) {
    return true;                              // Allow navigation
  }
  
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url }     // Redirect to login
  });
};

// Admin guard
export const adminGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const user = authService.getCurrentUser();
  return user?.role === 'admin';
};
```

```typescript
// Applying guards
export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [authGuard]                   // Must be logged in
  },
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [authGuard, adminGuard]       // Must be admin
  }
];
```

### Guard Types

| Guard | When | Purpose |
|---|---|---|
| `canActivate` | Before entering route | Check authentication |
| `canActivateChild` | Before entering child | Protect all children |
| `canDeactivate` | Before leaving route | Unsaved changes warning |
| `canMatch` | Before matching route | Conditional route matching |
| `resolve` | Before rendering | Pre-fetch data |

---

## Route Resolvers

Pre-fetch data **before** the component loads.

```typescript
// user.resolver.ts
import { ResolveFn } from '@angular/router';

export const userResolver: ResolveFn<User> = (route, state) => {
  const userService = inject(UserService);
  const id = Number(route.paramMap.get('id'));
  return userService.getById(id);  // Can return Observable, Promise, or value
};
```

```typescript
// Route config
{
  path: 'users/:id',
  component: UserDetailComponent,
  resolve: { user: userResolver }    // 'user' is the key
}
```

```typescript
// Component — data is already available!
export class UserDetailComponent {
  private route = inject(ActivatedRoute);
  user: User = this.route.snapshot.data['user'];
}
```

---

## Route Transitions & Events

```typescript
// Listen to router events
@Component({ ... })
export class AppComponent {
  private router = inject(Router);
  
  constructor() {
    this.router.events.subscribe(event => {
      if (event instanceof NavigationStart) {
        console.log('Navigation started:', event.url);
        // Show loading spinner
      }
      if (event instanceof NavigationEnd) {
        console.log('Navigation ended:', event.url);
        // Hide loading spinner
      }
      if (event instanceof NavigationError) {
        console.error('Navigation error:', event.error);
      }
    });
  }
}
```

---

## Named Router Outlets (Advanced)

Multiple router outlets on the same page.

```typescript
// Routes
{ path: 'chat', component: ChatComponent, outlet: 'sidebar' }
```

```html
<!-- Template -->
<router-outlet />                      <!-- Primary outlet -->
<router-outlet name="sidebar" />       <!-- Named outlet -->

<!-- Navigate to named outlet -->
<a [routerLink]="[{ outlets: { sidebar: ['chat'] } }]">Open Chat</a>
<!-- URL: /users(sidebar:chat) -->
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Routes | Map URLs to components in `app.routes.ts` |
| `<router-outlet>` | Where routed components render |
| `routerLink` | Template navigation directive |
| `Router.navigate()` | Programmatic navigation |
| Route params | `:id` → `paramMap.get('id')` |
| Query params | `?key=val` → `queryParamMap.get('key')` |
| Child routes | Nested routes with parent layout |
| Lazy loading | `loadComponent()` / `loadChildren()` |
| Guards | `canActivate`, `canDeactivate`, `resolve` |
| Resolvers | Pre-fetch data before component loads |
| `**` wildcard | Catch-all 404 route (must be LAST) |

---

*Next Topic: Reactive Forms & Template Forms →*
