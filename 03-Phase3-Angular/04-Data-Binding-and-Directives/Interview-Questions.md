# Topic 04: Data Binding and Directives — Interview Questions

---

## Q1. What are the four types of data binding in Angular?
**Answer:**
| Type | Syntax | Direction | Example |
|---|---|---|---|
| **Interpolation** | `{{ expression }}` | Component → Template | `{{ user.name }}` |
| **Property binding** | `[property]="expr"` | Component → Template | `[src]="imageUrl"` |
| **Event binding** | `(event)="handler($event)"` | Template → Component | `(click)="save()"` |
| **Two-way binding** | `[(ngModel)]="prop"` | Both directions | `[(ngModel)]="name"` |

```html
<!-- Interpolation -->
<p>Hello {{ user.name }}</p>

<!-- Property binding -->
<img [src]="imageUrl" [alt]="imageAlt" />
<button [disabled]="isLoading">Save</button>

<!-- Event binding -->
<button (click)="onSave()">Save</button>
<input (keyup.enter)="onSearch()" (blur)="onBlur($event)" />

<!-- Two-way binding -->
<input [(ngModel)]="searchTerm" />
<!-- Desugars to: -->
<input [ngModel]="searchTerm" (ngModelChange)="searchTerm = $event" />
```

---

## Q2. What is the difference between `[property]` binding and `{{interpolation}}`?
**Answer:**
- **Interpolation** — converts the expression to a string and embeds it in text content. Suitable for text nodes.
- **Property binding** — binds to a DOM property directly. Can bind non-string types (boolean, object, array).

```html
<!-- Interpolation — always a string -->
<p>{{ user.name }}</p>
<img src="{{ imageUrl }}"> <!-- works but not recommended -->

<!-- Property binding — any type -->
<img [src]="imageUrl" />          <!-- string -->
<button [disabled]="isLoading" />  <!-- boolean — correct -->
<button disabled="{{ isLoading }}"> <!-- WRONG — always disabled (string "false" is truthy) -->
<app-user [data]="userObject" />   <!-- object -->
```

**Rule:** Use interpolation for text content. Use property binding for DOM properties and component inputs.

---

## Q3. What is the difference between property binding and attribute binding?
**Answer:**
DOM properties and HTML attributes are different things:
- **Properties** — live state of the DOM element (what the browser uses).
- **Attributes** — initial values in HTML (only exist in the HTML document).

```html
<!-- Property binding — preferred -->
<input [value]="name" />   <!-- binds to input.value (DOM property) -->
<button [disabled]="true"> <!-- binds to button.disabled (DOM property) -->

<!-- Attribute binding — needed for HTML attributes with no matching DOM property -->
<td [attr.colspan]="colSpan">       <!-- colspan has no matching property -->
<button [attr.aria-label]="label">  <!-- ARIA attributes -->
<svg:circle [attr.r]="radius">      <!-- SVG attributes -->

<!-- Class and Style bindings (special shorthand) -->
<div [class.active]="isActive">     <!-- toggle single class -->
<div [class]="{ active: true, hidden: false }"> <!-- object map -->
<div [style.color]="color">         <!-- single style -->
<div [style]="{ color: 'red', 'font-size': '16px' }"> <!-- object map -->
```

---

## Q4. What are built-in structural directives?
**Answer:**
Structural directives (prefixed with `*`) change the DOM structure:

```html
<!-- *ngIf — conditional rendering -->
<div *ngIf="user; else notFound">{{ user.name }}</div>
<ng-template #notFound><p>User not found</p></ng-template>

<!-- *ngFor — list rendering -->
<li *ngFor="let item of items; index as i; let last = last; trackBy: trackById">
  {{ i + 1 }}. {{ item.name }} {{ last ? '(last)' : '' }}
</li>

<!-- *ngSwitch — multi-condition -->
<div [ngSwitch]="status">
  <p *ngSwitchCase="'active'">Active</p>
  <p *ngSwitchCase="'inactive'">Inactive</p>
  <p *ngSwitchDefault>Unknown</p>
</div>
```

The `*` is syntactic sugar that wraps content in an `<ng-template>`.

---

## Q5. What are built-in attribute directives?
**Answer:**
Attribute directives change the appearance or behaviour of an element without altering the DOM structure:

