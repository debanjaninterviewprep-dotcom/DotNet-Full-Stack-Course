# Topic 06: Frontend Bootstrap & Architecture — Interview Questions

---

## Q1. What is the frontend architecture for a full-stack .NET + Angular/React app?
**Answer:**
```
Full-stack architecture:
┌──────────────────────────────────────────────────────────┐
│  Frontend (Angular/React)                                │
│  ├── Pages/Routes (feature-based)                        │
│  ├── Components (dumb/smart)                             │
│  ├── Services/API clients (generated from OpenAPI)       │
│  ├── State Management (NgRx/Redux/Zustand/Signals)        │
│  └── Auth (JWT handling, guards, interceptors)           │
└──────────────────────────────────────────────────────────┘
         ↕ HTTPS + JSON (REST/GraphQL)
┌──────────────────────────────────────────────────────────┐
│  Backend (.NET Core API)                                  │
│  ├── Presentation (Controllers/Minimal APIs)              │
│  ├── Application (Services, CQRS Handlers)               │
│  ├── Domain (Entities, Value Objects)                    │
│  └── Infrastructure (EF Core, External Services)         │
└──────────────────────────────────────────────────────────┘
         ↕
┌──────────────────────────────────────────────────────────┐
│  Data Layer (SQL Server + Redis + Blob Storage)           │
└──────────────────────────────────────────────────────────┘
```

---

## Q2. What is a typed API client and how do you generate one?
**Answer:**
Instead of writing HTTP calls manually, generate a typed client from the OpenAPI spec:

```bash
# Install NSwag CLI
dotnet tool install -g NSwag.ConsoleX

# Generate TypeScript client for Angular
nswag openapi2tsclient /input:http://localhost:5000/swagger/v1/swagger.json /output:src/app/api/api.ts

# For React (Orval)
npx orval --input http://localhost:5000/swagger/v1/swagger.json --output src/api
```

```typescript
// Generated typed client (Angular)
@Injectable({ providedIn: 'root' })
export class UsersClient {
  constructor(private http: HttpClient) {}

  getUsers(page: number, pageSize: number): Observable<PagedResult<UserDto>> {
    return this.http.get<PagedResult<UserDto>>(`/api/users?page=${page}&pageSize=${pageSize}`);
  }

  createUser(dto: CreateUserDto): Observable<UserDto> {
    return this.http.post<UserDto>('/api/users', dto);
  }
}

// Type-safe usage in component
this.usersClient.getUsers(1, 20).subscribe(result => this.users = result.data);
```

---

## Q3. What is Angular's module federation / micro-frontends?
**Answer:**
Module Federation (Webpack 5) allows multiple independently deployed frontend apps to be composed at runtime:

```
Shell App (main container)
├── loads Team A's app (users module) at runtime
├── loads Team B's app (orders module) at runtime
└── loads Team C's app (reports module) at runtime

Each app:
- Has its own CI/CD pipeline
- Deploys independently
- Has its own Angular version (within compatibility)
```

```javascript
// webpack.config.js (shell)
new ModuleFederationPlugin({
  remotes: {
    usersApp:   "usersApp@http://cdn.example.com/users/remoteEntry.js",
    ordersApp:  "ordersApp@http://cdn.example.com/orders/remoteEntry.js",
  }
});

// shell routing
{ path: 'users',  loadChildren: () => loadRemoteModule({ remoteName: 'usersApp', exposedModule: './Module' }) }
```

---

## Q4. What is a design system and why does it matter for full-stack apps?
**Answer:**
A design system is a collection of reusable components, patterns, and guidelines ensuring visual and behavioral consistency:

```typescript
// Component library (Angular)
@Component({ selector: 'app-button', ... })
export class ButtonComponent {
  @Input() variant: 'primary' | 'secondary' | 'danger' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() loading = false;
  @Input() disabled = false;
}

// Usage
<app-button variant="primary" (click)="save()">Save</app-button>
<app-button variant="danger" [loading]="deleting" (click)="delete()">Delete</app-button>
```

**Popular design systems:**
- Angular Material (Angular)
- PrimeNG / DevExtreme (Angular)
- shadcn/ui (React + Tailwind)
- Ant Design (React)
- MUI / Chakra UI (React)

---

