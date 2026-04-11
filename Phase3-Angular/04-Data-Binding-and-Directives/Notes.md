# Topic 4: Data Binding & Directives

## Data Binding Overview

Data binding connects the **component class** (TypeScript) with the **template** (HTML). Angular provides four types:

```
┌──────────────────────────────────────────────────────────┐
│                    DATA BINDING                           │
│                                                          │
│  Component (.ts)              Template (.html)           │
│  ┌──────────┐                 ┌──────────┐              │
│  │          │ ── {{ value }} ──→│          │  Interpolation│
│  │          │ ── [prop]="val" ──→│          │  Property     │
│  │          │ ←── (event)="fn()" ──│          │  Event        │
│  │          │ ←→ [(ngModel)]="val" →│          │  Two-way      │
│  └──────────┘                 └──────────┘              │
│                                                          │
│  One-way →    Interpolation, Property binding            │
│  One-way ←    Event binding                              │
│  Two-way ↔    [(ngModel)]                                │
└──────────────────────────────────────────────────────────┘
```

---

## 1. Interpolation `{{ }}`

Outputs component data as text in the template.

```typescript
// component
export class DemoComponent {
  name = 'Debanjan';
  price = 49.99;
  items = ['Angular', 'React', 'Vue'];
  
  getFullName(): string {
    return `${this.name} Das`;
  }
}
```

```html
<!-- template -->
<h1>{{ name }}</h1>                    <!-- Debanjan -->
<p>Price: {{ price | currency }}</p>   <!-- $49.99 (with pipe) -->
<p>Items: {{ items.length }}</p>       <!-- 3 -->
<p>{{ getFullName() }}</p>             <!-- Debanjan Das -->
<p>{{ 2 + 2 }}</p>                     <!-- 4 -->
<p>{{ name ? name : 'Guest' }}</p>     <!-- Debanjan -->
<img src="{{ imageUrl }}" />           <!-- Works but prefer [src] -->
```

---

## 2. Property Binding `[property]="expression"`

Binds a **DOM property** (not HTML attribute) to a component expression.

```html
<!-- Bind to DOM properties -->
<img [src]="imageUrl" [alt]="imageAlt" />
<button [disabled]="isSubmitting">Submit</button>
<input [value]="userName" [placeholder]="hint" />
<div [hidden]="!isVisible">I can be hidden</div>

<!-- Bind to component @Input() -->
<app-user-card [user]="selectedUser" [showDetails]="true" />

<!-- Bind to class -->
<div [class.active]="isActive">Toggle me</div>
<div [class]="currentClasses">Multiple classes</div>

<!-- Bind to style -->
<div [style.color]="textColor">Colored text</div>
<div [style.font-size.px]="fontSize">Sized text</div>
<div [style.width.%]="progressPercent">Progress</div>

<!-- Bind to attribute (for non-DOM properties) -->
<td [attr.colspan]="columnSpan">Spanning cell</td>
<div [attr.role]="ariaRole" [attr.aria-label]="label">Accessible</div>
```

### Property vs Attribute

```
HTML Attribute: Initial value in HTML           → [attr.colspan]
DOM Property:   Current value on DOM element    → [disabled], [value], [src]

<input value="initial">
- HTML attribute "value" = "initial" (never changes)
- DOM property .value = current text in the box (changes as user types)

Rule: Angular binds to DOM PROPERTIES by default.
Use [attr.xxx] only when there's no corresponding DOM property.
```

---

## 3. Event Binding `(event)="handler($event)"`

Listens for DOM events and calls component methods.

```html
<!-- Click -->
<button (click)="onSave()">Save</button>
<button (click)="onDelete(item.id)">Delete</button>

<!-- With $event (the native DOM event) -->
<input (input)="onInput($event)" />
<input (keyup)="onKeyUp($event)" />
<input (keyup.enter)="onEnter($event)" />  <!-- Key filter! -->
<input (keyup.escape)="onEscape()" />

<!-- Mouse events -->
<div (mouseenter)="onHover(true)" (mouseleave)="onHover(false)">
  Hover me
</div>
<div (dblclick)="onDoubleClick()">Double click me</div>

<!-- Form events -->
<form (submit)="onSubmit($event)">...</form>
<select (change)="onSelectionChange($event)">...</select>

<!-- Focus/Blur -->
<input (focus)="onFocus()" (blur)="onBlur()" />
```

```typescript
// Component methods
export class DemoComponent {
  onSave(): void {
    console.log('Saved!');
  }
  
  onInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    console.log('Value:', input.value);
  }
  
  onKeyUp(event: KeyboardEvent): void {
    console.log('Key:', event.key);
  }
  
  onEnter(event: KeyboardEvent): void {
    const input = event.target as HTMLInputElement;
    this.addItem(input.value);
    input.value = '';
  }
}
```

