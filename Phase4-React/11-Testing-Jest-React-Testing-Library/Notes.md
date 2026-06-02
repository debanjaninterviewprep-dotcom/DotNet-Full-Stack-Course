# Topic 11: Testing (Jest + React Testing Library)

A confident React codebase rests on a layered testing strategy: fast **unit** tests for pure logic, **integration** tests for components+state+routing, and a small set of **end-to-end (E2E)** tests that drive a real browser. This note covers the modern toolchain — Jest, Vitest, React Testing Library (RTL), MSW, Cypress, and Playwright — with patterns you can copy into a project.

---

## 1. The Testing Pyramid for React

```
        /\        E2E (Cypress / Playwright)         — slow, few, high confidence
       /  \       Integration (RTL + MSW + Router)   — medium speed/count
      /----\      Unit (pure fns, hooks, reducers)   — fast, many
     /______\
```

| Layer | Scope | Tools | Example | Speed | Count |
|-------|-------|-------|---------|-------|-------|
| Unit | One function / hook / reducer in isolation | Jest / Vitest, `renderHook` | `formatPrice(1000)` returns `"$1,000"` | ms | 100s |
| Integration | Multiple units wired together (component + store + router) | RTL + MSW | Submit `<LoginForm/>` and assert redirect | 10–100 ms | 10s–100s |
| E2E | Full app in a real browser, real (or staged) backend | Playwright / Cypress | User logs in, creates order, logs out | seconds | <50 |

Rule of thumb: **70% unit, 25% integration, 5% E2E**. RTL covers most of the "integration" middle for you.

---

## 2. Test Runners: Jest vs Vitest

| Feature | Jest | Vitest |
|---------|------|--------|
| Default in | CRA, Next.js | Vite, Nuxt 3, Astro |
| Config | `jest.config.js` (Babel/SWC) | `vitest.config.ts` (shares `vite.config.ts`) |
| ESM support | Workarounds, `--experimental-vm-modules` | Native |
| Speed (cold) | Slower (Babel transform) | Faster (esbuild) |
| Watch UX | Good | Excellent (HMR-style) |
| API | `describe/it/expect`, `jest.mock` | Same API, `vi.mock` |
| TypeScript | via `ts-jest` / Babel | Out of the box |
| In-source tests | No | Yes (`if (import.meta.vitest)`) |
| Browser mode | No (jsdom only) | Experimental real-browser runner |

**Choose Vitest** if you use Vite (almost always for new React apps). **Choose Jest** if you're on CRA, Next.js, or React Native where Jest is the default. The RTL code looks identical; only the imports and mock helpers differ (`jest.fn` ↔ `vi.fn`).

---

## 3. Setup

### 3.1 Vite + Vitest + RTL

```bash
npm i -D vitest @testing-library/react @testing-library/jest-dom \
        @testing-library/user-event jsdom @vitest/coverage-v8
```

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
    coverage: { provider: 'v8', reporter: ['text', 'html', 'lcov'] },
  },
});
```

```ts
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';
afterEach(() => cleanup());
```

### 3.2 CRA / Jest

CRA pre-wires Jest and `setupTests.ts`. Just add:

```ts
// src/setupTests.ts
import '@testing-library/jest-dom';
```

For non-CRA Jest projects, add `jest.config.js` with `testEnvironment: 'jsdom'`, `setupFilesAfterEach: ['<rootDir>/src/setupTests.ts']`, and a `babel.config.js` with `@babel/preset-react` and `@babel/preset-typescript`.

---

## 4. RTL Philosophy

> "The more your tests resemble the way your software is used, the more confidence they can give you." — Kent C. Dodds

- **Test behavior, not implementation.** Don't assert internal state or that a specific function was called — assert what the **user sees and does**.
- Prefer **accessible queries** (role, label) — they double as accessibility checks.
- Avoid `data-testid` until nothing else works.

```tsx
// ❌ implementation detail
expect(component.state.count).toBe(1);

// ✅ user-visible behavior
expect(screen.getByRole('status')).toHaveTextContent('Count: 1');
```

---

## 5. `render`, `screen`, `debug`

```tsx
import { render, screen } from '@testing-library/react';

