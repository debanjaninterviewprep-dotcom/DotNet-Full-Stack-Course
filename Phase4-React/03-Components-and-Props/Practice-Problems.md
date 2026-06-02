# Topic 3: Components & Props — Practice Problems

> Five graded problems. Each lists the **concept** under test, **requirements**, **ARIA expectations**, **TypeScript expectations**, and a **starter snippet**. Solutions live in `PracticeProblemsSolutions/` (create as you go).

---

## Problem 1 — `Button` with variants & loading state

**Concept tag:** Props, discriminated variants, accessibility, defaults via destructuring.

**Difficulty:** Easy.

### Requirements

- Build a `<Button>` component that wraps `<button type="button">` by default.
- Variants (`variant` prop): `'primary' | 'secondary' | 'danger'`. Default `'primary'`.
- Sizes (`size` prop): `'sm' | 'md' | 'lg'`. Default `'md'`.
- Supports `disabled`, `type` (`'button' | 'submit' | 'reset'`), `onClick`, `children`, `className`.
- Supports `loading?: boolean`. While loading:
  - Button is **not clickable** (`disabled` is effectively true).
  - Render a spinner before `children`.
  - Set `aria-busy="true"`.
- Forwards any extra DOM props (`id`, `data-*`, `aria-*`).
- Forwards `ref` to the underlying `<button>` (use `forwardRef` or React 19 ref-as-prop).

### ARIA expectations

- `aria-busy="true"` while loading.
- `aria-disabled="true"` mirrors `disabled`.
- Icon-only usage must be possible by passing `aria-label` (test by spreading rest).

### TypeScript expectations

- Extend `React.ButtonHTMLAttributes<HTMLButtonElement>` so all native props are accepted.
- Variant/size are **string literal unions**, not arbitrary strings.

### Starter

```tsx
import { forwardRef, ButtonHTMLAttributes, ReactNode } from 'react';

type Variant = 'primary' | 'secondary' | 'danger';
type Size = 'sm' | 'md' | 'lg';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  children?: ReactNode;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  function Button({ variant = 'primary', size = 'md', loading, disabled, children, className, ...rest }, ref) {
    // TODO: render spinner, merge classes, set aria-busy
    return null;
  }
);
```

---

## Problem 2 — `<UserCard/>` composition with replaceable `Avatar`

**Concept tag:** Containment, render props, specialization, optional callbacks.

**Difficulty:** Easy–Medium.

### Requirements

- Build three components: `Avatar`, `UserMeta`, `UserActions`.
- Build `<UserCard user={...}/>` that composes the three.
- `UserCard` accepts:
  - `user: { id: string; name: string; avatarUrl?: string; role: string; }`.
  - `onFollow?: (userId: string) => void` — when provided, render a "Follow" button inside `UserActions`.
  - `renderAvatar?: (user) => ReactNode` — optional **render prop** to override the default `Avatar`.
- `UserActions` must accept `children` so consumers can add custom action buttons.

### ARIA expectations

- Avatar's `<img>` always has an `alt` (default to user name).
- Action buttons have visible text or `aria-label`.
- `UserCard` root is an `<article>` with `aria-labelledby` pointing at the name.

### TypeScript expectations

- Define a `User` type once and reuse.
- `renderAvatar` is typed as `(user: User) => ReactNode`.
- No `any`.

### Starter

```tsx
interface User { id: string; name: string; avatarUrl?: string; role: string; }

interface UserCardProps {
  user: User;
  onFollow?: (id: string) => void;
  renderAvatar?: (user: User) => React.ReactNode;
  children?: React.ReactNode;
}

export function UserCard({ user, onFollow, renderAvatar, children }: UserCardProps) {
  return (
    <article aria-labelledby={`u-${user.id}`}>
      {renderAvatar ? renderAvatar(user) : <Avatar src={user.avatarUrl} alt={user.name} />}
      <UserMeta id={`u-${user.id}`} name={user.name} role={user.role} />
      <UserActions>
        {onFollow && <button onClick={() => onFollow(user.id)}>Follow</button>}
        {children}
      </UserActions>
    </article>
  );
}
```

---

## Problem 3 — Polymorphic `<Text as="..."/>`

**Concept tag:** Polymorphic components, generics, `ComponentPropsWithoutRef`.

**Difficulty:** Medium.

### Requirements

