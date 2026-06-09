# Topic 3: Components & Templates

## Components — The Core Building Block

Every piece of Angular UI is a **component**. A component = **TypeScript class** + **HTML template** + **CSS styles**.

```
Component = @Component decorator + class + template + styles

@Component({
  selector: 'app-user',           → HTML tag name
  standalone: true,               → No NgModule needed  
  imports: [...],                 → Dependencies (other components, directives, pipes)
  templateUrl: './user.html',     → HTML template
  styleUrls: ['./user.css']       → Scoped CSS
})
export class UserComponent {
  // Class = data + methods
}
```

---

## Creating Components

### Using CLI (Recommended)

```bash
# Full component (4 files: .ts, .html, .css, .spec.ts)
ng generate component user-profile
# or shorthand:
ng g c user-profile

# Inline template and styles (single file)
ng g c user-card --inline-template --inline-style
# or:
ng g c user-card -it -is

# Skip test file
ng g c user-card --skip-tests

# Generate in a specific folder
ng g c features/dashboard/task-stats
```

### Generated Files

```
user-profile/
├── user-profile.component.ts       ← Component class
├── user-profile.component.html     ← Template
├── user-profile.component.css      ← Scoped styles
└── user-profile.component.spec.ts  ← Unit tests
```

---

## Component Class

```typescript
import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './user-profile.component.html',
  styleUrls: ['./user-profile.component.css']
})
export class UserProfileComponent implements OnInit, OnDestroy {
  // Properties (data for the template)
  name: string = 'Debanjan';
  age: number = 25;
  skills: string[] = ['C#', 'Angular', 'TypeScript'];
  isActive: boolean = true;
  
  // Computed property via getter
  get greeting(): string {
    return `Hello, ${this.name}!`;
  }
  
  // Lifecycle hooks
  ngOnInit(): void {
    console.log('Component initialized');
  }
  
  ngOnDestroy(): void {
    console.log('Component destroyed');
  }
  
  // Methods (event handlers)
  toggleActive(): void {
    this.isActive = !this.isActive;
  }
  
  addSkill(skill: string): void {
    this.skills.push(skill);
  }
}
```

---

## Template Syntax

### Text Interpolation `{{ }}`

```html
<!-- Displays property values in the template -->
<h1>{{ name }}</h1>
<p>Age: {{ age }}</p>
<p>{{ greeting }}</p>            <!-- Getter -->
<p>{{ 2 + 2 }}</p>               <!-- Expression -->
<p>{{ name.toUpperCase() }}</p>  <!-- Method call -->
<p>{{ isActive ? 'Active' : 'Inactive' }}</p>  <!-- Ternary -->
```

**Rules:**
- Must evaluate to a string (or be auto-converted)
- No assignments: `{{ x = 5 }}` ❌
- No `new`, `typeof`, `instanceof`
- No chaining with `;`

---

### Control Flow (Angular 17+ Built-in Syntax)

Angular 17 introduced new **built-in control flow** syntax that replaces `*ngIf`, `*ngFor`, `*ngSwitch`.

#### @if / @else

```html
<!-- New syntax (Angular 17+) -->
@if (isLoggedIn) {
  <p>Welcome, {{ username }}!</p>
} @else if (isGuest) {
  <p>Welcome, Guest!</p>
} @else {
  <p>Please log in.</p>
}

<!-- Old syntax (*ngIf — still works) -->
<p *ngIf="isLoggedIn; else guestBlock">Welcome, {{ username }}!</p>
<ng-template #guestBlock><p>Please log in.</p></ng-template>
```

#### @for

```html
<!-- New syntax (Angular 17+) — REQUIRES track -->
@for (user of users; track user.id) {
  <div class="user-card">
    <h3>{{ user.name }}</h3>
    <p>{{ user.email }}</p>
  </div>
} @empty {
  <p>No users found.</p>
}

<!-- With index and other variables -->
@for (item of items; track item.id; let i = $index; let isFirst = $first; let isLast = $last) {
  <li [class.first]="isFirst" [class.last]="isLast">
    {{ i + 1 }}. {{ item.name }}
  </li>
}

<!-- Available variables in @for:
  $index  — current index (0-based)
  $first  — true if first item
  $last   — true if last item
  $even   — true if even index
  $odd    — true if odd index
  $count  — total number of items
-->

<!-- Old syntax (*ngFor — still works) -->
<div *ngFor="let user of users; let i = index; trackBy: trackByFn">
  {{ i + 1 }}. {{ user.name }}
</div>
```

#### @switch

```html
<!-- New syntax -->
@switch (status) {
  @case ('active') {
    <span class="badge active">Active</span>
  }
  @case ('inactive') {
    <span class="badge inactive">Inactive</span>
  }
  @case ('pending') {
    <span class="badge pending">Pending</span>
  }
  @default {
    <span class="badge">Unknown</span>
  }
}

<!-- Old syntax (*ngSwitch — still works) -->
<div [ngSwitch]="status">
  <span *ngSwitchCase="'active'">Active</span>
  <span *ngSwitchCase="'inactive'">Inactive</span>
  <span *ngSwitchDefault>Unknown</span>
</div>
```

