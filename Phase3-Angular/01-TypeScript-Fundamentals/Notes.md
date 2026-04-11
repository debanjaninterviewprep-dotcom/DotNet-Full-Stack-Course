# Topic 1: TypeScript Fundamentals

## Why TypeScript?

TypeScript is a **superset of JavaScript** that adds **static typing**. Angular is built entirely with TypeScript, so mastering it is a prerequisite.

```
JavaScript:  Dynamic typing, errors at runtime
TypeScript:  Static typing, errors at compile time → safer, more productive

TypeScript (.ts) → Compiler (tsc) → JavaScript (.js) → Browser
```

### Key Benefits

| Feature | JavaScript | TypeScript |
|---|---|---|
| Type safety | No | Yes |
| IntelliSense/Autocomplete | Limited | Excellent |
| Compile-time errors | No | Yes |
| Interfaces | No | Yes |
| Enums | No | Yes |
| Generics | No | Yes |
| Decorators | Experimental | Full support |

---

## Setting Up TypeScript

```bash
# Install TypeScript globally
npm install -g typescript

# Check version
tsc --version

# Initialize a TypeScript project
tsc --init    # Creates tsconfig.json

# Compile a single file
tsc hello.ts   # Outputs hello.js

# Watch mode (auto-compile on save)
tsc --watch
```

### tsconfig.json (Key Options)

```json
{
  "compilerOptions": {
    "target": "ES2022",           // Output JS version
    "module": "ES2022",           // Module system
    "strict": true,               // Enable all strict checks
    "esModuleInterop": true,      // Better import compatibility
    "outDir": "./dist",           // Output directory
    "rootDir": "./src",           // Source directory
    "declaration": true,          // Generate .d.ts files
    "sourceMap": true,            // Generate source maps for debugging
    "noImplicitAny": true,        // Error on implicit 'any'
    "strictNullChecks": true      // null/undefined are separate types
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

---

## Basic Types

### Primitive Types

```typescript
// String
let name: string = "Debanjan";
let greeting: string = `Hello, ${name}!`;  // Template literals

// Number (no int/float distinction — all numbers are floating point)
let age: number = 25;
let price: number = 19.99;
let hex: number = 0xff;
let binary: number = 0b1010;

// Boolean
let isActive: boolean = true;

// Null and Undefined
let empty: null = null;
let notDefined: undefined = undefined;

// BigInt (for very large numbers)
let bigNum: bigint = 100n;

// Symbol (unique identifier)
let sym: symbol = Symbol("id");
```

### Type Inference

```typescript
// TypeScript infers types when possible
let message = "Hello";   // Inferred as string
message = 42;            // ❌ Error: Type 'number' is not assignable to type 'string'

let count = 10;          // Inferred as number
let isValid = true;      // Inferred as boolean

// Best practice: Let TypeScript infer when obvious
let name = "Debanjan";        // ✅ Good — type is obvious
let items: string[] = [];     // ✅ Good — empty array needs annotation
```

### Any, Unknown, Never, Void

```typescript
// any — disables type checking (AVOID!)
let anything: any = "hello";
anything = 42;          // No error — but you lose all safety!
anything.foo();         // No error at compile time — crashes at runtime!

// unknown — safe version of any (MUST check type before using)
let value: unknown = "hello";
// value.toUpperCase();    // ❌ Error! Must check first
if (typeof value === "string") {
    value.toUpperCase();   // ✅ Okay — type narrowed
}

// void — no return value
function log(message: string): void {
    console.log(message);
}

// never — function never returns (throws or infinite loop)
function throwError(msg: string): never {
    throw new Error(msg);
}

function infiniteLoop(): never {
    while (true) {}
}
```

---

## Arrays & Tuples

### Arrays

```typescript
// Two syntax options (both equivalent)
let numbers: number[] = [1, 2, 3, 4, 5];
let names: Array<string> = ["Alice", "Bob", "Charlie"];

// Mixed types (union)
let mixed: (string | number)[] = [1, "hello", 2, "world"];

