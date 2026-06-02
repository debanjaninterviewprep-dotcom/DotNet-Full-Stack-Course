import { http, HttpResponse, delay } from 'msw';
import { env } from '@config/env';

const shouldFail = () => env.VITE_MSW_FAIL === 'true' && Math.random() < 0.3;

export const handlers = [
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string };
    await delay(150);
    if (body.email !== 'demo@taskflow.dev' || body.password !== 'password123') {
      return HttpResponse.json(
        { title: 'Invalid credentials', status: 401, traceId: 'mock' },
        { status: 401 },
      );
    }
    return HttpResponse.json({
      accessToken: 'mock.jwt.token',
      user: { id: 'u1', email: body.email, roles: ['Member'] },
    });
  }),

  http.post('/api/v1/auth/refresh', () =>
    HttpResponse.json({ accessToken: 'mock.refreshed.token' }),
  ),

  http.post('/api/v1/auth/logout', () => new HttpResponse(null, { status: 204 })),

  http.get('/api/v1/projects', () =>
    HttpResponse.json({
      items: [
        { id: 'p1', name: 'Demo project', status: 'Active' },
        { id: 'p2', name: 'Internal tools', status: 'Active' },
      ],
      total: 2,
      page: 1,
      pageSize: 20,
    }),
  ),

  http.patch('/api/v1/tasks/:id', async ({ params, request }) => {
    const body = (await request.json()) as { status?: string };
    if (shouldFail()) {
      return HttpResponse.json(
        { title: 'Random failure (MSW)', status: 500, traceId: 'mock' },
        { status: 500 },
      );
    }
    return HttpResponse.json({ id: params.id, status: body.status });
  }),
];