render(<Counter initial={5} />);
screen.debug();              // prints current DOM
screen.debug(screen.getByRole('button')); // a single node
screen.logTestingPlaygroundURL(); // open Testing Playground for query suggestions
```

`screen` is just `within(document.body)` — use it instead of destructuring `render`'s result.

---

## 6. Queries

| Variant | Throws when 0 | Throws when >1 | Returns Promise | Use for |
|---------|---------------|----------------|-----------------|---------|
| `getBy*` | ✅ | ✅ | ❌ | Element should exist now |
| `queryBy*` | ❌ (returns null) | ✅ | ❌ | Asserting **absence** |
| `findBy*` | ✅ (after timeout) | ✅ | ✅ | Element appears **async** |
| `getAllBy*` / `queryAllBy*` / `findAllBy*` | varies | ❌ | varies | Multiple matches |

### Query priority (use the highest one that works)

1. `getByRole` (with `name` option) — preferred for everything interactive
2. `getByLabelText` — form fields
3. `getByPlaceholderText`
4. `getByText` — non-interactive content
5. `getByDisplayValue` — current input value
6. `getByAltText` — images
7. `getByTitle`
8. `getByTestId` — last resort

```tsx
screen.getByRole('button', { name: /submit/i });
screen.getByRole('textbox', { name: 'Email' });
screen.getByRole('heading', { level: 1, name: 'Dashboard' });
screen.queryByText(/error/i);          // null if absent
await screen.findByRole('alert');      // waits up to 1s
```

### Roles cheat sheet

| Element | Implicit role |
|---------|---------------|
| `<button>`, `<input type="button">` | `button` |
| `<a href>` | `link` |
| `<input type="text\|email\|search">`, `<textarea>` | `textbox` |
| `<input type="checkbox">` | `checkbox` |
| `<input type="radio">` | `radio` |
| `<select>` | `combobox` |
| `<h1>`–`<h6>` | `heading` |
| `<ul>` / `<ol>` | `list` |
| `<li>` | `listitem` |
| `<img alt="...">` | `img` |
| `<nav>` | `navigation` |
| `[role="alert"]`, toast | `alert` |
| `<dialog>` | `dialog` |

---

## 7. Custom Matchers (`@testing-library/jest-dom`)

```tsx
expect(el).toBeInTheDocument();
expect(el).toBeVisible();
expect(el).toBeDisabled();
expect(el).toHaveTextContent(/welcome/i);
expect(input).toHaveValue('alice@example.com');
expect(input).toHaveFocus();
expect(el).toHaveClass('btn-primary');
expect(el).toHaveAttribute('aria-expanded', 'true');
expect(form).toHaveFormValues({ email: 'a@b.c', remember: true });
expect(checkbox).toBeChecked();
```

---

## 8. `userEvent` vs `fireEvent`

`fireEvent` dispatches a single synthetic event. `userEvent` simulates the **full sequence** a real user generates (focus, keydown, keypress, input, keyup, change…). Always prefer `userEvent` v14+.

```tsx
import userEvent from '@testing-library/user-event';

const user = userEvent.setup();          // call once per test
await user.click(screen.getByRole('button', { name: /save/i }));
await user.type(screen.getByLabelText('Email'), 'alice@example.com');
await user.clear(input);
await user.hover(tooltipTrigger);
await user.selectOptions(screen.getByRole('combobox'), 'AU');
await user.upload(fileInput, new File(['hi'], 'hi.txt', { type: 'text/plain' }));
await user.keyboard('{Enter}{ArrowDown}{Tab}');
await user.paste('pasted text');
```

All v14 methods are **async** — always `await`.

---

## 9. Async Testing

```tsx
// element appears later
const alert = await screen.findByRole('alert');

// arbitrary assertion that needs to settle
await waitFor(() => {
  expect(mockSave).toHaveBeenCalledTimes(1);
});

