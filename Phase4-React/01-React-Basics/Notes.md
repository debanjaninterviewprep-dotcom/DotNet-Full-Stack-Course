# Topic 1: React & JSX Fundamentals

## Overview

This note is a deep-dive reference for React beginners and experienced developers alike.
It covers JSX, rendering, component design, state and props, hooks, TypeScript patterns,
accessibility, testing basics, common pitfalls, and a rich set of examples and exercises.

The goal is to provide a self-contained chapter that mirrors the thoroughness
found in the Angular notes: practical examples, clear definitions, patterns,
anti-patterns, and a progression from basics to advanced topics.

---

## 1. What is React? (Short Answer)

- React is a JavaScript library for building user interfaces.
- It uses a component-based model where UI is expressed as a tree of components.
- React separates concerns by focusing on view layer and composition rather than
  enforcing a particular architecture for state, routing, or data fetching.

Key benefits:

- Declarative APIs that describe what UI should look like for a given state.
- Reusable components that encourage encapsulation and composability.
- A large ecosystem (router, state libraries, form libraries, testing tools).

---

## 2. JSX — The Syntax You Use Everyday

JSX is a syntax extension that looks like HTML and is compiled to `React.createElement`.
Understanding JSX helps you reason about the UI structure and how data flows.

Rules and notes:

- JSX expressions must have a single parent element. Use `<>...</>` fragments
  when you need to return multiple sibling nodes.
- Use `className` not `class`.
- Inline styles are objects: `style={{ color: 'red', fontSize: 14 }}`.
- Spread props with `{...props}` to forward unknown properties.

Examples:

```jsx
// Basic JSX
const el = <h1 className="title">Hello, world!</h1>;

// Fragment
function Row() {
  return (
    <>
      <td>Cell A</td>
      <td>Cell B</td>
    </>
  );
}

// Spread props
function Input(props) {
  return <input {...props} />;
}
```

Why JSX? It blends template and logic without forcing a separate templating
language. Code is easier to refactor and IDE tooling (autocomplete) works well.

---

## 3. Rendering & the Virtual DOM

Rendering in React is about translating state into UI. React maintains a
lightweight virtual DOM and uses reconciliation algorithms to compute the
minimal set of changes required to update the real DOM.

### 3.1 Reconciliation (How updates happen)

- When component state or props change, React re-renders the component tree
  into a new virtual DOM tree.
- React then compares the previous virtual DOM and the new one to find
  differences.
- Only the necessary DOM operations are applied. This process is called
  reconciliation.

Important notes:

- Keys in lists are crucial. They help React match elements between renders.
- Avoid using array index as key when items can be reordered.

Example: Why keys matter

```jsx
const list = items.map(item => <li key={item.id}>{item.name}</li>);
```

If keys are wrong, React may reuse DOM nodes incorrectly and cause
unexpected behavior.

---

## 4. Component Types and Design Patterns

React components are functions (or classes) that return JSX. Most modern
code uses function components with hooks.

Common component types:

1. Presentational (UI) components: receive props, render markup, no
   business logic.
2. Container components: orchestrate state, fetch data, pass props down.
3. Higher-order components (HOC): functions that wrap components to add
   behavior (less common with hooks).
4. Render props: components that accept a function prop for flexible rendering.

Design principles:

- Keep components small and focused.
- Prefer composition over inheritance.
- Extract reusable pieces and give clear prop contracts.

Example - Presentational vs Container

```jsx
// Presentational
function UserCard({ user }) {
  return <div>{user.name}</div>;
}

// Container
function UserCardContainer({ userId }) {
  const [user, setUser] = useState(null);
  useEffect(() => { fetchUser(userId).then(setUser); }, [userId]);
  if (!user) return <div>Loading...</div>;
  return <UserCard user={user} />;
}
```

---

## 5. Props — The Inputs to Components

Props are the primary mechanism for passing data and callbacks from parent
to child components.

Key points:

- Props are read-only; do not mutate props inside a child component.
- Use default props or default parameters to provide fallback values.
- Validate props when using JavaScript with `PropTypes` or prefer TypeScript
  for static checking.

Example with default props:

```jsx
function Badge({ label = 'New', color = 'blue' }) {
  return <span className={`badge ${color}`}>{label}</span>;
}
```

---

## 6. State — Local Component State

Use `useState` to hold local state inside function components.

