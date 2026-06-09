# Topic 8: Styling & CSS

Styling is one of React's most opinionated areas — the framework itself is unopinionated, but the ecosystem offers a dozen valid approaches. This topic surveys the landscape, deep-dives into the popular options, and gives you a decision framework.

---

## 1. Overview: Comparison of Approaches

| Approach | Scope | Runtime cost | DX | Theming | Best for |
|---|---|---|---|---|---|
| Plain CSS (global) | Global | None | Low | Manual | Tiny apps, quick prototypes |
| CSS Modules | Local (file) | None (build-time) | Medium | CSS vars | Component libraries, default Vite/CRA setups |
| Sass/SCSS | Global or local | None (compiled) | Medium | Variables/mixins | Teams with CSS background, design-system tokens |
| styled-components | Component | Runtime (small) | High | First-class `ThemeProvider` | Dynamic, prop-driven styles |
| Emotion | Component | Runtime | High | `ThemeProvider` + `css` prop | Same as styled-components, lighter API |
| Tailwind CSS | Utility classes | None (purged at build) | Very high after learning curve | Config-based | Product apps, design systems |
| vanilla-extract | Local (TS) | **Zero runtime** | High (typed) | Typed tokens | Type-safe atomic CSS |
| Panda CSS | Local (TS) | Zero runtime | High | Recipes/tokens | Modern alternative to Chakra/styled |
| Linaria | Component | Zero runtime | High | Theme via CSS vars | Migrate off styled-components |

> Rule of thumb: pick **one primary** approach per app. Mixing CSS Modules + Tailwind is fine; mixing styled-components + Emotion is not.

---

## 2. Inline Styles in JSX

```tsx
<div style={{ backgroundColor: 'tomato', paddingTop: 12, fontSize: '1rem' }} />
```

- Object syntax; properties are **camelCase** (`backgroundColor`, not `background-color`).
- Numeric values default to `px` for most properties (`padding: 8` → `8px`).
- Vendor prefixes: React adds them for some properties, but **not all** — prefer CSS for `-webkit-` heavy work.
- **Use for**: truly dynamic per-instance values (e.g. positioning from a calculation, drag offsets).
- **Avoid for**: hover/focus/media queries (impossible inline), shared component styles, anything benchmarkable.

```tsx
const Bar = ({ pct }: { pct: number }) => (
  <div style={{ width: `${pct}%` }} className="progress-bar" />
);
```

Mix the two: structural CSS in a class, dynamic value inline.

---

## 3. `className` and Conditional Classes

```tsx
<button className={`btn ${isPrimary ? 'btn--primary' : 'btn--ghost'} ${disabled ? 'is-disabled' : ''}`} />
```

This breaks down quickly. Use **`clsx`** (or `classnames`):

```tsx
import clsx from 'clsx';

<button className={clsx('btn', {
  'btn--primary': isPrimary,
  'btn--ghost': !isPrimary,
  'is-disabled': disabled,
})} />
```

For Tailwind, pair with **`tailwind-merge`** to dedupe conflicting utilities:

```tsx
import { twMerge } from 'tailwind-merge';
import clsx from 'clsx';

const cn = (...args: any[]) => twMerge(clsx(args));
cn('px-2 py-1', condition && 'px-4'); // → "py-1 px-4"
```

---

## 4. Plain CSS Imports

```tsx
import './App.css'; // global, leaks everywhere
```

Pitfalls of global scope:
- Class-name collisions across teams.
- Specificity wars → people reach for `!important`.
- Dead code: removed components leave orphan rules.
- Order-of-import sensitivity.

Use only for true globals: resets, typography, root CSS variables.

---

## 5. CSS Modules

Built into Vite and CRA. Any file ending in `.module.css` is locally scoped.

```css
/* Button.module.css */
.root { padding: 8px 12px; border-radius: 6px; }
.primary { composes: root; background: var(--color-brand); color: white; }
.disabled { composes: root; opacity: 0.5; pointer-events: none; }
```