// Readonly array
let readonlyArr: readonly number[] = [1, 2, 3];
// readonlyArr.push(4);  // ❌ Error: Property 'push' does not exist

// Array methods — all work as in JavaScript
numbers.push(6);
numbers.pop();
numbers.map(n => n * 2);
numbers.filter(n => n > 3);
numbers.reduce((sum, n) => sum + n, 0);
```

### Tuples

Fixed-length arrays with specific types at each position.

```typescript
// Tuple — fixed structure
let person: [string, number] = ["Debanjan", 25];
let entry: [string, number, boolean] = ["Alice", 30, true];

// Accessing
let name = person[0];   // string
let age = person[1];    // number
// person[2];           // ❌ Error: Tuple has no element at index 2

// Named tuples (for readability)
type PersonTuple = [name: string, age: number, active: boolean];
let user: PersonTuple = ["Bob", 28, true];

// Rest elements in tuples
type StringNumberBooleans = [string, number, ...boolean[]];
let val: StringNumberBooleans = ["hello", 1, true, false, true];
```

---

## Objects & Type Aliases

### Object Types

```typescript
// Inline object type
let user: { name: string; age: number; email: string } = {
    name: "Debanjan",
    age: 25,
    email: "debanjan@example.com"
};

// Optional properties (?)
let config: { host: string; port?: number } = {
    host: "localhost"
    // port is optional
};

// Readonly properties
let point: { readonly x: number; readonly y: number } = { x: 10, y: 20 };
// point.x = 30;  // ❌ Error: Cannot assign to 'x'
```

### Type Aliases

```typescript
// Create reusable types
type User = {
    id: number;
    name: string;
    email: string;
    age?: number;        // Optional
    readonly createdAt: Date;  // Readonly
};

let user: User = {
    id: 1,
    name: "Debanjan",
    email: "debanjan@example.com",
    createdAt: new Date()
};

// Nested types
type Address = {
    street: string;
    city: string;
    zip: string;
};

type Employee = {
    name: string;
    role: string;
    address: Address;
};
```

---

## Union & Intersection Types

### Union Types (OR — `|`)

```typescript
// Value can be ONE of several types
let id: string | number;
id = "abc";    // ✅
id = 123;      // ✅
// id = true;  // ❌

// Union with literals
type Status = "active" | "inactive" | "pending";
let userStatus: Status = "active";
// userStatus = "deleted";  // ❌ Error

type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

// Type narrowing with unions
function printId(id: string | number) {
    if (typeof id === "string") {
        console.log(id.toUpperCase());  // TypeScript knows it's string
    } else {
        console.log(id.toFixed(2));     // TypeScript knows it's number
    }
}
```

### Intersection Types (AND — `&`)

```typescript
// Combine multiple types into one
type HasName = { name: string };
type HasAge = { age: number };
type HasEmail = { email: string };

type Person = HasName & HasAge & HasEmail;

let person: Person = {
    name: "Debanjan",
    age: 25,
    email: "debanjan@example.com"
};
// Must have ALL properties from all intersected types
```

---

## Interfaces

Interfaces define the **shape** of objects. Similar to type aliases but with some differences.

```typescript
interface User {
    id: number;
    name: string;
    email: string;
    age?: number;                   // Optional
    readonly createdAt: Date;       // Readonly
}

// Implementing
let user: User = {
    id: 1,
    name: "Debanjan",
    email: "debanjan@example.com",
    createdAt: new Date()
};

// Extending interfaces (inheritance)
interface Employee extends User {
    role: string;
    department: string;
    salary: number;
}

// Multiple inheritance
interface Manager extends Employee {
    team: Employee[];
    budget: number;
}

// Function type in interface
interface SearchFunc {
    (source: string, subString: string): boolean;
}

let search: SearchFunc = (src, sub) => src.includes(sub);

// Index signatures
interface StringMap {
    [key: string]: string;
}

