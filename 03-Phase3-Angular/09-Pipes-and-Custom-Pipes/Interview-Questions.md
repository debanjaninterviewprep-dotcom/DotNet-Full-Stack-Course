# Topic 09: Pipes and Custom Pipes — Interview Questions

---

## Q1. What is a pipe in Angular and what is its purpose?
**Answer:**
A pipe transforms data for display in the template without changing the underlying data model. It uses the `|` operator:

```html
{{ user.name | uppercase }}              <!-- "DEBANJAN" -->
{{ price | currency:'USD' }}             <!-- "$99.99" -->
{{ birthdate | date:'mediumDate' }}      <!-- "Jul 8, 2026" -->
{{ user | json }}                        <!-- JSON string for debugging -->
{{ longText | slice:0:100 }}             <!-- first 100 characters -->
{{ users$ | async }}                     <!-- subscribe to Observable -->
```

Pipes keep templates clean and declarative. They're **pure functions** by default: same input always yields the same output.

---

## Q2. What are the built-in Angular pipes?
**Answer:**
| Pipe | Purpose | Example |
|---|---|---|
| `uppercase` / `lowercase` | Case transform | `'hello' \| uppercase` → `'HELLO'` |
| `titlecase` | Title case | `'hello world' \| titlecase` → `'Hello World'` |
| `currency` | Format currency | `100 \| currency:'EUR':'symbol':'1.2-2'` → `'€100.00'` |
| `decimal` / `number` | Format numbers | `3.14159 \| number:'1.2-2'` → `'3.14'` |
| `percent` | Format percent | `0.25 \| percent` → `'25%'` |
| `date` | Format dates | `today \| date:'yyyy-MM-dd'` |
| `json` | Serialize to JSON | `obj \| json` |
| `slice` | Array/string slice | `arr \| slice:1:4` |
| `keyvalue` | Iterate object as key-value pairs | `obj \| keyvalue` |
| `async` | Subscribe to Observable/Promise | `data$ \| async` |
| `i18nPlural` | Pluralization | `count \| i18nPlural:rules` |
| `i18nSelect` | Mapping | `gender \| i18nSelect:phrases` |

---

## Q3. What is the `date` pipe and what are common format strings?
**Answer:**
```html
{{ today | date }}                        <!-- 'Jul 8, 2026' (mediumDate) -->
{{ today | date:'short' }}               <!-- '7/8/26, 10:30 AM' -->
{{ today | date:'medium' }}              <!-- 'Jul 8, 2026, 10:30:00 AM' -->
{{ today | date:'long' }}                <!-- 'July 8, 2026 at 10:30:00 AM GMT+5:30' -->
{{ today | date:'yyyy-MM-dd' }}          <!-- '2026-07-08' (ISO) -->
{{ today | date:'dd/MM/yyyy HH:mm' }}    <!-- '08/07/2026 10:30' -->
{{ today | date:'EEEE, MMMM d' }}        <!-- 'Tuesday, July 8' -->
{{ today | date:'relative' }}            <!-- '2 hours ago' (needs Angular 17.3+) -->

<!-- With timezone -->
{{ today | date:'short':'UTC' }}
{{ today | date:'short':'+0530' }}       <!-- IST -->
```

---

## Q4. What is the `async` pipe and what are its benefits?
**Answer:**
The `async` pipe:
1. **Subscribes** to an Observable or Promise.
2. **Unwraps** the emitted value for display.
3. **Unsubscribes automatically** when the component is destroyed (no memory leak).
4. **Triggers change detection** when new values arrive (essential with `OnPush`).

```html
<!-- Observable -->
<p>{{ user$ | async | json }}</p>

<!-- With *ngIf alias pattern -->
<div *ngIf="user$ | async as user">
  <h1>{{ user.name }}</h1>
  <p>{{ user.email }}</p>
</div>

<!-- Error and loading states -->
<ng-container *ngIf="{ data: data$ | async, error: error$ | async } as vm">
  @if (vm.error) { <p class="error">{{ vm.error }}</p> }
  @if (vm.data)  { <p>{{ vm.data.title }}</p> }
</ng-container>
```

---

