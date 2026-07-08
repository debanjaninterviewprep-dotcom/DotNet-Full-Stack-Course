# Topic 06: Routing and Navigation — Interview Questions

---

## Q1. What is React Router and what problem does it solve?
**Answer:**
React Router is the standard routing library for React SPAs. It maps URL paths to components without full page reloads:

```jsx
// Without React Router — manual URL checking
if (window.location.pathname === '/users') return <UserList />;
if (window.location.pathname === '/about') return <About />;

// With React Router v6
import { BrowserRouter, Routes, Route } from 'react-router-dom';
function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/"       element={<Home />} />
        <Route path="/users"  element={<UserList />} />
        <Route path="/users/:id" element={<UserDetail />} />
        <Route path="/about"  element={<About />} />
        <Route path="*"       element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
```

---

## Q2. What is the difference between `BrowserRouter`, `HashRouter`, and `MemoryRouter`?
**Answer:**
| | `BrowserRouter` | `HashRouter` | `MemoryRouter` |
|---|---|---|---|
| **URL style** | `/users/42` | `/#/users/42` | (in memory, no URL) |
| **Server needed?** | Yes — server must serve index.html for all paths | No | No |
| **SEO** | ✓ Good | ✗ Poor (crawlers ignore `#`) |  N/A |
| **Use case** | Modern SPAs | Static hosting, legacy | Tests, non-browser environments |

```jsx
// BrowserRouter — real URLs (requires server config)
<BrowserRouter>...</BrowserRouter>

// HashRouter — hash-based URLs (no server config needed)
<HashRouter>...</HashRouter>

// MemoryRouter — for tests
<MemoryRouter initialEntries={['/users/1']}>...</MemoryRouter>
```

---

## Q3. How do you access route parameters?
**Answer:**
```jsx
// Route definition
<Route path="/users/:id" element={<UserDetail />} />
<Route path="/shop/:category/:productId" element={<Product />} />

// Access in component
import { useParams } from 'react-router-dom';

function UserDetail() {
  const { id } = useParams(); // { id: '42' } — always string
  const userId = parseInt(id!);

  const { data: user } = useFetch(`/api/users/${userId}`);
  return <h1>{user?.name}</h1>;
}

// Multiple params
function Product() {
  const { category, productId } = useParams<{ category: string; productId: string }>();
}
```

---

## Q4. How do you handle query parameters?
**Answer:**
```jsx
import { useSearchParams } from 'react-router-dom';

// URL: /users?sort=name&page=2&active=true
function UserList() {
  const [searchParams, setSearchParams] = useSearchParams();

  const sort   = searchParams.get('sort')   || 'id';
  const page   = parseInt(searchParams.get('page') || '1');
  const active = searchParams.get('active') === 'true';

  // Update query params without full navigation
  const handleSortChange = (newSort) => {
    setSearchParams(prev => {
      prev.set('sort', newSort);
      prev.set('page', '1'); // reset page on sort change
      return prev;
    });
  };

  return (
    <>
      <select value={sort} onChange={e => handleSortChange(e.target.value)}>
        <option value="id">ID</option>
        <option value="name">Name</option>
      </select>
      <UserTable sort={sort} page={page} active={active} />
    </>
  );
}
```

---

## Q5. How do you navigate programmatically?
**Answer:**
```jsx
import { useNavigate } from 'react-router-dom';

function LoginForm() {
  const navigate = useNavigate();

  const handleLogin = async (credentials) => {
    await login(credentials);
    navigate('/dashboard');           // navigate to path
    navigate('/dashboard', { replace: true }); // replace history entry
    navigate(-1);                     // go back
    navigate(1);                      // go forward
    navigate('/users', {
      state: { fromLogin: true }      // pass state (not visible in URL)
    });
  };

  // Access navigation state
  const location = useLocation();
  const { fromLogin } = location.state || {};
}
```

---