// element disappears (e.g., spinner)
await waitForElementToBeRemoved(() => screen.queryByText(/loading/i));
```

`findBy*` = `waitFor` + `getBy*`. Don't wrap `findBy*` in `waitFor`.

---

## 10. Testing Forms

### Controlled form

```tsx
test('submits with trimmed email', async () => {
  const onSubmit = vi.fn();
  const user = userEvent.setup();
  render(<LoginForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText(/email/i), '  alice@x.com  ');
  await user.type(screen.getByLabelText(/password/i), 'secret123');
  await user.click(screen.getByRole('button', { name: /log in/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: 'alice@x.com', password: 'secret123' });
});
```

### React Hook Form

Same approach — RHF runs validation on submit/blur, so you may need `findBy*` for error messages.

```tsx
await user.click(screen.getByRole('button', { name: /submit/i }));
expect(await screen.findByText(/email is required/i)).toBeInTheDocument();
```

---

## 11. Testing Custom Hooks

RTL v14 includes `renderHook` (no more `@testing-library/react-hooks`).

```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

test('increments', () => {
  const { result } = renderHook(() => useCounter(0));
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

Use the `wrapper` option to provide context:

```tsx
const wrapper = ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>;
const { result } = renderHook(() => useTodos(), { wrapper });
```

---

## 12. Mocking Modules

```ts
// Vitest
vi.mock('./api');                          // auto-mock
vi.mock('./api', () => ({ getUser: vi.fn() })); // factory
vi.mock('./api', async (importOriginal) => {
  const real = await importOriginal<typeof import('./api')>();
  return { ...real, getUser: vi.fn() };    // partial mock
});

// Jest
jest.mock('./api');
jest.mock('./api', () => ({ getUser: jest.fn() }));
```

**ESM quirk:** `jest.mock` is hoisted; in pure-ESM Jest you must use `jest.unstable_mockModule` + dynamic `import()`. Vitest hoists `vi.mock` for you and works natively.

---

## 13. Mocking the Network with MSW

MSW intercepts at the **network level** (Service Worker in browser, Node interceptor in tests) — your code keeps calling `fetch`/`axios` unchanged. This is the recommended approach for both integration tests and E2E.

```ts
// src/test/handlers.ts
import { http, HttpResponse } from 'msw';
export const handlers = [
  http.get('/api/users/:id', ({ params }) =>
    HttpResponse.json({ id: params.id, name: 'Alice' })
  ),
  http.post('/api/login', async ({ request }) => {
    const body = (await request.json()) as { email: string };
    if (body.email === 'fail@x.com') return new HttpResponse(null, { status: 401 });
    return HttpResponse.json({ token: 'abc' });
  }),
];
```

```ts
// src/test/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);
```

```ts
// src/test/setup.ts
import { server } from './server';
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Override per-test for error cases:

```tsx
import { http, HttpResponse } from 'msw';
server.use(
  http.get('/api/users/:id', () => HttpResponse.json({ message: 'boom' }, { status: 500 }))
);
```

---

## 14. Testing Redux Toolkit

**Test reducers/selectors as pure functions** — no React needed.

```ts
import counter, { increment } from './counterSlice';
expect(counter(undefined, increment())).toEqual({ value: 1 });
```

**Test connected components** with a real store wrapper:

```tsx
function renderWithStore(ui: React.ReactElement, { preloadedState } = {}) {
  const store = configureStore({ reducer: rootReducer, preloadedState });
  return { store, ...render(<Provider store={store}>{ui}</Provider>) };
}
```

---

## 15. Testing Context

```tsx
function renderWithProviders(ui: React.ReactElement, { route = '/' } = {}) {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <MemoryRouter initialEntries={[route]}>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>{ui}</AuthProvider>
      </QueryClientProvider>
    </MemoryRouter>
  );
}
```

Export this from `src/test/utils.tsx` and use it everywhere — most teams re-export `screen`, `userEvent`, and `renderWithProviders` as their canonical test helpers.

---

## 16. Testing React Router

```tsx
import { MemoryRouter, Routes, Route } from 'react-router-dom';

render(
  <MemoryRouter initialEntries={['/users/42']}>
    <Routes>
      <Route path="/users/:id" element={<UserPage />} />
    </Routes>
  </MemoryRouter>
);
expect(await screen.findByRole('heading', { name: /user 42/i })).toBeInTheDocument();
```

To assert navigation, click a link and check for the new page's content (don't inspect URL state — that's implementation).

---

## 17. Testing TanStack Query

Use a fresh `QueryClient` per test with retries off so failures surface immediately:

```tsx
const client = new QueryClient({
  defaultOptions: { queries: { retry: false, gcTime: 0 } },
});
```

Combine with MSW handlers to drive success / loading / error branches.

---

## 18. Snapshot Testing

```tsx
expect(asFragment()).toMatchSnapshot();
```

| Useful for | Harmful when |
|------------|--------------|
| Stable presentational components | Snapshots are huge and constantly churn |
| Reducer outputs, formatter results | Devs blindly run `--update` without reading the diff |
| Error/empty states | DOM contains dynamic IDs, dates, random data |

Prefer **inline snapshots** (`toMatchInlineSnapshot()`) for small fragments — the diff lives next to the code.

---

## 19. Code Coverage

```bash
vitest run --coverage
jest --coverage
```

```ts
// vitest.config.ts
test: {
  coverage: {
    thresholds: { lines: 80, branches: 75, functions: 80, statements: 80 },
    exclude: ['**/*.stories.tsx', '**/*.config.*', 'src/main.tsx'],
  },
},
```

Coverage is a **floor**, not a goal. 100% coverage with shallow assertions is worse than 70% with strong behavioral tests.

---

## 20. Accessibility Testing

```tsx
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

test('has no a11y violations', async () => {
  const { container } = render(<Dashboard />);
  expect(await axe(container)).toHaveNoViolations();
});
```

Add manual keyboard tests:

```tsx
await user.tab();
expect(screen.getByRole('button', { name: /save/i })).toHaveFocus();
```

---

## 21. Visual Regression (brief)

| Tool | Notes |
|------|-------|
| Chromatic | Built on Storybook, snapshots stories in cloud |
| Percy | BrowserStack, integrates with Cypress/Playwright |
| Playwright `toHaveScreenshot()` | Built-in, free, pixel-diff per project |

Use sparingly — visual diffs are noisy across OSes/fonts.

---

## 22. E2E: Cypress vs Playwright

| Feature | Cypress | Playwright |
|---------|---------|-----------|
| Browsers | Chrome/Edge/Firefox/WebKit | Chromium/Firefox/WebKit |
| Architecture | Runs **inside** browser | Drives browser via CDP/WebDriver BiDi |
| Multi-tab / multi-origin | Limited (improving) | Native |
| Parallelism | Paid dashboard / 3rd-party | Built-in, free |
| Auto-wait | Yes | Yes |
| Language | JS/TS only | TS, JS, Python, Java, .NET |
| Component testing | Mature | Mature (Playwright CT) |
| API testing | Plugin | Built-in (`request` fixture) |

Industry trend (2024+) leans toward **Playwright** for new projects.

### Playwright basic example

```ts
// tests/login.spec.ts
import { test, expect } from '@playwright/test';

test('user can log in', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('alice@x.com');
  await page.getByLabel('Password').fill('secret');
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

### Page Object pattern

```ts
export class LoginPage {
  constructor(private page: import('@playwright/test').Page) {}
  goto = () => this.page.goto('/login');
  email = () => this.page.getByLabel('Email');
  password = () => this.page.getByLabel('Password');
  submit = () => this.page.getByRole('button', { name: 'Log in' });
  async login(email: string, pw: string) {
    await this.email().fill(email);
    await this.password().fill(pw);
    await this.submit().click();
  }
}
```

### Fixtures

```ts
import { test as base } from '@playwright/test';
export const test = base.extend<{ loginPage: LoginPage }>({
  loginPage: async ({ page }, use) => { await use(new LoginPage(page)); },
});
```

---

## 23. Component Testing in Cypress / Playwright

Both runners can mount a single React component in a real browser — useful when JSDOM falls short (CSS-driven behavior, real layout, drag-and-drop, IntersectionObserver). Slower than RTL, so reserve for components RTL cannot fairly test.

```ts
// playwright/ct
import { test, expect } from '@playwright/experimental-ct-react';
import Counter from '../src/Counter';
test('mounts', async ({ mount }) => {
  const c = await mount(<Counter />);
  await c.getByRole('button').click();
  await expect(c).toContainText('1');
});
```

---

## 24. TDD Workflow

1. **Red** — write a failing test that describes the next small behavior.
2. **Green** — write the smallest code that passes.
3. **Refactor** — clean up; tests must stay green.

In React this is most natural for **hooks, reducers, utilities, and presentational components**. For complex layouts, write the component first, then capture behavior in tests (test-after).

---

## 25. Best Practices

- Test behavior, not implementation.
- Prefer `getByRole` and `getByLabelText`. Avoid `data-testid`.
- Use `userEvent` (v14, async) over `fireEvent`.
- One behavior per `test()`. Names should read like sentences: `it('shows an error when email is invalid')`.
- Use **factory functions** for test data (`makeUser({ name: 'Alice' })`) instead of literals everywhere.
- Never `setTimeout`/sleep. Use `findBy*` / `waitFor`.
- Reset MSW handlers and any global mocks between tests.
- Keep tests fast — slow tests are skipped tests.

---

## 26. Common Pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| `act(...)` warning | State update happened outside an awaited interaction | `await user.click(...)` / `findBy*` |
| Test passes alone, fails in suite | Shared mock or store leaks | Reset in `afterEach` |
| `getBy*` "multiple elements found" | Query too broad | Add `name`, scope with `within()` |
| Flaky async test | `waitFor` body has multiple assertions or side effects | Keep `waitFor` body to a single assertion |
| Snapshot churn | Dynamic IDs/dates in DOM | Mock `Date.now`, normalize, or stop snapshotting |
| Testing Redux state directly | Implementation detail | Assert rendered output instead |

---

## 27. CI Integration (GitHub Actions)

```yaml
# .github/workflows/test.yml
name: test
on: [push, pull_request]
jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
      - uses: codecov/codecov-action@v4
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run build && npm run preview &
      - run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: playwright-report, path: playwright-report }
```

---

## Key Takeaways

- **Pyramid:** lots of unit, fewer integration, very few E2E.
- **RTL** drives integration tests; query by role/label, assert what users see.
- **`userEvent` v14 async** is the default — never reach for `fireEvent` first.
- **MSW** mocks at the network layer for both tests and dev.
- **Vitest** for Vite, **Jest** for legacy/CRA — APIs are nearly identical.
- **Playwright** is the modern E2E pick; pair it with a small page-object layer.
- **`jest-axe`** catches accessibility regressions cheaply.
- Test **behavior**, keep tests **fast and deterministic**, and wire them into CI.
