# Topic 01: TypeScript Fundamentals — Interview Questions

---

## Q1. What is TypeScript and what are its advantages over JavaScript?
**Answer:**
TypeScript is a **statically typed superset of JavaScript** developed by Microsoft. It compiles to plain JavaScript.

**Advantages:**
- **Static typing** — catch type errors at compile time, not runtime.
- **IntelliSense** — rich IDE support with autocomplete and refactoring.
- **Interfaces & generics** — express design contracts explicitly.
- **Modern JS features** — decorators, optional chaining, etc., compiled to older targets.
- **Refactoring safety** — rename a symbol and all usages update.

```typescript
// JavaScript — no error until runtime
function greet(name) { return "Hello " + nme; } // nme is undefined — runtime error

// TypeScript — caught at compile time
function greet(name: string): string { return "Hello " + nme; } // ❌ Error: 'nme' not found
```

---

## Q2. What is the difference between `interface` and `type` in TypeScript?
**Answer:**
| | `interface` | `type` |
|---|---|---|
| **Extends** | `extends` keyword | `&` (intersection) |
| **Merged declarations** | ✓ Yes (declaration merging) | ✗ No |
| **Primitives/unions** | ✗ No | ✓ Yes |
| **Implements** | ✓ Classes can implement | ✓ Classes can implement |
| **Computed properties** | ✗ | ✓ |

```typescript
interface User { name: string; }
interface User { age: number; } // ✓ Declaration merging — User now has both

type Point = { x: number; y: number };
type ID = string | number; // ✓ Union type — only possible with type

// Both support extending:
interface Admin extends User { role: string; }
type AdminType = User & { role: string };
```

**Rule of thumb:** Prefer `interface` for object shapes and public APIs (supports merging). Use `type` for unions, intersections, and utility types.

---

## Q3. What are generics in TypeScript?
**Answer:**
Generics allow writing **reusable, type-safe code** that works with multiple types without sacrificing type information:

```typescript
// Without generics — loses type info
function identity(arg: any): any { return arg; }

// With generics — type is preserved
function identity<T>(arg: T): T { return arg; }

const s = identity<string>("hello"); // s is string
const n = identity(42);              // T inferred as number

// Generic interface
interface Repository<T> {
  getById(id: number): T;
  save(entity: T): void;
}

// Generic constraints
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
```

---

## Q4. What are TypeScript utility types?
**Answer:**
Built-in generic types that transform existing types:

```typescript
interface User { id: number; name: string; email: string; age?: number; }

Partial<User>    // all properties optional:  { id?: number; name?: string; ... }
Required<User>   // all properties required:  { id: number; name: string; age: number; }
Readonly<User>   // all properties read-only
Pick<User, 'id' | 'name'>  // { id: number; name: string }
Omit<User, 'email'>        // { id: number; name: string; age?: number }
Record<string, number>     // { [key: string]: number }
Exclude<'a'|'b'|'c', 'a'> // 'b' | 'c'
Extract<'a'|'b'|'c', 'a'|'f'> // 'a'
NonNullable<string | null | undefined> // string
ReturnType<typeof fetch>   // Promise<Response>
Parameters<typeof Math.max> // [x: number, y: number]
```

---

## Q5. What are union and intersection types?
**Answer:**
- **Union (`|`)** — value can be one of several types.
- **Intersection (`&`)** — value must satisfy all types simultaneously.

```typescript
// Union — string OR number
type ID = string | number;
let id: ID = "abc"; id = 42; // both valid

// Intersection — has ALL properties of both types
type Employee = { name: string; department: string };
type Manager  = { reports: Employee[] };
type ManagerEmployee = Employee & Manager;

const mgr: ManagerEmployee = { name: "Alice", department: "Eng", reports: [] };

// Discriminated union (most common pattern)
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "square"; side: number };

function area(s: Shape): number {
  switch (s.kind) {
    case "circle": return Math.PI * s.radius ** 2;
    case "square": return s.side ** 2;
  }
}
```

---