- Build `<Text>` that renders `<p>` by default.
- Accepts an `as` prop that may be **any intrinsic HTML element** (`'p' | 'span' | 'label' | 'h1' | ...`).
- Accepts custom props: `size?: 'sm' | 'md' | 'lg'`, `weight?: 'normal' | 'bold'`, `children?: ReactNode`.
- Forwards **all native props** of the element chosen via `as`. Example: `as="label"` must accept `htmlFor`; `as="a"` must accept `href`; `as="img"` must require `src` and `alt` (since intrinsic typings demand them — test that TS errors when missing).
- Forwards `ref` correctly typed to the chosen element.

### ARIA expectations

- No baked-in role — the chosen element brings its own semantics.
- Component must not strip `aria-*` / `data-*` attributes.

### TypeScript expectations

- Use a generic `<E extends ElementType>`.
- Use `Omit<ComponentPropsWithoutRef<E>, keyof OwnProps>` to avoid prop collision.
- Default generic param: `'p'`.

### Starter

```tsx
import { ElementType, ComponentPropsWithoutRef, ReactNode } from 'react';

type TextOwn<E extends ElementType> = {
  as?: E;
  size?: 'sm' | 'md' | 'lg';
  weight?: 'normal' | 'bold';
  children?: ReactNode;
};

export type TextProps<E extends ElementType> =
  TextOwn<E> & Omit<ComponentPropsWithoutRef<E>, keyof TextOwn<E>>;

export function Text<E extends ElementType = 'p'>(props: TextProps<E>) {
  const { as, size = 'md', weight = 'normal', children, ...rest } = props;
  const Tag = (as ?? 'p') as ElementType;
  return <Tag data-size={size} data-weight={weight} {...rest}>{children}</Tag>;
}
```

### Test cases (must compile / not compile)

```tsx
<Text>Hi</Text>                                       // ✅
<Text as="label" htmlFor="x">Email</Text>             // ✅
<Text as="a" href="/about">About</Text>               // ✅
<Text as="a">Missing href is OK</Text>                // ✅ (href optional)
// @ts-expect-error — img requires alt
<Text as="img" src="/x.png" />
// @ts-expect-error — htmlFor not valid on <p>
<Text htmlFor="x">no</Text>
```

---

## Problem 4 — Compound `<Tabs>` with full keyboard navigation

**Concept tag:** Compound components, Context, ARIA tablist pattern, focus management.

**Difficulty:** Medium–Hard.

### Requirements

- Build a compound component:
  - `<Tabs defaultValue="a" onChange?>` — wrapper, owns active state.
  - `<Tabs.List>` — wraps tab buttons.
  - `<Tabs.Tab value="a">` — clickable tab.
  - `<Tabs.Panel value="a">` — content shown only when active.
- Controlled (`value` + `onChange`) **and** uncontrolled (`defaultValue`) modes both supported.
- Keyboard navigation inside `Tabs.List`:
  - **`ArrowRight`** / **`ArrowLeft`** — move focus to next/previous tab, wrap around.
  - **`Home`** / **`End`** — jump to first / last tab.
  - **`Enter`** / **`Space`** — activate the focused tab (if not already active).
  - Tabs that are not active must have `tabIndex={-1}`; the active tab has `tabIndex={0}` (roving tabindex).
- Activating a tab moves focus to its panel? **No** — keep focus on the tab button (standard pattern). Panel must be reachable via Tab key (`tabIndex={0}`).
- Throw a clear error if `Tabs.Tab` is rendered outside `<Tabs>`.

### ARIA expectations

- `<Tabs.List>` → `role="tablist"`, optional `aria-label`.
- `<Tabs.Tab>` → `role="tab"`, `aria-selected`, `aria-controls={panelId}`, `id={tabId}`.
- `<Tabs.Panel>` → `role="tabpanel"`, `aria-labelledby={tabId}`, `id={panelId}`, `tabIndex={0}`.
- Inactive panels must be unmounted **or** hidden with `hidden` attribute (pick one and document).

### TypeScript expectations

- Internal context type is private (not exported).
- Each subcomponent has its own `Props` type.
- `value` / `onChange` typed against the union of allowed values? Stretch goal: make `Tabs` generic over the value union.

### Starter

```tsx
import { createContext, useContext, useState, useCallback, KeyboardEvent, ReactNode } from 'react';

interface Ctx {
  active: string;
  setActive: (v: string) => void;
  registerTab: (v: string) => number;
  values: string[];
}
const TabsCtx = createContext<Ctx | null>(null);
const useTabs = () => {
  const c = useContext(TabsCtx);
  if (!c) throw new Error('Tabs.* must be used inside <Tabs>');
  return c;
};

export function Tabs({ defaultValue, value, onChange, children }: {
  defaultValue?: string; value?: string; onChange?: (v: string) => void; children: ReactNode;
}) {
  // TODO: controlled vs uncontrolled, keyboard handler shared via context, registerTab order
  return null;
}

Tabs.List = function List(props: { children: ReactNode; 'aria-label'?: string }) { /* … */ return null; };
Tabs.Tab  = function Tab(props: { value: string; children: ReactNode; disabled?: boolean }) { /* … */ return null; };
Tabs.Panel = function Panel(props: { value: string; children: ReactNode }) { /* … */ return null; };
```

