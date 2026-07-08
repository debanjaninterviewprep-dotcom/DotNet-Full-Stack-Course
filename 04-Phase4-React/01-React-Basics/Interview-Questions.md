# Topic 01: React Basics — Interview Questions

---

## Q1. What is React and what are its core principles?
**Answer:**
React is a **JavaScript library** (not a framework) for building user interfaces, maintained by Meta. It focuses exclusively on the View layer.

Core principles:
- **Component-based** — UI split into reusable, self-contained components.
- **Declarative** — describe what the UI should look like; React figures out how to update it.
- **Unidirectional data flow** — data flows down (parent → child via props), events flow up (child → parent via callbacks).
- **Virtual DOM** — React keeps a lightweight in-memory copy of the real DOM to minimize expensive real DOM operations.
- **Learn once, write anywhere** — same concepts for web (ReactDOM), mobile (React Native), and server rendering (Next.js).

---

## Q2. What is the Virtual DOM and how does React use it?
**Answer:**
The Virtual DOM (VDOM) is an **in-memory JavaScript representation** of the real DOM tree.

Reconciliation process:
1. When state/props change, React creates a **new VDOM tree**.
2. React **diffs** the new tree against the previous one using the reconciliation algorithm.
3. React computes the **minimum set of changes** (patches) needed.
4. React applies those changes to the **real DOM** in a single batch.

```
State Change
    ↓
New VDOM tree created
    ↓
Diffing algorithm (O(n) heuristics):
  - Different element types → full subtree replacement
  - Same element type → update only changed attributes
  - Lists → use key prop to track identity
    ↓
Minimal DOM updates applied
```

This avoids expensive direct DOM manipulation and keeps performance high.

---

## Q3. What is JSX and how does it compile?
**Answer:**
JSX (JavaScript XML) is a syntax extension for JavaScript that looks like HTML but compiles to `React.createElement()` calls:

```jsx
// JSX
const element = <h1 className="title">Hello {name}</h1>;

// Compiled output (React 17+ JSX transform — no React import needed)
import { jsx as _jsx } from 'react/jsx-runtime';
const element = _jsx("h1", { className: "title", children: `Hello ${name}` });

// Older transform (React < 17 — required React import)
const element = React.createElement("h1", { className: "title" }, `Hello ${name}`);
```

JSX rules:
- Every component must return a single root element (or Fragment `<>…</>`).
- `class` → `className`, `for` → `htmlFor` (JS reserved words).
- Self-closing tags must end with `/>`
- Expressions in `{}` — objects, arrays, functions.
- `null`, `undefined`, `false` render nothing.

---

## Q4. What is React Fiber?
**Answer:**
React Fiber (introduced in React 16) is a **complete rewrite of React's reconciliation engine** to enable incremental rendering:

**Old stack reconciler (pre-16):** Rendering was synchronous and couldn't be interrupted — long renders blocked the main thread causing jank.

**Fiber:** Work is split into small units called **fibers**. React can:
- **Pause** work and resume later.
- **Prioritize** different types of updates (user input > background data loading).
- **Abort** and restart work if it becomes stale.
- **Reuse** completed work.

This enables:
- React 18's **Concurrent Mode** (startTransition, useDeferredValue).
- **Suspense** — pause rendering while waiting for data.
- **Streaming SSR** — send HTML incrementally.

---

## Q5. What is the difference between React, Angular, and Vue?
**Answer:**
| | React | Angular | Vue |
|---|---|---|---|
| **Type** | UI Library | Full Framework | Progressive Framework |
| **Language** | JavaScript/TypeScript | TypeScript (required) | JavaScript/TypeScript |
| **Data binding** | One-way | Two-way | Two-way |
| **State management** | External (Redux, Zustand) | NgRx / Signals | Pinia / Vuex |
| **Learning curve** | Moderate | Steep | Gentle |
| **Size (min+gzip)** | ~45KB | ~130KB | ~34KB |
| **Rendering** | Virtual DOM | Real DOM + CD | Virtual DOM |
| **Maintainer** | Meta | Google | Community (Evan You) |
| **Use case** | Flexible SPA/SSR | Enterprise | Small-medium apps |

