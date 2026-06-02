# Topic 3: Components & Props

> Senior-engineer reference notes for designing, typing, and composing React components. Covers function components, props contracts, advanced composition patterns (compound, polymorphic, render props, HOCs), TypeScript prop typing, accessibility, and pitfalls. Targets React 18.x / 19.

---

## 1. What Is a Component?

A **component** is a function (or, legacy, a class) that returns a tree of React elements (JSX). It is the **unit of reuse, testing, and rendering** in React.

```tsx
function Hello({ name }: { name: string }) {
  return <h1>Hello, {name}!</h1>;
}
```

### Function vs Class — and why function won

| Aspect | Function component | Class component (legacy) |
|---|---|---|
| Definition | Plain function returning JSX | `class X extends React.Component` |
| State / effects | Hooks (`useState`, `useEffect`, ...) | `this.state`, lifecycle methods |
| `this` binding | Not needed | Required (`bind`, arrow methods) |
| Code size | ~30 % smaller on average | More boilerplate |
| Composition | Custom hooks (any logic) | HOCs / render props only |
| React 18+ features | Concurrent, Suspense, Server Components — all hook-based | Limited |
| Recommendation | **Default for all new code** | Maintain only |

> Class components still work and will not be removed soon, but every new React feature (Suspense, Server Components, transitions, the new `use` API) ships hook-first. Treat them as legacy.

---

## 2. Anatomy of a Function Component

```tsx
import { useState, useEffect } from 'react';

interface CounterProps {
  initial?: number;
  step?: number;
  onChange?: (n: number) => void;
}

export function Counter({ initial = 0, step = 1, onChange }: CounterProps) {
  const [n, setN] = useState(initial);              // hook: state

  useEffect(() => { onChange?.(n); }, [n, onChange]); // hook: effect

  return (
    <button type="button" onClick={() => setN(n + step)}>
      Count: {n}
    </button>
  );
}
```

Pieces:
1. **Signature** — function taking exactly **one** props object.
2. **Hooks** — must be at the top level, never inside loops/conditionals.
3. **Return** — JSX, a string/number, an array, a fragment, `null`, or `false`.
4. **Export** — named or default (see §3).

---

## 3. Naming & File Conventions

- Components are **PascalCase** (`UserCard`, not `userCard`). React relies on the capital letter to distinguish components from intrinsic DOM elements (`<div>`).
- Files commonly named after the component: `UserCard.tsx`. Co-locate styles/tests: `UserCard.module.css`, `UserCard.test.tsx`, `UserCard.stories.tsx`.
- Hooks are **camelCase with `use` prefix**: `useUser`, `useDebounced`.

### Default vs named export

| | Default export | Named export |
|---|---|---|
| Syntax | `export default Foo` / `import Foo from './Foo'` | `export function Foo` / `import { Foo } from './Foo'` |
| Rename on import | Anything, silently | Must use `as` |
| Refactor safety | Weaker (typos compile) | Strong (compiler enforces) |
| Tree-shaking | Equivalent | Equivalent |
| Recommendation | OK for one-component files | **Preferred** in libraries / large codebases |

---

## 4. Props — The Component's Contract

Props are a **read-only** object passed from parent to child. Treat them like function arguments: pure inputs, never mutate them.

```tsx
function Badge({ label = 'New', tone = 'info' }: { label?: string; tone?: 'info' | 'warn' | 'error' }) {
  return <span className={`badge badge--${tone}`}>{label}</span>;
}
```

Defaults via destructuring (`label = 'New'`) is the **modern** way. The legacy `Component.defaultProps = {...}` static is **deprecated for function components** in React 18.3+ and will warn / be removed.

Rules of good props:
- **Required vs optional** — make everything required by default; only mark `?` when the component truly has a sensible default.
- **Boolean props** — name them positively (`disabled`, `loading`), default to `false`.
- **Callback props** — `on<Event>` (`onClick`, `onSelect`).
- **Avoid "god objects"** — `<Card config={huge}/>` hides the contract; spread fields when the list is short.

---

## 5. The `children` Prop

`children` is special: anything between `<Open>...</Close>` JSX tags becomes `props.children`.

```tsx
import { ReactNode } from 'react';

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="card">
      <h3>{title}</h3>
      <div className="card__body">{children}</div>
    </section>
  );
}
```

### Typing children

| Type | Allows |
|---|---|
| `ReactNode` | **Anything renderable** — JSX, strings, numbers, arrays, `null`, `false`. Default. |
| `ReactElement` | Exactly one JSX element (no strings/null). |
| `JSX.Element` | Same as `ReactElement` (legacy alias). |
| `(x: T) => ReactNode` | Render-prop child (function as children). |

