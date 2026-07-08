# Topic 03: Components and Props — Interview Questions

---

## Q1. What is the difference between functional and class components?
**Answer:**
| | Functional | Class |
|---|---|---|
| **Syntax** | Function | `class Foo extends React.Component` |
| **State** | `useState` hook | `this.state` |
- **Lifecycle** | Hooks (`useEffect`) | `componentDidMount`, `componentDidUpdate` |
| **`this`** | Not used | Required everywhere |
| **Performance** | Slightly better (less overhead) | Slightly more |
| **Hooks** | ✓ Yes | ✗ No |
| **Current status** | ✓ Recommended | Legacy |

```jsx
// Functional (modern — preferred)
function Greeting({ name }) {
  const [count, setCount] = useState(0);
  return <h1 onClick={() => setCount(c => c + 1)}>Hello {name} ({count})</h1>;
}

// Class (legacy)
class Greeting extends React.Component {
  state = { count: 0 };
  render() {
    return <h1 onClick={() => this.setState({ count: this.state.count + 1 })}>
      Hello {this.props.name} ({this.state.count})
    </h1>;
  }
}
```

---

## Q2. What are props and how do they work?
**Answer:**
Props (properties) are **read-only inputs** passed from parent to child components:

```jsx
// Parent passes props
<UserCard name="Debanjan" age={25} isAdmin={true} onClick={handleClick} />

// Child receives as first argument
function UserCard({ name, age, isAdmin, onClick }) {
  return (
    <div onClick={onClick}>
      <h2>{name}</h2>
      <p>Age: {age}</p>
      {isAdmin && <span>Admin</span>}
    </div>
  );
}
```

**Key rules:**
- Props flow **one direction** — parent to child.
- Props are **immutable** — never modify `props` directly.
- Any valid JavaScript value can be a prop (string, number, object, function, JSX).
- All React components must act like **pure functions** with respect to their props.

---

## Q3. What is the `children` prop?
**Answer:**
`children` is a special prop that represents the **content between opening and closing JSX tags**:

```jsx
// Card component uses children
function Card({ title, children, className }) {
  return (
    <div className={`card ${className}`}>
      <h2>{title}</h2>
      <div className="card-body">{children}</div>
    </div>
  );
}

// Usage — anything between tags becomes children
<Card title="User Profile" className="shadow">
  <img src="/avatar.jpg" alt="avatar" />
  <p>Debanjan Mukherjee</p>
  <button>Edit</button>
</Card>
```

TypeScript type for children:
```tsx
interface Props {
  children: React.ReactNode;  // most permissive — any valid React content
  // OR
  children: React.ReactElement;  // only JSX elements
  // OR
  children: string;              // only strings
}
```

---

## Q4. What are default props and how do you define them?
**Answer:**
```tsx
// Modern approach — default parameter values (recommended)
function Button({ label, variant = 'primary', size = 'md', disabled = false }) {
  return <button className={`btn-${variant} btn-${size}`} disabled={disabled}>{label}</button>;
}

// TypeScript approach
interface ButtonProps {
  label: string;
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}

function Button({ label, variant = 'primary', size = 'md' }: ButtonProps) {
  return <button className={`btn-${variant} btn-${size}`}>{label}</button>;
}

// Legacy approach (deprecated for functional components)
Button.defaultProps = { variant: 'primary', size: 'md' };
```

---

## Q5. What is PropTypes and when do you use TypeScript instead?
**Answer:**
`PropTypes` is a runtime prop type checker — validates props during development:

```jsx
import PropTypes from 'prop-types';

function UserCard({ name, age, isAdmin }) { ... }

UserCard.propTypes = {
  name:    PropTypes.string.isRequired,
  age:     PropTypes.number,
  isAdmin: PropTypes.bool,
  onClick: PropTypes.func
};
```

**PropTypes vs TypeScript:**
| | PropTypes | TypeScript |
|---|---|---|
| **Check time** | Runtime (development) | Compile time |
| **Bundle impact** | Small overhead | None (stripped) |
| **IDE support** | None | Full IntelliSense |
| **Coverage** | Components only | Entire codebase |