let colors: StringMap = {
    red: "#ff0000",
    green: "#00ff00"
};
```

### Interface vs Type Alias

```typescript
// Interfaces can be extended/merged
interface Animal { name: string; }
interface Animal { sound: string; }  // ✅ Declaration merging
// Now Animal has both name AND sound

// Type aliases CANNOT be merged
type Car = { brand: string; };
// type Car = { speed: number; };  // ❌ Error: Duplicate identifier

// Use interface for: object shapes, class contracts, API responses
// Use type for: unions, intersections, mapped types, primitives
```

---

## Enums

Named groups of constants.

```typescript
// Numeric enum (default — auto-increments from 0)
enum Direction {
    Up,      // 0
    Down,    // 1
    Left,    // 2
    Right    // 3
}
let dir: Direction = Direction.Up;
console.log(dir);           // 0
console.log(Direction[0]);  // "Up" (reverse mapping)

// Custom values
enum HttpStatus {
    OK = 200,
    Created = 201,
    BadRequest = 400,
    NotFound = 404,
    ServerError = 500
}

// String enum (preferred — more readable in debugging)
enum Color {
    Red = "RED",
    Green = "GREEN",
    Blue = "BLUE"
}
console.log(Color.Red);  // "RED"

// Const enum (inlined at compile time — no runtime object)
const enum Size {
    Small = "S",
    Medium = "M",
    Large = "L"
}
let shirt: Size = Size.Medium;  // Compiled to: let shirt = "M";
```

---

## Functions

### Function Types

```typescript
// Named function with types
function add(a: number, b: number): number {
    return a + b;
}

// Arrow function
const multiply = (a: number, b: number): number => a * b;

// Optional parameters
function greet(name: string, greeting?: string): string {
    return `${greeting ?? "Hello"}, ${name}!`;
}
greet("Debanjan");           // "Hello, Debanjan!"
greet("Debanjan", "Hi");     // "Hi, Debanjan!"

// Default parameters
function createUser(name: string, role: string = "user"): object {
    return { name, role };
}

// Rest parameters
function sum(...numbers: number[]): number {
    return numbers.reduce((total, n) => total + n, 0);
}
sum(1, 2, 3, 4, 5);  // 15

// Function type alias
type MathOperation = (a: number, b: number) => number;
const divide: MathOperation = (a, b) => a / b;
```

### Function Overloading

```typescript
// Overload signatures
function format(value: string): string;
function format(value: number): string;
function format(value: string | number): string {
    if (typeof value === "string") {
        return value.trim().toUpperCase();
    }
    return value.toFixed(2);
}

format("  hello  ");  // "HELLO"
format(3.14159);       // "3.14"
```

---

## Generics

Write **reusable**, **type-safe** code that works with any type.

```typescript
// Without generics — lose type information
function identity(value: any): any {
    return value;  // Returns any — no type safety!
}

// With generics — preserve type information
function identity<T>(value: T): T {
    return value;
}
let str = identity<string>("hello");  // str: string
let num = identity<number>(42);       // num: number
let inferred = identity("auto");      // inferred: string (TypeScript infers T)

// Generic with arrays
function getFirst<T>(arr: T[]): T | undefined {
    return arr[0];
}
getFirst([1, 2, 3]);         // number | undefined
getFirst(["a", "b", "c"]);   // string | undefined

// Generic interfaces
interface ApiResponse<T> {
    data: T;
    status: number;
    message: string;
}

interface User { id: number; name: string; }
let response: ApiResponse<User> = {
    data: { id: 1, name: "Debanjan" },
    status: 200,
    message: "Success"
};

// Generic constraints
interface HasLength {
    length: number;
}

function logLength<T extends HasLength>(value: T): void {
    console.log(value.length);
}
logLength("hello");      // ✅ strings have length
logLength([1, 2, 3]);    // ✅ arrays have length
// logLength(42);         // ❌ numbers don't have length

// Multiple type parameters
function merge<T, U>(obj1: T, obj2: U): T & U {
    return { ...obj1, ...obj2 };
}
let result = merge({ name: "Debanjan" }, { age: 25 });
// result: { name: string } & { age: number }