## Q6. What is the difference between `any`, `unknown`, and `never`?
**Answer:**
| Type | Assignable from | Assignable to | Usage |
|---|---|---|---|
| `any` | Anything | Anything | Opt out of type checking — avoid |
| `unknown` | Anything | Only `unknown`/`any` without narrowing | Safe alternative to `any` |
| `never` | Nothing | Everything | Impossible values, exhaustive checks |

```typescript
let a: any    = "hello"; a.toUpperCase(); // ✓ no type check — dangerous
let u: unknown = "hello";
// u.toUpperCase(); // ❌ must narrow first
if (typeof u === "string") u.toUpperCase(); // ✓ narrowed

// never — unreachable code / exhaustive check
function assertNever(x: never): never { throw new Error("Unexpected: " + x); }
type Dir = "left" | "right";
function move(d: Dir) {
  if (d === "left") {}
  else if (d === "right") {}
  else assertNever(d); // ✓ compiler ensures this is never reached
}
```

---

## Q7. What is type narrowing in TypeScript?
**Answer:**
Type narrowing reduces a broader type to a more specific one within a block, using **type guards**:

```typescript
function process(val: string | number) {
  if (typeof val === "string") {
    console.log(val.toUpperCase()); // val is string here
  } else {
    console.log(val.toFixed(2));    // val is number here
  }
}

// instanceof narrowing
if (error instanceof HttpError) error.statusCode;

// Custom type guard (user-defined)
function isUser(obj: any): obj is User {
  return typeof obj.name === "string" && typeof obj.id === "number";
}

// in operator narrowing
if ("fly" in animal) animal.fly(); // animal has a fly method

// Nullish narrowing
if (value != null) value.toString(); // not null or undefined
```

---

## Q8. What are TypeScript decorators and how are they used?
**Answer:**
Decorators are **metadata annotations** (functions) applied to classes, methods, properties, or parameters using `@`:

```typescript
// Class decorator
function Injectable(target: Function) {
  Reflect.defineMetadata("injectable", true, target);
}

// Method decorator
function Log(target: any, name: string, descriptor: PropertyDescriptor) {
  const original = descriptor.value;
  descriptor.value = function(...args: any[]) {
    console.log(`Calling ${name} with`, args);
    return original.apply(this, args);
  };
  return descriptor;
}

// Property decorator
function Required(target: any, key: string) {
  // adds validation metadata
}

@Injectable
class UserService {
  @Log
  getUser(@Inject(TOKEN) id: number) {}
}
```

Angular uses decorators extensively: `@Component`, `@NgModule`, `@Injectable`, `@Input`, `@Output`.

---

## Q9. What are mapped types and template literal types?
**Answer:**
**Mapped types** create new types by transforming each property of an existing type:

```typescript
// Make all properties optional (like Partial<T>)
type MyPartial<T> = { [K in keyof T]?: T[K] };

// Make all properties nullable
type Nullable<T> = { [K in keyof T]: T[K] | null };

// Remove readonly
type Mutable<T> = { -readonly [K in keyof T]: T[K] };
```

**Template literal types** create string union types using template syntax:

```typescript
type EventName = "click" | "focus" | "blur";
type Handler = `on${Capitalize<EventName>}`; // "onClick" | "onFocus" | "onBlur"

type CSSProperty = `${string}-${string}`; // "background-color", "font-size", etc.

// Used in Angular forms:
type FormField = "name" | "email";
type ControlName = `${FormField}Control`; // "nameControl" | "emailControl"
```

---

## Q10. What are TypeScript enums and when should you avoid them?
**Answer:**
```typescript
// Numeric enum (default)
enum Direction { Up, Down, Left, Right } // 0, 1, 2, 3
Direction.Up // 0

// String enum (recommended — more readable)
enum Status { Active = "ACTIVE", Inactive = "INACTIVE" }

// Const enum — inlined at compile time (no runtime object)
const enum Size { Small = "S", Medium = "M", Large = "L" }

// Usage
let dir: Direction = Direction.Up;
let status: Status = Status.Active;
```

**When to avoid enums:**
- Numeric enums allow reverse mapping (`Direction[0] === "Up"`) which can be surprising.
- Enums generate JavaScript runtime code (extra bundle size).
- `const enum` can break with Babel/esbuild.

