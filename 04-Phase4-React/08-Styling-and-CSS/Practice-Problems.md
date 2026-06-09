# Topic 8: Styling & CSS — Practice Problems

Five problems, increasing difficulty. Each problem lists the concept being practiced, the requirements, and the expected behavior. Starter snippets are given where they save time.

---

## Problem 1 — Card Component with CSS Modules (Easy)

**Concept tag:** `CSS Modules` · `composes` · `:hover` · `:focus-visible`

Build a reusable `<ProfileCard />` component styled entirely with CSS Modules.

### Requirements
- File layout: `ProfileCard.tsx` + `ProfileCard.module.css` colocated.
- Props: `{ name: string; role: string; avatarUrl: string; onMessage?: () => void }`.
- The card must contain an avatar (circular, 64×64), name (bold), role (muted color), and a **Message** button.
- Use a `composes:` rule so `.primaryBtn` and `.ghostBtn` share base button styles from a `.btnBase` class.
- Define at least 3 CSS custom properties at the `:root` level (`--card-bg`, `--card-radius`, `--card-shadow`) and consume them inside the module.

### Expected Behavior
- Hovering the card lifts it (`translateY(-2px)`) and increases shadow — transition 150ms.
- The Message button shows a **visible focus ring** when keyboard-focused (`:focus-visible`), but no ring on mouse click.
- Card is keyboard navigable: tab order Avatar (skipped) → Message button.

### Starter
```tsx
import s from './ProfileCard.module.css';

export function ProfileCard({ name, role, avatarUrl, onMessage }: Props) {
  return (
    <article className={s.card}>
      <img className={s.avatar} src={avatarUrl} alt="" />
      <h3 className={s.name}>{name}</h3>
      <p className={s.role}>{role}</p>
      <button className={s.primaryBtn} onClick={onMessage}>Message</button>
    </article>
  );
}
```

---

## Problem 2 — Theme Toggler with CSS Variables + Context (Easy-Medium)

**Concept tag:** `CSS variables` · `Context` · `localStorage` · `prefers-color-scheme`

Implement a global theme system with three modes: `light`, `dark`, `system`.

### Requirements
- `ThemeProvider` exposes `{ theme, resolvedTheme, setTheme }` via `useTheme()`.
- Persist the user's choice in `localStorage` under key `theme`.
- When `theme === 'system'`, follow `matchMedia('(prefers-color-scheme: dark)')` and react live to OS changes.
- Set `data-theme="light" | "dark"` on `<html>` so all CSS rules cascade naturally.
- Provide a `<ThemeToggle />` UI: 3-button segmented control (Light / Dark / System), with an active visual state.
- Define a token file `tokens.css` with at minimum: `--bg`, `--fg`, `--muted`, `--border`, `--brand` for both themes.

### Expected Behavior
- No flash of wrong theme on first paint — set `data-theme` in a synchronous inline `<script>` in `index.html` before React boots.
- Switching modes is instant; switching to **System** while OS is dark immediately applies dark.
- Reload preserves the user's selection.

### Stretch
- Add a CSS transition `transition: background-color 200ms, color 200ms` on `body`, but disable when `prefers-reduced-motion: reduce`.

---

## Problem 3 — Three-Way Button Comparison (Medium)

**Concept tag:** `CSS Modules` · `styled-components` · `Tailwind` · `tradeoff analysis`

Build the **same** `<Button />` component three times in three folders. The component spec:

```ts
type Variant = 'primary' | 'secondary' | 'danger' | 'ghost';
type Size    = 'sm' | 'md' | 'lg';
interface ButtonProps {
  variant?: Variant;          // default 'primary'
  size?: Size;                // default 'md'
  fullWidth?: boolean;
  loading?: boolean;          // shows spinner, disables button
  iconStart?: ReactNode;
  iconEnd?: ReactNode;
  children: ReactNode;
  // …plus all native <button> props
}
```

### Requirements
- **Folder A — `button-css-modules/`**: implement with `Button.module.css`, use `composes:` for variant/size combinations, type the module.
- **Folder B — `button-styled/`**: implement with `styled-components`, use a `ThemeProvider` for colors, transient props (`$variant`), and an `as` polymorphic example (`<Button as="a" href="…">`).
- **Folder C — `button-tailwind/`**: implement with Tailwind, use `clsx` + `tailwind-merge` (export a `cn()` helper), variant maps as `Record<Variant, string>`.
- All three must support: hover, active, focus-visible ring, disabled state, loading spinner, RTL-friendly icon spacing.
- Export a single `<ButtonShowcase />` page that renders all three side-by-side with a label.

### Deliverable: `COMPARISON.md`
Write a short table comparing:
- Bundle impact (production)
- DX for adding a new variant
- Theming flexibility
- Runtime cost
- TypeScript ergonomics

---

## Problem 4 — Responsive Dashboard Layout with Tailwind (Medium-Hard)