```tsx
import s from './Button.module.css';

export const Button = ({ variant = 'primary', disabled }: Props) => (
  <button className={disabled ? s.disabled : s[variant]} disabled={disabled} />
);
```

- Build tool hashes class names → `Button_primary__a1b2`.
- `composes` reuses rules without copying.
- For TypeScript, install `typescript-plugin-css-modules` or generate `.d.ts` via `tcm`/`vite-plugin-css-modules`.

---

## 6. CSS Variables & Theming

```css
:root { --color-bg: #fff; --color-fg: #111; }
:root[data-theme='dark'] { --color-bg: #0b0b0b; --color-fg: #eee; }
body { background: var(--color-bg); color: var(--color-fg); }
```

Toggle the attribute on `<html>` from React:

```tsx
document.documentElement.dataset.theme = isDark ? 'dark' : 'light';
```

CSS variables work everywhere (Tailwind, CSS Modules, styled-components) and have **zero runtime cost**.

---

## 7. Sass/SCSS Basics

```bash
npm i -D sass
```

```scss
// _tokens.scss
$brand: #4f46e5;
@mixin focus-ring { &:focus-visible { outline: 2px solid $brand; outline-offset: 2px; } }

// Card.module.scss
@use './tokens' as *;
.card { padding: 16px; @include focus-ring; &__title { font-weight: 600; } }
```

Use SCSS for: shared mixins, color functions, build-time loops. Avoid it as a substitute for component-scoping (use `.module.scss`).

---

## 8. styled-components

```tsx
import styled, { css, ThemeProvider, createGlobalStyle } from 'styled-components';

const Button = styled.button<{ $primary?: boolean }>`
  padding: 8px 12px;
  border-radius: 6px;
  background: ${(p) => (p.$primary ? p.theme.colors.brand : 'transparent')};
  ${(p) => p.disabled && css`opacity: 0.5; pointer-events: none;`}
  &:hover { filter: brightness(1.1); }
`;

const LinkButton = styled(Button).attrs({ as: 'a' })`text-decoration: none;`;

const GlobalStyles = createGlobalStyle`body { margin: 0; font-family: system-ui; }`;

<ThemeProvider theme={{ colors: { brand: '#4f46e5' } }}>
  <GlobalStyles />
  <Button $primary as="a" href="/">Go</Button>
</ThemeProvider>
```

Key APIs: `styled.tag`, `styled(Component)` to extend, `attrs()` for default props/HTML attrs, `as` polymorphic prop, `ThemeProvider`, `createGlobalStyle`, `keyframes`. Use **transient props** (`$primary`) so they don't leak to the DOM.

SSR: call `ServerStyleSheet.collectStyles()` and inject `sheet.getStyleTags()` into the HTML head.

---

## 9. Emotion

```tsx
/** @jsxImportSource @emotion/react */
import { css } from '@emotion/react';
import styled from '@emotion/styled';

<button css={css`padding: 8px; color: hotpink; &:hover { color: deeppink; }`} />

const Card = styled.div<{ pad?: number }>`padding: ${(p) => p.pad ?? 16}px;`;
```

Differences vs styled-components:
- `css` prop allows ad-hoc styles without naming a component.
- Smaller bundle, slightly faster.
- Works with the same theming + SSR patterns.

---

## 10. Tailwind CSS

```bash
npm i -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

```tsx
<button className="px-3 py-2 rounded-md bg-indigo-600 text-white
                   hover:bg-indigo-500 focus-visible:ring-2 ring-indigo-300
                   md:px-4 dark:bg-indigo-500">Save</button>