**Modern alternative:** Use `as const` union types:
```typescript
const Direction = { Up: "UP", Down: "DOWN" } as const;
type Direction = typeof Direction[keyof typeof Direction]; // "UP" | "DOWN"
```

---

## Q11. What is `readonly` and how does it differ from `const`?
**Answer:**
- `const` — prevents **variable reassignment** (the binding is constant).
- `readonly` — prevents **property mutation** on an object or interface.

```typescript
const arr = [1, 2, 3];
arr.push(4);   // ✓ array contents can change
arr = [5, 6];  // ❌ reassignment not allowed

interface Config { readonly apiUrl: string; }
const cfg: Config = { apiUrl: "http://api.example.com" };
cfg.apiUrl = "other"; // ❌ Property is readonly

// Readonly array
const readonlyArr: ReadonlyArray<number> = [1, 2, 3];
readonlyArr.push(4); // ❌
```

---

## Q12. What is optional chaining (`?.`) and nullish coalescing (`??`) in TypeScript?
**Answer:**
Both are JavaScript/TypeScript features for safe null/undefined handling:

```typescript
// Optional chaining — returns undefined instead of throwing
const city = user?.address?.city;    // undefined if user or address is null/undefined
const len  = str?.length;            // undefined if str is null
const first = arr?.[0];              // undefined if arr is null
const result = fn?.();               // undefined if fn is null

// Nullish coalescing — use default only for null/undefined (not 0 or "")
const name = user.name ?? "Anonymous"; // uses "Anonymous" only if null/undefined
const count = value ?? 0;             // uses 0 only if null/undefined

// Compare with || (uses default for ANY falsy value):
const n1 = 0 ?? 10;  // 0  (0 is not null/undefined)
const n2 = 0 || 10;  // 10 (0 is falsy)

// Nullish assignment
user.name ??= "Default"; // assign only if null/undefined
```

---

## Q13. What are TypeScript access modifiers in classes?
**Answer:**
```typescript
class BankAccount {
  public owner: string;         // accessible everywhere (default)
  private _balance: number;     // only within this class
  protected _pin: number;       // this class + subclasses
  readonly id: string;          // cannot be reassigned after construction
  #secretCode: string;          // private field (true JS private — not TypeScript-only)

  constructor(
    public name: string,        // shorthand — declares AND assigns public property
    private email: string       // shorthand — declares AND assigns private property
  ) {}

  get balance(): number { return this._balance; }
  set balance(val: number) {
    if (val < 0) throw new Error("Negative balance");
    this._balance = val;
  }
}
```

TypeScript `private` is compile-time only — it's accessible at runtime in JS. Use `#field` (ES2022 private fields) for true runtime privacy.

---

## Q14. What is type assertion and when should it be used?
**Answer:**
Type assertion tells the compiler "trust me, I know the type" — it does NOT perform runtime conversion:

```typescript
// as syntax (preferred)
const input = document.getElementById("name") as HTMLInputElement;
input.value = "hello"; // OK — HTMLInputElement has .value

// angle bracket syntax (not usable in JSX files)
const input = <HTMLInputElement>document.getElementById("name");

// Double assertion — force any incompatible type (use sparingly!)
const n = ("hello" as unknown) as number; // compiles but wrong at runtime

// Non-null assertion (!)
const el = document.getElementById("app")!; // assert non-null
el.addEventListener("click", handler);      // no null check needed
```

**When to use:** when you have more information than TypeScript can infer (DOM access, JSON parsing, third-party JS libraries). Prefer type guards over assertions for safety.

---

## Q15. What is strict mode in TypeScript and what does it enable?
**Answer:**
Enabling `"strict": true` in `tsconfig.json` activates a set of stricter checks:

| Flag | What it checks |
|---|---|
| `strictNullChecks` | `null`/`undefined` not assignable to non-nullable types |
| `strictFunctionTypes` | Stricter function parameter checking |
| `strictBindCallApply` | Checks `bind`, `call`, `apply` argument types |
| `strictPropertyInitialization` | Class properties must be assigned in constructor |
| `noImplicitAny` | Error on inferred `any` types |
| `noImplicitThis` | Error when `this` has implicit `any` type |

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler"
  }
}
```

Angular projects use `strict: true` by default. It catches the majority of runtime bugs at compile time.