Patterns and tips:

- Keep state minimal and focused. Store only what you need to render.
- Avoid duplication of state that can be derived from props or other state.
- Prefer immutable updates: use state setters that accept functional updates
  (`setState(prev => newState)`) when new state depends on previous state.

Example: functional updates

```jsx
setCount(prev => prev + 1);
```

Complex state:

- Use `useReducer` when you have complex state transitions.

Example: `useReducer`

```jsx
function reducer(state, action) {
  switch (action.type) {
    case 'add': return { ...state, items: [...state.items, action.payload] };
    case 'remove': return { ...state, items: state.items.filter(i => i.id !== action.payload) };
    default: return state;
  }
}

const [state, dispatch] = useReducer(reducer, { items: [] });
```

---

## 7. Hooks — The Core API

Hooks let you use state and other React features without writing classes.

Common hooks:

- `useState` — local state
- `useEffect` — side effects and lifecycle management
- `useRef` — mutable container and DOM refs
- `useMemo` — memoize expensive computations
- `useCallback` — memoize callbacks
- `useContext` — consume context
- `useReducer` — reducer-based state

Rules of Hooks:

1. Only call hooks at the top level of your component or custom hook.
2. Only call hooks from React function components or custom hooks.

Breaking these rules will cause bugs because React relies on hook call order.

Example: a custom hook

```jsx
function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);
  useEffect(() => {
    const onResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);
  return width;
}
```

---

## 8. `useEffect` Deep Dive

`useEffect` is used for side effects: data fetching, subscriptions, manual DOM
operations, timers.

Basic structure:

```jsx
useEffect(() => {
  // effect
  return () => {
    // cleanup
  };
}, [dependencies]);
```

Guidelines:

- Always include dependencies used inside the effect.
- Use ESLint plugin `react-hooks/exhaustive-deps` to catch missing deps.
- Avoid heavy computation inside effects — prefer `useMemo` or move logic
  outside the effect when possible.

Common pitfalls:

- Infinite loops caused by updating state inside an effect without proper deps.
- Stale closures: functions inside effects capturing old values — use refs
  or ensure correct deps.

Example: fetch with cancellation

```jsx
useEffect(() => {
  let cancelled = false;
  fetch('/api/data')
    .then(r => r.json())
    .then(data => { if (!cancelled) setData(data); });
  return () => { cancelled = true; };
}, []);
```

---

## 9. Custom Hooks — Reuse Logic

Custom hooks extract reusable logic and improve testability.

Rules:

- Preface with `use` (e.g., `useForm`, `useApi`).
- Keep hooks focused — one concern per hook.

Example: `useDebouncedValue`

```jsx
function useDebouncedValue(value, delay = 300) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
```

---

## 10. Refs, Portals, and Imperative APIs

`useRef` is a mutable container that survives re-renders. It's commonly used
for DOM access or storing mutable values that don't trigger re-renders.

```jsx
function TextInput() {
  const ref = useRef(null);
  return <input ref={ref} />;
}
```

Portals render children into a DOM node outside the parent hierarchy. Useful
for modals and overlays.

```jsx
createPortal(<Modal/>, document.body);
```

---

## 11. Forms — Controlled vs Uncontrolled

Controlled components store the field value in React state:

```jsx
function Login() {
  const [email, setEmail] = useState('');
  return <input value={email} onChange={e => setEmail(e.target.value)} />;
}
```

Uncontrolled components use refs and read values from the DOM when needed.

Choose controlled for validation and dynamic behavior, uncontrolled for
simple forms or performance-sensitive inputs.

Examples for validation and accessibility are provided later in this note.

---

## 12. Events and Synthetic Event System

React normalizes browser events into a cross-browser `SyntheticEvent`.

Examples:

```jsx
function Button() {
  function onClick(e) { e.preventDefault(); }
  return <button onClick={onClick}>Click</button>;
}
```

Notes:

- Event props use camelCase: `onClick`, `onChange`, `onSubmit`.
- To pass arguments use arrow functions: `onClick={() => handle(id)}`.

---

## 13. Performance: Avoiding Unnecessary Renders

Strategies:

- Memoize components with `React.memo` when props are stable.
- Memoize expensive computations with `useMemo`.
- Memoize callbacks with `useCallback` when passing to pure children.
- Use virtualization (e.g., `react-window`) for large lists.

