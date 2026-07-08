# Topic 03: Components and Templates — Interview Questions

---

## Q1. What is an Angular component and what does `@Component` decorator configure?
**Answer:**
A component is the fundamental building block of an Angular UI. It combines a TypeScript class (logic), an HTML template (view), and optional CSS (styles):

```typescript
@Component({
  selector: 'app-user',          // HTML tag to use this component: <app-user>
  templateUrl: './user.component.html', // external template file
  // template: `<p>Inline</p>`,  // OR inline template
  styleUrls: ['./user.component.scss'], // external styles
  // styles: [`p { color: red }`],     // OR inline styles
  standalone: true,              // standalone (Angular 17+)
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.Emulated // default
})
export class UserComponent implements OnInit {
  ngOnInit() { /* init logic */ }
}
```

---

## Q2. What are component lifecycle hooks and when is each used?
**Answer:**
```typescript
@Component({ selector: 'app-demo', template: '' })
export class DemoComponent implements OnInit, OnChanges, AfterViewInit, OnDestroy {
  @Input() data!: string;
  private subscription!: Subscription;

  ngOnChanges(changes: SimpleChanges) {
    // Called BEFORE ngOnInit and whenever @Input changes
    console.log('Previous:', changes['data'].previousValue);
    console.log('Current:',  changes['data'].currentValue);
  }

  ngOnInit() {
    // Called ONCE after first ngOnChanges — best place for HTTP calls
    this.subscription = this.service.getData().subscribe();
  }

  ngAfterViewInit() {
    // Called ONCE after view + child views are initialized
    // Safe to access @ViewChild here
    this.chart.render();
  }

  ngOnDestroy() {
    // Called just before component is destroyed
    this.subscription.unsubscribe(); // CRITICAL: avoid memory leaks
    this.destroyed$.next(); this.destroyed$.complete();
  }
}
```

---

## Q3. What is `@Input()` and `@Output()`?
**Answer:**
- `@Input()` — accepts data from a parent component (property binding).
- `@Output()` — emits events to the parent (event binding), always an `EventEmitter`.

```typescript
// Child component
@Component({ selector: 'app-counter', template: `
  <p>{{ count }}</p>
  <button (click)="increment()">+</button>
` })
export class CounterComponent {
  @Input() initialCount: number = 0;
  @Input({ required: true }) label!: string; // required input (Angular 16+)
  @Output() countChanged = new EventEmitter<number>();

  count = 0;
  ngOnInit() { this.count = this.initialCount; }
  increment() { this.count++; this.countChanged.emit(this.count); }
}

// Parent template
// <app-counter [initialCount]="5" label="Items" (countChanged)="onCount($event)" />
```

---

## Q4. What are `@ViewChild` and `@ContentChild`?
**Answer:**
- `@ViewChild` — queries the component's own **view** for a child component, directive, or template reference variable.
- `@ContentChild` — queries **projected content** (content passed via `<ng-content>`).

```typescript
@Component({
  selector: 'app-parent',
  template: `
    <app-child #childRef></app-child>
    <input #nameInput type="text" />
  `
})
export class ParentComponent implements AfterViewInit {
  @ViewChild(ChildComponent) child!: ChildComponent;        // by type
  @ViewChild('childRef') childByRef!: ChildComponent;       // by template var
  @ViewChild('nameInput') nameInput!: ElementRef<HTMLInputElement>;

  ngAfterViewInit() {
    this.child.doSomething();           // safe here — view is initialized
    this.nameInput.nativeElement.focus();
  }
}

// ViewChildren — multiple matches
@ViewChildren(ItemComponent) items!: QueryList<ItemComponent>;
```

---

## Q5. What is content projection (`ng-content`)?
**Answer:**
`<ng-content>` allows a component to receive and display HTML from the parent — like React's `children` prop:

```typescript
// Reusable card component
@Component({
  selector: 'app-card',
  template: `
    <div class="card">
      <ng-content select="[card-header]"></ng-content> <!-- named slot -->
      <ng-content></ng-content>                        <!-- default slot -->
      <ng-content select="[card-footer]"></ng-content>
    </div>
  `
})
export class CardComponent {}

// Usage
// <app-card>
//   <h2 card-header>Title</h2>
//   <p>Body content goes here</p>
//   <button card-footer>OK</button>
// </app-card>
```

