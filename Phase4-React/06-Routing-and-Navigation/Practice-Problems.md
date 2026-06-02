# Topic 6: Routing & Navigation — Practice Problems

> Work through these in order. Each problem builds skills the next one assumes. Use `react-router-dom` v6.4+ or v7. TypeScript is recommended but not required.

---

## Problem 1 — Multi-Page Marketing Site (Easy)

**Concept:** `BrowserRouter`, `<Routes>`/`<Route>`, `<Link>`/`<NavLink>`, 404 catch-all.

Build a small public site with four routes and a shared top navigation bar.

### Requirements
- Routes: `/` (Home), `/about`, `/contact`, and a `*` catch-all (`NotFound`).
- A `<Header/>` component visible on every page with `<NavLink>`s; the active link must visually stand out (different colour or weight) **and** carry `aria-current="page"`.
- Clicking a link must update the URL **without** a full page reload.
- The `Contact` page contains a `mailto:` link and a small form (no submission logic required).
- Hitting an unknown URL like `/random` shows a friendly 404 with a link back to `/`.

### Sub-tasks
1. Scaffold the app with `npm create vite@latest`, install `react-router-dom`.
2. Wrap `<App/>` in `<BrowserRouter>` in `main.tsx`.
3. Implement `<Header/>` using `NavLink` with the `className` callback.
4. Add the catch-all route as the last `<Route>` and verify it triggers on garbage URLs.
5. Deploy preview locally — confirm browser back/forward works.

### Expected behaviour
- URL bar always reflects the visible page.
- Refreshing on `/about` still loads `/about` (configure dev server fallback if you deploy).
- Active nav link is obvious to sighted users *and* exposed to assistive tech.

### Starter

```tsx
// src/App.tsx
import { Routes, Route, NavLink } from 'react-router-dom';

const linkClass = ({ isActive }: { isActive: boolean }) =>
  isActive ? 'nav-link nav-link--active' : 'nav-link';

export default function App() {
  return (
    <>
      <header>
        <nav>
          <NavLink to="/"        end className={linkClass}>Home</NavLink>
          <NavLink to="/about"       className={linkClass}>About</NavLink>
          <NavLink to="/contact"     className={linkClass}>Contact</NavLink>
        </nav>
      </header>
      <main id="main">
        <Routes>
          {/* TODO: routes here */}
        </Routes>
      </main>
    </>
  );
}
```

---

## Problem 2 — Dashboard with Nested Layout (Easy–Medium)

**Concept:** Nested routes, layout routes, `<Outlet/>`, index routes, relative links.

Build a `/dashboard` area with a persistent sidebar and three child pages.

### Requirements
- `/dashboard` renders a `<DashboardLayout/>` containing a sidebar (`Overview`, `Analytics`, `Settings`) and an `<Outlet/>` for the content area.
- `/dashboard` (no extra segment) renders `Overview` as the **index** route.
- `/dashboard/analytics` shows a placeholder chart.
- `/dashboard/settings/profile` and `/dashboard/settings/security` are nested two levels deep — the `Settings` page itself has its own inner sidebar with two tabs and another `<Outlet/>`.
- Sidebar links use `<NavLink>` and stay highlighted when on the corresponding child route.

### Sub-tasks
1. Create the layout components: `DashboardLayout`, `SettingsLayout`.
2. Configure nested `<Route>` children — remember `index` for the default child.
3. Use **relative** `to=""` paths inside the sidebar (e.g. `<NavLink to="analytics">`), then verify they resolve correctly from `/dashboard`.
4. Add a "Back to site" link that navigates to `/` using `useNavigate()` on a button click.
5. Confirm reloading on `/dashboard/settings/security` lands you exactly there with both sidebars rendered.

### Expected behaviour
- Sidebar never unmounts when switching between dashboard child routes (verify with a `useEffect` log).
- The deepest tab is highlighted and the parent settings link is *also* highlighted (without `end` prop).

---

## Problem 3 — Products Catalog with URL State (Medium)

**Concept:** `useParams`, `useSearchParams`, dynamic segments, deriving state from URL.