## Q5. What is the difference between a pure and impure pipe?
**Answer:**
| | Pure (default) | Impure |
|---|---|---|
| **Recalculates when** | Input reference or primitive value changes | Every change detection cycle |
| **Performance** | Fast | Slow (called on every CD cycle) |
| **Memoized** | Yes — same input returns same output | No |
| **Use for** | Stateless transformations | Mutable objects, random values, external state |

```typescript
// Pure pipe (default) — NOT called if object reference is the same
@Pipe({ name: 'format' }) // pure: true by default
export class FormatPipe implements PipeTransform {
  transform(value: string): string { return value.trim(); }
}

// Impure pipe — called every change detection cycle
@Pipe({ name: 'filter', pure: false })
export class FilterPipe implements PipeTransform {
  transform(items: any[], filterFn: (item: any) => boolean): any[] {
    return items.filter(filterFn); // needed for mutated arrays
  }
}
```

**Avoid impure pipes** in hot paths — they significantly hurt performance. Prefer filtering/sorting in the component.

---

## Q6. How do you create a custom pipe?
**Answer:**
```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'truncate',
  standalone: true,
  pure: true
})
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit: number = 100, suffix: string = '...'): string {
    if (!value) return '';
    return value.length > limit ? value.substring(0, limit) + suffix : value;
  }
}

// Register (standalone)
@Component({
  standalone: true,
  imports: [TruncatePipe],
  template: `{{ description | truncate:50 }}`
})

// Register (NgModule)
@NgModule({ declarations: [TruncatePipe], exports: [TruncatePipe] })
```

Usage:
```html
{{ 'Very long text...' | truncate }}          <!-- 100 chars + '...' -->
{{ 'Very long text...' | truncate:50 }}       <!-- 50 chars + '...' -->
{{ 'Very long text...' | truncate:50:'[more]' }} <!-- 50 chars + '[more]' -->
```

---

## Q7. How do you chain multiple pipes?
**Answer:**
Pipes can be chained with multiple `|` operators — evaluated left to right:

```html
<!-- Chain: first convert to string, then uppercase, then truncate -->
{{ price | currency:'USD' | uppercase }}

{{ name | lowercase | titlecase }}

{{ date | date:'shortDate' | uppercase }}

<!-- Multi-argument pipes with chaining -->
{{ text | slice:0:50 | uppercase | truncate:30 }}

<!-- async with transformation -->
{{ users$ | async | slice:0:5 }}
```

---

## Q8. How do you create a pipe that formats phone numbers?
**Answer:**
```typescript
@Pipe({ name: 'phone', standalone: true })
export class PhonePipe implements PipeTransform {
  transform(value: string, format: 'US' | 'IN' = 'US'): string {
    if (!value) return '';
    const digits = value.replace(/\D/g, ''); // remove non-digits

    if (format === 'US' && digits.length === 10)
      return `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}`;

    if (format === 'IN' && digits.length === 10)
      return `+91 ${digits.slice(0,5)} ${digits.slice(5)}`;

    return value; // unrecognized format — return as-is
  }
}

// Usage: {{ '9876543210' | phone:'IN' }} → '+91 98765 43210'
```

---

## Q9. What are parameterized pipes and how do you pass multiple arguments?
**Answer:**
```typescript
@Pipe({ name: 'padStart', standalone: true })
export class PadStartPipe implements PipeTransform {
  transform(value: number | string, length: number, fillChar: string = '0'): string {
    return String(value).padStart(length, fillChar);
  }
}
```

```html
<!-- Single argument -->
{{ 5 | padStart:3 }}           <!-- '005' -->

<!-- Multiple arguments (colon-separated) -->
{{ 5 | padStart:3:'0' }}       <!-- '005' -->
{{ 5 | padStart:5:'*' }}       <!-- '****5' -->

<!-- Built-in examples with multiple args -->
{{ 3.14159 | number:'1.2-4' }} <!-- '3.1416' (min 1 int, 2-4 decimal) -->
{{ 100 | currency:'EUR':'code':'1.2-2':'de' }} <!-- German locale -->
```

---