---

## Q6. What are `ng-template`, `ng-container`, and `ng-content`?
**Answer:**
| Element | Purpose |
|---|---|
| `ng-template` | Defines a reusable template fragment — not rendered until explicitly instantiated |
| `ng-container` | Logical grouping without adding a DOM element — useful for structural directives |
| `ng-content` | Projection slot — renders content passed by the parent |

```html
<!-- ng-container: apply *ngIf without extra DOM element -->
<ng-container *ngIf="isAdmin">
  <button>Edit</button>
  <button>Delete</button>
</ng-container>

<!-- ng-template: define template for later use -->
<ng-template #loading>
  <p>Loading...</p>
</ng-template>
<ng-container *ngIf="data; else loading">{{ data }}</ng-container>

<!-- ng-content: projection -->
<app-modal>
  <h1>Title</h1>    <!-- projected via ng-content -->
</app-modal>
```

---

## Q7. What are template reference variables?
**Answer:**
Template reference variables (prefixed with `#`) provide a reference to a DOM element, component, or directive within the template:

```html
<!-- Reference to DOM element -->
<input #nameInput type="text" />
<button (click)="submit(nameInput.value)">Submit</button>

<!-- Reference to component instance -->
<app-child #child></app-child>
<button (click)="child.reset()">Reset Child</button>

<!-- Reference to NgForm -->
<form #loginForm="ngForm" (ngSubmit)="onSubmit(loginForm)">
  <input name="email" ngModel required />
  <button type="submit" [disabled]="loginForm.invalid">Login</button>
</form>
```

---

## Q8. What is View Encapsulation in Angular?
**Answer:**
View encapsulation controls how component styles are scoped:

| Mode | Behaviour |
|---|---|
| `Emulated` (default) | Angular adds unique attributes to DOM elements and scopes CSS using them — styles don't leak out |
| `ShadowDom` | Native browser Shadow DOM — true CSS isolation |
| `None` | No encapsulation — styles are global (can affect other components) |

```typescript
@Component({
  encapsulation: ViewEncapsulation.Emulated, // generates _ngcontent-abc
  styles: [`p { color: red }`]  // only affects THIS component's p tags
})

// Special selectors with Emulated:
:host { }         // targets the component's host element
:host-context(.dark) { }  // targets host when ancestor has .dark class
::ng-deep { }    // pierce encapsulation (deprecated — use carefully)
```

---

## Q9. What is the `async` pipe and why is it recommended?
**Answer:**
The `async` pipe subscribes to an Observable or Promise in the template and **automatically unsubscribes** when the component is destroyed:

```typescript
@Component({
  template: `
    <!-- Automatically subscribes + unsubscribes -->
    <div *ngIf="users$ | async as users">
      <p *ngFor="let user of users">{{ user.name }}</p>
    </div>

    <!-- With loading state -->
    <ng-container *ngIf="(data$ | async) as data; else loading">
      {{ data.title }}
    </ng-container>
    <ng-template #loading>Loading...</ng-template>
  `
})
export class UserListComponent {
  users$ = this.userService.getAll(); // Observable — NO manual subscribe needed
  constructor(private userService: UserService) {}
}
```

Benefits: no manual `subscribe`/`unsubscribe`, works perfectly with `OnPush`, declarative.

---

## Q10. What are smart (container) vs dumb (presentational) components?
**Answer:**
| | Smart (Container) | Dumb (Presentational) |
|---|---|---|
| **Purpose** | Manages state and data fetching | Pure display / UI |
| **Services** | Injects and uses services | No service injection |
| **@Input** | Usually none | Receives all data via @Input |
| **@Output** | Handles events | Emits events, doesn't handle them |
| **Testing** | Complex | Simple — just pass inputs |
| **Reusability** | Low | High |

```typescript
// Smart — knows about UserService
@Component({
  template: `<app-user-list [users]="users$ | async" (delete)="onDelete($event)"></app-user-list>`
})
class UserPageComponent { users$ = this.svc.getAll(); }

// Dumb — just displays
@Component({ template: `<li *ngFor="let u of users">{{ u.name }}</li>` })
class UserListComponent { @Input() users: User[] = []; @Output() delete = new EventEmitter<User>(); }
```