#### @defer (Lazy Loading Templates)

```html
<!-- Load component only when visible in viewport -->
@defer (on viewport) {
  <app-heavy-chart />
} @placeholder {
  <div>Chart loading area...</div>
} @loading (minimum 500ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart.</p>
}

<!-- Other triggers -->
@defer (on idle) { ... }        <!-- When browser is idle -->
@defer (on timer(3s)) { ... }   <!-- After 3 seconds -->
@defer (on hover) { ... }       <!-- When user hovers -->
@defer (on interaction) { ... } <!-- When user interacts -->
@defer (when condition) { ... } <!-- When condition is true -->
```

---

## Input & Output (Component Communication)

### Parent → Child: `@Input()`

```typescript
// child: user-card.component.ts
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-user-card',
  standalone: true,
  template: `
    <div class="card">
      <h3>{{ user.name }}</h3>
      <p>{{ user.email }}</p>
      @if (showDetails) {
        <p>Age: {{ user.age }}</p>
      }
    </div>
  `
})
export class UserCardComponent {
  @Input() user!: { name: string; email: string; age: number };
  @Input() showDetails: boolean = false;
}
```

```html
<!-- parent template -->
<app-user-card [user]="currentUser" [showDetails]="true" />
```

#### Input with Transform & Required

```typescript
// Modern input APIs (Angular 16+)
import { Component, input } from '@angular/core';

@Component({ ... })
export class UserCardComponent {
  // Signal-based inputs (Angular 17+)
  user = input.required<User>();           // Required
  showDetails = input<boolean>(false);     // Optional with default
  
  // Transform input
  label = input('', { transform: (v: string) => v.toUpperCase() });
}
```

### Child → Parent: `@Output()`

```typescript
// child: user-card.component.ts
import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-user-card',
  standalone: true,
  template: `
    <div class="card">
      <h3>{{ user.name }}</h3>
      <button (click)="onSelect()">Select</button>
      <button (click)="onDelete()">Delete</button>
    </div>
  `
})
export class UserCardComponent {
  @Input() user!: User;
  @Output() selected = new EventEmitter<User>();
  @Output() deleted = new EventEmitter<number>();
  
  onSelect(): void {
    this.selected.emit(this.user);      // Emit the user object
  }
  
  onDelete(): void {
    this.deleted.emit(this.user.id);    // Emit just the ID
  }
}
```

```html
<!-- parent template -->
<app-user-card 
  [user]="currentUser"
  (selected)="onUserSelected($event)"
  (deleted)="onUserDeleted($event)"
/>
```

```typescript
// parent component
export class UserListComponent {
  onUserSelected(user: User): void {
    console.log('Selected:', user.name);
  }
  
  onUserDeleted(userId: number): void {
    this.users = this.users.filter(u => u.id !== userId);
  }
}
```

### Communication Pattern Summary

```
┌─────────────┐    [property]="value"     ┌─────────────┐
│   PARENT     │ ─────────────────────────→│    CHILD     │
│  Component   │                           │  Component   │
│              │ ←─────────────────────────│              │
└─────────────┘    (event)="handler($event)" └──────────┘

Parent → Child:  @Input()  with [property binding]
Child → Parent:  @Output() with (event binding)
```

---

## ViewChild & ViewChildren

Access child components or DOM elements from the parent.

```typescript
import { Component, ViewChild, AfterViewInit, ElementRef } from '@angular/core';

@Component({
  selector: 'app-parent',
  standalone: true,
  imports: [ChildComponent],
  template: `
    <input #nameInput type="text" />
    <app-child #childComp />
    <button (click)="focusInput()">Focus</button>
  `
})
export class ParentComponent implements AfterViewInit {
  // Access DOM element
  @ViewChild('nameInput') nameInput!: ElementRef<HTMLInputElement>;
  
  // Access child component instance
  @ViewChild('childComp') childComponent!: ChildComponent;
  
  // Available AFTER view initializes
  ngAfterViewInit(): void {
    console.log(this.childComponent);    // Child component instance
    this.nameInput.nativeElement.focus(); // Focus the input
  }
  
  focusInput(): void {
    this.nameInput.nativeElement.focus();
  }
}
```

### ViewChildren (Multiple)

```typescript
import { ViewChildren, QueryList } from '@angular/core';

@Component({
  template: `
    @for (item of items; track item.id) {
      <app-item-card #cards [item]="item" />
    }
  `
})
export class ListComponent {
  @ViewChildren('cards') cards!: QueryList<ItemCardComponent>;
  
  ngAfterViewInit(): void {
    console.log(`Found ${this.cards.length} cards`);
    this.cards.forEach(card => console.log(card));
  }
}
```

---

## Content Projection (`<ng-content>`)

Allows parent to pass arbitrary HTML INTO a child component.