**Rule:** If using TypeScript, skip PropTypes entirely — TypeScript interfaces provide better coverage with zero runtime cost.

---

## Q6. What is component composition and how is it different from inheritance?
**Answer:**
React uses **composition** (combining components) instead of class inheritance:

```jsx
// Composition — build complex UIs from simple components
function Layout({ children }) {
  return (
    <div className="layout">
      <Header />
      <main>{children}</main>
      <Footer />
    </div>
  );
}

// Slot pattern — multiple content areas
function SplitPane({ left, right }) {
  return (
    <div className="split-pane">
      <div className="left">{left}</div>
      <div className="right">{right}</div>
    </div>
  );
}

// Usage
<SplitPane
  left={<UserList />}
  right={<UserDetail userId={selectedId} />}
/>
```

Inheritance is rarely (if ever) recommended in React — composition is more flexible and easier to reason about.

---

## Q7. What is lifting state up?
**Answer:**
When two sibling components need to share state, move the state to their **closest common ancestor**:

```jsx
// Problem: TemperatureInput and BoilingVerdict need to share temperature
// Solution: lift temperature state to Calculator (common parent)

function Calculator() {
  const [temp, setTemp] = useState('');

  return (
    <>
      <TemperatureInput value={temp} onChange={setTemp} />
      <BoilingVerdict celsius={parseFloat(temp)} />
    </>
  );
}

// Child receives value + callback — "controlled component"
function TemperatureInput({ value, onChange }) {
  return <input value={value} onChange={e => onChange(e.target.value)} />;
}
```

---

## Q8. What is prop drilling and how is it avoided?
**Answer:**
Prop drilling occurs when props are passed through multiple intermediate components that don't use them:

```jsx
// Prop drilling — Header doesn't use user, just passes it down
function App() { return <Header user={user} />; }
function Header({ user }) { return <Nav user={user} />; }
function Nav({ user }) { return <UserMenu user={user} />; }
function UserMenu({ user }) { return <span>{user.name}</span>; } // only this uses it
```

**Solutions:**
1. **Context API** — broadcast value without passing through intermediaries.
2. **Component composition** — pass the fully-formed component as a prop instead.
3. **State management** (Redux, Zustand) — access state anywhere.

```jsx
// Composition solution — pass UserMenu directly
function App() { return <Header userMenu={<UserMenu user={user} />} />; }
function Header({ userMenu }) { return <nav>{userMenu}</nav>; } // no user prop needed
```

---

## Q9. How do you type component props with TypeScript?
**Answer:**
```tsx
// Interface (preferred for component props)
interface UserCardProps {
  user: {
    id: number;
    name: string;
    email: string;
    avatar?: string; // optional
  };
  onDelete: (id: number) => void;
  isEditable?: boolean;
  children?: React.ReactNode;
}

// Functional component with typed props
function UserCard({ user, onDelete, isEditable = false, children }: UserCardProps) {
  return (
    <div>
      <h2>{user.name}</h2>
      {isEditable && <button onClick={() => onDelete(user.id)}>Delete</button>}
      {children}
    </div>
  );
}

// Generic component
function List<T>({ items, renderItem }: { items: T[]; renderItem: (item: T) => React.ReactNode }) {
  return <ul>{items.map((item, i) => <li key={i}>{renderItem(item)}</li>)}</ul>;
}
```

---

## Q10. What are Higher-Order Components (HOCs)?
**Answer:**
A HOC is a function that takes a component and returns a new enhanced component:

```jsx
// HOC — adds loading state to any component
function withLoading(WrappedComponent) {
  return function WithLoadingComponent({ isLoading, ...props }) {
    if (isLoading) return <Spinner />;
    return <WrappedComponent {...props} />;
  };
}

// HOC — adds authentication check
function withAuth(WrappedComponent) {
  return function AuthenticatedComponent(props) {
    const { isAuthenticated } = useAuth();
    if (!isAuthenticated) return <Navigate to="/login" />;
    return <WrappedComponent {...props} />;
  };
}

const AuthUserList = withAuth(UserList);
const LoadableUserList = withLoading(UserList);
```

**Modern alternative:** Custom hooks replaced most HOC use cases. HOCs are still useful for cross-cutting concerns that need JSX wrapping.

