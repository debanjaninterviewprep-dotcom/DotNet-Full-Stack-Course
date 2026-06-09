import { createBrowserRouter, redirect } from 'react-router-dom';
import { useAuth } from '@features/auth/token-store';
import { refreshAccessToken } from '@features/auth/api';

// P3: requireAuth attempts a silent refresh on cold load before redirecting.
async function requireAuth() {
  let token = useAuth.getState().accessToken;
  if (!token) {
    token = await refreshAccessToken();
    if (!token) throw redirect('/login');
  }
  return null;
}

export const router = createBrowserRouter([
  {
    path: '/login',
    lazy: async () => {
      const m = await import('@features/auth/LoginPage');
      return { Component: m.LoginPage };
    },
  },
  {
    path: '/',
    loader: requireAuth,
    children: [
      { index: true, loader: () => redirect('/projects') },
      { path: 'projects', element: <div>TODO: projects list (P2 layout)</div> },
    ],
  },
  { path: '*', element: <div>404</div> },
]);