Example: memo

```jsx
const Item = React.memo(function Item({ value }) {
  return <div>{value}</div>;
});
```

When to avoid memo:

- Premature optimization — measure first with Profiler.
- Memo adds complexity and memory overhead.

---

## 14. Code Splitting & Lazy Loading

Use `React.lazy` and `Suspense` to lazily load heavy components.

```jsx
const Heavy = React.lazy(() => import('./Heavy'));

function App() {
  return (
    <Suspense fallback={<Loading/>}>
      <Heavy />
    </Suspense>
  );
}
```

Note: Suspense for data fetching is experimental; rely on it when stable.

---

## 15. Error Boundaries

Error boundaries catch errors during rendering and lifecycle methods in class
components. There is no hook equivalent; implement class-based error boundaries
and use them to show fallback UIs.

```jsx
class ErrorBoundary extends React.Component {
  state = { error: null };
  static getDerivedStateFromError(error) { return { error }; }
  render() { return this.state.error ? <Fallback /> : this.props.children; }
}
```

Use error boundaries around risky UI blocks to avoid full app crashes.

---

## 16. Routing Basics (React Router v6)

Install `react-router-dom` for SPA routing.

Core concepts:

- `BrowserRouter`, `Routes`, `Route`
- `useParams`, `useNavigate`, `useLocation`

Example:

```jsx
<BrowserRouter>
  <Routes>
    <Route path="/" element={<Home />} />
    <Route path="/users/:id" element={<User />} />
  </Routes>
</BrowserRouter>
```

Nested routes provide layout composition and are highly recommended.

---

## 17. State Management Patterns

Local state works for many apps. For global concerns consider:

- React Context for UI-level state (theme, locale, auth) — not ideal for
  high-frequency updates because it causes re-renders of consumers.
- Redux Toolkit for predictable global state with devtools and middleware.
- Zustand / Jotai for lightweight alternatives with less boilerplate.

Guideline: start simple, extract to global state only when needed.

---

## 18. Testing React Components

Testing focuses on behavior and user-facing output.

Tools:

- Jest as the test runner.
- React Testing Library (RTL) for DOM-focused tests.

Example test (RTL):

```jsx
import { render, screen, fireEvent } from '@testing-library/react';
import Counter from './Counter';
test('increments', () => {
  render(<Counter />);
  fireEvent.click(screen.getByText('Increment'));
  expect(screen.getByText('Count: 1')).toBeInTheDocument();
});
```

Testing tips:

- Prefer queries that resemble user behavior (`getByRole`, `getByText`).
- Mock network calls with `msw` for integration-like tests.

---

## 19. TypeScript Integration

Use TypeScript for robust prop typing and safer refactoring.

Examples:

```tsx
type User = { id: string; name: string };
function UserCard({ user }: { user: User }) {
  return <div>{user.name}</div>;
}
```

Typing hooks and utilities is recommended. Example `useApi` signature:

```ts
function useApi<T>(url: string): { data: T | null; loading: boolean; error: Error | null }
```

---

## 20. Accessibility (A11y)

Accessibility is essential. Follow these rules:

- Use semantic HTML elements whenever possible.
- Provide descriptive alt text for images.
- Ensure all interactive controls are keyboard-accessible.
- Use ARIA roles and attributes when semantic markup is insufficient.

Example: accessible button

```jsx
<button aria-pressed={isActive} onClick={toggle}>Toggle</button>
```

Test accessibility with browser extensions and automated tools (axe-core).

---

## 21. Internationalization & Localization

Plan for i18n early: separate text, support pluralization, and directionality.

Libraries: `react-intl`, `i18next`.

Avoid hardcoding strings; use IDs and translation files.

---

## 22. Folder Structure & Project Layout

A typical React folder layout:

```
src/
  components/
  features/
  pages/
  hooks/
  services/
  styles/
  App.tsx
  index.tsx
```

Guidelines:

- Co-locate component files and styles.
- Keep shared utilities in `services` or `lib`.
- Use `features` for domain-based grouping (recommended for larger apps).

---

## 23. Build & Production

Optimize production bundles:

- Tree-shaking and ES module output by default with modern bundlers.
- Minify and compress (gzip/brotli) assets on the server.
- Use environment variables for runtime config: `process.env` or Vite's `import.meta.env`.

