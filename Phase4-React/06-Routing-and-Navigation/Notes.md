# Topic 6: Routing & Navigation (React Router)

> Covers **React Router v6.4+ / v7** — the data router era. Concepts also apply to TanStack Router and Next.js App Router with naming differences.

---

## 1. Why a Router? SPA vs MPA

A traditional **Multi-Page Application (MPA)** asks the server for a brand-new HTML document on every link click — full reload, lost in-memory state, flash of white screen. A **Single-Page Application (SPA)** loads one shell document, then JavaScript swaps the visible UI in place while the URL changes via the browser's **History API**. A router is the layer that:

1. Listens for URL changes (clicks, back/forward, programmatic).
2. Matches the current URL against a configured route tree.
3. Renders the matching component(s) — often nested.
4. Synchronises browser history so back/forward, bookmarks, deep links, and refresh all work.

### History API primer

| API | Effect | Triggers `popstate`? |
|-----|--------|----------------------|
| `history.pushState(state, '', url)` | Adds a new entry, URL changes, **no reload** | No (only on back/forward) |
| `history.replaceState(state, '', url)` | Replaces current entry | No |
| `window.addEventListener('popstate', ...)` | Fires on back/forward / `history.go()` | — |
| `location.assign(url)` | Full page navigation | N/A |

React Router wraps these so you rarely call them directly.

---

## 2. Router Flavours

| Router | URL shape | Server config needed? | Use when |
|--------|-----------|------------------------|----------|
| `BrowserRouter` / `createBrowserRouter` | `/users/42` (clean) | **Yes** — server must serve `index.html` for unknown paths | Production web apps you control the server for |
| `HashRouter` / `createHashRouter` | `/#/users/42` | No — everything after `#` is client-only | Static hosting (GitHub Pages without rewrites), legacy hosts |
| `MemoryRouter` / `createMemoryRouter` | In-memory only, no URL bar sync | No | Tests, React Native, Storybook, embedded previews |
| `StaticRouter` | One-shot render against a given URL | — | Server-side rendering |

```tsx
// Typical SPA bootstrap
import { BrowserRouter } from 'react-router-dom';
createRoot(document.getElementById('root')!).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
);
```

---

## 3. Installation

```bash
npm install react-router-dom
# Types ship with the package — no separate @types install needed.
```

> v7 unifies `react-router` and `react-router-dom`. v6 examples below mostly work unchanged on v7.

---

## 4. Declarative Setup: `<Routes>` / `<Route>`

```tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/"          element={<Home />} />
        <Route path="/about"     element={<About />} />
        <Route path="/users/:id" element={<UserPage />} />
        <Route path="/files/*"   element={<FileBrowser />} />
        <Route path="*"          element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
```

### Path patterns

| Pattern | Matches | Notes |
|---------|---------|-------|
| `/users/:id` | `/users/42` | `id` is a required dynamic segment |
| `/users/:id?` | `/users` and `/users/42` | v6.4+ optional segments via `?` |
| `/files/*` | `/files/a/b/c` | "splat" — capture rest of URL |
| `/` (index route) | parent's exact URL | nested only |
| `*` | anything not matched above | place last for 404 |

Routes are ranked automatically — most specific wins, you don't need an `exact` prop.

---

## 5. Core Hooks

```tsx
import {
  useParams, useNavigate, useLocation,
  useSearchParams, useMatch, useResolvedPath
} from 'react-router-dom';

function UserPage() {
  const { id } = useParams<{ id: string }>();         // dynamic segments
  const navigate = useNavigate();                     // programmatic nav
  const location = useLocation();                     // { pathname, search, hash, state, key }
  const [params, setParams] = useSearchParams();      // ?foo=bar CRUD
  const match = useMatch('/users/:id');               // boolean-ish: did this pattern match?
  const resolved = useResolvedPath('settings');       // resolves relative to current route

  return (
    <button onClick={() => navigate(`/users/${id}/edit`, { state: { from: location } })}>
      Edit
    </button>
  );
}
```

### Programmatic navigation

```tsx
navigate('/dashboard');                       // push
navigate('/login', { replace: true });        // replace — back button skips current
navigate(-1);                                 // browser back
navigate(1);                                  // browser forward
navigate('/checkout', { state: { cart } });   // pass state without serialising in URL
```

> `location.state` is preserved across history but **not** on full reload — it lives in `history.state`, not the URL. For shareable state use search params.

---

## 6. Nested Routes, Layouts, and `<Outlet/>`