---

## Q11. How do you dynamically load components in Angular?
**Answer:**
Use `ViewContainerRef` and `ComponentRef` to create components programmatically:

```typescript
@Component({ template: '<ng-container #host></ng-container>' })
export class DynamicHostComponent {
  @ViewChild('host', { read: ViewContainerRef }) host!: ViewContainerRef;

  loadComponent(type: Type<any>) {
    this.host.clear();
    const ref = this.host.createComponent(type);
    ref.instance.data = { title: 'Dynamic' }; // pass inputs
    ref.changeDetectorRef.detectChanges();
  }
}
```

Angular 14+ also supports `@defer` blocks and `NgComponentOutlet` directive for simpler dynamic rendering:

```html
<ng-container *ngComponentOutlet="dynamicComponent; inputs: { title: 'Hello' }"></ng-container>
```

---

## Q12. What is `ChangeDetectorRef` and when do you use it?
**Answer:**
`ChangeDetectorRef` gives direct control over change detection for a component:

```typescript
@Component({ changeDetection: ChangeDetectionStrategy.OnPush })
export class DataComponent {
  constructor(private cdr: ChangeDetectorRef) {}

  // Trigger change detection manually (when using OnPush + manual data updates)
  update() {
    this.data = fetchData();
    this.cdr.markForCheck();   // schedule for next CD cycle
    // OR
    this.cdr.detectChanges();  // run immediately (synchronous)
  }

  // Detach from change detection (for heavy background processing)
  heavyWork() {
    this.cdr.detach();         // stop CD for this component
    // ... do heavy work
    this.cdr.reattach();       // resume
    this.cdr.detectChanges();  // run once
  }
}
```

---

## Q13. What is the `@defer` block (Angular 17+)?
**Answer:**
`@defer` enables declarative lazy loading of component parts without router configuration:

```html
<!-- Basic defer — loads when visible in viewport -->
@defer (on viewport) {
  <app-heavy-chart [data]="chartData" />
} @placeholder {
  <div class="chart-placeholder">Chart will load...</div>
} @loading (minimum 500ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart</p>
}

<!-- Defer on interaction -->
@defer (on interaction) {
  <app-comments />
}

<!-- Defer with custom trigger -->
@defer (when isLoggedIn) {
  <app-dashboard />
}
```

---

## Q14. What is the new control flow syntax (`@if`, `@for`, `@switch`) in Angular 17+?
**Answer:**
Angular 17 replaced structural directives with built-in control flow syntax:

```html
<!-- @if — replaces *ngIf -->
@if (user) {
  <p>Welcome {{ user.name }}</p>
} @else if (loading) {
  <app-spinner />
} @else {
  <a routerLink="/login">Log in</a>
}

<!-- @for — replaces *ngFor — track is REQUIRED -->
@for (user of users; track user.id) {
  <app-user [user]="user" />
} @empty {
  <p>No users found</p>
}

<!-- @switch — replaces ngSwitch -->
@switch (status) {
  @case ('active')   { <span class="green">Active</span> }
  @case ('inactive') { <span class="red">Inactive</span> }
  @default           { <span>Unknown</span> }
}
```

Benefits: better type inference, no need to import `CommonModule`, improved performance.

---

## Q15. What is `trackBy` in `*ngFor` and why is it important?
**Answer:**
By default, `*ngFor` re-renders all items when the array changes. `trackBy` tells Angular which property uniquely identifies each item so it only re-renders changed items:

```typescript
// Component
trackById(index: number, user: User): number { return user.id; }
```

```html
<!-- Without trackBy — ALL li elements re-created on any array change -->
<li *ngFor="let user of users">{{ user.name }}</li>

<!-- With trackBy — only changed items re-rendered -->
<li *ngFor="let user of users; trackBy: trackById">{{ user.name }}</li>

<!-- New @for syntax — track is required -->
@for (user of users; track user.id) {
  <li>{{ user.name }}</li>
}
```

For lists that update frequently (real-time data, server polling), `trackBy` significantly reduces unnecessary DOM manipulation.