## Q5. What is lazy loading in Angular and how does it reduce initial load time?
**Answer:**
```typescript
// Eager loading — all code in main bundle (slow initial load)
import { AdminModule } from './admin/admin.module';
@NgModule({ imports: [AdminModule] })

// Lazy loading — AdminModule loaded only when user visits /admin
const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent },     // eager
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
  },
  {
    path: 'reports',
    loadComponent: () => import('./reports/reports.component').then(c => c.ReportsComponent)
  }
];

// Result:
// main.js: ~200KB (dashboard only)
// admin-module.js: ~150KB (loaded on first /admin visit)
// reports-component.js: ~50KB (loaded on first /reports visit)
```

---

## Q6. What are environment configurations in Angular?
**Answer:**
```typescript
// src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:5000/api',
  signalrUrl: 'http://localhost:5000/hubs',
  logLevel: 'debug'
};

// src/environments/environment.production.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.myapp.com/api',
  signalrUrl: 'https://api.myapp.com/hubs',
  logLevel: 'error'
};

// angular.json file replacement
"configurations": {
  "production": {
    "fileReplacements": [{
      "replace": "src/environments/environment.ts",
      "with": "src/environments/environment.production.ts"
    }]
  }
}
```

---

## Q7. What is the Angular HttpClient interceptor pattern for API integration?
**Answer:**
```typescript
// Auth interceptor — adds JWT to every outgoing request
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  if (token) {
    req = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }
  return next(req);
};

// Error interceptor — handle 401/403/500 globally
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const notify = inject(NotificationService);

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) router.navigate(['/login']);
      if (err.status === 403) router.navigate(['/unauthorized']);
      if (err.status >= 500) notify.showError('Server error. Please try again.');
      return throwError(() => err);
    })
  );
};

// Loading interceptor
export const loadingInterceptor: HttpInterceptorFn = (req, next) => {
  const loading = inject(LoadingService);
  loading.show();
  return next(req).pipe(finalize(() => loading.hide()));
};

// Register
provideHttpClient(withInterceptors([authInterceptor, errorInterceptor, loadingInterceptor]))
```

---

## Q8. What is Storybook and how does it help with frontend development?
**Answer:**
Storybook is a tool for developing and documenting UI components in isolation:

```typescript
// Button.stories.ts
import type { Meta, StoryObj } from '@storybook/angular';
import { ButtonComponent } from './button.component';

const meta: Meta<ButtonComponent> = {
  title: 'UI/Button',
  component: ButtonComponent,
  parameters: { layout: 'centered' }
};
export default meta;

type Story = StoryObj<ButtonComponent>;

export const Primary: Story = {
  args: { variant: 'primary', label: 'Click me' }
};

export const Loading: Story = {
  args: { variant: 'primary', label: 'Save', loading: true }
};

export const Disabled: Story = {
  args: { variant: 'primary', label: 'Disabled', disabled: true }
};
```

**Benefits:**
- Develop components without a running API.
- Document all component variants.
- Visual regression testing.
- Share component library with design team.

---

## Q9. What is PWA (Progressive Web App) and when should you build one?
**Answer:**
A PWA adds native app-like features to a web app:

```json
// manifest.webmanifest
{
  "name": "TaskFlow",
  "short_name": "TaskFlow",
  "display": "standalone",
  "theme_color": "#007bff",
  "icons": [{ "src": "icons/icon-192.png", "sizes": "192x192" }]
}
```

```typescript
// Angular: ng add @angular/pwa
// Adds: Service Worker, Web Manifest, offline support

// Service Worker caching strategies
// Cache-first: static assets (JS, CSS, images)
// Network-first: API calls (fresh data preferred)
// Stale-while-revalidate: show cached, update in background
```

**Features:**
- **Offline support** — works without internet (Service Worker caches).
- **Installable** — "Add to Home Screen" on mobile/desktop.
- **Push notifications** — send alerts even when app is closed.
- **Background sync** — queue actions offline, sync when online.

**Use when:** Your users are on mobile/poor connectivity, offline functionality is needed, app-store installation overhead is a barrier.

---

## Q10. What is the BFF (Backend for Frontend) pattern?
**Answer:**
BFF is a separate backend API tailored for a specific frontend's needs:

```
Without BFF:
React App → Generic API (designed for all consumers)
  → Many round-trips to get data needed for one screen
  → Over-fetching (more data than React needs)
  → Or under-fetching (React needs more than API returns)

With BFF:
React App → React BFF (tailored for React's needs)
  → Single request returns exactly what React needs for a screen
  → BFF calls multiple backend services internally
  → BFF handles auth, aggregation, response shaping

Architecture:
Mobile App → Mobile BFF → Microservices
React App  → Web BFF    → Microservices
Admin App  → Admin BFF  → Microservices
```

