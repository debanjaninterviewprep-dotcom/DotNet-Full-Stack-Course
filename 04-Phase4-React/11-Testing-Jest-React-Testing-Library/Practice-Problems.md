# Topic 11: Testing — Practice Problems

Five progressive problems that take you from your first RTL test to a full integration + E2E suite. Use **Vitest + RTL + `userEvent` v14 + MSW** unless stated otherwise. All `vi.*` calls translate 1:1 to `jest.*` if you're on Jest.

---

## Problem 1 — Counter (Easy)

**Concept:** `render`, `screen`, `getByRole`, `userEvent.click`, basic assertions.

Build and test a `<Counter initial={0} />` that renders:

- a `<h1>` showing `Count: N`
- an "Increment" button
- a "Decrement" button
- a "Reset" button (only enabled when `count !== initial`)

### Requirements

- [ ] Renders the initial count from props.
- [ ] Clicking Increment increases by 1, Decrement decreases by 1.
- [ ] Reset is **disabled** initially and **enabled** after any change.
- [ ] Clicking Reset returns to `initial`.
- [ ] No `data-testid` — query by role/name only.

### Expected assertions

```tsx
expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Count: 0');
expect(screen.getByRole('button', { name: /reset/i })).toBeDisabled();
await user.click(screen.getByRole('button', { name: /increment/i }));
expect(screen.getByRole('heading')).toHaveTextContent('Count: 1');
expect(screen.getByRole('button', { name: /reset/i })).toBeEnabled();
```

### Starter

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Counter } from './Counter';

test('counts up and resets', async () => {
  const user = userEvent.setup();
  render(<Counter initial={0} />);
  // ...
});
```

---

## Problem 2 — Login Form (Easy–Medium)

**Concept:** controlled forms, validation, async `userEvent`, `findBy*`.

Test a `<LoginForm onSubmit={fn} />` with:

- `email` (required, must match `/.+@.+\..+/`)
- `password` (required, min 8 chars)
- a "Log in" submit button

### Requirements

- [ ] Submitting an empty form shows two error messages with `role="alert"`.
- [ ] Invalid email shows `Email is invalid`.
- [ ] Short password shows `Password must be at least 8 characters`.
- [ ] Errors clear once the field becomes valid.
- [ ] On valid submit, `onSubmit` is called **once** with `{ email, password }`.
- [ ] Submit button is disabled while submitting (mock `onSubmit` to return a pending Promise).

### Expected assertions

```tsx
const onSubmit = vi.fn();
const user = userEvent.setup();
render(<LoginForm onSubmit={onSubmit} />);

await user.click(screen.getByRole('button', { name: /log in/i }));
expect(await screen.findAllByRole('alert')).toHaveLength(2);

await user.type(screen.getByLabelText(/email/i), 'not-an-email');
await user.type(screen.getByLabelText(/password/i), 'short');
await user.click(screen.getByRole('button', { name: /log in/i }));
expect(screen.getByText(/email is invalid/i)).toBeVisible();
expect(screen.getByText(/at least 8 characters/i)).toBeVisible();

await user.clear(screen.getByLabelText(/email/i));
await user.type(screen.getByLabelText(/email/i), 'alice@example.com');
await user.clear(screen.getByLabelText(/password/i));
await user.type(screen.getByLabelText(/password/i), 'longenough');
await user.click(screen.getByRole('button', { name: /log in/i }));

expect(onSubmit).toHaveBeenCalledExactlyOnceWith({
  email: 'alice@example.com',
  password: 'longenough',
});
```

---

## Problem 3 — `useFetch` Hook with MSW (Medium)

**Concept:** `renderHook`, MSW handlers, success vs error branches, `waitFor`.

Implement and test:

```ts
function useFetch<T>(url: string): {
  data: T | null;
  error: Error | null;
  status: 'idle' | 'loading' | 'success' | 'error';
};
```

### Requirements

- [ ] Set up `setupServer` in `src/test/setup.ts` with `listen / resetHandlers / close`.
- [ ] **Success:** handler returns `{ id: 1, name: 'Ada' }` → status transitions `loading → success`, `data` is the JSON, `error` is `null`.
- [ ] **404 error:** override with `server.use(http.get(..., () => new HttpResponse(null, { status: 404 })))` → status becomes `error`, `error.message` includes `"404"`.
- [ ] **Network failure:** `HttpResponse.error()` → status `error`.
- [ ] Aborts the fetch on unmount (test by spying on `AbortController.prototype.abort`).

### Expected assertions

```tsx
const { result } = renderHook(() => useFetch<{ name: string }>('/api/user/1'));
expect(result.current.status).toBe('loading');
await waitFor(() => expect(result.current.status).toBe('success'));
expect(result.current.data).toEqual({ id: 1, name: 'Ada' });

