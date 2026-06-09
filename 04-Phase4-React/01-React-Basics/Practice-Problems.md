# Topic 1: React & JSX Fundamentals — Practice Problems

A progressive set of exercises designed to take you from "JSX looks like HTML" to building a small, typed, accessible component library. Attempt problems in order — each builds on prior concepts. Prefer TypeScript (`.tsx`) and React 18+ throughout. Keep `strict: true` in `tsconfig.json`.

> Refer to `Notes.md` in this folder for the underlying concepts (JSX rules, rendering model, hooks intro, accessibility patterns, common pitfalls).

---

## Problem 1 (Easy) — JSX Basics & Rendering

**Concepts:** JSX syntax rules, expressions in braces, attribute naming, self-closing tags, comments, keys.

### 1a. HTML → JSX conversion
Convert the following HTML block to valid JSX. Identify and fix every JSX violation.

```html
<div class="profile-card" style="padding: 12px; background-color: #fafafa;">
  <label for="email">Email</label>
  <input type="email" id="email" tabindex="0" autofocus>
  <img src="/me.png">
  <!-- profile footer -->
  <br>
</div>
```

**Requirements:**
- Replace `class` → `className`, `for` → `htmlFor`, `tabindex` → `tabIndex`, `autofocus` → `autoFocus`.
- Convert inline `style` from a string to an object: `style={{ padding: 12, backgroundColor: '#fafafa' }}`.
- Self-close `<input>`, `<img>` (with `alt`), `<br />`.
- Replace HTML comments with `{/* ... */}`.

**Pitfalls to avoid:** mixing kebab-case with camelCase; forgetting `alt` on images (a11y); using a string for `style`.

### 1b. `Card` component with fragments and conditionals
Build `Card.tsx` with this signature:

```tsx
type CardProps = { title?: string; footer?: React.ReactNode; children: React.ReactNode };
```

**Requirements:**
- Render `title` only when provided (use `&&` short-circuit).
- Render `footer` inside a `<footer>` element only if it's a non-empty node.
- Use a fragment (`<>...</>`) when no extra wrapper is needed inside the body.
- Apply at least one inline style derived from a prop (e.g. `elevated?: boolean`).

### 1c. Lists & the index-as-key bug
Render a list of `{ id: string; label: string }` items.

**Requirements:**
- First version: use `key={index}` and add a controlled `<input>` per row. Insert a new item at the **top** of the list and observe the input values shifting.
- Second version: use `key={item.id}` and verify inputs stay aligned with their original row.
- Briefly comment in the code why the bug occurred (reconciliation reuses DOM nodes by key position).

### 1d. Expression behavior in JSX
Render the following and explain (in a code comment) what shows up in the DOM:

```tsx
{true && 'shown'}        // ?
{false && 'hidden'}      // ?
{0 && 'zero-bug'}        // ?  (classic falsy pitfall)
{null}                   // ?
{undefined}              // ?
{[1, 2, 3]}              // ?
```

**Pitfall:** `{count && <Badge/>}` renders literal `0` when `count === 0`. Use `count > 0 && ...` or a ternary instead.

---

## Problem 2 (Easy-Medium) — Conditional & List Rendering

**Concepts:** branching strategies in JSX (ternary vs `&&` vs early return), lookup objects, mapping configs to UI.

### 2a. Notifications panel with four states
Build `<NotificationsPanel status data error />` where `status: 'idle' | 'loading' | 'error' | 'success'`.

**Expected behavior:**
- `idle` → render nothing (return `null`).
- `loading` → render a `<Spinner />` and a `role="status"` live region with text "Loading…".
- `error` → render `error.message` inside `role="alert"`.
- `success` and `data.length === 0` → render an empty state ("No notifications").
- `success` and `data.length > 0` → render the list.

**Requirements:**
- Implement once with a `switch (status)` returning JSX, then refactor to a lookup object: `const views = { idle: ..., loading: ... }`.
- No nested ternaries deeper than one level.

### 2b. `<Menu/>` from a config array with submenus
Given:

```ts
type MenuItem = { label: string; href?: string; children?: MenuItem[] };
const config: MenuItem[] = [
  { label: 'Home', href: '/' },
  { label: 'Products', children: [{ label: 'New', href: '/new' }, { label: 'Sale', href: '/sale' }] },
];
```