Deploy options: Vercel, Netlify, Cloudflare Pages, static hosting via S3+CloudFront.

---

## 24. Debugging & Profiling

- Use React DevTools for inspecting component props, state, and hooks.
- Use the Profiler tab to identify slow components and unnecessary re-renders.
- Add console logs temporarily; remove them before committing.

---

## 25. Common Pitfalls and How to Avoid Them

- Missing `key` in lists: leads to UI glitches.
- Too much global state: prefer local state where possible.
- Over-reliance on `any` in TypeScript: defeats the purpose of types.
- Forgetting cleanup in `useEffect`: memory leaks and background tasks.

---

## 26. Developer Workflow and Tools

- Use `eslint` with `plugin:react-hooks` and `@typescript-eslint` rules.
- Use `prettier` for consistent formatting.
- Use `husky` + `lint-staged` to enforce checks on commit.

Commands to try locally:

```bash
npm create vite@latest my-app --template react-ts
cd my-app
npm install
npm run dev
npm run lint
npm run build
```

---

## 27. Learning Exercises (Progressive)

1. Convert static HTML to JSX and fix issues like `class`.
2. Build a `Counter` with `useState` and unit test it.
3. Create a `Todo` app using `useReducer` and persist to `localStorage`.
4. Add routing and lazy load the `Todo` details page.

---

## 28. Full Example — Mini App Architecture

This section shows a minimal app structure and key code snippets used
throughout the course. The full implementation is left as exercises.

`src/App.tsx` (simplified):

```tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Tasks from './pages/Tasks';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/tasks" element={<Tasks />} />
      </Routes>
    </BrowserRouter>
  );
}
```

---

## 29. Reference Checklist (Practical)

- [ ] Project scaffolded with TypeScript and linting
- [ ] Components typed and documented
- [ ] Accessiblity checks run
- [ ] Unit and integration tests for core flows
- [ ] CI pipeline runs lint and build

---

## 30. Additional Resources

- React official docs: https://reactjs.org/docs/getting-started.html
- React Hooks FAQ: https://reactjs.org/docs/hooks-faq.html
- TypeScript + React: https://react-typescript-cheatsheet.netlify.app/
- Testing: https://testing-library.com/docs/react-testing-library/intro/

---

## 31. FAQ

Q: Should I always use hooks?
A: Yes for new code. Hooks are the standard way to manage state and side
effects in function components.

Q: When to use Redux?
A: Use Redux for large apps that require a single immutable store, time
travel debugging, and predictable update patterns. Start with local state
and Context where suitable.

---

## 32. Summary

This topic provides a comprehensive overview of React fundamentals and a
practical guide to building production-ready apps. Continue by implementing
the exercises, then move to routing, forms, state management, and testing
as separate topics.

---

End of Topic 1 Notes.

---

## Appendix A: Advanced Hooks & Patterns

### `useLayoutEffect` vs `useEffect`

- `useLayoutEffect` runs synchronously after DOM mutations but before the
  browser paints. Use it when you must measure DOM elements and synchronously
  apply changes that would otherwise cause flicker.
- `useEffect` runs after paint and is generally preferred to avoid blocking
  the UI thread.

Example: measuring an element

```jsx
useLayoutEffect(() => {
  const rect = ref.current.getBoundingClientRect();
  setSize({ width: rect.width, height: rect.height });
}, []);
```

### `useImperativeHandle`

Expose imperative methods from a child component to the parent.

```jsx
useImperativeHandle(ref, () => ({ focus: () => inputRef.current.focus() }));
```

### Compound components pattern

Allow flexible APIs where components share implicit state via context.

```jsx
<Tabs>
  <TabList>
    <Tab>One</Tab>
    <Tab>Two</Tab>
  </TabList>
  <TabPanels>
    <TabPanel>Panel One</TabPanel>
    <TabPanel>Panel Two</TabPanel>
  </TabPanels>
</Tabs>
```

---

## Appendix B: Concurrency & New React Features

React has been introducing concurrency features to help build responsive apps.

Key APIs:

- `startTransition` for marking non-urgent updates.
- `Suspense` for data fetching (experimental for server use).

Example: `startTransition`

```jsx
import { startTransition } from 'react';

function onFilterChange(value) {
  startTransition(() => {
    setFilter(value);
  });
}
```

This tells React that updates inside the callback are low-priority and can
be interrupted to keep the UI responsive.

