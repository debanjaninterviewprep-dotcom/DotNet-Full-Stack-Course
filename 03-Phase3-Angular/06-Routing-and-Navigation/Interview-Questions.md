# Topic 06: Routing and Navigation — Interview Questions

---

## Q1. What is the Angular Router and how is it configured?
**Answer:**
The Angular Router enables client-side navigation between views without full page reloads:

```typescript
// app.routes.ts
export const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'users', component: UserListComponent },
  { path: 'users/:id', component: UserDetailComponent },
  { path: '**', component: NotFoundComponent } // wildcard — must be last
];

// Provide router (standalone app)
bootstrapApplication(AppComponent, {
  providers: [provideRouter(routes)]
});

// Or with NgModule
@NgModule({
  imports: [RouterModule.forRoot(routes)]
})
export class AppModule {}
```

---

## Q2. What is `router-outlet` and how does routing work in the template?
**Answer:**
`<router-outlet>` is a placeholder directive where the router renders the matched component:

```html
<!-- app.component.html -->
<nav>
  <a routerLink="/home" routerLinkActive="active">Home</a>
  <a routerLink="/users" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">Users</a>
</nav>

<router-outlet></router-outlet> <!-- matched component renders here -->

<!-- Named outlets for secondary routes -->
<router-outlet name="sidebar"></router-outlet>
```

When the user navigates to `/users`, Angular renders `UserListComponent` inside the `<router-outlet>`.

---

## Q3. What is the difference between route parameters and query parameters?
**Answer:**
| | Route Parameters | Query Parameters |
|---|---|---|
| **Syntax** | `/users/:id` | `/users?sort=name&page=2` |
| **Required?** | Yes — part of the URL path | No — optional |
| **Purpose** | Identify a specific resource | Filter/sort/pagination options |
| **Access** | `route.params` or `route.paramMap` | `route.queryParams` or `route.queryParamMap` |

```typescript
// Route parameter: /users/42
this.route.paramMap.subscribe(params => {
  const id = params.get('id'); // '42'
  this.route.snapshot.paramMap.get('id'); // synchronous
});

// Query parameters: /users?sort=name&page=2
this.route.queryParamMap.subscribe(params => {
  const sort = params.get('sort'); // 'name'
  const page = params.get('page'); // '2'
});

// Navigate with parameters
this.router.navigate(['/users', 42]);                          // route param
this.router.navigate(['/users'], { queryParams: { sort: 'name' } }); // query param
this.router.navigate(['/users'], { queryParamsHandling: 'merge' });   // keep existing
```

---

## Q4. What are child routes and how are they configured?
**Answer:**
Child routes render nested components inside a parent component's `<router-outlet>`:

```typescript
const routes: Routes = [
  {
    path: 'users',
    component: UsersComponent,
    children: [
      { path: '', component: UserListComponent },      // /users
      { path: ':id', component: UserDetailComponent }, // /users/42
      { path: ':id/edit', component: UserEditComponent } // /users/42/edit
    ]
  }
];

// UsersComponent template must have its own router-outlet:
// <div class="users-layout">
//   <app-sidebar />
//   <router-outlet></router-outlet>  ← child renders here
// </div>
```

---

## Q5. How does lazy loading work in Angular routing?
**Answer:**
```typescript
const routes: Routes = [
  // Eager loaded — bundled in main chunk
  { path: 'home', component: HomeComponent },

  // Lazy loaded module — separate chunk downloaded on demand
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
  },

  // Lazy loaded standalone component (Angular 17+)
  {
    path: 'dashboard',
    loadComponent: () => import('./dashboard/dashboard.component')
      .then(c => c.DashboardComponent)
  },

  // Lazy loaded routes (without module/component wrapper)
  {
    path: 'reports',
    loadChildren: () => import('./reports/reports.routes').then(r => r.REPORTS_ROUTES)
  }
];
```

Each lazy route generates a separate JS chunk. The chunk is downloaded only when the user first navigates to that route.

