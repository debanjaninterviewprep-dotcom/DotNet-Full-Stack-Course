import { create } from 'zustand';

export type AuthUser = { id: string; email: string; roles: string[] };

type AuthState = {
  accessToken: string | null;
  user: AuthUser | null;
  setAuth: (token: string, user: AuthUser) => void;
  setAccessToken: (token: string | null) => void;
  clear: () => void;
};

export const useAuth = create<AuthState>((set) => ({
  accessToken: null,
  user: null,
  setAuth: (accessToken, user) => set({ accessToken, user }),
  setAccessToken: (accessToken) => set((s) => ({ ...s, accessToken })),
  clear: () => set({ accessToken: null, user: null }),
}));

// Non-React accessors used by the axios interceptor.
export const getAccessToken = () => useAuth.getState().accessToken;