---

## Q6. What are React 18's major features?
**Answer:**
**Concurrent Rendering** — React can work on multiple state updates simultaneously:

```jsx
// startTransition — mark non-urgent updates (won't block input)
import { startTransition } from 'react';
startTransition(() => setSearchResults(filter(data, query)));

// useDeferredValue — defer rendering of heavy parts
const deferredList = useDeferredValue(heavyList); // renders with lower priority

// useTransition — track pending state of a transition
const [isPending, startTransition] = useTransition();
```

**Automatic Batching** — multiple setState calls in async contexts now batch together (was only in event handlers before):
```jsx
// React 18: both setA and setB batched into ONE re-render (even in setTimeout/fetch)
setTimeout(() => { setA(1); setB(2); }); // one render in React 18
```

**Suspense on the server** — streaming SSR with selective hydration.

**New root API:**
```jsx
// React 18
import { createRoot } from 'react-dom/client';
createRoot(document.getElementById('root')).render(<App />);
```

---

## Q7. What is the difference between a React element and a React component?
**Answer:**
- **React element** — a plain JavaScript object describing what to render. Immutable. Created by JSX or `React.createElement()`.
- **React component** — a function (or class) that accepts props and returns React elements.

```jsx
// React element — just a description
const element = <h1>Hello</h1>;
// { type: 'h1', props: { children: 'Hello' }, key: null, ref: null }

// React component — a function that returns elements
function Greeting({ name }) {
  return <h1>Hello {name}</h1>; // returns a React element
}

// Component creates element when called/rendered
const greetingElement = <Greeting name="Debanjan" />;
// { type: Greeting, props: { name: 'Debanjan' }, ... }
```

---

## Q8. What is reconciliation and what are the heuristics React uses?
**Answer:**
Reconciliation is React's algorithm to diff the old VDOM tree against the new one.

**Two key heuristics (make it O(n)):**

1. **Different element types → tear down and rebuild:**
```jsx
// Old: <div><Counter /></div>
// New: <span><Counter /></span>
// → Counter is unmounted and remounted (different type: div vs span)
```

2. **Use `key` prop to track list items:**
```jsx
// Without key — React diffs by position (wrong)
{items.map(item => <Item name={item.name} />)}

// With key — React tracks by identity (correct)
{items.map(item => <Item key={item.id} name={item.name} />)}
```

Without keys, React may reuse the wrong component instance when items are reordered, causing incorrect state.

---

## Q9. What is the difference between controlled and uncontrolled components?
**Answer:**
- **Controlled** — React controls the form element's value via state. The component is the "source of truth".
- **Uncontrolled** — The DOM element manages its own state; React accesses it via a `ref`.

```jsx
// Controlled
function ControlledInput() {
  const [value, setValue] = useState('');
  return <input value={value} onChange={e => setValue(e.target.value)} />;
}

// Uncontrolled
function UncontrolledInput() {
  const inputRef = useRef(null);
  const handleSubmit = () => console.log(inputRef.current.value);
  return <input ref={inputRef} defaultValue="initial" />;
}
```

**Prefer controlled components** — they make validation, conditional disabling, and formatting easier.

---

## Q10. What is a React Fragment and why is it used?
**Answer:**
Fragments let you group multiple elements without adding an extra DOM node:

```jsx
// Problem — extra <div> added to DOM
function Columns() {
  return (
    <div>           {/* extra DOM element — may break table layout */}
      <td>Name</td>
      <td>Age</td>
    </div>
  );
}

// Solution — Fragment (no DOM node added)
function Columns() {
  return (
    <>
      <td>Name</td>
      <td>Age</td>
    </>
  );
}

// Named Fragment (when key is needed for lists)
{items.map(item => (
  <React.Fragment key={item.id}>
    <dt>{item.term}</dt>
    <dd>{item.description}</dd>
  </React.Fragment>
))}
```