// Generic classes
class DataStore<T> {
    private items: T[] = [];
    
    add(item: T): void { this.items.push(item); }
    get(index: number): T { return this.items[index]; }
    getAll(): T[] { return [...this.items]; }
}

let numberStore = new DataStore<number>();
numberStore.add(1);
numberStore.add(2);

let stringStore = new DataStore<string>();
stringStore.add("hello");
```

---

## Classes

```typescript
class Person {
    // Properties with access modifiers
    public name: string;
    private _age: number;
    protected email: string;
    readonly id: number;
    
    // Static property
    static count: number = 0;
    
    // Constructor
    constructor(name: string, age: number, email: string) {
        this.name = name;
        this._age = age;
        this.email = email;
        this.id = ++Person.count;
    }
    
    // Getter
    get age(): number {
        return this._age;
    }
    
    // Setter with validation
    set age(value: number) {
        if (value < 0) throw new Error("Age cannot be negative");
        this._age = value;
    }
    
    // Method
    greet(): string {
        return `Hi, I'm ${this.name}, age ${this._age}`;
    }
    
    // Static method
    static getCount(): number {
        return Person.count;
    }
}

// Shorthand constructor (parameter properties)
class Product {
    constructor(
        public name: string,
        public price: number,
        private _stock: number = 0
    ) {}
    // TypeScript auto-creates and assigns properties!
}

// Inheritance
class Employee extends Person {
    constructor(
        name: string,
        age: number,
        email: string,
        public role: string
    ) {
        super(name, age, email);
    }
    
    override greet(): string {
        return `${super.greet()}, Role: ${this.role}`;
    }
}

// Abstract class
abstract class Shape {
    abstract area(): number;        // Must be implemented
    abstract perimeter(): number;   // Must be implemented
    
    describe(): string {            // Concrete method — shared
        return `Area: ${this.area()}, Perimeter: ${this.perimeter()}`;
    }
}

class Circle extends Shape {
    constructor(private radius: number) { super(); }
    area(): number { return Math.PI * this.radius ** 2; }
    perimeter(): number { return 2 * Math.PI * this.radius; }
}

// Implementing interfaces
interface Printable {
    print(): void;
}

interface Serializable {
    serialize(): string;
}

class Document implements Printable, Serializable {
    constructor(public content: string) {}
    print(): void { console.log(this.content); }
    serialize(): string { return JSON.stringify({ content: this.content }); }
}
```

### Access Modifiers

| Modifier | Class | Subclass | Outside |
|---|---|---|---|
| `public` | ✅ | ✅ | ✅ |
| `protected` | ✅ | ✅ | ❌ |
| `private` | ✅ | ❌ | ❌ |
| `readonly` | Read only after construction |

---

## Utility Types

Built-in types for common transformations.

```typescript
interface User {
    id: number;
    name: string;
    email: string;
    age: number;
}

// Partial — all properties optional
type PartialUser = Partial<User>;
let update: PartialUser = { name: "New Name" };  // Only update what changed

// Required — all properties required
type RequiredUser = Required<User>;

// Pick — select specific properties
type UserSummary = Pick<User, "id" | "name">;
// Result: { id: number; name: string; }

// Omit — exclude specific properties
type UserWithoutEmail = Omit<User, "email">;
// Result: { id: number; name: string; age: number; }

// Record — key-value mapping
type Roles = Record<string, string[]>;
let permissions: Roles = {
    admin: ["read", "write", "delete"],
    user: ["read"]
};

// Readonly — all properties readonly
type ReadonlyUser = Readonly<User>;

// ReturnType — extract return type of function
function getUser() { return { id: 1, name: "Debanjan" }; }
type UserReturn = ReturnType<typeof getUser>;
// Result: { id: number; name: string; }

// Exclude / Extract (for unions)
type T1 = Exclude<"a" | "b" | "c", "a">;     // "b" | "c"
type T2 = Extract<"a" | "b" | "c", "a" | "f">; // "a"

