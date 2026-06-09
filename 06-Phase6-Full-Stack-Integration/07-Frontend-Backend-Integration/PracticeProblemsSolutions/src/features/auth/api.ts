import { useMutation } from '@tanstack/react-query';
import { api } from '@api/client';
import { useAuth, type AuthUser } from './token-store';
import { queryClient } from '@app/providers';

type LoginResponse = { accessToken: string; user: AuthUser };

// P2: login mutation — store result, never touch localStorage
export function useLogin() {
  return useMutation({
    mutationFn: async (creds: { email: string; password: string }) => {
      const res = await api.post<LoginResponse>('/api/v1/auth/login', creds);
      return res.data;
    },
    onSuccess: (data) => {
      useAuth.getState().setAuth(data.accessToken, data.user);
    },
  });
}

// P2: logout — wipe in-memory state + cache, hard-redirect
export function useLogout() {
  return useMutation({
    mutationFn: () => api.post('/api/v1/auth/logout'),
    onSettled: () => {
      useAuth.getState().clear();
      queryClient.clear();
      window.location.href = '/login';
    },
  });
}

// P3: silent refresh — single network round-trip, returns new access token or null
export async function refreshAccessToken(): Promise<string | null> {
  try {
    const res = await api.post<{ accessToken: string }>('/api/v1/auth/refresh');
    useAuth.getState().setAccessToken(res.data.accessToken);
    return res.data.accessToken;
  } catch {
    useAuth.getState().clear();
    return null;
  }
}
