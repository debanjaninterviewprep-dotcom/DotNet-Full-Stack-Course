# Topic 9: Pipes & Custom Pipes

## What Are Pipes?

Pipes **transform** displayed data in templates. They take a value, process it, and return a formatted result — without changing the underlying data.

```
{{ value | pipeName }}
{{ value | pipeName:arg1:arg2 }}
{{ value | pipe1 | pipe2 }}        ← Chaining
```

---

## Built-in Pipes

### DatePipe

```html
<!-- value: new Date() or '2026-04-11T10:30:00' -->

{{ today | date }}                    → Apr 11, 2026
{{ today | date:'short' }}            → 4/11/26, 10:30 AM
{{ today | date:'medium' }}           → Apr 11, 2026, 10:30:00 AM
{{ today | date:'long' }}             → April 11, 2026 at 10:30:00 AM GMT+5
{{ today | date:'full' }}             → Saturday, April 11, 2026 at 10:30:00 AM
{{ today | date:'shortDate' }}        → 4/11/26
{{ today | date:'longDate' }}         → April 11, 2026
{{ today | date:'shortTime' }}        → 10:30 AM
{{ today | date:'mediumTime' }}       → 10:30:00 AM

<!-- Custom format -->
{{ today | date:'dd/MM/yyyy' }}       → 11/04/2026
{{ today | date:'yyyy-MM-dd' }}       → 2026-04-11
{{ today | date:'EEEE, MMMM d' }}    → Saturday, April 11
{{ today | date:'hh:mm a' }}          → 10:30 AM
{{ today | date:'dd MMM yyyy, h:mm a' }} → 11 Apr 2026, 10:30 AM
```

### CurrencyPipe

```html
{{ 1999.99 | currency }}              → $1,999.99 (default: USD)
{{ 1999.99 | currency:'EUR' }}        → €1,999.99
{{ 1999.99 | currency:'GBP' }}        → £1,999.99
{{ 1999.99 | currency:'INR' }}        → ₹1,999.99
{{ 1999.99 | currency:'USD':'symbol':'1.0-0' }} → $2,000
{{ 49.9 | currency:'USD':'code' }}    → USD49.90
```

### DecimalPipe (number)

```html
{{ 3.14159 | number }}                → 3.142 (default: 1.0-3)
{{ 3.14159 | number:'1.0-2' }}        → 3.14
{{ 3.14159 | number:'3.2-2' }}        → 003.14
{{ 1234567 | number }}                → 1,234,567
{{ 0.756 | number:'1.0-0' }}          → 1

<!-- Format: {minIntDigits}.{minFracDigits}-{maxFracDigits} -->
<!-- '1.2-4' → min 1 integer digit, min 2 decimal, max 4 decimal -->
```

### PercentPipe

```html
{{ 0.756 | percent }}                 → 76%
{{ 0.756 | percent:'1.1-1' }}         → 75.6%
{{ 0.12 | percent:'1.0-0' }}          → 12%
```

### UpperCase / LowerCase / TitleCase

```html
{{ 'hello world' | uppercase }}       → HELLO WORLD
{{ 'HELLO WORLD' | lowercase }}       → hello world
{{ 'hello world' | titlecase }}       → Hello World
```

### SlicePipe

```html
<!-- Arrays -->
{{ [1,2,3,4,5] | slice:1:3 }}        → [2, 3]

<!-- Strings -->
{{ 'Angular is great' | slice:0:7 }}  → Angular

<!-- With *ngFor -->
@for (item of items | slice:0:5; track item.id) {
  <div>{{ item.name }}</div>    <!-- Show only first 5 -->
}
```

### JsonPipe (Debugging)

```html
{{ user | json }}
<!-- { "name": "Debanjan", "age": 25, "email": "deb@test.com" } -->

<!-- Great for debugging -->
<pre>{{ complexObject | json }}</pre>
```

### AsyncPipe

```html
<!-- Auto-subscribes to Observable/Promise and unsubscribes on destroy -->
{{ data$ | async }}

@if (users$ | async; as users) {
  @for (user of users; track user.id) {
    <div>{{ user.name }}</div>
  }
}

<!-- With other pipes -->
{{ lastUpdated$ | async | date:'mediumTime' }}
```

### KeyValuePipe

```html
<!-- Iterate over object keys -->
@for (item of myObject | keyvalue; track item.key) {
  <div>{{ item.key }}: {{ item.value }}</div>
}

<!-- With Map -->
@for (entry of myMap | keyvalue; track entry.key) {
  <div>{{ entry.key }} → {{ entry.value }}</div>
}
```

---

## Pipe Chaining

```html
<!-- Chain multiple pipes left to right -->
{{ birthday | date:'longDate' | uppercase }}
→ APRIL 11, 2026

{{ user.name | lowercase | titlecase }}
→ Debanjan Das

{{ price | currency:'USD' | slice:0:-3 }}
→ $1,999 (remove cents)
```

---

## Creating Custom Pipes