Build a product browsing experience where every filter is bookmarkable.

### Requirements
- `/products` — paginated, filterable list. State lives **entirely in the URL**:
  - `?q=phone`     → free-text search
  - `?category=electronics` → category filter
  - `?sort=price-asc|price-desc|name`
  - `?page=2`      → 1-indexed pagination, 12 per page
- `/products/:productId` — detail page; reads `productId` via `useParams`.
- `/products/:productId/reviews` — nested under detail, shows reviews.
- A "Back to results" link on the detail page must preserve the filters the user had — the easiest way is to navigate with `state: { search: location.search }` and read it back, or simply `navigate(-1)`.
- Changing a filter must call `setSearchParams(..., { replace: true })` so users can hit Back to undo a *batch* of changes, not every keystroke.

### Sub-tasks
1. Mock a `products.ts` array of ~50 items with `id`, `name`, `category`, `price`.
2. Build a `useProductQuery()` hook that reads `useSearchParams()` and returns the filtered + sorted + paginated slice plus `totalPages`.
3. Implement a `<Pagination/>` component whose `Prev`/`Next` buttons call `setSearchParams` with the new `page` while preserving other params.
4. Reset `page` to `1` whenever `q` or `category` changes (otherwise users land on an empty page).
5. Add a "Clear filters" button that calls `setSearchParams({})`.
6. On the detail page, implement breadcrumbs: `Products › {category} › {name}`.

### Expected behaviour
- Copying the URL into another tab reproduces the **exact** view.
- Browser Back undoes the last filter change, not each character typed in the search box.
- Direct-loading `/products?category=books&page=3` works on first paint (no flash of unfiltered data).

---

## Problem 4 — Protected Admin Area with Role Guards (Medium–Hard)

**Concept:** Auth context, layout-route guards, role-based access, post-login redirect, `<Navigate/>`.

Build an app with three audiences: anonymous, authenticated user, admin.

### Requirements
- Public routes: `/`, `/login`.
- Authenticated routes (any logged-in user): `/account`, `/account/orders`.
- Admin-only routes: `/admin`, `/admin/users`, `/admin/users/:id`.
- Anonymous user hitting `/account` → redirected to `/login`, and **after successful login** lands back on `/account` (not on `/`).
- Authenticated non-admin hitting `/admin` → redirected to `/403` (Forbidden page).
- Logout button anywhere in the app sends user back to `/`.
- `AuthContext` exposes `{ user, login, logout, ready }` where `ready` becomes `true` after the initial async auth-check resolves; the guard must render a spinner while `!ready` to avoid a redirect flash.

### Sub-tasks
1. Build `AuthContext` with mock `login(email, password)` that resolves to a user object containing `roles: string[]`. Persist to `localStorage` so refresh keeps the session.
2. Build a `<RequireAuth roles?: string[]/>` layout route that renders `<Outlet/>`, `<Spinner/>`, or `<Navigate/>` depending on state.
3. Compose the route tree: nest `RequireAuth` *without roles* around user pages, nest `RequireAuth roles={['admin']}` around admin pages.
4. In `Login.tsx`, after success: `navigate(location.state?.from?.pathname ?? '/account', { replace: true })`.
5. Add a `/403` page with a "Go home" link.
6. Bonus: handle the case where the admin lands on `/login` while already authed — redirect them straight to `/account`.

### Expected behaviour
- No flicker of protected content for unauthenticated users.
- Deep-linking to `/admin/users/42` while logged out: redirect to `/login`, log in as admin, land on `/admin/users/42` (not `/`).
- Logging out from `/admin/users/42` redirects home (or to `/login`) and Back doesn't restore the protected page.

### Starter

```tsx
export function RequireAuth({ roles }: { roles?: string[] }) {
  const { user, ready } = useAuth();
  const location = useLocation();
  if (!ready) return <Spinner />;
  if (!user)  return <Navigate to="/login" replace state={{ from: location }} />;
  if (roles && !roles.some(r => user.roles.includes(r)))
    return <Navigate to="/403" replace />;
  return <Outlet />;
}
```

---

## Problem 5 — Blog with Data Router, Loaders, Lazy Routes (Hard)