### Single Slot Projection

```typescript
// card.component.ts
@Component({
  selector: 'app-card',
  standalone: true,
  template: `
    <div class="card">
      <ng-content />   <!-- Parent's content goes HERE -->
    </div>
  `,
  styles: [`.card { border: 1px solid #ccc; padding: 1rem; border-radius: 8px; }`]
})
export class CardComponent {}
```

```html
<!-- parent uses it -->
<app-card>
  <h3>My Title</h3>
  <p>This content is projected into the card!</p>
</app-card>

<!-- Another usage -->
<app-card>
  <img src="photo.jpg" />
  <p>Different content here</p>
</app-card>
```

### Multi-Slot Projection

```typescript
// modal.component.ts
@Component({
  selector: 'app-modal',
  standalone: true,
  template: `
    <div class="modal">
      <div class="modal-header">
        <ng-content select="[header]" />
      </div>
      <div class="modal-body">
        <ng-content select="[body]" />
      </div>
      <div class="modal-footer">
        <ng-content select="[footer]" />
      </div>
    </div>
  `
})
export class ModalComponent {}
```

```html
<!-- parent -->
<app-modal>
  <div header>
    <h2>Confirm Delete</h2>
  </div>
  <div body>
    <p>Are you sure you want to delete this item?</p>
  </div>
  <div footer>
    <button>Cancel</button>
    <button>Delete</button>
  </div>
</app-modal>
```

### Conditional Content Projection

```html
<!-- Check if content was projected -->
<div class="header" *ngIf="hasHeader">
  <ng-content select="[header]" />
</div>

<!-- Or with @ContentChild -->
```

```typescript
import { ContentChild, TemplateRef } from '@angular/core';

@Component({ ... })
export class CardComponent {
  @ContentChild('headerTpl') headerTemplate?: TemplateRef<any>;
  
  get hasHeader(): boolean {
    return !!this.headerTemplate;
  }
}
```

---

## ng-template & ng-container

### ng-template — Reusable template block (not rendered by default)

```html
<!-- Define a template -->
<ng-template #loadingTpl>
  <div class="spinner">Loading...</div>
</ng-template>

<!-- Use it conditionally -->
@if (isLoading) {
  <ng-container *ngTemplateOutlet="loadingTpl" />
} @else {
  <div>Content loaded!</div>
}
```

### ng-container — Invisible grouping element

```html
<!-- ng-container doesn't create a DOM element -->
<ng-container>
  <p>These elements are grouped</p>
  <p>But no wrapper div in the DOM</p>
</ng-container>

<!-- Useful with structural directives -->
<ul>
  @for (item of items; track item.id) {
    <ng-container>
      <li>{{ item.name }}</li>
      <li>{{ item.description }}</li>  <!-- Two <li> per item, no wrapper -->
    </ng-container>
  }
</ul>
```

---

## Template Reference Variables

```html
<!-- #variableName gives access to the element -->
<input #nameInput type="text" placeholder="Enter name" />
<button (click)="greet(nameInput.value)">Greet</button>

<!-- On a component — gives the component instance -->
<app-timer #timer />
<button (click)="timer.start()">Start Timer</button>
<button (click)="timer.stop()">Stop Timer</button>
<p>Elapsed: {{ timer.seconds }}s</p>
```

---

## Component Styles (Scoping)

Styles in a component are **scoped** to that component by default (using Angular's ViewEncapsulation).

```typescript
@Component({
  selector: 'app-user',
  template: `<p class="name">{{ name }}</p>`,
  styles: [`
    .name { color: blue; font-weight: bold; }
    /* This ONLY affects <p> inside THIS component! */
  `],
  
  // View encapsulation options:
  // encapsulation: ViewEncapsulation.Emulated   ← Default (scoped via attributes)
  // encapsulation: ViewEncapsulation.None        ← Global (no scoping)
  // encapsulation: ViewEncapsulation.ShadowDom   ← Use real Shadow DOM
})
export class UserComponent {
  name = 'Debanjan';
}
```

### Special CSS Selectors

```css
/* :host — style the component's HOST element */
:host {
  display: block;
  padding: 1rem;
  border: 1px solid #ddd;
}

/* :host with condition */
:host(.active) {
  border-color: green;
}

/* ::ng-deep — pierce through child scoping (use sparingly!) */
:host ::ng-deep .child-class {
  color: red;
}
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Component | Class + Template + Styles with `@Component` |
| `@Input()` | Pass data from parent → child |
| `@Output()` | Emit events from child → parent |
| `@ViewChild` | Access child component/DOM from parent |
| `@for` / `@if` / `@switch` | Angular 17+ built-in control flow |
| `@defer` | Lazy load template sections |
| `<ng-content>` | Project parent content into child slots |
| `ng-template` | Reusable template block |
| `ng-container` | Invisible grouping (no DOM element) |
| ViewEncapsulation | Styles scoped to component by default |

---

*Next Topic: Data Binding & Directives →*
