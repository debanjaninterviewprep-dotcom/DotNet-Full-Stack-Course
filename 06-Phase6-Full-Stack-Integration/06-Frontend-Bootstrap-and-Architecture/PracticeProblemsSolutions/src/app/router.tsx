import { createBrowserRouter, redirect } from 'react-router-dom';

// P2: Build the routing shell.
//   - PublicLayout for /login + /signup
//   - AppLayout (sidebar + topbar) for authenticated routes, with requireAuth loader
//   - Lazy-load every page route
export const router = createBrowserRouter([
  {
    path: '/',
    element: <div>TODO P2: replace with PublicLayout/AppLayout split</div>,
    loader: () => redirect('/projects'),
  },
  { path: '*', element: <div>404</div> },
]);

// async function requireAuth() { ... } // P2