```html
<!-- ngClass — conditionally apply CSS classes -->
<div [ngClass]="{ 'active': isActive, 'error': hasError }"></div>
<div [ngClass]="['base', isActive ? 'active' : 'inactive']"></div>

<!-- ngStyle — conditionally apply inline styles -->
<div [ngStyle]="{ 'background-color': bgColor, 'font-size': fontSize + 'px' }"></div>

<!-- ngModel — two-way binding for form elements (requires FormsModule) -->
<input [(ngModel)]="username" name="username" />

<!-- ngTemplateOutlet — instantiate an ng-template -->
<ng-container *ngTemplateOutlet="myTemplate; context: { $implicit: data }"></ng-container>
```

---

## Q6. How do you create a custom attribute directive?
**Answer:**
```typescript
import { Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
  selector: '[appHighlight]', // attribute selector
  standalone: true
})
export class HighlightDirective {
  @Input() appHighlight = 'yellow'; // directive input (same name as selector)
  @Input() defaultColor = 'white';

  private el: HTMLElement;

  constructor(el: ElementRef<HTMLElement>) {
    this.el = el.nativeElement;
  }

  @HostListener('mouseenter') onMouseEnter() {
    this.el.style.backgroundColor = this.appHighlight;
  }

  @HostListener('mouseleave') onMouseLeave() {
    this.el.style.backgroundColor = this.defaultColor;
  }
}

// Usage: <p [appHighlight]="'lightblue'" defaultColor="white">Hover me</p>
```

---

## Q7. How do you create a custom structural directive?
**Answer:**
Custom structural directives manipulate the DOM using `TemplateRef` and `ViewContainerRef`:

```typescript
@Directive({
  selector: '[appRepeat]',
  standalone: true
})
export class RepeatDirective {
  @Input() set appRepeat(count: number) {
    this.vcr.clear();
    for (let i = 0; i < count; i++) {
      this.vcr.createEmbeddedView(this.tpl, { $implicit: i, index: i });
    }
  }

  constructor(
    private tpl: TemplateRef<any>,
    private vcr: ViewContainerRef
  ) {}
}

// Usage: <p *appRepeat="3; let i">Item {{ i }}</p>
// Renders 3 paragraphs: Item 0, Item 1, Item 2
```

---

## Q8. What is `$event` in event binding?
**Answer:**
`$event` is a built-in Angular template variable that refers to the event payload:

```html
<!-- DOM events — $event is the native DOM event -->
<button (click)="onClick($event)">Click</button>
<input (keyup)="onKey($event)" />           <!-- $event is KeyboardEvent -->
<input (input)="onInput($event.target.value)" />

<!-- Custom EventEmitter — $event is the emitted value -->
<app-child (valueChanged)="onValueChanged($event)"></app-child>
<!-- if child emits: this.valueChanged.emit('hello') → $event = 'hello' -->

<!-- Form events -->
<form (ngSubmit)="onSubmit($event)">         <!-- $event is SubmitEvent -->
<input (blur)="onBlur($event.target.value)">
```

---

## Q9. What is the difference between a directive and a component?
**Answer:**
| | Component | Directive |
|---|---|---|
| **Template** | Has its own template | No template |
| **Selector** | Element: `app-user` | Attribute: `[highlight]` or element |
| **DOM** | Creates a new DOM subtree | Modifies existing elements |
| **Decorator** | `@Component` | `@Directive` |
| **Usage** | Encapsulate UI blocks | Add behaviour to existing elements |

A **component is a directive with a template**. `@Component` extends `@Directive`.

---

## Q10. What is `ngModel` and what module is needed for it?
**Answer:**
`ngModel` provides two-way data binding for form input elements. It requires the `FormsModule` or `ReactiveFormsModule`:

```typescript
// Standalone component
@Component({
  standalone: true,
  imports: [FormsModule], // required for ngModel
  template: `
    <input [(ngModel)]="name" name="name" />
    <p>Hello {{ name }}</p>
  `
})
export class FormComponent {
  name = '';
}
```

`[(ngModel)]` is "banana in a box" syntax — `[ngModel]` sets the value, `(ngModelChange)` reads updates. The name attribute is required when using `ngModel` inside a `<form>`.

---

## Q11. What are `@HostBinding` and `@HostListener`?
**Answer:**
- `@HostBinding` — binds a property to the host element (the element the directive/component is on).
- `@HostListener` — listens to events on the host element.

