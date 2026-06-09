# Topic 2: Angular Setup & Architecture

## What is Angular?

Angular is a **component-based**, **TypeScript-first** frontend framework built by Google. It provides everything out of the box: routing, forms, HTTP client, dependency injection, testing, and more.

```
React:   Library — you pick the tools
Vue:     Progressive framework — flexible
Angular: Full framework — batteries included (opinionated)
```

### Angular vs AngularJS

| Feature | AngularJS (1.x) | Angular (2+) |
|---|---|---|
| Language | JavaScript | TypeScript |
| Architecture | MVC | Component-based |
| Mobile support | No | Yes (Ionic, NativeScript) |
| Performance | Slow (dirty checking) | Fast (change detection, AOT) |
| CLI | No | Angular CLI |
| Current version | Deprecated | Angular 17+ (standalone by default) |

---

## Setting Up Angular

### Prerequisites

```bash
# Install Node.js (LTS) — includes npm
node --version   # v20+ recommended
npm --version    # v10+

# Install Angular CLI globally
npm install -g @angular/cli

# Verify
ng version
```

### Creating a New Project

```bash
# Create new Angular project
ng new my-app

# Options during creation:
# ? Which stylesheet format? → CSS / SCSS / SASS / Less
# ? Do you want to enable Server-Side Rendering (SSR)? → No (for now)

# This creates:
# my-app/
#   ├── src/
#   ├── angular.json
#   ├── package.json
#   ├── tsconfig.json
#   └── ...

# Navigate and start
cd my-app
ng serve
# Open http://localhost:4200
```

### Useful CLI Commands

```bash
# Generate components, services, etc.
ng generate component header          # or: ng g c header
ng generate service data              # or: ng g s data
ng generate module shared             # or: ng g m shared
ng generate pipe currency-format      # or: ng g p currency-format
ng generate guard auth                # or: ng g guard auth
ng generate interface models/user     # or: ng g i models/user
ng generate enum models/status        # or: ng g e models/status
ng generate class models/product      # or: ng g cl models/product

# Build for production
ng build --configuration=production

# Run unit tests
ng test

# Run end-to-end tests
ng e2e

# Lint the code
ng lint

# Update Angular
ng update @angular/core @angular/cli
```

---

## Project Structure

```
my-app/
├── src/
│   ├── app/
│   │   ├── app.component.ts          ← Root component
│   │   ├── app.component.html        ← Root template
│   │   ├── app.component.css         ← Root styles
│   │   ├── app.component.spec.ts     ← Root tests
│   │   ├── app.config.ts             ← App configuration (standalone)
│   │   └── app.routes.ts             ← Route definitions
│   │
│   ├── assets/                        ← Static files (images, fonts)
│   ├── environments/                  ← Environment configs
│   │   ├── environment.ts
│   │   └── environment.prod.ts
│   │
│   ├── index.html                     ← Main HTML page
│   ├── main.ts                        ← Entry point — bootstraps the app
│   └── styles.css                     ← Global styles
│
├── angular.json                       ← Angular workspace config
├── package.json                       ← npm dependencies
├── tsconfig.json                      ← TypeScript config
├── tsconfig.app.json                  ← TS config for app
├── tsconfig.spec.json                 ← TS config for tests
└── .editorconfig                      ← Editor settings
```

---

## Angular Architecture

### The Big Picture

```
┌──────────────────────────────────────────────┐
│                  Angular App                  │
│                                              │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   │
│  │Component│   │Component│   │Component│   │
│  │  + HTML │   │  + HTML │   │  + HTML │   │
│  │  + CSS  │   │  + CSS  │   │  + CSS  │   │
│  └────┬────┘   └────┬────┘   └────┬────┘   │
│       │              │              │        │
│       └──────────────┼──────────────┘        │
│                      │                        │
│              ┌───────┴───────┐                │
│              │   Services    │                │
│              │ (shared logic)│                │
│              └───────┬───────┘                │
│                      │                        │
│              ┌───────┴───────┐                │
│              │  HTTP Client  │                │
│              │  (API calls)  │                │
│              └───────────────┘                │
└──────────────────────────────────────────────┘
```