```

- **Responsive prefixes**: `sm: md: lg: xl: 2xl:` (mobile-first).
- **State variants**: `hover: focus: active: disabled: focus-visible: group-hover: peer-checked:`.
- **Dark mode**: `darkMode: 'class'` then toggle `class="dark"` on `<html>`.
- `@apply` to extract repeated utilities into a CSS class (use sparingly).
- **Customizing**: edit `tailwind.config.js` `theme.extend` for colors, spacing, fonts.
- **Plugins**: `@tailwindcss/forms`, `@tailwindcss/typography`, `tailwindcss-animate`.
- **Purging**: only classes statically present in your `content` glob survive — **never build class names with string concatenation** (`bg-${color}-500` will be purged). Use full class strings or a safelist.

```tsx
// BAD — purged
const c = `bg-${color}-500`;
// GOOD — full strings
const map = { red: 'bg-red-500', blue: 'bg-blue-500' } as const;
```

---

## 11. Headless UI Libraries

Provide accessible behavior without styles — you bring the look. Pair beautifully with Tailwind.

- **Radix UI**: dialogs, menus, popovers, tabs — gold standard for a11y.
- **Headless UI** (Tailwind Labs): Listbox, Combobox, Disclosure.
- **React Aria** (Adobe): hooks-based, full keyboard/SR support.

```tsx
import * as Dialog from '@radix-ui/react-dialog';

<Dialog.Root>
  <Dialog.Trigger className="btn">Open</Dialog.Trigger>
  <Dialog.Portal>
    <Dialog.Overlay className="fixed inset-0 bg-black/50" />
    <Dialog.Content className="fixed inset-0 m-auto w-96 h-fit p-6 bg-white rounded-xl">
      <Dialog.Title>Hi</Dialog.Title>
    </Dialog.Content>
  </Dialog.Portal>