---

## Problem 5 — Typed component library (capstone)

**Concept tag:** Library packaging, shared types, Storybook, Vite library mode, declaration emit.

**Difficulty:** Hard.

### Requirements

Build a small UI library `@yourname/ui` containing:

1. `Button` (from Problem 1).
2. `Input` — labelled text input, `error` state, `helperText`, forwards `ref`.
3. `Modal` — portal-based dialog, focus trap, `Escape` to close, restores focus to opener on close.
4. `Tooltip` — appears on hover and focus, `Escape` dismisses, positioned via the native `<dialog>` or a portal.
5. `Dropdown` (menu) — keyboard navigable (`ArrowUp`/`ArrowDown`/`Home`/`End`/`Escape`), closes on outside click.

### Architectural rules

- Each component lives in its own folder with `Component.tsx`, `Component.types.ts`, `Component.module.css`, `Component.stories.tsx`, `Component.test.tsx`, `index.ts`.
- A **shared** `types.ts` exports `Size`, `Variant`, `BaseProps` and is re-used by every component.
- Single barrel export: `src/index.ts` re-exports each component and its `Props` type.
- Bundled with **Vite library mode** (`build.lib`) producing **ESM + CJS** + a **single `.d.ts`** generated by `vite-plugin-dts`.
- `peerDependencies`: `react`, `react-dom` (do not bundle them).
- `package.json` has correct `main`, `module`, `types`, `exports` map, `sideEffects: false`.
- `npm pack` produces a tarball that another app can `npm install ./pack.tgz` and consume with full IntelliSense.
- Storybook configured (`@storybook/react-vite`); every component has at least: **default**, **all variants**, **disabled**, **error/empty**, **dark mode** stories.
- `@storybook/addon-a11y` enabled — no axe violations on default stories.

### ARIA expectations

- `Modal` — `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, focus trap, restores focus.
- `Tooltip` — `role="tooltip"`, anchor uses `aria-describedby={tooltipId}`.
- `Dropdown` — `role="menu"`, items `role="menuitem"`, trigger has `aria-haspopup="menu"` / `aria-expanded`.
- `Input` — `<label htmlFor>` linked, `aria-invalid`, `aria-describedby={helperId}` when `error` present.

### TypeScript expectations

- **Zero `any`.** Strict mode on (`strict: true`, `noUncheckedIndexedAccess: true`).
- Each component exports its `Props` type.
- Generic components (e.g., `Dropdown<T>` with `items: T[]`) preserve item type through to `onSelect(item: T)`.

### Starter — `package.json` snippet

```jsonc
{
  "name": "@yourname/ui",
  "version": "0.1.0",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  },
  "sideEffects": false,
  "peerDependencies": { "react": ">=18", "react-dom": ">=18" },
  "scripts": {
    "build": "vite build && tsc --emitDeclarationOnly",
    "storybook": "storybook dev -p 6006",
    "pack": "npm run build && npm pack"
  }
}
```

### Acceptance demo

In a separate Vite app:

```bash
npm install ../yourname-ui-0.1.0.tgz
```

```tsx
import { Button, Modal } from '@yourname/ui';

export function App() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button onClick={() => setOpen(true)}>Open</Button>
      <Modal open={open} onClose={() => setOpen(false)} title="Hi">Hello!</Modal>
    </>
  );
}
```

— must compile, render, and pass keyboard / a11y checks.

---

## Global Checklist (all problems)

- [ ] Strict TypeScript — no `any`, no `// @ts-ignore`.
- [ ] Every interactive component has a Storybook story.
- [ ] Every component has at least one React Testing Library test asserting role-based queries.
- [ ] All clickable things use `<button>` or `<a>` — no `<div onClick>`.
- [ ] All inputs have associated `<label>`.
- [ ] All icon-only controls expose `aria-label`.
- [ ] No `console.log` left in committed code.
- [ ] No mutation of `props` or array prop contents.
- [ ] No ESLint warnings (`react/jsx-key`, `react-hooks/exhaustive-deps` clean).

---

End of Practice Problems for Topic 3.