### Basic Custom Pipe

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'truncate',        // Used as: {{ text | truncate:50 }}
  standalone: true
})
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit: number = 100, trail: string = '...'): string {
    if (!value) return '';
    if (value.length <= limit) return value;
    return value.substring(0, limit) + trail;
  }
}
```

```html
{{ longText | truncate }}           → First 100 chars...
{{ longText | truncate:50 }}        → First 50 chars...
{{ longText | truncate:30:'→' }}    → First 30 chars→
```

### Time Ago Pipe

```typescript
@Pipe({
  name: 'timeAgo',
  standalone: true
})
export class TimeAgoPipe implements PipeTransform {
  transform(value: Date | string): string {
    const date = new Date(value);
    const now = new Date();
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);
    
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)} minutes ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)} hours ago`;
    if (seconds < 2592000) return `${Math.floor(seconds / 86400)} days ago`;
    if (seconds < 31536000) return `${Math.floor(seconds / 2592000)} months ago`;
    return `${Math.floor(seconds / 31536000)} years ago`;
  }
}
```

```html
{{ post.createdAt | timeAgo }}     → 3 hours ago
{{ post.createdAt | timeAgo }}     → 5 days ago
```

### Filter Pipe

```typescript
@Pipe({
  name: 'filter',
  standalone: true
})
export class FilterPipe implements PipeTransform {
  transform<T>(items: T[], field: keyof T, value: any): T[] {
    if (!items || !field || value === undefined) return items;
    return items.filter(item => item[field] === value);
  }
}
```

```html
@for (user of users | filter:'role':'admin'; track user.id) {
  <div>{{ user.name }} (Admin)</div>
}
```

### Sort Pipe

```typescript
@Pipe({
  name: 'sort',
  standalone: true
})
export class SortPipe implements PipeTransform {
  transform<T>(items: T[], field: keyof T, direction: 'asc' | 'desc' = 'asc'): T[] {
    if (!items || !field) return items;
    
    return [...items].sort((a, b) => {
      const valA = a[field];
      const valB = b[field];
      
      if (valA < valB) return direction === 'asc' ? -1 : 1;
      if (valA > valB) return direction === 'asc' ? 1 : -1;
      return 0;
    });
  }
}
```

```html
@for (user of users | sort:'name':'asc'; track user.id) {
  <div>{{ user.name }}</div>
}
```

### File Size Pipe

```typescript
@Pipe({
  name: 'fileSize',
  standalone: true
})
export class FileSizePipe implements PipeTransform {
  transform(bytes: number, decimals: number = 2): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
  }
}
```

```html
{{ 1024 | fileSize }}           → 1 KB
{{ 1048576 | fileSize }}        → 1 MB
{{ 1073741824 | fileSize:1 }}   → 1.0 GB
```

---

## Pure vs Impure Pipes

### Pure Pipes (Default)

- Called ONLY when input **reference** changes (or primitive value changes)
- Does NOT detect changes inside objects or arrays
- **Faster** — Angular caches result

```typescript
@Pipe({ name: 'myPipe', pure: true })  // Default
```

```typescript
// Pure pipe won't detect this:
this.users.push(newUser);  // Same array reference — pipe not called!

// Must create new reference:
this.users = [...this.users, newUser];  // New array — pipe called!
```

### Impure Pipes

- Called on **every** change detection cycle
- Detects changes inside arrays/objects
- **Slower** — use sparingly!

```typescript
@Pipe({ 
  name: 'filter', 
  standalone: true,
  pure: false    // Impure — called every cycle!
})
export class FilterPipe implements PipeTransform {
  transform(items: any[], searchText: string): any[] {
    // Called very frequently — keep it fast!
    return items.filter(item => item.name.includes(searchText));
  }
}
```

**Best Practice:** Keep pipes pure. When you need reactivity, create new array/object references instead of mutating.

---

## Pipes in Components (Not Just Templates)

```typescript
import { CurrencyPipe, DatePipe } from '@angular/common';

@Component({
  standalone: true,
  imports: [CurrencyPipe, DatePipe],
  providers: [CurrencyPipe, DatePipe]  // Also provide for injection
})
export class MyComponent {
  private currencyPipe = inject(CurrencyPipe);
  private datePipe = inject(DatePipe);
  
  getFormattedPrice(price: number): string {
    return this.currencyPipe.transform(price, 'USD') ?? '';
  }
  
  getFormattedDate(date: Date): string {
    return this.datePipe.transform(date, 'mediumDate') ?? '';
  }
}
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| Pipe | Transform data for display: `{{ value \| pipe }}` |
| DatePipe | Format dates: `date:'mediumDate'` |
| CurrencyPipe | Format money: `currency:'USD'` |
| DecimalPipe | Format numbers: `number:'1.2-2'` |
| AsyncPipe | Auto-subscribe/unsubscribe Observables |
| KeyValuePipe | Iterate object keys in template |
| Custom pipe | `@Pipe` + `PipeTransform` interface |
| Pure pipe | Called only on reference change (default, fast) |
| Impure pipe | Called every cycle (`pure: false`, slow) |
| Pipe chaining | `{{ val \| pipe1 \| pipe2 }}` |

---

*Next Topic: State Management (NgRx Basics) →*