Nesting lets you compose UI: a layout (header/sidebar) wraps many child pages.

```tsx
import { Outlet } from 'react-router-dom';

function DashboardLayout() {
  return (
    <div className="dash">
      <Sidebar />
      <main><Outlet /></main>      {/* child route renders here */}
    </div>
  );
}

<Routes>
  <Route path="/dashboard" element={<DashboardLayout />}>
    <Route index element={<DashHome />} />          {/* /dashboard */}
    <Route path="stats"     element={<Stats />} />  {/* /dashboard/stats */}
    <Route path="settings"  element={<Settings />} />
    <Route path="users/:id" element={<UserDetail />} />
  </Route>
</Routes>
```

**Layout routes** are routes without a `path`, used purely to wrap children:

```tsx
<Route element={<RequireAuth />}>      {/* gates everything inside */}
  <Route path="/admin" element={<AdminLayout />}>
    <Route index element={<AdminHome />} />
  </Route>
</Route>
```

---

## 7. Object Configuration: `createBrowserRouter` + `RouterProvider`

The modern way. Unlocks **loaders, actions, deferred data, error boundaries** at the route level.

```tsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';

const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <RootError />,
    children: [
      { index: true, element: <Home /> },
      {
        path: 'posts',
        loader: postsLoader,
        element: <PostsList />,
        children: [
          { path: ':slug', loader: postLoader, action: postAction, element: <Post /> }
        ]
      },
      { path: '*', element: <NotFound /> }
    ]
  }
]);

createRoot(document.getElementById('root')!).render(<RouterProvider router={router} />);
```

---

## 8. Data Routers: Loaders, Actions, `Form`

Loaders run **before** a route renders; actions run on form submission. Both can run in parallel for sibling routes.

```tsx
// loader runs on navigation to this route
export async function postLoader({ params, request }: LoaderFunctionArgs) {
  const res = await fetch(`/api/posts/${params.slug}`, { signal: request.signal });
  if (!res.ok) throw new Response('Not found', { status: 404 });
  return res.json();
}

// action runs on <Form method="post"> submission to this route
export async function postAction({ request, params }: ActionFunctionArgs) {
  const form = await request.formData();
  await fetch(`/api/posts/${params.slug}/comments`, {
    method: 'POST',
    body: JSON.stringify({ text: form.get('text') })
  });
  return redirect(`/posts/${params.slug}`);
}

function Post() {
  const post = useLoaderData() as Post;
  const nav   = useNavigation();          // 'idle' | 'loading' | 'submitting'
  const error = useActionData();          // value returned from action
  return (
    <article>
      <h1>{post.title}</h1>
      <Form method="post">
        <textarea name="text" required />
        <button disabled={nav.state === 'submitting'}>
          {nav.state === 'submitting' ? 'Posting…' : 'Comment'}
        </button>
      </Form>
    </article>
  );
}
```

### Deferred data (`defer` + `<Await/>`)

Stream slow data without blocking the whole route.

```tsx
import { defer, Await, useLoaderData } from 'react-router-dom';

export const loader = ({ params }: LoaderFunctionArgs) =>
  defer({
    post: fetchPost(params.slug!),                  // awaited (fast)
    comments: fetchComments(params.slug!)           // promise (slow, streamed)
  });

function Post() {
  const { post, comments } = useLoaderData() as any;
  return (
    <>
      <h1>{post.title}</h1>
      <Suspense fallback={<p>Loading comments…</p>}>
        <Await resolve={comments} errorElement={<p>Failed to load.</p>}>
          {(list: Comment[]) => <CommentList items={list} />}
        </Await>
      </Suspense>
    </>
  );
}
```

### Error boundaries per route

```tsx
{ path: 'posts/:slug', loader: postLoader, element: <Post />, errorElement: <PostError /> }
```

```tsx
function PostError() {
  const err = useRouteError();
  if (isRouteErrorResponse(err)) return <h1>{err.status} {err.statusText}</h1>;
  return <h1>Something went wrong</h1>;
}
```

### `useFetcher` — call loaders/actions without navigating

```tsx
const fetcher = useFetcher();
<fetcher.Form method="post" action="/posts/42/like">
  <button>{fetcher.state === 'submitting' ? '…' : '♥'}</button>
</fetcher.Form>
```

Use cases: inline likes, async dropdowns, optimistic toggles.

---

## 9. Navigation Components

