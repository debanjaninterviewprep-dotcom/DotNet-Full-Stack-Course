# Topic 02: Angular Setup & Architecture — Interview Questions

---

## Q1. What is Angular and what are its core features?
**Answer:**
Angular is a **platform and framework** for building single-page client applications using HTML and TypeScript, developed and maintained by Google.

Core features:
- **Component-based architecture** — UI split into reusable, encapsulated components.
- **Two-way data binding** — automatic sync between model and view.
- **Dependency Injection** — built-in DI container for service management.
- **RxJS integration** — reactive programming with Observables throughout.
- **TypeScript-first** — type safety by design.
- **Angular CLI** — scaffolding, build, test, and deployment tooling.
- **Directives & Pipes** — extend HTML and transform display values.
- **Router** — client-side SPA routing.

---

## Q2. What is NgModule and what does it contain?
**Answer:**
`NgModule` is a class decorated with `@NgModule` that groups related components, directives, pipes, and services:

```typescript
@NgModule({
  declarations: [AppComponent, UserComponent, UserPipe], // components, directives, pipes
  imports:      [BrowserModule, HttpClientModule, RouterModule], // other modules
  providers:    [UserService],   // services (root-level preferred with providedIn)
  exports:      [UserComponent], // make available to other modules
  bootstrap:    [AppComponent]   // root component (AppModule only)
})
export class AppModule {}
```

**Key rules:**
- A component/directive/pipe can be declared in only ONE module.
- To use a component from another module, that module must `export` it and this module must `import` it.
- In Angular 17+, **standalone components** reduce reliance on NgModule.

---

## Q3. What are standalone components and how do they change Angular architecture?
**Answer:**
Standalone components (stable in Angular 17) eliminate the need for NgModule — they declare their own dependencies directly:

```typescript
@Component({
  standalone: true,
  selector: 'app-user',
  template: `<p>{{ user.name }}</p>`,
  imports: [CommonModule, RouterModule] // imported directly, no NgModule
})
export class UserComponent {}

// Bootstrap standalone app
bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes),
    provideHttpClient(),
    provideAnimations()
  ]
});
```

Benefits: simpler mental model, better tree-shaking, easier lazy loading, reduced boilerplate.

---

## Q4. What are the most important Angular CLI commands?
**Answer:**
```bash
ng new my-app                         # create new workspace
ng generate component user            # g c — create component
ng generate service user              # g s — create service
ng generate module feature --routing  # g m — with routing module
ng generate guard auth                # g guard
ng generate pipe format               # g pipe
ng generate directive highlight       # g d

ng serve                              # start dev server (localhost:4200)
ng serve --open                       # open browser automatically
ng build                              # production build (dist/)
ng build --configuration=production   # explicit prod config
ng test                               # run unit tests (Karma)
ng e2e                                # end-to-end tests (Playwright/Cypress)
ng lint                               # lint code
ng update                             # update Angular + dependencies
```

---

## Q5. What is Angular's change detection mechanism?
**Answer:**
Angular detects changes and updates the DOM using a **change detection tree**. By default, it checks every component on every event (Default strategy). 

**Default strategy:** Checks the entire component tree on every browser event, timer, or async operation.

**OnPush strategy:** Only checks a component when:
- An `@Input()` reference changes.
- An event originates from the component or its children.
- An Observable triggers via `async` pipe.
- `markForCheck()` is called manually.

```typescript
@Component({
  selector: 'app-user',
  changeDetection: ChangeDetectionStrategy.OnPush, // more performant
  template: `{{ user.name }}`
})
export class UserComponent {
  @Input() user!: User;
}
```

**Zone.js** monkey-patches browser APIs (setTimeout, DOM events, HTTP) to notify Angular when to run change detection. Angular 17+ introduced **zoneless change detection** as an experimental feature.

---

## Q6. What is the Angular component lifecycle?
**Answer:**
Lifecycle hooks (in order):

| Hook | Called when |
|---|---|
| `ngOnChanges` | Input property changes (before ngOnInit, and on each change) |
| `ngOnInit` | After first ngOnChanges — component initialized |
| `ngDoCheck` | Every change detection cycle |
| `ngAfterContentInit` | After content projection (`ng-content`) is initialized |
| `ngAfterContentChecked` | After every check of projected content |
| `ngAfterViewInit` | After component's view and child views initialized |
| `ngAfterViewChecked` | After every check of the view |
| `ngOnDestroy` | Just before Angular destroys the component |

**Most commonly used:** `ngOnInit` (init logic, API calls), `ngOnDestroy` (cleanup subscriptions).

---

## Q7. What is the difference between `declarations`, `imports`, `providers`, and `exports` in NgModule?
**Answer:**
```typescript
@NgModule({
  declarations: [/* components, directives, pipes OWNED by this module */],
  imports:      [/* other NgModules this module depends on */],
  providers:    [/* services available to all components in this module */],
  exports:      [/* declarations to make visible to importing modules */]
})
```

- **declarations** — "I own these." Only components/directives/pipes.
- **imports** — "I need these." Only modules, not services or components directly.
- **providers** — "These services are available here." Prefer `providedIn: 'root'`.
- **exports** — "Other modules can use these from me."

---