---

## Q6. What is a route resolver and when should you use it?
**Answer:**
A resolver pre-fetches data **before** the route is activated — the component receives the data ready-to-use:

```typescript
// Resolver function (Angular 14+ functional style)
export const userResolver: ResolveFn<User> = (route, state) => {
  const userService = inject(UserService);
  return userService.getById(+route.paramMap.get('id')!);
};

// Route configuration
const routes: Routes = [
  { path: 'users/:id', component: UserDetailComponent, resolve: { user: userResolver } }
];

// Component receives resolved data
@Component({})
export class UserDetailComponent implements OnInit {
  user!: User;
  constructor(private route: ActivatedRoute) {}
  ngOnInit() {
    this.user = this.route.snapshot.data['user'];
    // or: this.route.data.subscribe(data => this.user = data['user']);
  }
}
```

**Use when:** you want to prevent blank flashes or show the component only after data is loaded.
**Avoid when:** you want to show a loading skeleton — the router waits for the resolver before rendering.

---

## Q7. What are preloading strategies?
**Answer:**
Preloading downloads lazy-loaded chunks in the background after the app loads — reducing perceived navigation delay:

```typescript
// NoPreloading (default) — chunks downloaded on demand
// PreloadAllModules — all lazy chunks downloaded immediately after app starts
import { PreloadAllModules } from '@angular/router';

provideRouter(routes, withPreloading(PreloadAllModules));

// Custom preloading strategy — selective
@Injectable({ providedIn: 'root' })
export class SelectivePreloading implements PreloadingStrategy {
  preload(route: Route, fn: () => Observable<any>): Observable<any> {
    return route.data?.['preload'] ? fn() : of(null);
  }
}

// Routes: { path: 'admin', loadChildren: ..., data: { preload: true } }
// Routes: { path: 'reports', loadChildren: ... } // not preloaded
```

---

## Q8. How do you navigate programmatically?
**Answer:**
```typescript
@Component({})
export class LoginComponent {
  constructor(private router: Router, private route: ActivatedRoute) {}

  // Absolute navigation
  goHome()  { this.router.navigate(['/home']); }
  goUser(id: number) { this.router.navigate(['/users', id]); }

  // Relative navigation
  goNext() { this.router.navigate(['../next'], { relativeTo: this.route }); }

  // With extras
  save() {
    this.router.navigate(['/users'], {
      queryParams: { sort: 'name' },
      queryParamsHandling: 'merge',    // keep existing query params
      fragment: 'top',                  // add #top
      replaceUrl: true,                 // don't add to history
      state: { fromLogin: true }        // navigation state (not visible in URL)
    });
  }

  // Navigate by URL string
  this.router.navigateByUrl('/users/42?tab=profile#contact');
}
```

---

## Q9. What is `ActivatedRoute` and what data can you get from it?
**Answer:**
`ActivatedRoute` provides information about the currently active route:

```typescript
@Component({})
export class UserComponent implements OnInit {
  constructor(private route: ActivatedRoute) {}

  ngOnInit() {
    // Snapshot (static — values at time of navigation, doesn't update)
    const id      = this.route.snapshot.paramMap.get('id');
    const sort    = this.route.snapshot.queryParamMap.get('sort');
    const user    = this.route.snapshot.data['user'];  // resolver data

    // Observable (reactive — updates on navigation within same component)
    this.route.paramMap.subscribe(p => this.userId = +p.get('id')!);
    this.route.queryParamMap.subscribe(q => this.sort = q.get('sort'));
    this.route.data.subscribe(d => this.user = d['user']);

    // URL and path info
    this.route.url.subscribe(segments => console.log(segments));
    this.route.parent?.paramMap.subscribe(...); // parent route params
  }
}
```

---