server.use(http.get('/api/user/1', () => new HttpResponse(null, { status: 404 })));
const second = renderHook(() => useFetch('/api/user/1'));
await waitFor(() => expect(second.result.current.status).toBe('error'));
expect(second.result.current.error?.message).toMatch(/404/);
```

### Starter handlers

```ts
import { http, HttpResponse } from 'msw';
export const handlers = [
  http.get('/api/user/1', () => HttpResponse.json({ id: 1, name: 'Ada' })),
];
```

---

## Problem 4 — Redux Toolkit Slice + Connected Component (Medium–Hard)

**Concept:** pure reducer/selector tests, `renderWithStore`, async thunks with MSW.

Build a `cartSlice` with:

- state `{ items: { id: string; qty: number }[]; status: 'idle'|'loading'|'error' }`
- reducers: `addItem`, `removeItem`, `setQty`
- thunk `checkout()` that POSTs to `/api/checkout` and clears items on success
- selector `selectTotalQty`

And a `<Cart />` component showing items, qty inputs, a total, and a "Checkout" button.

### Requirements

- [ ] **Pure tests** for each reducer (no React, no store): start from a fixture, dispatch an action, assert next state.
- [ ] **Selector test:** `selectTotalQty({ cart: { items: [{qty:2},{qty:3}] }})` returns `5`.
- [ ] **Thunk test:** with MSW returning 200, dispatch `checkout()` from a real store; assert state becomes `idle` with `items: []`.
- [ ] **Connected component:** render `<Cart />` via `renderWithStore` with `preloadedState`. Click a "+" button, assert the displayed qty updates.
- [ ] **Error path:** MSW returns 500; assert UI shows an alert and items are preserved.

### Expected assertions

```ts
expect(cartReducer(initialState, addItem({ id: 'a' })))
  .toEqual({ ...initialState, items: [{ id: 'a', qty: 1 }] });

expect(selectTotalQty({ cart: { items: [{ id: 'a', qty: 2 }, { id: 'b', qty: 3 }], status: 'idle' } }))
  .toBe(5);

const { store } = renderWithStore(<Cart />, {
  preloadedState: { cart: { items: [{ id: 'a', qty: 1 }], status: 'idle' } },
});
await user.click(screen.getByRole('button', { name: /increase qty for a/i }));
expect(store.getState().cart.items[0].qty).toBe(2);
```

---

## Problem 5 — Full Integration + E2E (Hard)

**Concept:** routing, TanStack Query, MSW, `jest-axe`, then the same flow in Playwright.

Build a small "Notes" app with three routes:

- `/notes` — list (GET `/api/notes`)
- `/notes/:id` — detail (GET `/api/notes/:id`)
- `/notes/:id/edit` — edit form (PUT `/api/notes/:id`)

Wire it with `react-router-dom` v6 and `@tanstack/react-query`.

### Part A — RTL integration test

#### Requirements

- [ ] Build a `renderWithProviders` helper that wraps in `MemoryRouter`, `QueryClientProvider` (no retries), and any context.
- [ ] Provide MSW handlers for the three endpoints, seeded with two notes.
- [ ] Test scenario, in **one** test:
  1. Start at `/notes`. Assert two notes render as a `list` with two `listitem`s.
  2. Click the first note's link. Assert detail heading appears (`findByRole('heading', { name: ... })`).
  3. Click "Edit". Assert the form is pre-filled with the current title/body.
  4. Edit the title to `Updated`, click Save.
  5. Assert it navigates back to detail and shows `Updated`.
  6. Assert the PUT was called once with the new payload (use `server.events` or a spy handler).
- [ ] Add a **`jest-axe`** assertion on the list page and on the edit form — `toHaveNoViolations`.
- [ ] Add an **error case**: override the PUT to 500 and assert the form stays open with an `alert`.

#### Skeleton

```tsx
const handlers = [
  http.get('/api/notes', () => HttpResponse.json([{ id: '1', title: 'A', body: 'a' }, { id: '2', title: 'B', body: 'b' }])),
  http.get('/api/notes/:id', ({ params }) => HttpResponse.json({ id: params.id, title: 'A', body: 'a' })),
  http.put('/api/notes/:id', async ({ request, params }) => {
    const body = await request.json();
    return HttpResponse.json({ id: params.id, ...body });
  }),
];