```tsx
import { Link, NavLink, Navigate } from 'react-router-dom';

<Link to="/about">About</Link>
<Link to=".." relative="path">Up</Link>          {/* relative path navigation */}

<NavLink
  to="/posts"
  end                                             // exact match (no /posts/* highlight)
  className={({ isActive, isPending }) =>
    isActive ? 'active' : isPending ? 'pending' : ''
  }
  style={({ isActive }) => ({ fontWeight: isActive ? 700 : 400 })}
>
  Posts
</NavLink>

{/* Declarative redirect */}
{!user && <Navigate to="/login" replace state={{ from: location }} />}
```

`NavLink` automatically sets `aria-current="page"` when active — accessibility comes free.

---

## 10. Query Strings / Search Params

`useSearchParams` returns a tuple shaped like `useState`, but the source of truth is the URL.

```tsx
const [params, setParams] = useSearchParams();
const q    = params.get('q') ?? '';
const page = Number(params.get('page') ?? 1);

function setQuery(next: string) {
  setParams(prev => {
    prev.set('q', next);
    prev.set('page', '1');                  // reset pagination on new search
    if (!next) prev.delete('q');
    return prev;
  }, { replace: true });                    // don't pollute history on every keystroke
}
```

Bookmarkable filters, shareable URLs, and back/forward "undo" of filter state — all free.

---

## 11. Protected Routes / Route Guards

The cleanest pattern: a **layout route** that reads auth context and either renders `<Outlet/>` or redirects.

```tsx
// auth/RequireAuth.tsx
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext';

export function RequireAuth({ roles }: { roles?: string[] }) {
  const { user, ready } = useAuth();
  const location = useLocation();

  if (!ready) return <Spinner />;                       // avoid flicker
  if (!user)  return <Navigate to="/login" replace state={{ from: location }} />;
  if (roles && !roles.some(r => user.roles.includes(r)))
    return <Navigate to="/403" replace />;
  return <Outlet />;
}

// router
<Route element={<RequireAuth />}>
  <Route path="/account" element={<Account />} />
  <Route element={<RequireAuth roles={['admin']} />}>
    <Route path="/admin/*" element={<AdminLayout />} />
  </Route>
</Route>
```

After login, redirect back:

```tsx
const from = (location.state as any)?.from?.pathname ?? '/';
navigate(from, { replace: true });
```

For data routers, do the same check inside a **loader**:

```tsx
export const loader = async () => {
  const user = await getUser();
  if (!user) throw redirect('/login');
  return user;
};
```

---

## 12. Lazy Routes & Code Splitting

```tsx
import { lazy, Suspense } from 'react';
const Admin = lazy(() => import('./pages/Admin'));

<Route
  path="/admin/*"
  element={
    <Suspense fallback={<Spinner />}>
      <Admin />
    </Suspense>
  }
/>
```

With data routers, use the route-level `lazy` field — it splits the loader/action/element together and shows the parent's pending UI:

```tsx
{
  path: 'admin',
  lazy: () => import('./routes/admin')   // module exports { loader, action, Component }
}
```

---

## 13. Scroll Restoration

Browsers restore scroll on reload but not on SPA navigations. React Router gives you `<ScrollRestoration/>`:

```tsx
function RootLayout() {
  return (
    <>
      <Nav />
      <Outlet />
      <ScrollRestoration
        getKey={(location) => location.pathname}   // share scroll between same path
      />
    </>
  );
}
```

For "scroll to top on every nav", a small custom hook also works:

```tsx
function useScrollTop() {
  const { pathname } = useLocation();
  useEffect(() => { window.scrollTo(0, 0); }, [pathname]);
}
```

---

## 14. 404 / Not Found

```tsx
<Route path="*" element={<NotFound />} />
```

In data router config, the same — a child with `path: '*'` at the deepest level you want it to apply. Inside loaders, throw a `Response` with status 404 and let `errorElement` render the not-found UI.

---

## 15. Pending UI, Optimistic UI, Transitions

```tsx
const nav = useNavigation();   // 'idle' | 'loading' | 'submitting'
{nav.state === 'loading' && <TopProgressBar />}
```

Optimistic UI with `useFetcher`: read `fetcher.formData` immediately to render the new value before the server confirms.

```tsx
const optimisticLikes = fetcher.formData
  ? Number(fetcher.formData.get('likes'))
  : post.likes;
```

---

## 16. Nested Layouts in Practice