</Dialog.Root>
```

---

## 12. Component Libraries (Brief)

| Library | Style engine | Theming | Notes |
|---|---|---|---|
| MUI | Emotion (default) | `createTheme` + `ThemeProvider` | Largest, Material spec |
| Chakra UI | Emotion | Style props + tokens | Great DX, opinionated |
| Mantine | Emotion → CSS modules (v7) | Hooks-rich | Hooks lib bundled |
| Ant Design | CSS-in-JS (v5) | ConfigProvider | Enterprise/admin look |

**shadcn/ui** is *not* a library — it's a CLI that copies Radix + Tailwind components into your repo. You own and edit the source. Best of both worlds: a11y + full control, no version bumps.

---

## 13. CSS-in-JS Cost & Zero-Runtime Alternatives

Runtime CSS-in-JS (styled-components, Emotion):
- Pros: dynamic styles via props, theming, colocation.
- Cons: serialization on every render, larger bundle, SSR complexity, React 18 streaming friction.

Zero-runtime:
- **vanilla-extract**: write styles in `.css.ts`, fully typed, extracted at build.
- **Linaria**: tagged templates compiled at build to atomic CSS.
- **Panda CSS**: recipes, patterns, typed tokens; modern Chakra-style ergonomics.

```ts
// styles.css.ts (vanilla-extract)
import { style } from '@vanilla-extract/css';
export const button = style({ padding: 8, ':hover': { opacity: 0.9 } });
```

---

## 14. Animations

- **CSS transitions**: cheapest, GPU-accelerated for `transform`/`opacity`.
- **`@keyframes`**: for repeating or complex animations.
- **Framer Motion**: declarative, layout animations, gestures, variants.
  ```tsx
  import { motion, AnimatePresence } from 'framer-motion';
  <AnimatePresence>
    {open && <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} />}
  </AnimatePresence>
  ```
- **React Transition Group**: lower-level mount/unmount lifecycle classes.
- **View Transitions API**: `document.startViewTransition(() => setState(...))` for native cross-DOM animations (Chromium today).

---

## 15. Responsive Design

- **Mobile-first**: write base styles, add `min-width` media queries up.
- **Breakpoints** (Tailwind defaults): `sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536`.
- **Container queries** (`@container`): style based on parent size, not viewport — perfect for cards in a grid.
  ```css
  .card-grid { container-type: inline-size; }
  @container (min-width: 480px) { .card { display: grid; grid-template-columns: 1fr 2fr; } }
  ```

---

## 16. Accessibility

- **Visible focus**: never `outline: none` without a replacement (`focus-visible:ring-2`).
- **Color contrast**: AA = 4.5:1 body text, 3:1 large/UI. Test with axe DevTools.
- **`prefers-reduced-motion`**:
  ```css
  @media (prefers-reduced-motion: reduce) { * { animation-duration: 0.01ms !important; transition: none !important; } }
  ```
- **Dark mode**: respect `prefers-color-scheme` as default, allow user override.
- Don't rely on color alone to convey state — pair with icons or text.

---

## 17. Theming Pattern: Context Switcher

```tsx
type Theme = 'light' | 'dark' | 'system';
const ThemeCtx = createContext<{ theme: Theme; setTheme: (t: Theme) => void }>(null!);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(() =>
    (localStorage.getItem('theme') as Theme) ?? 'system'
  );
  useEffect(() => {
    const resolved = theme === 'system'
      ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
      : theme;
    document.documentElement.dataset.theme = resolved;
    localStorage.setItem('theme', theme);
  }, [theme]);
  return <ThemeCtx.Provider value={{ theme, setTheme }}>{children}</ThemeCtx.Provider>;
}
export const useTheme = () => useContext(ThemeCtx);
```

Pair with CSS variables on `[data-theme='dark']` — works for any styling approach.

---

## 18. SSR Considerations (Next.js / Remix)

- **styled-components**: register stylesheet, flush on render.
- **Emotion**: `@emotion/cache` + `CacheProvider`; Next.js App Router needs the `useServerInsertedHTML` pattern.
- **Tailwind / CSS Modules / vanilla-extract**: zero work — pure CSS files.
- Hydration mismatch warning: never render `theme === 'dark'` conditionals on the server based on `localStorage` — read on client effect, or use a cookie.

---

## 19. Performance

- **Critical CSS**: inline above-the-fold styles in `<head>` (frameworks like Next.js do this for CSS Modules).
- **Code-split styles**: dynamic `import()` of a route auto-splits its CSS.
- **Avoid inline-style churn**: object literals in JSX are recreated each render — fine for static, but for heavy lists prefer classes.
- **`will-change`** sparingly: only on elements about to animate.
- Tailwind ships only the classes you use — typically <10 KB gzipped in production.

---

## 20. Common Pitfalls

| Pitfall | Cause | Fix |
|---|---|---|
| Specificity war | Global selectors fighting | Use Modules / scoped classes |
| `!important` everywhere | Lost specificity battle | Refactor selector hierarchy |
| FOUC (flash of unstyled content) | CSS loaded async | Inline critical CSS, blocking link |
| FOUC for dark mode | Theme set after paint | Set `data-theme` in a synchronous `<script>` before hydration |
| Tailwind class missing in prod | Built dynamically | Use full strings or `safelist` |
| Hydration mismatch | Server/client style differ | Use cookies for theme, or `suppressHydrationWarning` on `<html>` |
| Slow re-renders | Inline objects in tight loops | Move to className |

---

## 21. File / Folder Organization

```
src/
  styles/
    globals.css         # resets, root vars
    tokens.css          # color/spacing CSS variables
    tailwind.css        # @tailwind directives (if used)
  components/
    Button/
      Button.tsx
      Button.module.css
      Button.test.tsx
      index.ts
```

Colocate styles with components. Keep only **true globals** in `src/styles/`.

---

## 22. Key Takeaways

- React is unopinionated about styling — pick **one** primary approach per app.
- **CSS Modules + CSS variables** is a fantastic, boring, performant default.
- **Tailwind** wins for product velocity once the team learns it; pair with `clsx` + `tailwind-merge`.
- Runtime CSS-in-JS is losing ground to **zero-runtime** options (vanilla-extract, Panda) and Tailwind.
- Always design for **dark mode, focus states, reduced motion, and color contrast** — accessibility is styling.
- Use **Radix / React Aria** for behavior, your styling system for looks — don't reinvent dialogs.
- Avoid dynamic class-name string building with Tailwind; the JIT can't see what isn't literal.