**Requirements:**
- Render recursively. A node with `children` renders a nested `<ul>`.
- Use stable keys (`label` is fine for static config; document why you'd switch to `id` for dynamic data).
- Mark the active item with `aria-current="page"`.

### 2c. Filter toggle: ternary vs short-circuit
Build a todo list with a filter: `'all' | 'active' | 'done'`.

**Requirements:**
- Implement the filter button group three ways and pick the cleanest:
  1. `filter === 'all' ? <AllList/> : filter === 'active' ? <ActiveList/> : <DoneList/>`
  2. `{filter === 'all' && <AllList/>}` chained for each state.
  3. **Early-return pattern** inside a render helper function.
- Show the rendered count in the heading: "Showing 3 of 12".

### 2d. Bonus — empty/zero pitfall
Add a counter pill: `{unread && <Badge>{unread}</Badge>}`. Reproduce the `0` bug then fix it with `unread > 0 && ...`.

---

## Problem 3 (Medium) — Components, Props & Children

**Concepts:** composition, `children`, render props, polymorphic typing.

### 3a. `<Modal/>` with focus management
Build a controlled modal:

```tsx
type ModalProps = {
  open: boolean;
  title: string;
  children: React.ReactNode;
  onClose: () => void;
};
```

**Requirements:**
- Render `null` when `open === false`.
- On open: move focus to the close button; on close: restore focus to the previously focused element.
- Close on `Escape` key and on backdrop click (but not when clicking the modal body).
- Use `role="dialog"`, `aria-modal="true"`, `aria-labelledby` referencing the title id.

**Pitfall:** trapping focus is non-trivial — for this exercise, simple focus move + restore is enough; document the limitation.

### 3b. `<List items renderItem/>` — render-prop pattern
```tsx
type ListProps<T> = {
  items: readonly T[];
  renderItem: (item: T, index: number) => React.ReactNode;
  getKey: (item: T) => string;
  empty?: React.ReactNode;
};
```

**Requirements:**
- Generic over `T`. Compile under `strict: true` with no `any`.
- Render `empty` when `items.length === 0`; default to `null`.
- Demo with two different shapes (e.g. `User` and `Product`) using the same `<List/>`.

### 3c. `<Switch>` / `<Match/>` declarative branching
Replicate Solid.js-style branching:

```tsx
<Switch fallback={<Empty />}>
  <Match when={status === 'loading'}><Spinner /></Match>
  <Match when={status === 'error'}><ErrorView /></Match>
  <Match when={status === 'success'}><Data /></Match>
</Switch>
```

**Requirements:**
- `Switch` iterates `React.Children.toArray` and returns the first `Match` whose `when` is truthy, else `fallback`.
- Type both components; ensure non-`Match` children are ignored with a clear runtime warning in dev.

### 3d. TypeScript polish
- All props typed with `interface` or `type` — no `any`, no `Function`.
- Use `React.PropsWithChildren<T>` where appropriate.
- Export prop types alongside components.

---

## Problem 4 (Medium-Hard) — Hooks Intro

**Concepts:** `useState`, `useEffect`, `useRef`, custom hooks, cleanup.

### 4a. Bounded counter with `onChange` callback
```tsx
type CounterProps = { min?: number; max?: number; step?: number; value?: number; onChange?: (n: number) => void };
```

**Requirements:**
- Controlled OR uncontrolled (if `value` is provided, treat as controlled).
- Disable `+`/`−` at bounds; show bounds in `aria-valuemin`/`aria-valuemax`.
- Fire `onChange` only when the value actually changes (avoid re-firing on identical clicks).

### 4b. Stopwatch with `useRef` for the interval id
**Requirements:**
- Buttons: Start, Stop, Reset, Lap.
- Store the interval id in a `useRef<number | null>(null)` — **not** in `useState` (avoid re-renders).
- Clear the interval in `useEffect` cleanup on unmount.
- Display elapsed time as `mm:ss.cs`.

**Pitfall:** stale closures — if you read `seconds` inside `setInterval`, use the functional updater `setSeconds(s => s + 1)`.

### 4c. `useToggle` + dark-mode persistence
Custom hook:

```tsx
function useToggle(initial = false): readonly [boolean, () => void, (v: boolean) => void] { /* ... */ }
```

**Requirements:**
- Build a `<DarkModeToggle/>` that uses `useToggle` and persists the value to `localStorage` under key `theme`.
- On mount, hydrate from `localStorage` (guard for SSR — `typeof window !== 'undefined'`).
- Apply the theme by toggling a `data-theme="dark"` attribute on `document.documentElement`.

### 4d. Auto-focus input with `useRef`
Build `<AutoFocusInput label />`.

**Requirements:**
- Focus the input on mount via `useEffect` + `inputRef.current?.focus()`.
- Expose an imperative `focus()` method via `useImperativeHandle` (with `forwardRef`).
- Verify focus does **not** re-trigger on every re-render.

---

## Problem 5 (Hard) — Mini Component Library

**Concept:** integrate everything — TS, a11y, styling, composition.

Build a primitives library under `src/components/` with the following five components:

| Component | Key props | A11y notes |
|-----------|-----------|------------|
| `Button`  | `variant: 'primary' \| 'secondary' \| 'ghost'`, `size`, `loading`, `disabled`, `iconLeft`, `iconRight` | Native `<button>`; `aria-busy` while loading; visible focus ring |
| `Input`   | `label`, `error`, `hint`, `id?`, all standard `<input>` props | Auto-generated id linking `<label>`/`<input>`/`aria-describedby` for hint+error |
| `Card`    | `title?`, `footer?`, `elevated?`, `as?` (polymorphic) | Use `<section>` with `aria-labelledby` when `title` set |
| `Badge`   | `tone: 'neutral' \| 'success' \| 'warning' \| 'danger'`, `children` | Decorative by default; if status, use `role="status"` |
| `Spinner` | `size`, `label?` | `role="status"` with visually-hidden label text |

### 5a. Implementation requirements
- Each component lives in its own folder: `Button/Button.tsx`, `Button/Button.module.css`, `Button/index.ts`, `Button/README.md`.
- Strict TS prop interfaces exported from `index.ts`. No `any`.
- Default styling via **CSS Modules**; tokens (colors, spacing, radius) defined in a single `tokens.css` imported once.
- Forward refs where a consumer would reasonably want them (`Button`, `Input`).
- All interactive components have visible `:focus-visible` styles.

### 5b. "User Profile" demo page
Compose all five primitives into a single page at `src/pages/UserProfile.tsx`:

- `Card` titled "User Profile" containing avatar, name, role `Badge`, bio.
- An edit form with two `Input`s (name, email) and a primary `Button` ("Save") + secondary `Button` ("Cancel").
- While saving, the Save button shows `loading` (renders `Spinner` inside, sets `aria-busy`).
- All form errors render inline below the input via the `error` prop.

### 5c. Per-component README
Each `README.md` documents:
- **Props table** (name, type, default, description).
- **A11y notes** (roles, ARIA, focus behavior).
- **Usage example** (one minimal snippet).
- **Don'ts** (e.g. "Don't put `Spinner` outside a live region if it conveys status").

### 5d. Verification
- `npm run build` passes with `strict: true`.
- No `console.error` / `console.warn` in browser devtools when rendering the demo page.
- Tab order through the form is logical; Escape never traps the user.

---

## Submission Checklist

Before marking the topic complete, verify every item:

1. [ ] `tsconfig.json` has `"strict": true` and the project compiles cleanly.
2. [ ] No `any`, no `// @ts-ignore`, no `Function` types in committed code.
3. [ ] Browser console is clean — no warnings about keys, controlled/uncontrolled, or missing `alt`.
4. [ ] Every `<img>` has meaningful `alt` (or `alt=""` if purely decorative).
5. [ ] Every form control has an associated `<label>` (visible or via `aria-label`).
6. [ ] Full keyboard navigation works for the demo page (Tab, Shift+Tab, Enter, Escape).
7. [ ] Visible focus ring on every interactive element (no `outline: none` without a replacement).
8. [ ] Lighthouse Accessibility score ≥ 95 on the demo page.
9. [ ] Each component folder has a `README.md` and at least one usage snippet.
10. [ ] Components are pure where possible — no side effects in render, all effects in `useEffect` with cleanup.

---

**Stretch goals (optional):**
- Add `vitest` + `@testing-library/react` smoke tests for `Button`, `Input`, `Modal`.
- Add a Storybook (or Ladle) story per primitive.
- Extract design tokens to a `theme.ts` and support a `ThemeProvider` via context (preview for Topic 9).