## Q6. What is `Link` vs `NavLink` vs `<a>`?
**Answer:**
| | `<Link>` | `<NavLink>` | `<a>` |
|---|---|---|---|
| **Purpose** | Client-side navigation | Same + active class | Full page reload |
| **Active state** | ✗ | ✓ `isActive` prop | ✗ |
| **Use case** | General navigation | Menus, tabs, breadcrumbs | External links |

```jsx
import { Link, NavLink } from 'react-router-dom';

// Link — basic navigation
<Link to="/users">Users</Link>
<Link to={`/users/${user.id}`} state={{ from: 'list' }}>View</Link>

// NavLink — adds 'active' class when route matches
<NavLink to="/users">Users</NavLink>
// <a href="/users" class="active"> when on /users

// Custom active style
<NavLink
  to="/dashboard"
  className={({ isActive, isPending }) =>
    isActive ? 'nav-link active' : isPending ? 'nav-link loading' : 'nav-link'
  }
  style={({ isActive }) => ({ fontWeight: isActive ? 'bold' : 'normal' })}
>
  Dashboard
</NavLink>

// External link — use regular <a>
<a href="https://example.com" target="_blank" rel="noopener noreferrer">External</a>
```

---

## Q7. How do you implement nested routes?
**Answer:**
```jsx
// App routes
<Routes>
  <Route path="/admin" element={<AdminLayout />}>        {/* layout route */}
    <Route index element={<AdminDashboard />} />          {/* /admin */}
    <Route path="users"    element={<AdminUsers />} />    {/* /admin/users */}
    <Route path="users/:id" element={<UserEdit />} />     {/* /admin/users/42 */}
    <Route path="settings" element={<AdminSettings />} /> {/* /admin/settings */}
  </Route>
</Routes>

// AdminLayout — must render <Outlet /> for children
import { Outlet, NavLink } from 'react-router-dom';
function AdminLayout() {
  return (
    <div className="admin">
      <nav>
        <NavLink to="/admin">Dashboard</NavLink>
        <NavLink to="/admin/users">Users</NavLink>
        <NavLink to="/admin/settings">Settings</NavLink>
      </nav>
      <main>
        <Outlet />  {/* child route renders here */}
      </main>
    </div>
  );
}
```

---

## Q8. How do you implement protected routes?
**Answer:**
```jsx
// AuthGuard component
function PrivateRoute({ children }) {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) return <LoadingSpinner />;

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
}

// Or as a layout route
function RequireAuth() {
  const { isAuthenticated } = useAuth();
  const location = useLocation();
  if (!isAuthenticated) return <Navigate to="/login" state={{ from: location }} replace />;
  return <Outlet />; // renders nested routes
}

// Route config
<Routes>
  <Route path="/login" element={<Login />} />
  <Route element={<RequireAuth />}>           {/* protected layout */}
    <Route path="/dashboard" element={<Dashboard />} />
    <Route path="/profile"   element={<Profile />} />
  </Route>
</Routes>

// Redirect back after login
function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from?.pathname || '/dashboard';

  const handleLogin = async () => {
    await loginUser();
    navigate(from, { replace: true }); // go to where they came from
  };
}
```

---

## Q9. How do you implement lazy loading with React Router?
**Answer:**
```jsx
import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

// Lazy load route components
const Home      = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Users     = lazy(() => import('./pages/Users'));
const Reports   = lazy(() => import('./pages/Reports'));

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<PageLoader />}>  {/* shown while chunk loads */}
        <Routes>
          <Route path="/"          element={<Home />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/users"     element={<Users />} />
          <Route path="/reports"   element={<Reports />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

Each page becomes a separate chunk downloaded only when navigated to.

---

## Q10. What is `useLocation` and `useNavigate`?
**Answer:**
```jsx
import { useLocation, useNavigate } from 'react-router-dom';