---

## 4. Two-Way Binding `[(ngModel)]`

Combines property binding `[ngModel]` and event binding `(ngModelChange)` — keeps component and template in sync.

```typescript
// MUST import FormsModule
import { FormsModule } from '@angular/forms';

@Component({
  standalone: true,
  imports: [FormsModule],  // Required for ngModel!
  template: `
    <input [(ngModel)]="name" />
    <p>Hello, {{ name }}!</p>
    
    <!-- What [(ngModel)] expands to: -->
    <input [ngModel]="name" (ngModelChange)="name = $event" />
  `
})
export class DemoComponent {
  name = 'Debanjan';
}
```

### Two-Way Binding with Custom Components

```typescript
// child component
@Component({
  selector: 'app-sizer',
  template: `
    <button (click)="decrease()">−</button>
    <span>{{ size }}</span>
    <button (click)="increase()">+</button>
  `
})
export class SizerComponent {
  @Input() size: number = 14;
  @Output() sizeChange = new EventEmitter<number>();  // Must be: propertyName + "Change"
  
  increase() { this.sizeChange.emit(this.size + 1); }
  decrease() { this.sizeChange.emit(this.size - 1); }
}
```

```html
<!-- parent — banana-in-a-box syntax! -->
<app-sizer [(size)]="fontSize" />
<p [style.font-size.px]="fontSize">Resizable text</p>
```

**Convention:** For `[(x)]` to work, the child needs `@Input() x` and `@Output() xChange`.

---

## Directives Overview

Directives are **classes that modify DOM elements**. Three types:

| Type | Purpose | Example |
|---|---|---|
| **Component** | Directive with a template | `@Component` |
| **Structural** | Add/remove DOM elements | `*ngIf`, `*ngFor`, `@if`, `@for` |
| **Attribute** | Change appearance/behavior | `ngClass`, `ngStyle`, custom |

---

## Built-in Attribute Directives

### ngClass — Dynamic CSS Classes

```html
<!-- Single class (boolean) -->
<div [ngClass]="{ 'active': isActive, 'disabled': isDisabled }">
  Conditional classes
</div>

<!-- Array of classes -->
<div [ngClass]="['bold', 'highlight']">Always bold and highlighted</div>

<!-- String -->
<div [ngClass]="currentClassString">Dynamic class string</div>

<!-- Shorthand: single class binding -->
<div [class.active]="isActive">Single class toggle</div>
<div [class.text-danger]="hasError">Error text</div>
```

```typescript
export class DemoComponent {
  isActive = true;
  isDisabled = false;
  hasError = false;
  
  // Complex class logic
  getCardClasses(card: any): Record<string, boolean> {
    return {
      'card': true,
      'card-active': card.isActive,
      'card-featured': card.isFeatured,
      'card-expired': card.isExpired
    };
  }
}
```

### ngStyle — Dynamic Inline Styles

```html
<!-- Object of styles -->
<div [ngStyle]="{
  'color': textColor,
  'font-size.px': fontSize,
  'background-color': isActive ? 'green' : 'gray'
}">
  Styled element
</div>

<!-- Shorthand: single style binding -->
<div [style.color]="textColor">Colored</div>
<div [style.font-size.px]="fontSize">Sized</div>
<div [style.width.%]="progress">Progress bar</div>
<div [style.display]="isVisible ? 'block' : 'none'">Toggle</div>
```

### ngModel — Form Binding (covered above)

---

## Built-in Structural Directives (Legacy Syntax)

Angular 17+ has built-in `@if`, `@for`, `@switch` (covered in Topic 3). The directive versions still work:

### *ngIf

```html
<div *ngIf="isLoggedIn">Welcome back!</div>

<!-- With else -->
<div *ngIf="isLoggedIn; else loginBlock">Welcome!</div>
<ng-template #loginBlock>
  <p>Please log in.</p>
</ng-template>

<!-- With then/else -->
<div *ngIf="condition; then thenBlock; else elseBlock"></div>
<ng-template #thenBlock>True content</ng-template>
<ng-template #elseBlock>False content</ng-template>

<!-- Store result in variable (useful with async) -->
<div *ngIf="user$ | async as user">
  <p>{{ user.name }}</p>
</div>
```

### *ngFor

```html
<li *ngFor="let item of items; let i = index; let first = first; let last = last; let even = even; trackBy: trackByFn">
  {{ i + 1 }}. {{ item.name }}
</li>
```

```typescript
trackByFn(index: number, item: any): number {
  return item.id;  // Track by unique ID for performance
}
```

### *ngSwitch