// NonNullable
type T3 = NonNullable<string | null | undefined>;  // string
```

---

## Modules

```typescript
// user.ts — Named exports
export interface User {
    id: number;
    name: string;
}

export function createUser(name: string): User {
    return { id: Date.now(), name };
}

export const MAX_USERS = 100;

// app.ts — Named imports
import { User, createUser, MAX_USERS } from "./user";

// Default export (one per file)
// logger.ts
export default class Logger {
    log(msg: string) { console.log(`[LOG] ${msg}`); }
}

// app.ts
import Logger from "./logger";  // No braces for default

// Re-export
export { User, createUser } from "./user";

// Import everything
import * as UserModule from "./user";
UserModule.createUser("Debanjan");
```

---

## Decorators (Preview — Used Heavily in Angular)

Decorators are special functions that modify classes, methods, properties, or parameters. Angular uses them extensively (`@Component`, `@Injectable`, `@Input`).

```typescript
// Class decorator
function Logger(constructor: Function) {
    console.log(`Creating instance of: ${constructor.name}`);
}

@Logger
class UserService {
    getUser() { return { id: 1, name: "Debanjan" }; }
}
// Output: "Creating instance of: UserService"

// Decorator factory (returns decorator)
function Component(config: { selector: string; template: string }) {
    return function (constructor: Function) {
        console.log(`Component registered: ${config.selector}`);
    };
}

@Component({ selector: "app-root", template: "<h1>Hello</h1>" })
class AppComponent {}

// Property decorator
function Required(target: any, propertyKey: string) {
    console.log(`${propertyKey} is required`);
}

class User {
    @Required
    name!: string;
}
```

**Note:** Angular uses decorators extensively — `@Component`, `@NgModule`, `@Injectable`, `@Input`, `@Output`, `@ViewChild`, etc. You'll see them in every Angular file.

---

## Async/Await in TypeScript

```typescript
// Promises with types
function fetchUser(id: number): Promise<User> {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (id > 0) resolve({ id, name: "Debanjan" });
            else reject(new Error("Invalid ID"));
        }, 1000);
    });
}

// Async/await
async function getUser(id: number): Promise<User> {
    try {
        const user = await fetchUser(id);
        console.log(user.name);
        return user;
    } catch (error) {
        console.error(error);
        throw error;
    }
}

// Parallel execution
async function getAllData(): Promise<[User[], Product[]]> {
    const [users, products] = await Promise.all([
        fetchUsers(),
        fetchProducts()
    ]);
    return [users, products];
}
```

---

## Key Differences from C#

| Feature | C# | TypeScript |
|---|---|---|
| Type annotation | `int x = 5;` | `let x: number = 5;` |
| Null safety | `int?` (nullable) | `string \| null` (union) |
| Interfaces | Explicit implementation | Structural (duck typing) |
| Generics | `List<T>` | `Array<T>` or `T[]` |
| Async | `async Task<T>` | `async Promise<T>` |
| Access modifiers | `public/private/protected/internal` | `public/private/protected` |
| String interpolation | `$"Hello {name}"` | `` `Hello ${name}` `` |
| Enum | Backed by int | Number or string |
| Null check | `x?.Property` | `x?.property` (same!) |
| Pattern matching | `switch` expressions | Type guards / narrowing |

---

## Key Takeaways

| Concept | Summary |
|---|---|
| TypeScript | JavaScript + static types → safer code |
| Type inference | TS figures out types when it can |
| `any` vs `unknown` | `unknown` is safe — requires type check |
| Union types | `string \| number` — one of several types |
| Interfaces | Define object shapes; extendable |
| Generics | `<T>` — reusable, type-safe functions/classes |
| Enums | Named constants (prefer string enums) |
| Classes | Similar to C# — access modifiers, abstract, inheritance |
| Utility types | `Partial`, `Pick`, `Omit`, `Record` |
| Decorators | Metadata functions — core of Angular |

---

*Next Topic: Angular Setup & Architecture →*
