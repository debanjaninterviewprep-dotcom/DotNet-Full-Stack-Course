# Topic 08: Styling and CSS — Interview Questions

---

## Q1. What are the different ways to style React components?
**Answer:**
| Method | Scoping | Dynamic styles | Trade-offs |
|---|---|---|---|
| Plain CSS | Global | Via className | Simple, but naming collisions |
| CSS Modules | Component-scoped | Via className | Great scoping, no runtime cost |
| Inline styles | Component | ✓ Direct JS | No pseudo-classes, no media queries |
| CSS-in-JS (styled-components) | Component | ✓ Props-based | Runtime cost, large bundle |
| Tailwind CSS | Utility | ✓ Conditional classes | Very fast dev, no custom CSS |
| Sass/SCSS | Global (by default) | Via className | More powerful CSS syntax |

---

## Q2. What are CSS Modules and why are they recommended?
**Answer:**
CSS Modules automatically scope CSS class names to the component — no global leakage:

```css
/* Button.module.css */
.button { padding: 8px 16px; border-radius: 4px; }
.primary { background: blue; color: white; }
.secondary { background: gray; }
.disabled { opacity: 0.5; cursor: not-allowed; }
```

```jsx
// Button.tsx
import styles from './Button.module.css';

function Button({ variant = 'primary', disabled, children }) {
  return (
    <button
      className={`${styles.button} ${styles[variant]} ${disabled ? styles.disabled : ''}`}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
// Generates unique class names: Button_button__abc123, Button_primary__def456
```

**Benefits:** Zero runtime cost, no naming collisions, TypeScript type support (`*.module.css.d.ts`).

---

## Q3. What are styled-components and how do they work?
**Answer:**
styled-components is a CSS-in-JS library that creates components with embedded styles using tagged template literals:

```jsx
import styled from 'styled-components';

// Create styled component
const Button = styled.button`
  padding: 8px 16px;
  border-radius: 4px;
  background: ${props => props.primary ? '#007bff' : '#6c757d'};
  color: white;
  opacity: ${props => props.disabled ? 0.5 : 1};
  cursor: ${props => props.disabled ? 'not-allowed' : 'pointer'};

  &:hover { filter: brightness(0.9); }
  &:focus { outline: 2px solid #0056b3; }

  @media (max-width: 768px) { width: 100%; }
`;

const Title = styled.h1`
  font-size: 2rem;
  color: ${({ theme }) => theme.colors.text}; // theming
`;

// Usage
<Button primary onClick={handleClick}>Save</Button>
<Button disabled>Cancel</Button>
```

---

## Q4. What is Tailwind CSS and how does it differ from traditional CSS?
**Answer:**
Tailwind is a **utility-first CSS framework** — you compose designs using predefined utility classes:

```jsx
// Traditional CSS approach
<button className="submit-btn">Submit</button>
// .submit-btn { background: blue; color: white; padding: 8px 16px; border-radius: 4px; }

// Tailwind approach — no custom CSS needed
<button className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 active:scale-95 transition-all">
  Submit
</button>

// Dynamic with clsx/cn utility
import clsx from 'clsx';
<button className={clsx(
  'px-4 py-2 rounded font-medium transition-colors',
  variant === 'primary' && 'bg-blue-500 text-white hover:bg-blue-600',
  variant === 'danger'  && 'bg-red-500 text-white hover:bg-red-600',
  disabled && 'opacity-50 cursor-not-allowed'
)}>
```

**Benefits:** No unused CSS in production (tree-shaken), consistent design system, no naming decisions.

---

## Q5. What are inline styles in React and when should you use them?
**Answer:**
```jsx
// Inline styles — JS object with camelCase properties
function Card({ bgColor, width }) {
  const style = {
    backgroundColor: bgColor,   // camelCase
    width: `${width}px`,
    borderRadius: '8px',
    padding: '16px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
  };
  return <div style={style}>Content</div>;
}

// Limitations of inline styles:
// ❌ No pseudo-classes (:hover, :focus, :active)
// ❌ No media queries
// ❌ No CSS animations (@keyframes)
// ❌ No CSS variables
// ❌ Poor performance (no style sharing between elements)
```

**Use inline styles only for:** Dynamic values that change per element (position, size from JavaScript calculations), third-party chart/visualization configs.

---

## Q6. How do you conditionally apply CSS classes?
**Answer:**
```jsx
// Approach 1: Template literal
<div className={`card ${isActive ? 'active' : ''} ${hasError ? 'error' : ''}`} />

// Approach 2: Array join
<div className={['card', isActive && 'active', hasError && 'error'].filter(Boolean).join(' ')} />

// Approach 3: clsx library (recommended)
import clsx from 'clsx';
<div className={clsx('card', { active: isActive, error: hasError, large: isLarge })} />

// Approach 4: cn (combines clsx + tailwind-merge for Tailwind projects)
import { cn } from '@/lib/utils'; // shadcn/ui pattern
<button className={cn('px-4 py-2 bg-blue-500', { 'opacity-50': disabled }, className)} />

// TypeScript: clsx type-safe usage
type Variant = 'primary' | 'secondary' | 'danger';
<button className={clsx(styles.btn, styles[variant])} />
```

---

## Q7. What is the CSS specificity issue in React and how do you handle it?
**Answer:**
When using CSS Modules or global CSS together, specificity conflicts can arise:

```css
/* global.css — high specificity */
.container .button { color: red; }

/* Button.module.css — lower specificity might lose */
.button { color: blue; }
```

**Solutions:**
```jsx
// Use CSS Modules composes for inheritance
/* Button.module.css */
.baseButton { padding: 8px 16px; }
.primaryButton { composes: baseButton; background: blue; }

// Or use CSS layers (modern CSS)
@layer utilities {
  .button { color: blue; } /* always wins over unlayered rules */
}

// Or increase specificity with :where/:is (0 specificity)
:where(.button) { color: blue; }

// Tailwind: use twMerge to properly handle overrides
import { twMerge } from 'tailwind-merge';
const cls = twMerge('text-red-500', 'text-blue-500'); // 'text-blue-500' wins
```

---

## Q8. What is CSS-in-JS and what are its trade-offs?
**Answer:**
CSS-in-JS writes styles in JavaScript, enabling dynamic theming and co-location of styles with components.

**Libraries:** styled-components, Emotion, Stitches, Vanilla Extract.

```jsx
// Emotion
import { css } from '@emotion/react';
const buttonStyle = css`
  background: ${theme.primary};
  &:hover { filter: brightness(0.9); }
`;

// Trade-offs
// Pros:
// ✓ Dynamic styles based on props/theme
// ✓ No CSS file management
// ✓ Automatic critical CSS
// ✓ TypeScript-friendly

// Cons:
// ✗ Runtime overhead (styles computed in JS)
// ✗ Larger bundle size
// ✗ SSR complexity (extract critical CSS)
// ✗ Poor performance on mobile (style recalculation)
```

**Trend:** Modern projects increasingly prefer CSS Modules + Tailwind (zero-runtime) over CSS-in-JS.

---

## Q9. How do you use global styles in a React project?
**Answer:**
```jsx
// main.tsx — import global CSS
import './index.css';

// index.css — global resets and variables
@import 'normalize.css';

:root {
  --primary: #007bff;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --radius: 4px;
  --shadow: 0 2px 4px rgba(0,0,0,0.1);
}

* { box-sizing: border-box; }
body { font-family: Inter, sans-serif; margin: 0; }

// With styled-components — GlobalStyle component
import { createGlobalStyle } from 'styled-components';
const GlobalStyle = createGlobalStyle`
  *, *::before, *::after { box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; }
`;

function App() { return (<><GlobalStyle /><Router /></>); }
```

---

## Q10. How do you implement a dark mode in React?
**Answer:**
```jsx
// Approach 1: CSS variables + class toggle
// :root { --bg: white; --text: black; }
// .dark { --bg: #1a1a1a; --text: white; }

function App() {
  const [isDark, setIsDark] = useState(() =>
    window.matchMedia('(prefers-color-scheme: dark)').matches
  );

  useEffect(() => {
    document.documentElement.classList.toggle('dark', isDark);
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
  }, [isDark]);

  return (
    <ThemeContext.Provider value={{ isDark, toggle: () => setIsDark(d => !d) }}>
      <div style={{ background: 'var(--bg)', color: 'var(--text)' }}>
        <App />
      </div>
    </ThemeContext.Provider>
  );
}

// Approach 2: Tailwind dark mode
// tailwind.config: { darkMode: 'class' }
<div className="bg-white dark:bg-gray-900 text-black dark:text-white">
```

---

## Q11. What is CSS animation in React?
**Answer:**
```jsx
// CSS animation via keyframes
// animation.module.css
// @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
// .fade-in { animation: fadeIn 0.3s ease-in-out; }

// React transition animation libraries
import { AnimatePresence, motion } from 'framer-motion';

function ModalWrapper({ isOpen, children }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 20 }}
          transition={{ duration: 0.2 }}
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
}

// CSS Transitions (simpler)
<div
  style={{
    opacity: isVisible ? 1 : 0,
    transform: isVisible ? 'translateY(0)' : 'translateY(-10px)',
    transition: 'opacity 0.3s, transform 0.3s'
  }}
/>
```

---

## Q12. How do you handle responsive design in React?
**Answer:**
```jsx
// CSS Media Queries (preferred — no JS re-render)
// in CSS/SCSS/modules:
// @media (max-width: 768px) { .container { flex-direction: column; } }

// Custom hook for responsive behavior
function useMediaQuery(query) {
  const [matches, setMatches] = useState(() => window.matchMedia(query).matches);
  useEffect(() => {
    const mq = window.matchMedia(query);
    const handler = (e) => setMatches(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [query]);
  return matches;
}

// Usage
function Navbar() {
  const isMobile = useMediaQuery('(max-width: 768px)');
  return isMobile ? <HamburgerMenu /> : <DesktopNav />;
}

// Tailwind responsive prefixes (no JS needed)
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
```

---

## Q13. What is the `clsx` library and why is it useful?
**Answer:**
`clsx` is a tiny utility for conditionally joining class names:

```jsx
import clsx from 'clsx';

// Handles all className patterns cleanly
clsx('a', 'b')                          // 'a b'
clsx({ active: true, disabled: false }) // 'active'
clsx(['a', 'b', { c: true }])           // 'a b c'
clsx(null, undefined, false, 'real')    // 'real' — falsy values ignored

// In components
function Alert({ type, visible, className, children }) {
  return (
    <div className={clsx(
      'alert',
      `alert-${type}`,    // always add type class
      visible && 'visible',  // conditional
      className           // allow parent override
    )}>
      {children}
    </div>
  );
}

// With Tailwind + tailwind-merge (avoids duplicate/conflicting classes)
import { twMerge } from 'tailwind-merge';
const cn = (...inputs) => twMerge(clsx(inputs));
<div className={cn('px-4 text-sm', className)} /> // className overrides work correctly
```

---

## Q14. What is the styled-components `ThemeProvider`?
**Answer:**
```jsx
import { ThemeProvider, styled } from 'styled-components';

// Define theme
const lightTheme = { bg: '#ffffff', text: '#333333', primary: '#007bff' };
const darkTheme  = { bg: '#1a1a1a', text: '#f0f0f0', primary: '#4dabf7' };

// Styled component uses theme
const Card = styled.div`
  background: ${({ theme }) => theme.bg};
  color: ${({ theme }) => theme.text};
  border: 1px solid ${({ theme }) => theme.primary};
`;

// Provide theme at app root
function App() {
  const [isDark, setIsDark] = useState(false);
  return (
    <ThemeProvider theme={isDark ? darkTheme : lightTheme}>
      <Card>Content</Card>
    </ThemeProvider>
  );
}
```

---

## Q15. What are CSS variables and how are they used in React?
**Answer:**
CSS variables (custom properties) enable dynamic theming without JavaScript re-renders:

```css
/* Define variables in :root */
:root {
  --color-primary: #007bff;
  --spacing-base: 8px;
  --border-radius: 4px;
}
.dark {
  --color-primary: #4dabf7;
}
```

```jsx
// Read/write CSS variables from React
function ThemeToggle() {
  const setTheme = (isDark) => {
    document.documentElement.style.setProperty('--color-primary', isDark ? '#4dabf7' : '#007bff');
    document.documentElement.classList.toggle('dark', isDark);
  };
}

// Use in inline styles
<div style={{ '--card-color': userColor } as React.CSSProperties}>

// Use in CSS
// .card { background: var(--card-color, white); }
```

CSS variables update instantly without React re-renders — ideal for smooth animations and theming.