---

## Q11. What are render props?
**Answer:**
A render prop is a function prop that a component calls to determine what to render:

```jsx
// DataFetcher uses render prop to delegate rendering
function DataFetcher({ url, render }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    fetch(url).then(r => r.json()).then(d => { setData(d); setLoading(false); });
  }, [url]);
  return render({ data, loading });
}

// Usage
<DataFetcher
  url="/api/users"
  render={({ data, loading }) =>
    loading ? <Spinner /> : <UserList users={data} />
  }
/>
```

**Modern alternative:** Custom hooks have largely replaced render props for logic sharing:
```jsx
function useDataFetcher(url) { ... }
function UserPage() {
  const { data, loading } = useDataFetcher('/api/users');
  return loading ? <Spinner /> : <UserList users={data} />;
}
```

---

## Q12. What is a controlled vs uncontrolled component (in context of props)?
**Answer:**
The concept also applies to custom components:

```jsx
// Uncontrolled — manages its own open/closed state internally
function Accordion() {
  const [isOpen, setIsOpen] = useState(false); // self-managed
  return <div onClick={() => setIsOpen(o => !o)}>{isOpen ? 'Content' : 'Click to open'}</div>;
}

// Controlled — parent owns the state, passes value + onChange
function Accordion({ isOpen, onToggle }) {
  return <div onClick={onToggle}>{isOpen ? 'Content' : 'Click to open'}</div>;
}

// Usage of controlled Accordion
const [open, setOpen] = useState(false);
<Accordion isOpen={open} onToggle={() => setOpen(o => !o)} />
```

Controlled components are more flexible — the parent can respond to changes or override the value.

---

## Q13. What are Forward Refs and why are they needed?
**Answer:**
`forwardRef` passes a `ref` through a component to a child DOM element or component instance:

```jsx
// Without forwardRef — parent can't get a ref to the input inside CustomInput
function CustomInput({ label }) {
  return <input placeholder={label} />; // ref can't reach this input
}

// With forwardRef — parent can access the underlying input
const CustomInput = React.forwardRef(function CustomInput({ label }, ref) {
  return <input ref={ref} placeholder={label} />;
});

// Parent can now focus the input
function Form() {
  const inputRef = useRef(null);
  return (
    <>
      <CustomInput label="Name" ref={inputRef} />
      <button onClick={() => inputRef.current?.focus()}>Focus Input</button>
    </>
  );
}
```

---

## Q14. What is `useImperativeHandle`?
**Answer:**
`useImperativeHandle` customizes what is exposed when a parent uses a `ref` on a component:

```jsx
const VideoPlayer = React.forwardRef(function VideoPlayer(props, ref) {
  const videoRef = useRef(null);

  // Expose only specific methods — not the entire DOM element
  useImperativeHandle(ref, () => ({
    play:  () => videoRef.current?.play(),
    pause: () => videoRef.current?.pause(),
    seek:  (time) => { if (videoRef.current) videoRef.current.currentTime = time; }
    // Does NOT expose: videoRef.current.src, videoRef.current.style, etc.
  }));

  return <video ref={videoRef} src={props.src} />;
});

// Parent
const playerRef = useRef(null);
<VideoPlayer ref={playerRef} src="/video.mp4" />
<button onClick={() => playerRef.current?.play()}>Play</button>
```

---

## Q15. How do you share logic between components without HOCs or render props?
**Answer:**
**Custom hooks** — extract shared stateful logic into reusable functions prefixed with `use`:

```jsx
// Shared logic extracted to a custom hook
function useWindowSize() {
  const [size, setSize] = useState({ width: window.innerWidth, height: window.innerHeight });
  useEffect(() => {
    const handler = () => setSize({ width: window.innerWidth, height: window.innerHeight });
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }, []);
  return size;
}

// Any component can use it
function Header() {
  const { width } = useWindowSize();
  return <nav>{width < 768 ? <MobileMenu /> : <DesktopMenu />}</nav>;
}

function Chart() {
  const { width, height } = useWindowSize();
  return <canvas width={width} height={height} />;
}
```

Custom hooks are the modern recommended pattern for sharing logic between components.