### Core Building Blocks

| Building Block | Purpose | Decorator |
|---|---|---|
| **Component** | UI piece with template + logic + styles | `@Component` |
| **Service** | Shared business logic / data | `@Injectable` |
| **Directive** | Modify DOM elements | `@Directive` |
| **Pipe** | Transform displayed data | `@Pipe` |
| **Guard** | Control route access | `@Injectable` |
| **Interceptor** | Modify HTTP requests/responses | `@Injectable` |
| **Module** | Group related features (legacy) | `@NgModule` |

---

## Components (Core of Angular)

Every piece of the UI is a **component**. Components are composable and reusable.

```
┌─────────────────────────────────────┐
│ AppComponent (root)                  │
│ ┌─────────────────────────────────┐ │
│ │ HeaderComponent                  │ │
│ │ ┌────────┐ ┌──────────────────┐ │ │
│ │ │ Logo   │ │ NavComponent     │ │ │
│ │ └────────┘ └──────────────────┘ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ MainContent                      │ │
│ │ ┌──────────┐ ┌────────────────┐ │ │
│ │ │ Sidebar  │ │ ProductList    │ │ │
│ │ │          │ │ ┌────────────┐ │ │ │
│ │ │          │ │ │ ProductCard│ │ │ │
│ │ │          │ │ │ ProductCard│ │ │ │
│ │ │          │ │ │ ProductCard│ │ │ │
│ │ │          │ │ └────────────┘ │ │ │
│ │ └──────────┘ └────────────────┘ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ FooterComponent                  │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Component Anatomy

```typescript
// header.component.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-header',           // HTML tag: <app-header></app-header>
  standalone: true,                  // Standalone component (Angular 17+ default)
  imports: [],                       // Other components/modules this uses
  templateUrl: './header.component.html',  // External template
  // OR inline:
  // template: `<h1>{{ title }}</h1>`,
  styleUrls: ['./header.component.css'],   // External styles
  // OR inline:
  // styles: [`h1 { color: blue; }`]
})
export class HeaderComponent {
  title = 'My Angular App';
  
  onLogoClick(): void {
    console.log('Logo clicked!');
  }
}
```

```html
<!-- header.component.html -->
<header>
  <h1 (click)="onLogoClick()">{{ title }}</h1>
  <nav>
    <a href="/">Home</a>
    <a href="/about">About</a>
  </nav>
</header>
```

```css
/* header.component.css — SCOPED to this component only! */
header {
  background-color: #333;
  color: white;
  padding: 1rem;
}
```

---

## Standalone Components (Angular 17+ Default)

Angular 17+ uses **standalone components** by default — no NgModules needed.

```typescript
// Before (Module-based — legacy)
@NgModule({
  declarations: [AppComponent, HeaderComponent, FooterComponent],
  imports: [BrowserModule, HttpClientModule, FormsModule],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {}

// After (Standalone — modern)
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [HeaderComponent, FooterComponent, RouterOutlet],
  template: `
    <app-header />
    <router-outlet />
    <app-footer />
  `
})
export class AppComponent {}
```

### Bootstrapping (main.ts)

```typescript
// main.ts — Entry point
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig)
  .catch(err => console.error(err));
```

```typescript
// app.config.ts — Application configuration
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient()
  ]
};
```

---

## Dependency Injection (DI) Overview

Angular has a powerful built-in DI system. Services are **injected** into components rather than created manually.

```typescript
// data.service.ts
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'  // Available app-wide (singleton)
})
export class DataService {
  getData(): string[] {
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}

// list.component.ts
@Component({
  selector: 'app-list',
  standalone: true,
  template: `
    <ul>
      @for (item of items; track item) {
        <li>{{ item }}</li>
      }
    </ul>
  `
})
export class ListComponent {
  items: string[];
  
  // Inject service via constructor
  constructor(private dataService: DataService) {
    this.items = this.dataService.getData();
  }
  