**Concept tag:** `Tailwind` · `responsive` · `grid` · `mobile menu` · `Radix`

Build the shell of an admin dashboard, fully responsive.

### Requirements
- **Layout zones**:
  - Top header (fixed, 56px tall): logo, search input (hidden < `md`), user avatar menu (Radix Dropdown).
  - Left sidebar (240px on `lg+`, collapsible to icons-only on `md`, drawer on `< md`).
  - Main content area: page heading + a responsive grid of stat cards + a table.
- **Stat cards grid**:
  - 1 column `< sm`, 2 columns `sm`, 3 columns `lg`, 4 columns `xl`.
  - Each card: title, big number, delta with up/down arrow (green/red).
- **Mobile menu**: when viewport < `md`, sidebar hides and a hamburger button appears in the header. Tapping opens a slide-in `Dialog` (Radix) from the left.
- Use **container queries** for the stat card to switch from vertical to horizontal layout when it gets wide enough — independent of viewport.
- Dark mode (`darkMode: 'class'`) supported throughout, toggle in user menu.
- All interactive elements have `focus-visible:ring-2 ring-offset-2` rings.

### Expected Behavior
- Resize from 320px → 1920px and the layout never overflows or shows horizontal scroll.
- Sidebar drawer traps focus and closes on `Escape` (Radix gives this for free).
- Lighthouse a11y ≥ 95.

### Stretch
- Persist the sidebar collapsed/expanded state in `localStorage`.
- Add a search command palette (`Ctrl/Cmd+K`) using Radix Dialog + a filtered list.

---

## Problem 5 — Animated Multi-Step Wizard with Theming (Hard)

**Concept tag:** `Framer Motion` · `AnimatePresence` · `theming` · `state machine` · `a11y`

Build a 4-step onboarding wizard with rich animations and a 3-theme system.

### Steps
1. **Welcome** — name + email
2. **Plan** — three plan cards (Free / Pro / Team), single-select
3. **Preferences** — checkboxes (notifications, newsletter, beta features)
4. **Review** — summary + Submit

### Requirements
- **State**: model with a tiny reducer or `useState` per step; on Submit, log the full payload.
- **Validation**: cannot proceed if current step is invalid; show inline error messages.
- **Animations** (Framer Motion):
  - Steps slide in from the right and out to the left when going **forward**, opposite when **going back**. Use `AnimatePresence` with `mode="wait"`.
  - Plan cards have a `layoutId` so the selected card's highlight border animates between cards.
  - Progress bar at the top animates its width with `motion.div` and a `spring` transition.
  - Respect `prefers-reduced-motion`: when reduced, swap to a simple opacity fade with `duration: 0.01`.
- **Theme system**: implement **3 themes** — `aurora` (cool blues/greens), `sunset` (warm oranges/pinks), `mono` (grayscale). 
  - Each theme is a set of CSS variables on `[data-theme='aurora' | 'sunset' | 'mono']`.
  - Theme picker in the wizard footer (3 swatches).
  - Theme persists across reloads.
- **Accessibility**:
  - Each step has an `<h2>` that receives focus on transition (programmatically via `ref.focus()` after animation completes).
  - Form fields are properly labeled, errors linked via `aria-describedby`.
  - The progress bar has `role="progressbar"` with `aria-valuenow/min/max`.
- **Routing (optional)**: sync the current step to the URL (`/onboarding/2`), so reload keeps you in place.

### Starter Skeleton
```tsx
const steps = ['welcome', 'plan', 'preferences', 'review'] as const;
type Step = typeof steps[number];

const [current, setCurrent] = useState<Step>('welcome');
const [direction, setDirection] = useState<1 | -1>(1);

const variants = {
  enter: (dir: number) => ({ x: dir * 40, opacity: 0 }),
  center:                  { x: 0, opacity: 1 },
  exit:  (dir: number) => ({ x: dir * -40, opacity: 0 }),
};

<AnimatePresence mode="wait" custom={direction}>
  <motion.section
    key={current}
    custom={direction}
    variants={variants}
    initial="enter" animate="center" exit="exit"
    transition={{ type: 'spring', stiffness: 300, damping: 30 }}
  >
    {/* render step */}
  </motion.section>
</AnimatePresence>
```

### Stretch
- Add a confetti animation on the final Submit using `framer-motion` particles or `canvas-confetti`.
- Add a `useReducedMotion()` hook from Framer Motion and gate **all** non-essential animations with it.
- Make the theme picker itself animate the swatch selection with `layoutId`.

---

## Self-Review Checklist

- [ ] Every interactive element has a visible focus state.
- [ ] No `outline: none` without a replacement.
- [ ] Color contrast meets WCAG AA (4.5:1 text).
- [ ] `prefers-reduced-motion` is respected.
- [ ] No FOUC for theme on reload.
- [ ] No hydration warnings (if using SSR).
- [ ] Tailwind classes are full literals, not built by string concatenation.
- [ ] Styles are colocated with their components, globals are minimal.