---

## Q11. What is the architecture for handling global errors in a frontend?
**Answer:**
```typescript
// Angular: Global error handler
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  constructor(private notify: NotificationService, private logger: LoggerService) {}

  handleError(error: unknown): void {
    const err = error as Error;

    // Don't show "network error" for cancelled requests
    if (err.message?.includes('Http failure response')) return;

    this.logger.logError(err);
    this.notify.showError('An unexpected error occurred. Please try again.');
    console.error(err); // keep in browser console for debugging
  }
}

providers: [{ provide: ErrorHandler, useClass: GlobalErrorHandler }]

// React: Error Boundary
class GlobalErrorBoundary extends React.Component {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    logErrorToService(error, info);
  }
  render() {
    return this.state.hasError ? <ErrorFallback /> : this.props.children;
  }
}
```

---

## Q12. What is the Angular standalone component architecture?
**Answer:**
Angular 17+ standalone components replace NgModule boilerplate:

```typescript
// Standalone component — declares its own imports
@Component({
  standalone: true,
  selector: 'app-user-card',
  imports: [CommonModule, RouterModule, UserAvatarComponent, DatePipe],
  template: `
    <div class="card">
      <app-user-avatar [src]="user.avatar" />
      <h3>{{ user.name }}</h3>
      <p>{{ user.createdAt | date }}</p>
      <a [routerLink]="['/users', user.id]">View Profile</a>
    </div>
  `
})
export class UserCardComponent {
  @Input({ required: true }) user!: UserDto;
}

// Standalone app bootstrap (no AppModule needed)
bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withPreloading(PreloadAllModules)),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimations(),
    provideStore(reducers),
    provideEffects([UserEffects])
  ]
});
```

---

## Q13. What is tree-shaking in Angular/React and how does it reduce bundle size?
**Answer:**
Tree-shaking removes unused exports from the final bundle:

```typescript
// Bad — imports entire library (no tree-shaking)
import * as _ from 'lodash';     // entire lodash included
import * as rxjs from 'rxjs';    // entire RxJS included

// Good — named imports (tree-shakable)
import { debounceTime, switchMap } from 'rxjs/operators'; // only these included
import { groupBy } from 'lodash-es';  // only groupBy included (lodash-es is ES modules)

// Angular: standalone components are more tree-shakable than NgModule
// Because unused components in NgModule.declarations are still included in the bundle

// Check bundle size
ng build --stats-json
npx webpack-bundle-analyzer dist/my-app/stats.json
```

---

## Q14. What is the difference between Client-Side Rendering (CSR) and Server-Side Rendering (SSR)?
**Answer:**
| | CSR (SPA) | SSR (Next.js/Angular Universal) |
|---|---|---|
| **Initial render** | Blank page, JS downloads | HTML from server (instant) |
| **SEO** | Poor (content in JS) | ✓ Excellent (HTML crawlable) |
| **First Paint** | Slow | Fast |
| **Time to Interactive** | Faster after initial load | May be slower (hydration) |
| **Server load** | Low | Higher |
| **Complexity** | Simple | Higher |

```typescript
// Angular Universal (SSR)
ng add @angular/ssr

// Careful with browser-only APIs in SSR
if (isPlatformBrowser(this.platformId)) {
    localStorage.setItem('key', value); // only in browser
}

// Next.js SSR
export async function getServerSideProps({ params }) {
    const user = await fetchUser(params.id); // runs on server
    return { props: { user } };
}
```

---

## Q15. What is Content Delivery Network (CDN) for frontend assets?
**Answer:**
A CDN distributes static assets (JS, CSS, images) to edge servers worldwide for faster delivery:

```
Without CDN:
User in Tokyo → Angular app files on server in US East → ~200ms latency

With CDN:
User in Tokyo → Files on CDN edge in Tokyo → ~10ms latency

Frontend deploy to CDN:
ng build --configuration production
# Upload dist/ to Azure CDN / AWS CloudFront / Cloudflare

// index.html served from API server (for auth/routing)
// All JS/CSS/images served from CDN

// Set cache headers for versioned assets
Cache-Control: public, max-age=31536000, immutable  // 1 year for main.abc123.js
Cache-Control: no-cache                             // for index.html (always fresh)
```