## Q8. What is lazy loading in Angular?
**Answer:**
Lazy loading defers loading feature modules until the user navigates to their route — reduces initial bundle size:

```typescript
// app-routing.module.ts
const routes: Routes = [
  { path: '', component: HomeComponent }, // eagerly loaded
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
  },
  // Standalone (Angular 17+)
  {
    path: 'dashboard',
    loadComponent: () => import('./dashboard/dashboard.component').then(c => c.DashboardComponent)
  }
];
```

Angular CLI creates a separate JavaScript chunk for each lazy-loaded module. The chunk is only downloaded when the user visits that route.

---

## Q9. What is the Angular build process?
**Answer:**
```
Source (TypeScript + Templates)
        ↓ TypeScript Compiler (tsc)
   JavaScript
        ↓ Angular Compiler (ngc / Ivy)
   Compiled Components + Factories
        ↓ Webpack / esbuild (Angular 17+)
   Bundled JS/CSS chunks
        ↓ Terser (minification)
   Optimized production bundle
```

Key build outputs in `dist/`:
- `main.js` — application code
- `polyfills.js` — browser compatibility
- `styles.css` — global styles
- Lazy-loaded chunks: `feature-module.js`

**Ivy** (default since Angular 9) — Angular's current compiler and runtime. Produces smaller bundles and better error messages than the old View Engine.

---

## Q10. What is `@NgModule` vs `@Component` `providers` array?
**Answer:**
Services registered at different levels create different **injection scopes**:

```typescript
// Root level — single instance app-wide (recommended)
@Injectable({ providedIn: 'root' })
export class AuthService {}

// Module level — shared within the module
@NgModule({ providers: [UserService] })
export class UserModule {}

// Component level — new instance per component (and its children)
@Component({
  selector: 'app-user',
  providers: [TempService] // each UserComponent instance gets its own TempService
})
export class UserComponent {}
```

---

## Q11. What is the difference between Angular, React, and Vue?
**Answer:**
| | Angular | React | Vue |
|---|---|---|---|
| **Type** | Full framework | UI library | Progressive framework |
| **Language** | TypeScript (required) | JS/TS | JS/TS |
| **Data binding** | Two-way (ngModel) | One-way + state | Two-way (v-model) |
| **Learning curve** | Steep | Moderate | Gentle |
| **DI built-in** | ✓ Yes | ✗ No (use context/libs) | ✗ No |
| **State management** | NgRx / Signals | Redux / Zustand | Pinia / Vuex |
| **Router built-in** | ✓ Yes | ✗ React Router (separate) | ✓ Vue Router |
| **Maintainer** | Google | Meta | Community |

---

## Q12. What is `zone.js` and what is zoneless Angular?
**Answer:**
**zone.js** monkey-patches async APIs (setTimeout, Promise, DOM events) to track when asynchronous operations start and complete, triggering Angular's change detection cycle.

```typescript
// zone.js intercepts these:
setTimeout(() => model.value = "hello", 1000); // triggers change detection
httpClient.get('/api').subscribe(d => this.data = d); // triggers change detection
```

**Zoneless Angular** (Angular 18+ experimental, stable in Angular 20):
- Removes zone.js dependency (smaller bundle, better performance).
- Change detection is signal-driven or manually triggered.
- Requires using `signals` and/or calling `markForCheck()`.

---

## Q13. What is the `environment.ts` file in Angular?
**Answer:**
Environment files provide build-time configuration that can differ between environments:

```typescript
// src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api',
  featureFlag: true
};

// src/environments/environment.production.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.myapp.com',
  featureFlag: false
};

// Usage in code
import { environment } from '../environments/environment';
const url = environment.apiUrl; // dev or prod based on build
```

Angular CLI replaces the file during `ng build --configuration=production`.

---

## Q14. What is the `angular.json` file?
**Answer:**
`angular.json` is the workspace configuration file. It defines:
- **Projects** in the workspace (app, lib).
- **Build targets** (build, serve, test, lint) and their options.
- **File replacements** for environments.
- **Assets, styles, scripts** to include in the build.

```json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "builder": "@angular-devkit/build-angular:application",
          "options": {
            "outputPath": "dist/my-app",
            "index": "src/index.html",
            "main": "src/main.ts",
            "styles": ["src/styles.css"],
            "assets": ["src/favicon.ico", "src/assets"]
          }
        }
      }
    }
  }
}
```

---

## Q15. What are Angular Signals and how do they change state management?
**Answer:**
Signals (stable in Angular 17) are **reactive primitives** — wrappers around values that notify consumers when they change:

```typescript
import { signal, computed, effect } from '@angular/core';

// Writable signal
const count = signal(0);
count();         // read value: 0
count.set(5);    // set: 5
count.update(n => n + 1); // update based on current: 6

// Computed signal — derived, read-only
const doubled = computed(() => count() * 2); // 12

// Effect — side effect when signals change
effect(() => {
  console.log('Count changed to', count()); // runs on every count change
});

// In component — no OnPush needed, fine-grained reactivity
@Component({ template: '<p>{{ count() }}</p>' })
export class CounterComponent {
  count = signal(0);
  increment() { this.count.update(n => n + 1); }
}
```

Signals replace the need for `BehaviorSubject` in many cases and make `OnPush` the de facto default.