```
RootLayout
├── PublicLayout       (header + footer)
│   ├── /              Home
│   ├── /about
│   └── /pricing
└── AppLayout          (sidebar, requires auth)
    ├── /dashboard
    ├── /projects
    └── /projects/:id
```

Implement each as a route element with `<Outlet/>`; share design system tokens, not props.

---

## 17. Breadcrumbs from Route Config

```tsx
{ path: 'projects', handle: { crumb: () => 'Projects' },
  children: [
    { path: ':id', loader: projectLoader,
      handle: { crumb: (data: Project) => data.name } }
  ]
}
```

```tsx
function Breadcrumbs() {
  const matches = useMatches();
  const crumbs = matches
    .filter(m => (m.handle as any)?.crumb)
    .map(m => (m.handle as any).crumb(m.data));
  return <ol>{crumbs.map((c, i) => <li key={i}>{c}</li>)}</ol>;
}
```

---

## 18. SSR & Framework Mode

- **`StaticRouter`** — render once on the server against a given URL, then hydrate with `BrowserRouter` on the client.
- **React Router v7 framework mode** (formerly Remix) — file-based routes, server loaders/actions, streaming SSR, built-in bundler. Great choice if you want SSR without rolling your own.

---

## 19. TanStack Router — Brief Comparison

| Feature | React Router v7 | TanStack Router |
|---------|-----------------|-----------------|
| Type-safe params/search | Manual generics | **Fully inferred** end-to-end |
| Search params validation | DIY | First-class (Zod-like schemas) |
| Data loading | Loaders | Loaders + integrates with TanStack Query |
| Bundle | Smaller | Slightly larger |
| Maturity | Very mature | Newer, fast-moving |

Pick TanStack Router when type safety on every link and search param matters; pick React Router for ecosystem familiarity and SSR/framework mode.

---

## 20. Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `/about` and `/about/` rendering differently | Don't rely on trailing slashes; React Router normalises but your server may not |
| `<Link to="profile">` from `/users/42` going to `/profile` | Use relative paths intentionally; `to="profile"` resolves to `/users/42/profile` only when current route is *parent*. Prefer absolute for clarity |
| `useNavigate()` called inside a render body | It must run inside an event handler or `useEffect`, never during render |
| Infinite redirect loops | Always check the *target* condition before redirecting (`if (user && pathname === '/login') ...`) |
| `404` shows for unauthenticated users instead of redirect | Order matters: gate routes *before* the catch-all `*` |
| State lost on refresh | `location.state` is in-memory — persist to URL or storage if needed |

---

## 21. Accessibility

- **Focus management** — by default, SPA navigation does *not* move focus. Move focus to the new `<h1>` or main landmark on route change:

```tsx
useEffect(() => {
  document.getElementById('main')?.focus();
}, [location.pathname]);
```

- **Skip links** — `<a href="#main">Skip to content</a>` at the top of every layout.
- **`aria-current="page"`** — `NavLink` adds this automatically when active.
- **Announce route changes** — render a visually hidden `aria-live="polite"` region with the new page title.

---

## 22. Testing Routes

`MemoryRouter` lets tests start at any URL without a real browser history:

```tsx
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { render, screen } from '@testing-library/react';

test('renders user page', () => {
  render(
    <MemoryRouter initialEntries={['/users/42']}>
      <Routes>
        <Route path="/users/:id" element={<UserPage />} />
      </Routes>
    </MemoryRouter>
  );
  expect(screen.getByText(/user 42/i)).toBeInTheDocument();
});
```

For data routers, use `createMemoryRouter` with the same config you ship to production — loaders and actions run in tests too.

---

## Key Takeaways

1. A router translates URL ↔ UI; the History API does the heavy lifting underneath.
2. Use `BrowserRouter` in production, `HashRouter` for static hosts, `MemoryRouter` for tests.
3. Prefer **`createBrowserRouter` + `RouterProvider`** for new apps — you unlock loaders, actions, error boundaries, and deferred data.
4. Compose UI with **nested routes + `<Outlet/>`** instead of prop-drilling layout components.
5. Keep filterable/shareable state in **search params**, ephemeral state in `location.state`.
6. Implement guards as **layout routes** that render `<Outlet/>` or `<Navigate/>` — no HOCs needed.
7. `lazy()` + `<Suspense>` (or route `lazy:`) gives you per-route code splitting almost for free.
8. Don't forget **focus management, skip links, and `aria-current`** — routing has real a11y consequences.
9. Test with `MemoryRouter` / `createMemoryRouter` so tests deep-link without a browser.