`PropsWithChildren<T>` is shorthand:

```tsx
import { PropsWithChildren } from 'react';
type CardProps = PropsWithChildren<{ title: string }>;
```

### `React.Children` utilities

When you must inspect children (rare — prefer composition):

```tsx
import { Children, isValidElement, cloneElement } from 'react';

Children.count(children);          // number of top-level children
Children.toArray(children);        // flat array (assigns keys)
Children.map(children, (c) => …);  // map preserving keys
Children.only(children);           // throws unless exactly one
```

> Use sparingly — these break composition and make the API surprising. Prefer compound components with Context (§9).

---

## 6. Composition over Inheritance

React deliberately has no class-extension story for components. Reuse comes from **composition**.

### Containment (slots)

```tsx
function Dialog({ header, footer, children }: { header: ReactNode; footer: ReactNode; children: ReactNode }) {
  return (
    <div className="dialog">
      <header>{header}</header>
      <main>{children}</main>
      <footer>{footer}</footer>
    </div>
  );
}
```

### Specialization

```tsx
function ConfirmDialog(props: { onConfirm: () => void; children: ReactNode }) {
  return (
    <Dialog
      header={<h2>Are you sure?</h2>}
      footer={<button onClick={props.onConfirm}>Confirm</button>}
    >
      {props.children}
    </Dialog>
  );
}
```

`ConfirmDialog` "extends" `Dialog` purely by composition — no inheritance.

---

## 7. Spreading Props

```tsx
function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} />;
}
```

Useful when wrapping a DOM element so consumers can pass `id`, `aria-*`, `data-*`, `className`, etc.

### When spreading hurts

- Leaks unwanted props (`internalKey`, `theme`) onto the DOM → React warns about unknown HTML attributes.
- Hides the contract — readers can't see what's accepted.

### Filtering pattern

```tsx
function Avatar({ size = 'md', alt, ...rest }: AvatarProps) {
  // `size` is consumed by the wrapper; `rest` is forwarded.
  return <img alt={alt} {...rest} className={`avatar avatar--${size}`} />;
}
```

For a generic `omit` use a small helper or `lodash-es/omit`. Avoid passing the entire props object unfiltered to a DOM node.

---

## 8. Refs and `forwardRef`

Refs let parents reach a child's DOM node or imperative API.

### React 18 — `forwardRef`

```tsx
import { forwardRef } from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

export const TextInput = forwardRef<HTMLInputElement, InputProps>(
  function TextInput(props, ref) {
    return <input ref={ref} type="text" {...props} />;
  }
);
```

### React 19 — `ref` is just a prop

In React 19 you no longer need `forwardRef`; `ref` flows through like any other prop:

```tsx
// React 19+
function TextInput({ ref, ...props }: InputProps & { ref?: React.Ref<HTMLInputElement> }) {
  return <input ref={ref} {...props} />;
}
```

`useImperativeHandle` still exists for exposing a curated API instead of the raw node.

---

## 9. Pattern Catalogue

### 9.1 Polymorphic components — the `as` prop

A `Text` component that can render any element while keeping props correctly typed.

```tsx
import { ElementType, ComponentPropsWithoutRef, ReactNode } from 'react';

type TextOwnProps<E extends ElementType> = {
  as?: E;
  size?: 'sm' | 'md' | 'lg';
  children?: ReactNode;
};

type TextProps<E extends ElementType> =
  TextOwnProps<E> & Omit<ComponentPropsWithoutRef<E>, keyof TextOwnProps<E>>;

export function Text<E extends ElementType = 'p'>({
  as,
  size = 'md',
  children,
  ...rest
}: TextProps<E>) {
  const Tag = as ?? 'p';
  return <Tag className={`text text--${size}`} {...rest}>{children}</Tag>;
}

// Usage — TypeScript infers element-specific props:
<Text>Default paragraph</Text>
<Text as="label" htmlFor="email">Email</Text>
<Text as="a" href="/about">About</Text>
```

### 9.2 Compound components

Multiple components share state via Context, exposing a clean nested API.