  // OR using inject() function (modern approach)
  // private dataService = inject(DataService);
}
```

---

## Change Detection

Angular automatically updates the DOM when data changes. It uses **Zone.js** to detect async events.

```
User clicks button
→ Zone.js detects event
→ Angular runs change detection
→ Compares current values with previous
→ Updates DOM where values changed
```

### Strategies

```typescript
// Default — checks entire component tree
@Component({
  changeDetection: ChangeDetectionStrategy.Default
})

// OnPush — only checks when:
// 1. @Input() reference changes
// 2. Event handler fires in this component
// 3. Observable linked with async pipe emits
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush  // Better performance
})
```

---

## Angular File Naming Conventions

```
Components:  user-list.component.ts / .html / .css / .spec.ts
Services:    user.service.ts / .spec.ts
Pipes:       date-format.pipe.ts
Guards:      auth.guard.ts
Interceptors: auth.interceptor.ts
Interfaces:  user.interface.ts  OR  user.model.ts
Enums:       status.enum.ts
Directives:  highlight.directive.ts
```

**Kebab-case** for file names, **PascalCase** for class names:
- `user-profile.component.ts` → `UserProfileComponent`
- `data.service.ts` → `DataService`

---

## Angular Lifecycle Hooks

Components have a lifecycle managed by Angular:

```typescript
export class MyComponent implements OnInit, OnDestroy, OnChanges {
  
  // 1. Constructor — DI happens here (don't put logic here)
  constructor(private service: DataService) {}
  
  // 2. ngOnChanges — when @Input() values change
  ngOnChanges(changes: SimpleChanges): void {
    console.log('Input changed:', changes);
  }
  
  // 3. ngOnInit — component initialized (most common — put logic HERE)
  ngOnInit(): void {
    this.loadData();
  }
  
  // 4. ngDoCheck — custom change detection
  
  // 5. ngAfterContentInit — after <ng-content> projected
  
  // 6. ngAfterContentChecked — after projected content checked
  
  // 7. ngAfterViewInit — after view (template) initialized
  
  // 8. ngAfterViewChecked — after view checked
  
  // 9. ngOnDestroy — cleanup (unsubscribe, remove listeners)
  ngOnDestroy(): void {
    this.subscription.unsubscribe();
  }
}
```

### Most Used Lifecycle Hooks

| Hook | When | Use For |
|---|---|---|
| `ngOnInit` | After first `ngOnChanges` | Load data, initialize component |
| `ngOnChanges` | `@Input()` changes | React to parent data changes |
| `ngOnDestroy` | Before component removed | Unsubscribe, cleanup |
| `ngAfterViewInit` | After view renders | Access DOM elements with `@ViewChild` |

---

## Environment Configuration

```typescript
// environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:5000/api',
  appName: 'My App (Dev)'
};

// environments/environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: 'https://api.myapp.com/api',
  appName: 'My App'
};

// Usage in any file:
import { environment } from '../environments/environment';

const url = `${environment.apiUrl}/users`;
```

---

## Build & Deployment

```bash
# Development build (with source maps, no optimization)
ng build

# Production build (minified, tree-shaken, AOT compiled)
ng build --configuration=production

# Output goes to dist/my-app/
# Contains: index.html, main.js, polyfills.js, styles.css

# Serve production build locally
npx http-server dist/my-app

# AOT vs JIT Compilation
# JIT (Just-in-Time): Compiles in browser — slower startup, used in dev
# AOT (Ahead-of-Time): Compiles during build — faster startup, used in prod
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Angular | Full-featured TypeScript framework by Google |
| Angular CLI | `ng` commands for generate, serve, build, test |
| Component | UI building block: template + class + styles |
| Standalone | Modern default — no NgModule needed |
| DI | Services injected via constructor or `inject()` |
| Lifecycle | `ngOnInit` (load), `ngOnDestroy` (cleanup) |
| Change detection | Zone.js detects changes, updates DOM |
| AOT | Ahead-of-time compilation for production |
| Conventions | Kebab-case files, PascalCase classes |

---

*Next Topic: Components & Templates →*
