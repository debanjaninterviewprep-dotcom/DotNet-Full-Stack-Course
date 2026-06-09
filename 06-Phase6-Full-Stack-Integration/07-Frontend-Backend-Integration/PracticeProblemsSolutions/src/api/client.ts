import axios, { type AxiosError, type AxiosRequestConfig } from 'axios';
import { env } from '@config/env';
import { getAccessToken } from '@features/auth/token-store';
import { refreshAccessToken } from '@features/auth/api';

export const api = axios.create({
  baseURL: env.VITE_API_BASE_URL,
  timeout: 15_000,
  withCredentials: true,
});

api.interceptors.request.use((cfg) => {
  const token = getAccessToken();
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  cfg.headers['X-Correlation-Id'] = crypto.randomUUID();
  return cfg;
});

// P3: shared in-flight refresh — N concurrent 401s trigger exactly one refresh.
let refreshing: Promise<string | null> | null = null;

api.interceptors.response.use(
  (r) => r,
  async (err: AxiosError) => {
    const original = err.config as (AxiosRequestConfig & { _retried?: boolean }) | undefined;
    const status = err.response?.status;
    const url = original?.url ?? '';
    const isAuthEndpoint = url.startsWith('/api/v1/auth/');

    if (status !== 401 || !original || original._retried || isAuthEndpoint) {
      throw err;
    }
    original._retried = true;

    refreshing ??= refreshAccessToken().finally(() => {
      refreshing = null;
    });
    const newToken = await refreshing;
    if (!newToken) throw err;

    original.headers = { ...(original.headers ?? {}), Authorization: `Bearer ${newToken}` };
    return api(original);
  },
);
