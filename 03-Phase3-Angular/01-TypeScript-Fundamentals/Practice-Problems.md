# Topic 1: TypeScript Fundamentals — Practice Problems

## Problem 1: Type System Basics (Easy)
**Concept**: Variables, types, type inference, unions

### 1a. Type Annotations
Declare variables with explicit types for:
- A person's name (string)
- Their age (number)
- Whether they're employed (boolean)
- A list of hobbies (string array)
- A nullable phone number (string or null)
- A readonly ID

### 1b. Union Types & Type Guards
Write a function `formatValue` that accepts `string | number | boolean`:
- string → return UPPERCASE
- number → return fixed to 2 decimal places
- boolean → return "Yes" or "No"

```
formatValue("hello")  → "HELLO"
formatValue(3.14159)  → "3.14"
formatValue(true)     → "Yes"
```

### 1c. Literal Types
Create a `TrafficLight` type that only accepts `"red" | "yellow" | "green"`.
Write a function `getAction` that returns:
- "red" → "Stop"
- "yellow" → "Caution"
- "green" → "Go"

### 1d. Tuple Operations
Define a tuple type `Coordinate` as `[number, number]`.
Write functions:
- `distance(a: Coordinate, b: Coordinate): number` — Euclidean distance
- `midpoint(a: Coordinate, b: Coordinate): Coordinate`

```
distance([0, 0], [3, 4]) → 5
midpoint([0, 0], [4, 6]) → [2, 3]
```

---

## Problem 2: Interfaces & Type Aliases (Easy-Medium)
**Concept**: Defining shapes, extending, optional/readonly

### 2a. Define a User System
Create interfaces for:
```typescript
// User: id, name, email, age (optional), createdAt (readonly)
// Address: street, city, state, zip, country
// UserProfile: extends User, adds address, bio (optional), avatar (optional)
// AdminUser: extends UserProfile, adds permissions (string array), level (1|2|3)
```

Create sample objects for each and print them.

### 2b. Function Interfaces
Define an interface `Validator` with:
```typescript
interface Validator {
    (value: string): boolean;
}
```
Implement validators: `isEmail`, `isPhone`, `isStrongPassword` (min 8 chars, uppercase, lowercase, number).

### 2c. Index Signatures & Record
Build a `TranslationDictionary`:
```typescript
// Key: language code ("en", "es", "fr")
// Value: object mapping English words to translations
// Example: translations["es"]["hello"] → "hola"
```

### 2d. Discriminated Unions
Create a `Shape` type that can be a Circle, Rectangle, or Triangle.
Each has a `kind` field ("circle", "rectangle", "triangle") and relevant dimensions.
Write an `area` function using type narrowing:
```
area({ kind: "circle", radius: 5 })          → 78.54
area({ kind: "rectangle", width: 4, height: 6 }) → 24
area({ kind: "triangle", base: 3, height: 8 })   → 12
```

---

## Problem 3: Generics & Utility Types (Medium)
**Concept**: Generic functions, classes, and built-in utility types

### 3a. Generic Functions
Implement:
```typescript
function reverseArray<T>(arr: T[]): T[]
function findItem<T>(arr: T[], predicate: (item: T) => boolean): T | undefined
function mapArray<T, U>(arr: T[], transform: (item: T) => U): U[]
function groupBy<T>(arr: T[], keyFn: (item: T) => string): Record<string, T[]>
```

Test each with different types (numbers, strings, objects).

### 3b. Generic Stack Class
Build `Stack<T>` with:
- `push(item: T): void`
- `pop(): T | undefined`
- `peek(): T | undefined`
- `isEmpty(): boolean`
- `size(): number`
- `toArray(): T[]`

Test with `Stack<number>` and `Stack<string>`.

### 3c. Utility Types Practice
Given:
```typescript
interface Product {
    id: number;
    name: string;
    price: number;
    description: string;
    category: string;
    inStock: boolean;
}
```