---

## Q11. What is server-side rendering (SSR) and how does React support it?
**Answer:**
SSR renders React components to HTML **on the server** before sending to the client, then React "hydrates" it on the client:

```
Client Request
    ↓
Server renders React → HTML string
    ↓
Browser receives HTML (immediately visible)
    ↓
React "hydrates" — attaches event listeners to existing HTML
    ↓
Fully interactive
```

Benefits: better SEO, faster First Contentful Paint (FCP), no blank page flash.

**Next.js** is the most popular framework for React SSR:
```jsx
// Next.js SSR — runs on server
export async function getServerSideProps() {
  const data = await fetchData();
  return { props: { data } };
}

// Next.js App Router (Next.js 13+) — Server Components by default
async function Page() {
  const data = await fetch('https://api.example.com/data').then(r => r.json());
  return <div>{data.title}</div>; // renders on server
}
```

---

## Q12. What is the difference between `ReactDOM.render()` and `createRoot()`?
**Answer:**
```jsx
// Legacy API (React 17 and below) — synchronous rendering
import ReactDOM from 'react-dom';
ReactDOM.render(<App />, document.getElementById('root'));

// React 18+ — enables Concurrent Mode
import { createRoot } from 'react-dom/client';
const root = createRoot(document.getElementById('root'));
root.render(<App />);

// For updates
root.render(<App newProp={value} />); // call render again

// Unmount
root.unmount();
```

`createRoot()` opts the app into React 18's concurrent features: automatic batching, startTransition, Suspense improvements.

---

## Q13. What is React StrictMode?
**Answer:**
`<React.StrictMode>` is a development tool that intentionally double-invokes certain functions to detect side effects and deprecated patterns:

```jsx
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

What StrictMode does (development only):
- **Double-invokes** render functions, state updaters, and reducers to detect impure functions.
- **Double-invokes** component function bodies and hooks to expose side effects.
- Warns about deprecated lifecycle methods.
- Warns about legacy string refs.
- Detects unexpected side effects in effects (runs effects twice).

**Does NOT affect production builds.**

---

## Q14. What is the key prop and when must you use it?
**Answer:**
`key` is a special prop that helps React identify which items in a list have changed, been added, or removed:

```jsx
// WITHOUT key — bugs when items reorder (React reuses wrong elements)
{users.map(user => <UserCard name={user.name} />)}

// WITH key — stable identity for each item
{users.map(user => <UserCard key={user.id} name={user.name} />)}

// Never use array index as key (unless list is static and never reordered)
{items.map((item, index) => <Item key={index} />)} // ❌ causes bugs on reorder

// Keys must be unique among siblings only (not globally)
```

**Rules:**
- Must be unique among siblings.
- Must be stable (don't use `Math.random()`).
- Use database IDs or stable string identifiers.
- Keys don't get passed to the component as a prop.

---

## Q15. What are React portals and when are they used?
**Answer:**
Portals render children into a DOM node outside the parent component's DOM hierarchy:

```jsx
import { createPortal } from 'react-dom';

function Modal({ children, isOpen }) {
  if (!isOpen) return null;
  return createPortal(
    <div className="modal-overlay">
      <div className="modal">{children}</div>
    </div>,
    document.body // render outside the component tree, directly to body
  );
}

// Usage
<Modal isOpen={showModal}>
  <h2>Are you sure?</h2>
  <button onClick={close}>Cancel</button>
</Modal>
```

**Use cases:** Modals, tooltips, dropdowns, toasts — anything that needs to escape a parent's `overflow: hidden` or `z-index` stacking context.

**Event bubbling still works:** Events triggered inside a portal bubble up through the React component tree (not the DOM tree).