## Q10. What is the difference between `RouterLink` and `Router.navigate()`?
**Answer:**
| | `routerLink` | `Router.navigate()` |
|---|---|---|
| **Usage** | Declarative (template) | Programmatic (component class) |
| **When to use** | Links in templates | After form submit, logic-based navigation |
| **Relative** | `[routerLink]="['../sibling']"` | `relativeTo: this.route` |

```html
<!-- routerLink — template declaration -->
<a routerLink="/users">Users</a>
<a [routerLink]="['/users', userId]">User {{ userId }}</a>
<a [routerLink]="['/users']" [queryParams]="{ sort: 'name' }">Sorted</a>
```

```typescript
// Router.navigate() — programmatic
this.router.navigate(['/users', this.userId], { queryParams: { sort: 'name' } });
```

---

## Q11. What is `RouterModule.forRoot()` vs `RouterModule.forChild()`?
**Answer:**
- **`forRoot()`** — registers the Router service and the global router directives. Call **once** in `AppModule`.
- **`forChild()`** — registers additional routes for a feature module. Does NOT re-register the Router service.

```typescript
// AppModule — root
@NgModule({ imports: [RouterModule.forRoot(appRoutes)] })
export class AppModule {}

// Feature module
@NgModule({ imports: [RouterModule.forChild(featureRoutes)] })
export class AdminModule {}
```

Calling `forRoot()` in a lazy-loaded module creates a **second Router instance** (a classic bug). Always use `forChild()` in feature modules.

---

## Q12. How do you pass data to a route without using a service?
**Answer:**
Three ways: route data, navigation state, and router params:

```typescript
// 1. Static data in route config — read-only, always available
{ path: 'about', component: AboutComponent, data: { title: 'About Us', role: 'admin' } }
// Access: this.route.snapshot.data['title']

// 2. Navigation state — temporary, not in URL, lost on refresh
this.router.navigate(['/result'], { state: { score: 95, name: 'Debanjan' } });
// Access: history.state.score  OR  this.router.getCurrentNavigation()?.extras.state

// 3. Query params — in URL, survives refresh
this.router.navigate(['/users'], { queryParams: { filter: 'active' } });
```

---

## Q13. What are named router outlets?
**Answer:**
Named outlets enable displaying multiple routes simultaneously — useful for sidebars, dialogs, and auxiliary views:

```typescript
const routes: Routes = [
  { path: 'main', component: MainComponent, outlet: 'primary' },
  { path: 'chat', component: ChatComponent, outlet: 'sidebar' }
];

// Navigate to named outlet
this.router.navigate([{ outlets: { primary: 'main', sidebar: 'chat' } }]);
// URL: /main(sidebar:chat)
```

```html
<router-outlet></router-outlet>              <!-- primary -->
<router-outlet name="sidebar"></router-outlet> <!-- named -->
```

---

## Q14. What is the `CanDeactivate` guard and how is it used?
**Answer:**
`CanDeactivate` prevents navigation away from a component with unsaved changes:

```typescript
export const unsavedChangesGuard: CanDeactivateFn<EditFormComponent> =
  (component) => {
    if (component.hasUnsavedChanges()) {
      return confirm('You have unsaved changes. Leave anyway?');
    }
    return true;
  };

// Route config
{ path: 'users/:id/edit', component: EditFormComponent, canDeactivate: [unsavedChangesGuard] }
```

---

## Q15. What is scroll behaviour in Angular routing?
**Answer:**
By default, Angular doesn't scroll to the top on navigation. Configure scroll behaviour with `withInMemoryScrolling`:

```typescript
provideRouter(routes,
  withInMemoryScrolling({
    scrollPositionRestoration: 'enabled', // restore scroll on back/forward
    anchorScrolling: 'enabled'           // scroll to #fragment
  })
);

// Programmatic scroll
this.router.navigate(['/page'], { fragment: 'section-2' }); // scrolls to #section-2

// ViewportScroller
this.viewportScroller.scrollToPosition([0, 0]); // scroll to top
this.viewportScroller.scrollToAnchor('hero');   // scroll to element with id="hero"
```