---

## Appendix C: Data Fetching Patterns

### Fetching options

- `fetch` / `axios` for simple requests
- React Query / SWR for caching, revalidation, and optimistic updates

React Query gives you:

- Caching and background revalidation
- Mutations with optimistic updates
- Automatic retries and stale-while-revalidate logic

Example mutation with optimistic update:

```js
const queryClient = useQueryClient();
useMutation(addTodo, {
  onMutate: async newTodo => {
    await queryClient.cancelQueries('todos');
    const previous = queryClient.getQueryData('todos');
    queryClient.setQueryData('todos', old => [...old, newTodo]);
    return { previous };
  },
  onError: (err, variables, context) => queryClient.setQueryData('todos', context.previous),
  onSettled: () => queryClient.invalidateQueries('todos')
});
```

### Pagination & Infinite Scrolling

Use key-based fetching and cursor-based pagination where possible. React
Query and SWR both provide utilities for paginated fetching.

---

## Appendix D: Security Considerations

- Sanitize user input before rendering as HTML. Avoid `dangerouslySetInnerHTML`
  unless content is sanitized and trusted.
- Protect authentication tokens; do not store sensitive tokens in localStorage
  if XSS risk is high — consider httpOnly cookies for server-provided tokens.
- Escape values when interpolating into attributes or HTML.

---

## Appendix E: Server-Side Rendering & SEO

Consider SSR with frameworks like Next.js for better SEO and faster first
paint. SSR provides HTML to crawlers and improves perceived performance.

Notes:

- Use data-fetching methods appropriate to your SSR framework (Next.js
  `getServerSideProps`, `getStaticProps`).
- Hydration is the client-side process that attaches event handlers to the
  server-rendered markup.

---

## Appendix F: E2E Testing and CI

E2E tools: Cypress, Playwright.

CI checklist for PRs:

- Run `npm ci` and install dependencies.
- Run `npm run lint` and `npm run test`.
- Optionally run E2E tests in a headless environment.

Sample GitHub Actions snippet for E2E:

```yaml
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - run: npm ci
      - run: npm start &
      - run: npx wait-on http://localhost:3000
      - run: npx cypress run
```

---

## Appendix G: Component API Design Guidelines

Design public component APIs carefully:

- Keep props minimal and predictable.
- Favor primitive props (string, boolean) and a small object for complex
  config.
- Provide sensible defaults and allow override via `className` or `style`.

Example: `Button` API

```tsx
type ButtonProps = {
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
  onClick?: () => void;
  children?: React.ReactNode;
};
```

---

## Appendix H: Glossary

- DOM: Document Object Model.
- JSX: JavaScript XML — React's templating syntax.
- Hook: Function that lets you use React features in function components.
- Reconciliation: The process React uses to update the DOM efficiently.

---

## Appendix I: Extended Exercises (30+ tasks)

These exercises are intended to solidify understanding with practical work.

1. Implement a `useApi` hook with caching and TTL.
2. Build a `PaginatedList` component that uses cursor-based pagination.
3. Implement optimistic updates for a todo app using React Query.
4. Create a `ThemeContext` with dark/light modes and persist choice to
   `localStorage` with a custom hook.
5. Build an accessible modal component using portals and focus trap.
6. Add keyboard navigation to a custom dropdown component.
7. Create a `useForm` hook that validates and reports errors.
8. Implement server-side rendering with Next.js for a small blog.
9. Build integration tests for the todo app with msw and RTL.
10. Add Cypress E2E tests for the login and task flows.
11. Create a small component library and publish it locally via `npm pack`.
12. Implement performance monitoring: track render times and slow components.

(Continue: advanced topics like micro-frontends, code generation, and
performance budgets are left as optional research tasks.)

---

## Appendix J: Production Readiness Checklist

- Linting and formatting enforced on commit.
- Test coverage for critical paths.
- Accessibility checks executed in CI.
- Security review for XSS/CSRF vulnerabilities.
- Monitoring and error reporting (Sentry, LogRocket).

---


End of Topic 1 — Extended material and exercises.

---

## Appendix K: Migration & Upgrade Strategies

If you have an older codebase with class components, migrate incrementally.

Steps:

1. Add tests for the existing behavior.
2. Convert small presentational components to function components.
3. Replace lifecycle with equivalent hooks (`componentDidMount` → `useEffect` with `[]`).
4. Replace stateful logic with `useReducer` or custom hooks where appropriate.

