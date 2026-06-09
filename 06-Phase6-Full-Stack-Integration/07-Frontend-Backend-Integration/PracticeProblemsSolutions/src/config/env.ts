import { z } from 'zod';

const schema = z.object({
  VITE_API_BASE_URL: z.string().url(),
  VITE_APP_NAME: z.string().min(1),
  VITE_RELEASE: z.string().default('local'),
  VITE_USE_MOCKS: z.enum(['true', 'false']).default('false'),
  VITE_MSW_FAIL: z.enum(['true', 'false']).default('false'),
});

export const env = schema.parse(import.meta.env);