**Concept:** `createBrowserRouter`, loaders, actions, `Form`, `useFetcher`, `defer` + `<Await/>`, `errorElement`, route-level `lazy`, `<ScrollRestoration/>`.

Re-implement a blog using the **data router** end-to-end. No `useEffect`-based fetching anywhere.

### Requirements

#### Routes
- `/`                       — `BlogHome` (loader: latest 5 posts)
- `/posts`                  — `PostsList` (loader: all posts, supports `?tag=`)
- `/posts/:slug`            — `Post` (loader: post + **deferred** comments; action: add comment)
- `/posts/:slug/edit`       — `EditPost` (loader: post; action: save) — **lazy-loaded**
- `/admin/*`                — admin section, **lazy-loaded** as a single chunk
- `*`                       — `NotFound`

#### Behaviour
- `Post` page renders the article immediately and **streams** comments inside `<Suspense fallback={<Spinner/>}><Await resolve={...}/></Suspense>`.
- Submitting a comment uses `<Form method="post">`; the action revalidates the page so the new comment appears without manual state juggling.
- Liking a post uses `useFetcher` — the heart icon updates **optimistically** from `fetcher.formData` before the server confirms.
- A 404 from the API (`throw new Response('Not found', { status: 404 })`) renders the route's `errorElement` (`<PostError/>`), which calls `useRouteError` + `isRouteErrorResponse`.
- The root layout includes `<ScrollRestoration/>` so navigating back to `/posts` returns to the previous scroll position.
- Top-of-page progress bar driven by `useNavigation().state !== 'idle'`.

### Sub-tasks
1. Define `router` with `createBrowserRouter([...])` exporting a single config tree.
2. For the post page loader, use `defer({ post: await fetchPost(slug), comments: fetchComments(slug) })`.
3. Implement `postAction` that reads `formData`, POSTs the comment, and `return null` (revalidation is automatic).
4. For `/posts/:slug/edit`, split it into its own module that exports `{ loader, action, Component }` and reference it via `lazy: () => import('./routes/edit-post')`.
5. Wrap admin similarly so `/admin/*` is fetched only when an admin clicks into it.
6. Add an `errorElement` at the root **and** at `/posts/:slug` — verify the per-route boundary catches without unmounting the root layout.
7. Add `<ScrollRestoration getKey={(loc) => loc.pathname}/>` to the root layout.
8. Write a test with `createMemoryRouter` that asserts: navigating to `/posts/missing` renders the post-level error element and **not** the root error element.

### Expected behaviour
- Initial bundle does **not** contain the edit page or admin code (verify in the build output / network tab).
- Article text appears instantly even when comments take 2 seconds to load.
- Optimistic like updates are reverted automatically if the server returns a non-2xx response.
- Per-route error UI keeps the header/sidebar mounted; only the content area shows the error.

### Starter

```tsx
// src/router.tsx
import { createBrowserRouter, defer } from 'react-router-dom';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <RootError />,
    children: [
      { index: true, loader: homeLoader, element: <BlogHome /> },
      { path: 'posts', loader: postsLoader, element: <PostsList />,
        children: [
          {
            path: ':slug',
            loader: ({ params }) => defer({
              post: fetchPost(params.slug!),          // awaited
              comments: fetchComments(params.slug!)   // promise → streamed
            }),
            action: postAction,
            element: <Post />,
            errorElement: <PostError />
          },
          {
            path: ':slug/edit',
            lazy: () => import('./routes/edit-post')
          }
        ]
      },
      { path: 'admin/*', lazy: () => import('./routes/admin') },
      { path: '*', element: <NotFound /> }
    ]
  }
]);
```

---

## Stretch Goals (Optional)

- Add a global command palette (`Cmd+K`) that uses `useNavigate()` to jump to any route.
- Implement breadcrumbs by reading `useMatches()` and `route.handle.crumb`.
- Migrate Problem 5 to **TanStack Router** and compare the developer experience around type-safe search params.
- Add SSR with `StaticRouter` (or React Router v7 framework mode) and measure first-contentful-paint vs the SPA build.