## Q10. How do you handle null and undefined values in pipes?
**Answer:**
```typescript
// Guard against null/undefined in the pipe
@Pipe({ name: 'safeDate', standalone: true })
export class SafeDatePipe implements PipeTransform {
  constructor(private datePipe: DatePipe) {}

  transform(value: Date | string | null | undefined, format = 'mediumDate'): string {
    if (value == null) return '—'; // show dash for null/undefined
    return this.datePipe.transform(value, format) ?? '—';
  }
}

// In templates — use safe navigation
{{ user?.birthdate | date }}      // null-safe navigation
{{ user?.birthdate | date | uppercase }} // chain safely

// Or nullish coalescing
{{ (user?.score | number) ?? 'N/A' }}
```

---

## Q11. What is the `keyvalue` pipe and when is it useful?
**Answer:**
`keyvalue` converts an object into an array of `{ key, value }` pairs for iteration:

```html
<!-- Iterate over object properties -->
@for (item of configObject | keyvalue; track item.key) {
  <p>{{ item.key }}: {{ item.value }}</p>
}

<!-- Sort by key (default), or custom comparator -->
{{ myObject | keyvalue:compareFn }}

<!-- With interface -->
interface Config { apiUrl: string; timeout: number; debug: boolean; }
config: Config = { apiUrl: '...', timeout: 30, debug: false };
<!-- Iterates: apiUrl, debug, timeout (alphabetical) -->
```

---

## Q12. Can you inject services into a pipe?
**Answer:**
Yes — pipes can have dependencies injected via the constructor:

```typescript
@Pipe({ name: 'translate', standalone: true })
export class TranslatePipe implements PipeTransform {
  constructor(private i18nService: I18nService) {}

  transform(key: string, params?: Record<string, string>): string {
    return this.i18nService.translate(key, params);
  }
}

// Caution: if the pipe is pure, it won't re-execute when translations load asynchronously
// Solution: make it impure (performance hit) or use async pipe with the service
```

---

## Q13. What is the `slice` pipe and how does it differ from `Array.slice()`?
**Answer:**
Angular's `slice` pipe works on both **arrays and strings**, similar to JavaScript's `slice()`:

```html
<!-- Array slice -->
{{ [1,2,3,4,5] | slice:1:4 }}    <!-- [2, 3, 4] -->
{{ [1,2,3,4,5] | slice:2 }}      <!-- [3, 4, 5] -->
{{ [1,2,3,4,5] | slice:-2 }}     <!-- [4, 5] (from end) -->

<!-- String slice -->
{{ 'Hello World' | slice:0:5 }}  <!-- 'Hello' -->

<!-- Pagination pattern — show items 0-9 on page 1 -->
{{ items | slice:(page-1)*10:page*10 }}
```

**Important:** Since `slice` returns a new array/string reference every time it runs, it triggers change detection even for the same data. For performance, pre-slice in the component.

---

## Q14. How do you test a custom pipe?
**Answer:**
Pipes are pure functions — they're the easiest Angular construct to test:

```typescript
describe('TruncatePipe', () => {
  let pipe: TruncatePipe;

  beforeEach(() => {
    pipe = new TruncatePipe(); // no DI needed for simple pipes
  });

  it('should truncate long strings', () => {
    expect(pipe.transform('A very long string indeed', 10)).toBe('A very lon...');
  });

  it('should not truncate short strings', () => {
    expect(pipe.transform('Short', 10)).toBe('Short');
  });

  it('should handle null/empty', () => {
    expect(pipe.transform(null as any)).toBe('');
    expect(pipe.transform('')).toBe('');
  });

  it('should use custom suffix', () => {
    expect(pipe.transform('Hello World', 5, ' [more]')).toBe('Hello [more]');
  });
});
```

---

## Q15. What is the performance impact of pipes vs component methods in templates?
**Answer:**
**Pure pipes** are **heavily optimized** — they are memoized and only called when the input reference changes.

**Component methods** in templates are called on **every change detection cycle** — a major performance issue:

```html
<!-- BAD — method called on every CD cycle (could be thousands of times) -->
<p>{{ formatName(user.name) }}</p>
<li *ngFor="let item of filterItems(items)">{{ item }}</li>

<!-- GOOD — pure pipe called only when input changes -->
<p>{{ user.name | formatName }}</p>
<li *ngFor="let item of items | filter:searchTerm">{{ item }}</li>

<!-- ALSO GOOD — computed in component, referenced in template -->
get formattedName(): string { return this.formatName(this.user.name); }
<p>{{ formattedName }}</p>
```

**Rule:** Never call functions in templates that compute values — use pipes or compute values in the component class.