```tsx
import { createContext, useContext, useState, ReactNode } from 'react';

interface TabsCtx { active: string; setActive: (id: string) => void; }
const Ctx = createContext<TabsCtx | null>(null);
const useTabs = () => {
  const c = useContext(Ctx);
  if (!c) throw new Error('Tabs.* must be inside <Tabs>');
  return c;
};

export function Tabs({ defaultValue, children }: { defaultValue: string; children: ReactNode }) {
  const [active, setActive] = useState(defaultValue);
  return <Ctx.Provider value={{ active, setActive }}>{children}</Ctx.Provider>;
}

Tabs.List = function List({ children }: { children: ReactNode }) {
  return <div role="tablist">{children}</div>;
};

Tabs.Tab = function Tab({ value, children }: { value: string; children: ReactNode }) {
  const { active, setActive } = useTabs();
  const selected = active === value;
  return (
    <button role="tab" aria-selected={selected} aria-controls={`panel-${value}`}
            id={`tab-${value}`} onClick={() => setActive(value)}>
      {children}
    </button>
  );
};

Tabs.Panel = function Panel({ value, children }: { value: string; children: ReactNode }) {
  const { active } = useTabs();
  if (active !== value) return null;
  return <div role="tabpanel" id={`panel-${value}`} aria-labelledby={`tab-${value}`}>{children}</div>;
};

// Consumer
<Tabs defaultValue="a">
  <Tabs.List>
    <Tabs.Tab value="a">A</Tabs.Tab>
    <Tabs.Tab value="b">B</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel value="a">Panel A</Tabs.Panel>
  <Tabs.Panel value="b">Panel B</Tabs.Panel>
</Tabs>
```

### 9.3 Render props (modern usage)

A child function that receives state and returns JSX. Mostly replaced by hooks, but still useful when you must expose state through JSX (e.g., to coordinate layout).

```tsx
function MousePosition({ children }: { children: (p: { x: number; y: number }) => ReactNode }) {
  const [p, setP] = useState({ x: 0, y: 0 });
  return <div onMouseMove={e => setP({ x: e.clientX, y: e.clientY })}>{children(p)}</div>;
}

<MousePosition>{({ x, y }) => <span>{x},{y}</span>}</MousePosition>
```

### 9.4 Higher-Order Components (HOCs)

A function that takes a component and returns an enhanced one. **Rarely** the right tool today — prefer custom hooks. Still appears in older codebases (`connect` from Redux, `withRouter`).

```tsx
function withAuth<P extends object>(Inner: React.ComponentType<P>) {
  return function Wrapped(props: P) {
    const user = useCurrentUser();
    if (!user) return <Login />;
    return <Inner {...props} />;
  };
}
```

Caveats: extra wrapper in the tree, unclear prop origin, ref forwarding gymnastics, harder TypeScript. Hooks usually win.

---

## 10. Controlled vs Uncontrolled (preview)

- **Controlled** — parent owns state, passes `value` + `onChange`.
- **Uncontrolled** — DOM owns state; parent reads via ref or `defaultValue`.

```tsx
<input value={v} onChange={e => setV(e.target.value)} />   // controlled
<input defaultValue="hi" ref={inputRef} />                 // uncontrolled
```

Full coverage in **Topic 5: Events & Forms**.

---

## 11. Purity & `React.memo`

A React component must be **pure during render**:
- Same props + state ⇒ same output.
- No side effects (no fetch, no DOM writes, no `Math.random` storage) in the render body — put those in event handlers or `useEffect`.

`React.memo` skips re-rendering when props are shallow-equal:

```tsx
const Row = React.memo(function Row({ item }: { item: Item }) { … });
```

Works only if callbacks/objects passed in are stable (`useCallback`, `useMemo`). Full performance treatment in **Topic 10**.

---

## 12. TypeScript Prop Typing — Patterns

### `interface` vs `type`

Both work. `interface` is open (declaration merging); `type` is closed but supports unions/intersections. Pick one per codebase and stick with it.

### Required vs optional

```tsx
interface Props {
  id: string;          // required
  label?: string;      // optional
}
```

### Discriminated unions for variants

Express "either icon-only or text" with a union — TypeScript enforces the right combination.

```tsx
type ButtonProps =
  | { kind: 'text'; label: string; icon?: never }
  | { kind: 'icon'; icon: ReactNode; label?: never };

function Button(p: ButtonProps) {
  return p.kind === 'text' ? <button>{p.label}</button> : <button aria-label="">{p.icon}</button>;
}
```

### Generic components

```tsx
interface ListProps<T> {
  items: readonly T[];
  renderItem: (item: T, index: number) => ReactNode;
  getKey: (item: T) => string | number;
}

export function List<T>({ items, renderItem, getKey }: ListProps<T>) {
  return <ul>{items.map((it, i) => <li key={getKey(it)}>{renderItem(it, i)}</li>)}</ul>;
}
```

