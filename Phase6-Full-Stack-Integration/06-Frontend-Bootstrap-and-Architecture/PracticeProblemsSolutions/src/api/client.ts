import axios, { type AxiosError } from 'axios';
import { env } from '@config/env';

// P4: full implementation — see Notes section 7.
//   - Request interceptor: inject Bearer + X-Correlation-Id
//   - Response interceptor: shared in-flight refresh on 401 (single round-trip for N concurrent 401s)
export const api = axios.create({
  baseURL: env.VITE_API_BASE_URL,
  timeout: 15_000,
  withCredentials: true,
});

api.interceptors.request.use((cfg) => {
  cfg.headers['X-Correlation-Id'] = crypto.randomUUID();
  // TODO P4: if (token = getAccessToken()) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

api.interceptors.response.use(
  (r) => r,
  async (err: AxiosError) => {
    // TODO P4: handle 401 with shared in-flight refresh + replay
    throw err;
  },
);