function Page() {
  const location = useLocation();
  const navigate = useNavigate();

  // location object
  console.log(location.pathname);  // '/users/42'
  console.log(location.search);    // '?sort=name&page=2'
  console.log(location.hash);      // '#section-1'
  console.log(location.state);     // navigation state (from Link/navigate)
  console.log(location.key);       // unique key for this history entry

  // useNavigate
  navigate('/home');                    // push to history
  navigate('/home', { replace: true }); // replace current entry
  navigate(-1);                         // go back
  navigate('/users', {
    state: { message: 'Welcome back!' }
  });
}
```

---

## Q11. What is an index route and how does it work?
**Answer:**
An index route renders when the parent route matches exactly (no child path):

```jsx
<Route path="/users" element={<UsersLayout />}>
  <Route index element={<UserList />} />       {/* renders at exactly /users */}
  <Route path=":id" element={<UserDetail />} /> {/* renders at /users/42 */}
  <Route path="new"  element={<UserForm />} />  {/* renders at /users/new */}
</Route>

// Without index route: visiting /users renders UsersLayout with empty Outlet
// With index route:    visiting /users renders UsersLayout + UserList

// Alternative: redirect from parent to index
<Route path="/admin" element={<AdminLayout />}>
  <Route index element={<Navigate to="dashboard" replace />} />
  <Route path="dashboard" element={<Dashboard />} />
</Route>
```

---

## Q12. What is the `<Navigate>` component?
**Answer:**
`<Navigate>` is a declarative way to redirect — renders nothing but changes the URL:

```jsx
// Redirect unauthenticated users
function ProtectedPage() {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <DashboardContent />;
}

// Default route redirect
<Route path="/" element={<Navigate to="/dashboard" replace />} />

// Redirect with preserved state
<Navigate to="/login" state={{ from: location }} replace />

// Conditional redirect
{role === 'admin'
  ? <Navigate to="/admin/dashboard" replace />
  : <Navigate to="/user/dashboard" replace />
}
```

---

## Q13. What is `useOutletContext`?
**Answer:**
`useOutletContext` allows a parent layout route to share data with child routes through `<Outlet>`:

```jsx
// Parent layout — passes data through Outlet context
function DashboardLayout() {
  const { user } = useAuth();
  const [notifications, setNotifications] = useState([]);

  return (
    <div>
      <Sidebar />
      <main>
        <Outlet context={{ user, notifications }} /> {/* pass to children */}
      </main>
    </div>
  );
}

// Child route — consumes context
function ProfilePage() {
  const { user, notifications } = useOutletContext();
  return <h1>Welcome, {user.name}</h1>;
}
```

---

## Q14. What is the difference between `replace` and `push` navigation?
**Answer:**
```jsx
// push (default) — adds entry to history stack
navigate('/dashboard');
// History: ['/home', '/login', '/dashboard']
// Back button goes to: '/login'

// replace — replaces current entry in history
navigate('/dashboard', { replace: true });
// History: ['/home', '/dashboard']  ← '/login' replaced
// Back button goes to: '/home'

// Use replace for:
// - Login redirects (user shouldn't go "back" to login)
// - Redirects after form submission
// - Default route redirects
<Navigate to="/dashboard" replace />
```

---

## Q15. What is a loader and action in React Router v6.4+?
**Answer:**
Data APIs in React Router allow loading data and handling mutations at the route level (similar to Next.js):

```jsx
// Route with loader (pre-loads data)
const router = createBrowserRouter([
  {
    path: '/users/:id',
    element: <UserDetail />,
    loader: async ({ params }) => {
      const user = await fetchUser(params.id);
      if (!user) throw new Response('Not Found', { status: 404 });
      return user;
    },
    errorElement: <ErrorPage />
  }
]);

// Component uses loaded data (no useEffect needed!)
import { useLoaderData } from 'react-router-dom';
function UserDetail() {
  const user = useLoaderData(); // already loaded — no loading state needed
  return <h1>{user.name}</h1>;
}

// Action — handles form submissions
{ action: async ({ request }) => {
    const formData = await request.formData();
    await createUser(Object.fromEntries(formData));
    return redirect('/users');
  }
}
```