### Utility types you will use constantly

| Utility | Use case |
|---|---|
| `Pick<T, K>` | Expose only some props of an underlying component |
| `Omit<T, K>` | Hide internal props from consumers |
| `Partial<T>` | Make all fields optional (useful for defaults / patches) |
| `Required<T>` | Inverse of `Partial` |
| `Readonly<T>` | Convey immutability of a complex prop |
| `ComponentPropsWithoutRef<E>` | Inherit DOM element props without `ref` |

> **Avoid `React.FC`.** It implicitly adds `children`, breaks generic inference, and is unidiomatic in modern React. Type props directly.

---

## 13. Accessibility & Semantics

A reusable component should produce **semantic HTML** by default and let consumers override only when necessary.

- A clickable thing is a `<button>`. A navigation thing is an `<a href>`. Don't paint `<div onClick>`.
- Forward `aria-*` props (`aria-label`, `aria-describedby`) — they're plain HTML attributes and belong on the underlying element.
- Manage focus on overlays: trap focus inside a modal, restore focus on close.
- Provide an accessible name for icon-only controls (`aria-label="Close"`).
- Test keyboard paths — every interaction must work without a mouse.

---

## 14. File / Folder Organisation

Two common approaches:

| Approach | Layout | When |
|---|---|---|
| **Type folders** | `components/`, `hooks/`, `pages/` | Tiny apps |
| **Feature folders** | `features/auth/`, `features/cart/` (each contains its own `components/`, `hooks/`, `api/`) | Real applications |

Co-locate everything a component owns:

```
features/cart/
  CartItem/
    CartItem.tsx
    CartItem.module.css
    CartItem.test.tsx
    CartItem.stories.tsx
    index.ts        ← re-export
```

---

## 15. Testing Components (preview)

Use **React Testing Library** — assert what the user sees, not implementation details.

```tsx
import { render, screen } from '@testing-library/react';

test('renders label', () => {
  render(<Button>Save</Button>);
  expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument();
});
```

Full treatment in **Topic 11**.

---

## 16. Storybook

Storybook is the de-facto component catalogue: each component gets a `*.stories.tsx` documenting variants, edge cases, and accessibility. Add the `@storybook/addon-a11y` addon to fail builds on accessibility regressions. (Optional but highly recommended for libraries.)

---

## 17. Common Pitfalls

- **Missing `key` on lists** — React warns and reconciliation degrades.
- **Mutating props** — props are frozen contractually; copy then change.
- **New callback / object every render** passed into `memo`-ised children defeats memoisation.
- **Prop drilling** — passing the same prop through 5 layers; lift to Context or split components.
- **God components** — 600-line file doing fetching + layout + form + animation. Split by responsibility.
- **`useEffect` for derived data** — compute it during render instead.

---

## 18. Anti-Patterns Gallery

| Anti-pattern | Better |
|---|---|
| `<div onClick>` for buttons | `<button type="button">` |
| Boolean prop explosion (`isPrimary`, `isDanger`, `isSmall`) | Single `variant` + `size` enum |
| Returning different component shapes from one component | Two components or a discriminated union |
| Index as `key` for reorderable lists | Stable id |
| Inline component definitions inside parent's render | Hoist outside — inline def remounts every render |
| Reading state in `useEffect` only to set another state | Compute it during render |

---

## 19. Component Design Checklist

- [ ] Single responsibility — one job, one place to change.
- [ ] Props are minimal and predictable; required by default.
- [ ] Sensible defaults; common case is one line of JSX.
- [ ] Accepts `className` / `style` for cosmetic overrides.
- [ ] Forwards `ref` when wrapping a DOM element.
- [ ] Produces semantic HTML; forwards `aria-*`.
- [ ] Pure render — no side effects in the body.
- [ ] Has a Storybook story and a smoke test.
- [ ] TypeScript types are as strict as possible.

---

## Key Takeaways

- Default to **function components + hooks**. Classes are legacy.
- **Props are read-only**, `children` is special, use **composition**, not inheritance.
- Pick a **pattern** matching the problem: containment, specialization, polymorphic `as`, compound, render prop. HOCs only when forced.
- TypeScript turns props into a real contract — use generics, discriminated unions, and `ComponentPropsWithoutRef` for polymorphism.
- Build for **accessibility** from the first commit — semantic HTML, ARIA, keyboard.
- Keep components **pure**, **small**, and **co-located** with their styles/tests/stories.

---

End of Topic 3 Notes.