```typescript
@Directive({ selector: '[appFocus]', standalone: true })
export class FocusDirective {
  @HostBinding('class.focused') isFocused = false;       // adds/removes class
  @HostBinding('style.border') border = '2px solid blue';
  @HostBinding('attr.aria-focused') get ariaFocused() { return this.isFocused; }

  @HostListener('focus') onFocus() { this.isFocused = true; }
  @HostListener('blur')  onBlur()  { this.isFocused = false; }
  @HostListener('document:keydown.escape') onEscape() { /* global key listener */ }
}
```

---

## Q12. What is the `host` property in `@Component`?
**Answer:**
The `host` property in `@Component` / `@Directive` is an alternative to `@HostBinding` / `@HostListener`, configuring the host element declaratively:

```typescript
@Component({
  selector: 'app-button',
  standalone: true,
  host: {
    'class': 'btn',                        // always-on CSS class
    '[class.btn-primary]': 'isPrimary',    // conditional class
    '[attr.disabled]': 'disabled || null', // attribute binding
    '(click)': 'onClick()',                // event listener
    '(document:keydown.enter)': 'onEnter()' // global event
  },
  template: '<ng-content></ng-content>'
})
export class ButtonComponent {
  @Input() isPrimary = false;
  @Input() disabled = false;
  onClick() { this.clicked.emit(); }
  @Output() clicked = new EventEmitter();
}
```

---

## Q13. What are `ngClass` and `ngStyle` and when to use `[class]` vs `[ngClass]`?
**Answer:**
```html
<!-- [class.name] — single class toggle (preferred for single class) -->
<div [class.active]="isActive"></div>

<!-- [class] with string — replaces all classes -->
<div [class]="'btn btn-primary'"></div>

<!-- [class] with object — multiple conditional classes -->
<div [class]="{ active: isActive, error: hasError, 'btn-lg': isLarge }"></div>

<!-- [ngClass] — same as [class] with object/array/string -->
<div [ngClass]="{ active: isActive }"></div>

<!-- [style.property] — single style (preferred) -->
<div [style.backgroundColor]="bgColor"></div>
<div [style.font-size.px]="fontSize"></div>  <!-- unit suffix -->

<!-- [style] with object — multiple styles -->
<div [style]="{ color: textColor, 'background-color': bgColor }"></div>

<!-- [ngStyle] — same as [style] with object -->
<div [ngStyle]="{ color: textColor }"></div>
```

Prefer `[class.name]` and `[style.property]` for single bindings — Angular can optimize these better.

---

## Q14. What is the `safe navigation operator` (`?.`) in templates?
**Answer:**
The safe navigation operator `?.` prevents template errors when binding to potentially null or undefined values:

```html
<!-- Without safe navigation — throws if user is null -->
<p>{{ user.address.city }}</p>  <!-- TypeError if user is null -->

<!-- With safe navigation — renders nothing if null -->
<p>{{ user?.address?.city }}</p>

<!-- Also works in property binding -->
<img [src]="user?.profileImage" />

<!-- Alternative: *ngIf guard -->
<ng-container *ngIf="user">
  <p>{{ user.address.city }}</p>  <!-- safe — user is guaranteed non-null here -->
</ng-container>
```

---

## Q15. What is event filtering and what are keyboard event shortcuts?
**Answer:**
Angular templates support **pseudo-events** for common keyboard keys, reducing the need for event handler logic:

```html
<!-- Traditional — must check key in handler -->
<input (keyup)="onKey($event)" />
<!-- handler: if(event.key === 'Enter') { ... } -->

<!-- Angular pseudo-events — filter by key -->
<input (keyup.enter)="onEnter()" />        <!-- only fires on Enter key -->
<input (keydown.escape)="onEscape()" />     <!-- Escape key -->
<input (keyup.space)="onSpace()" />         <!-- Space key -->
<input (keydown.control.s)="onSave()" />    <!-- Ctrl+S -->
<input (keydown.meta.shift.z)="onRedo()" /> <!-- Cmd+Shift+Z -->

<!-- Mouse event filtering -->
<div (click.stop)="onClick()">    <!-- stops propagation -->
<form (submit.prevent)="save()">  <!-- prevents default submit -->
```