When upgrading React versions:

- Review the Breaking Changes notes in the release changelog.
- Run the app in a separate branch and ensure tests pass.

---

## Appendix L: React Native — Brief Notes

React Native shares the component model and hooks, but the underlying
rendering targets native components rather than the DOM.

Differences to remember:

- Use components from `react-native` (View, Text, Image) not div/h1.
- Styling uses a JS object API (similar to inline styles) and is optimized
  for native rendering.

---

## Appendix M: Micro-frontends and Integration Patterns

For very large systems consider micro-frontends to split teams and releases.

Approaches:

- Web Components: encapsulation via Shadow DOM.
- Module Federation (Webpack) for runtime loading of remote components.
- Iframes for strict isolation (rare due to UX limitations).

Tradeoffs: runtime complexity vs team autonomy.

---

## Appendix N: Design Systems & Theming

Design systems provide a consistent set of components and tokens.

Key topics:

- Token design: colors, spacing, typography
- Theming strategy: CSS variables vs CSS-in-JS
- Accessibility baked into components (focus styles, contrast)

Example token file (JSON):

```json
{
  "color": { "primary": "#0b5fff", "muted": "#6b7280" },
  "spacing": { "sm": 4, "md": 8, "lg": 16 }
}
```

---

## Appendix O: Naming Conventions & Style Guide

Consistency improves readability.

Rules:

- Components in `PascalCase` (e.g., `UserCard`).
- Files: either `ComponentName.tsx` or `component-name.tsx` depending on
  project convention.
- Hooks prefixed with `use` and in `camelCase` (e.g., `useAuth`).

---

## Appendix P: Long Exercise Catalogue (Detailed)

The following exercises are intentionally granular to provide hands-on
practice. Each exercise includes acceptance criteria and hints.

Exercise 1: Accessible Modal

- Acceptance criteria:
  - Opens/closes with a button press
  - Focus trap inside the modal
  - Closes on `Escape`
  - Announce role to screen readers

Hint: Use portals, `aria-modal`, and a focus trap library or implement one.

Exercise 2: Form Library Integration

- Acceptance criteria:
  - Use React Hook Form to build a multi-step signup form
  - Validate server-side unique email check
  - Show inline errors and disable Next when invalid

Hint: Use `yup` for schema validation and `useForm` from React Hook Form.

Exercise 3: Real-time Updates

- Acceptance criteria:
  - Connect to a WebSocket source and update the UI in real-time
  - Show connection state (connecting, connected, disconnected)
  - Reconnect logic with exponential backoff

Hint: Use `useEffect` and refs to manage socket lifecycle. Clean up on
component unmount.

Exercise 4: GraphQL Integration

- Acceptance criteria:
  - Use Apollo Client or Urql to fetch and cache data
  - Implement a paginated query
  - Update cache after mutations to keep UI in sync

Hint: Learn cache update patterns or use `refetchQueries` where appropriate.

Exercise 5: Component Library Publishing

- Acceptance criteria:
  - Build a small set of components with TypeScript types
  - Create a build that outputs ES modules and type declarations
  - Document components with examples

Hint: Use Rollup or Vite library mode for bundling.

---

## Appendix Q: Cheatsheets

Short, copy-paste ready snippets for common tasks.

UseState:

```jsx
const [value, setValue] = useState(initial);
```

UseEffect for fetch:

```jsx
useEffect(() => {
  let mounted = true;
  async function load() { const res = await fetch(url); if (mounted) setData(await res.json()); }
  load();
  return () => { mounted = false; };
}, [url]);
```

Memo:

```jsx
const memoized = useMemo(() => expensive(a, b), [a, b]);
```

Callback:

```jsx
const handle = useCallback(() => doSomething(x), [x]);
```

---

## Appendix R: References and Further Reading

- Official docs: https://reactjs.org/
- React patterns: https://reactpatterns.com/
- React Query docs: https://tanstack.com/query/latest
- Accessibility: https://www.w3.org/WAI/

---

## Final Notes

This completes Topic 1 with an extended, practical, and reference-rich
document. If you'd like, I'll now expand Topics 2–4 with the same depth and
line count. After you approve one or two more topics, I'll batch-create the
remaining topics to the same standard.