Create these derived types:
1. `ProductSummary` — only `id`, `name`, `price` (use `Pick`)
2. `ProductUpdate` — all optional (use `Partial`)
3. `ProductCreate` — everything except `id` (use `Omit`)
4. `ReadonlyProduct` — all readonly (use `Readonly`)
5. `ProductCatalog` — `Record<string, Product[]>` keyed by category

### 3d. Generic Constraints
Write a function `getProperty<T, K extends keyof T>(obj: T, key: K): T[K]` that safely accesses object properties.

```typescript
const user = { name: "Debanjan", age: 25, email: "deb@test.com" };
getProperty(user, "name");   // ✅ returns "Debanjan"
getProperty(user, "age");    // ✅ returns 25
// getProperty(user, "foo"); // ❌ Compile error!
```

---

## Problem 4: Classes & OOP in TypeScript (Medium-Hard)
**Concept**: Classes, inheritance, abstract classes, interfaces

### 4a. Build a Task Management System
Implement these classes:

```typescript
// enum Priority { Low, Medium, High, Critical }
// enum TaskStatus { Todo, InProgress, Done, Cancelled }

// abstract class BaseEntity — id (readonly, auto-generated), createdAt, updatedAt

// class Task extends BaseEntity
//   - title, description, priority, status, assignee?, dueDate?
//   - complete(): void
//   - isOverdue(): boolean

// class TaskBoard
//   - tasks: Task[]
//   - addTask(), removeTask(), getByStatus(), getByPriority()
//   - getOverdueTasks(), getStatistics()
```

### 4b. Interface Implementation
```typescript
interface Sortable<T> {
    compareTo(other: T): number;
}

interface Filterable<T> {
    matches(criteria: Partial<T>): boolean;
}
```
Make `Task` implement both interfaces.

### 4c. Generic Repository
Build `Repository<T extends BaseEntity>`:
- `add(entity: T): void`
- `getById(id: string): T | undefined`
- `getAll(): T[]`
- `update(id: string, changes: Partial<T>): T | undefined`
- `delete(id: string): boolean`
- `find(predicate: (entity: T) => boolean): T[]`

---

## Problem 5: Comprehensive TypeScript Challenge (Hard)
**Concept**: Combine all TS concepts in a real-world scenario

### Build a Mini E-Commerce Type System

Create a complete type-safe e-commerce system:

**Types/Interfaces:**
```typescript
// Product, CartItem, Cart, Order, Customer, PaymentMethod
// Use generics for API responses: ApiResponse<T>
// Use discriminated unions for: PaymentMethod (credit | debit | paypal)
// Use enums for: OrderStatus, PaymentStatus
```

**Classes:**
```typescript
// ShoppingCart — add, remove, updateQuantity, getTotal, clear, checkout
// OrderProcessor — createOrder, processPayment, getOrderHistory
// PriceCalculator — subtotal, tax, discount, shipping, total
```

**Features:**
1. Full type safety — no `any` anywhere
2. Generics for API response wrapper
3. Discount strategies: percentage, fixed amount, buy-one-get-one
4. Cart operations with running totals
5. Order history with filtering

**Expected Output:**
```
=== Shopping Cart Demo ===
Added: MacBook Pro ($1,999.99) ×1
Added: Mouse ($49.99) ×2
Cart Total: $2,099.97

Apply 10% discount: -$210.00
Subtotal: $1,889.97
Tax (8%): $151.20
Shipping: FREE (over $100)
Order Total: $2,041.17

Payment: Credit Card ending in 4242
Order Status: Confirmed
Order ID: ORD-1234567

=== Order History ===
[ORD-1234567] $2,041.17 — Confirmed — April 11, 2026
```

---

### Submission
- Create a new folder and initialize: `npm init -y && tsc --init`
- Solve all problems in separate `.ts` files
- Enable `strict: true` in tsconfig.json — NO `any` types allowed!
- Compile and run with: `tsc && node dist/problem1.js`
- Tell me "check" when you're ready for review!