test('list → detail → edit → save', async () => {
  const user = userEvent.setup();
  renderWithProviders(<App />, { route: '/notes' });

  expect(await screen.findAllByRole('listitem')).toHaveLength(2);
  await user.click(screen.getByRole('link', { name: /A/ }));
  expect(await screen.findByRole('heading', { name: 'A' })).toBeVisible();

  await user.click(screen.getByRole('link', { name: /edit/i }));
  const title = await screen.findByLabelText(/title/i);
  expect(title).toHaveValue('A');

  await user.clear(title);
  await user.type(title, 'Updated');
  await user.click(screen.getByRole('button', { name: /save/i }));

  expect(await screen.findByRole('heading', { name: 'Updated' })).toBeVisible();

  expect(await axe(document.body)).toHaveNoViolations();
});
```

### Part B — Playwright E2E

Reproduce the **same flow** end-to-end against the running app (`npm run dev` or a Vite preview build). Use a **page-object** for the edit form.

#### Requirements

- [ ] `playwright.config.ts` with `webServer` starting the preview, `baseURL: 'http://localhost:4173'`, and projects for Chromium + WebKit.
- [ ] Stub the API either with Playwright `page.route('/api/**', …)` **or** by pointing the app at a test backend.
- [ ] One spec covering: list → detail → edit → save → assert updated heading visible.
- [ ] One assertion using `await expect(page).toHaveScreenshot()` for the detail page (visual regression, optional but recommended).
- [ ] Run the suite headed locally (`npx playwright test --headed`) and headless in CI.

#### Skeleton

```ts
import { test, expect } from '@playwright/test';

test('edit a note end-to-end', async ({ page }) => {
  await page.route('**/api/notes', (r) =>
    r.fulfill({ json: [{ id: '1', title: 'A', body: 'a' }] }));
  await page.route('**/api/notes/1', (r) =>
    r.fulfill({ json: { id: '1', title: 'A', body: 'a' } }));
  await page.route('**/api/notes/1', async (r) => {
    if (r.request().method() === 'PUT') {
      const body = r.request().postDataJSON();
      await r.fulfill({ json: { id: '1', ...body } });
    }
  });

  await page.goto('/notes');
  await page.getByRole('link', { name: 'A' }).click();
  await page.getByRole('link', { name: /edit/i }).click();
  await page.getByLabel(/title/i).fill('Updated');
  await page.getByRole('button', { name: /save/i }).click();
  await expect(page.getByRole('heading', { name: 'Updated' })).toBeVisible();
});
```

### Stretch goals

- [ ] Add a Cypress component test for `<NoteEditor />` and compare the DX with RTL.
- [ ] Add a coverage threshold of 80% lines/branches and make CI fail below it.
- [ ] Add a GitHub Actions workflow that runs unit + Playwright in parallel jobs and uploads the Playwright HTML report on failure.

---

## Self-check

After finishing, you should be able to:

- Pick the right query (role/label) without thinking.
- Write an MSW handler and override it per test.
- Test a custom hook with a provider wrapper.
- Wire RTL + Router + Query + Redux in one `renderWithProviders`.
- Drive the same flow in Playwright with a page object.
- Justify when **not** to write a snapshot or an E2E test.