```html
<div [ngSwitch]="role">
  <p *ngSwitchCase="'admin'">Admin Panel</p>
  <p *ngSwitchCase="'editor'">Editor Dashboard</p>
  <p *ngSwitchCase="'user'">User Home</p>
  <p *ngSwitchDefault>Guest Page</p>
</div>
```

---

## Custom Attribute Directives

Create your own directives to encapsulate reusable DOM behavior.

### Highlight Directive

```typescript
import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  selector: '[appHighlight]',   // Attribute selector
  standalone: true
})
export class HighlightDirective {
  @Input() appHighlight: string = 'yellow';  // Highlight color
  @Input() defaultColor: string = '';        // Default color
  
  constructor(private el: ElementRef) {}
  
  @HostListener('mouseenter')
  onMouseEnter(): void {
    this.highlight(this.appHighlight || 'yellow');
  }
  
  @HostListener('mouseleave')
  onMouseLeave(): void {
    this.highlight(this.defaultColor);
  }
  
  private highlight(color: string): void {
    this.el.nativeElement.style.backgroundColor = color;
  }
}
```

```html
<!-- Usage -->
<p appHighlight>Hover me (yellow highlight)</p>
<p [appHighlight]="'lightblue'">Hover me (blue highlight)</p>
<p [appHighlight]="'pink'" defaultColor="lightgray">Pink on hover, gray default</p>
```

### Auto-Focus Directive

```typescript
@Directive({
  selector: '[appAutoFocus]',
  standalone: true
})
export class AutoFocusDirective {
  constructor(private el: ElementRef) {}
  
  ngAfterViewInit(): void {
    this.el.nativeElement.focus();
  }
}
```

```html
<input appAutoFocus placeholder="I'm auto-focused!" />
```

### Click Outside Directive

```typescript
@Directive({
  selector: '[appClickOutside]',
  standalone: true
})
export class ClickOutsideDirective {
  @Output() appClickOutside = new EventEmitter<void>();
  
  constructor(private el: ElementRef) {}
  
  @HostListener('document:click', ['$event.target'])
  onClick(target: HTMLElement): void {
    const clickedInside = this.el.nativeElement.contains(target);
    if (!clickedInside) {
      this.appClickOutside.emit();
    }
  }
}
```

```html
<div class="dropdown" (appClickOutside)="closeDropdown()">
  <button (click)="toggleDropdown()">Menu</button>
  @if (isOpen) {
    <ul class="dropdown-menu">
      <li>Option 1</li>
      <li>Option 2</li>
    </ul>
  }
</div>
```

---

## Custom Structural Directive

```typescript
import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

// *appUnless — opposite of *ngIf
@Directive({
  selector: '[appUnless]',
  standalone: true
})
export class UnlessDirective {
  private hasView = false;
  
  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef
  ) {}
  
  @Input() set appUnless(condition: boolean) {
    if (!condition && !this.hasView) {
      // Show the element
      this.viewContainer.createEmbeddedView(this.templateRef);
      this.hasView = true;
    } else if (condition && this.hasView) {
      // Remove the element
      this.viewContainer.clear();
      this.hasView = false;
    }
  }
}
```

```html
<!-- Show when NOT admin -->
<p *appUnless="isAdmin">You are NOT an admin.</p>
```

---

## HostListener & HostBinding

Interact with the **host element** (the element the directive/component is placed on).

```typescript
@Directive({
  selector: '[appHoverable]',
  standalone: true
})
export class HoverableDirective {
  // Bind to host element's class
  @HostBinding('class.hovered') isHovered = false;
  
  // Bind to host element's style
  @HostBinding('style.cursor') cursor = 'pointer';
  
  // Listen for host element's events
  @HostListener('mouseenter')
  onEnter() { this.isHovered = true; }
  
  @HostListener('mouseleave')
  onLeave() { this.isHovered = false; }
  
  // Listen for document/window events
  @HostListener('window:resize', ['$event'])
  onResize(event: Event) {
    console.log('Window resized');
  }
}
```

---

## Key Takeaways

| Concept | Syntax | Direction |
|---|---|---|
| Interpolation | `{{ value }}` | Component → Template |
| Property binding | `[property]="expr"` | Component → Template |
| Event binding | `(event)="handler()"` | Template → Component |
| Two-way binding | `[(ngModel)]="prop"` | Both ways |
| ngClass | `[ngClass]="{ class: condition }"` | Dynamic CSS classes |
| ngStyle | `[ngStyle]="{ style: value }"` | Dynamic inline styles |
| Attribute directive | `[appHighlight]="color"` | Modify element behavior |
| Structural directive | `*appUnless="condition"` | Add/remove elements |
| HostListener | `@HostListener('event')` | Listen to host events |
| HostBinding | `@HostBinding('class.x')` | Bind to host properties |

---

*Next Topic: Services & Dependency Injection →*
