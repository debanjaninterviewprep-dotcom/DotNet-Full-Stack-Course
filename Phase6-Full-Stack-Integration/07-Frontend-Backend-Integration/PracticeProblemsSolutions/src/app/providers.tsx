import {
  MutationCache,
  QueryCache,
  QueryClient,
  QueryClientProvider,
} from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import type { ReactNode } from 'react';
import { toastError } from '@shared/lib/toast';

// P1: configure QueryClient with sensible defaults + centralized error handling
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      gcTime: 5 * 60_000,
      refetchOnWindowFocus: true,
      retry: (failureCount, error: unknown) => {
        const status = (error as { response?: { status?: number } })?.response?.status;
        if (status && [401, 403, 404].includes(status)) return false;
        return failureCount < 2;
      },
    },
    mutations: { retry: 0 },
  },
  queryCache: new QueryCache({ onError: toastError }),
  mutationCache: new MutationCache({ onError: toastError }),
});

export function AppProviders({ children }: { children: ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {import.meta.env.DEV ? <ReactQueryDevtools initialIsOpen={false} /> : null}
    </QueryClientProvider>
  );
}

export { queryClient };
