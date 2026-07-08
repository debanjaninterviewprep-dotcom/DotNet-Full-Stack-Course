# Topic 11: Testing — Jest and React Testing Library — Interview Questions

---

## Q1. What is the testing philosophy of React Testing Library?
**Answer:**
React Testing Library (RTL) is built on the principle:

> **"Test the way your users use your software, not implementation details."**

This means:
- Query elements the way users find them: by role, label, text, not by class/id/component internals.
- Interact as users do: click, type, focus, submit.
- Assert visible output, not component state or instance methods.

```jsx
// ❌ Testing implementation details
expect(wrapper.state('isOpen')).toBe(true);
expect(wrapper.find('.dropdown')).toHaveClass('open');

// ✓ Testing from user's perspective
expect(screen.getByRole('dialog')).toBeInTheDocument(); // visible dialog
await userEvent.click(screen.getByRole('button', { name: 'Delete' }));
expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
```

---

## Q2. What is Jest and what does it provide?
**Answer:**
Jest is a JavaScript testing framework that provides:
- **Test runner** — discovers and runs test files (`*.test.tsx`, `*.spec.ts`).
- **Assertion library** — `expect(value).toBe(expected)`.
- **Mocking** — `jest.fn()`, `jest.mock()`, `jest.spyOn()`.
- **Coverage** — `--coverage` flag.
- **Snapshots** — serialize components for regression testing.
- **Watch mode** — re-runs affected tests on file change.

```bash
# Run all tests
jest

# Run with coverage
jest --coverage

# Watch mode
jest --watch

# Run specific file
jest src/components/Button.test.tsx

# Run tests matching pattern
jest --testNamePattern="should render"
```

---

## Q3. How do you write a basic component test with RTL?
**Answer:**
```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Button from './Button';

describe('Button', () => {
  it('renders with correct label', () => {
    render(<Button label="Click me" />);
    expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument();
  });

  it('calls onClick when clicked', async () => {
    const handleClick = jest.fn();
    render(<Button label="Click" onClick={handleClick} />);

    await userEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is true', () => {
    render(<Button label="Disabled" disabled />);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

---

## Q4. What are the RTL query methods and their priority?
**Answer:**
RTL provides queries in priority order (most to least accessible):

```tsx
// Priority 1: Accessible queries (preferred)
screen.getByRole('button', { name: 'Submit' });   // by ARIA role + accessible name
screen.getByLabelText('Email address');            // by form label
screen.getByPlaceholderText('Enter email');        // by placeholder
screen.getByText('Submit');                        // by visible text
screen.getByDisplayValue('Current value');         // by form value

// Priority 2: Semantic queries
screen.getByAltText('Profile photo');              // by img alt
screen.getByTitle('Settings');                     // by title attribute

// Priority 3: Test IDs (last resort — not visible to users)
screen.getByTestId('submit-button');               // data-testid

// Query variants:
// getBy*    — throws if not found (synchronous)
// queryBy*  — returns null if not found (for asserting absence)
// findBy*   — async, waits for element to appear (Promises)
// getAllBy*  — returns array, throws if none found
// queryAllBy* — returns empty array if none found
```

---

## Q5. What is `userEvent` and how is it different from `fireEvent`?
**Answer:**
```tsx
import userEvent from '@testing-library/user-event';
import { fireEvent } from '@testing-library/react';

// fireEvent — low-level, dispatches a single DOM event
fireEvent.click(button);
fireEvent.change(input, { target: { value: 'hello' } });

// userEvent — high-level, simulates real user behaviour
// Clicking fires: pointerover, pointerenter, mouseover, mouseenter, pointermove,
//                 mousemove, pointerdown, mousedown, pointerup, mouseup, click

const user = userEvent.setup(); // v14+ — setup once per test
await user.click(button);
await user.type(input, 'hello'); // fires keydown, keypress, input, keyup per character
await user.clear(input);
await user.selectOptions(select, ['option1', 'option2']);
await user.upload(fileInput, file);
await user.keyboard('[Tab]');     // keyboard navigation

// Prefer userEvent over fireEvent for more realistic simulation
```

---

## Q6. How do you test async operations?
**Answer:**
```tsx
import { render, screen, waitFor } from '@testing-library/react';
import { server } from '../mocks/server'; // MSW mock server
import { http, HttpResponse } from 'msw';

test('displays users after loading', async () => {
  render(<UserList />);

  // Loading state
  expect(screen.getByRole('progressbar')).toBeInTheDocument();

  // Wait for content to appear
  const userItems = await screen.findAllByRole('listitem'); // findBy* is async
  expect(userItems).toHaveLength(3);

  // waitFor — poll until assertion passes
  await waitFor(() => {
    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  // Check content
  expect(screen.getByText('Alice')).toBeInTheDocument();
});

test('displays error on failure', async () => {
  server.use(http.get('/api/users', () => new HttpResponse(null, { status: 500 })));

  render(<UserList />);
  await screen.findByRole('alert');
  expect(screen.getByText(/failed to load/i)).toBeInTheDocument();
});
```

---

## Q7. What is Mock Service Worker (MSW) and why is it preferred over manual mocking?
**Answer:**
MSW intercepts HTTP requests at the network level — tests run against realistic API responses:

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () =>
    HttpResponse.json([{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }])
  ),
  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 3, ...body }, { status: 201 });
  }),
  http.get('/api/users/:id', ({ params }) =>
    HttpResponse.json({ id: +params.id, name: 'Alice' })
  )
];

// src/mocks/server.ts
import { setupServer } from 'msw/node';
export const server = setupServer(...handlers);

// jest.setup.ts
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**Why MSW over `jest.mock('axios')`:** Tests work the same way in browser (Storybook, manual testing) and test environment.

---

## Q8. How do you mock modules in Jest?
**Answer:**
```typescript
// Mock entire module
jest.mock('@/services/userService');
import { fetchUsers } from '@/services/userService';
(fetchUsers as jest.Mock).mockResolvedValue([{ id: 1, name: 'Alice' }]);

// Mock with factory
jest.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ isAuthenticated: true, user: { name: 'Debanjan' } })
}));

// Mock with auto-mock
jest.mock('@/services/api');
const mockApi = jest.mocked(api);
mockApi.get.mockResolvedValueOnce({ data: [] });

// Spy on existing module
jest.spyOn(window, 'alert').mockImplementation(() => {});
jest.spyOn(console, 'error').mockImplementation(() => {});

// Reset mocks between tests
afterEach(() => jest.clearAllMocks());
afterAll(() => jest.restoreAllMocks());
```

---

## Q9. How do you test custom hooks?
**Answer:**
```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

test('useCounter increments', () => {
  const { result } = renderHook(() => useCounter(0));

  expect(result.current.count).toBe(0);

  act(() => { result.current.increment(); });
  expect(result.current.count).toBe(1);

  act(() => { result.current.decrement(); });
  expect(result.current.count).toBe(0);
});

// Hook with dependencies (e.g., needs a Provider)
test('useAuth returns user', () => {
  const wrapper = ({ children }) => (
    <AuthProvider>{children}</AuthProvider>
  );
  const { result } = renderHook(() => useAuth(), { wrapper });
  expect(result.current.user).toBeDefined();
});

// Async hook
test('useFetch fetches data', async () => {
  const { result } = renderHook(() => useFetch('/api/users'));
  expect(result.current.loading).toBe(true);
  await waitFor(() => expect(result.current.loading).toBe(false));
  expect(result.current.data).toHaveLength(2);
});
```

---

## Q10. What is snapshot testing and when should you use it?
**Answer:**
Snapshot tests serialize the component output and compare against a stored snapshot on subsequent runs:

```tsx
import { render } from '@testing-library/react';

test('renders correctly', () => {
  const { container } = render(<UserCard user={{ name: 'Alice', role: 'admin' }} />);
  expect(container).toMatchSnapshot();
  // Creates/updates __snapshots__/UserCard.test.tsx.snap
});
```

**When to use snapshots:**
- ✓ Large static components where manual assertions are verbose.
- ✓ Catching accidental UI regressions.

**When NOT to use:**
- ❌ Dynamic content (dates, IDs).
- ❌ As a replacement for meaningful assertions.
- ❌ Large snapshots — they become noise that developers approve blindly.

**Modern alternative:** Use Storybook visual regression testing instead.

---

## Q11. What is `act()` and when do you need it?
**Answer:**
`act()` ensures all state updates and effects are processed before assertions:

```tsx
// RTL's render, userEvent, findBy*, waitFor already wrap in act()
// You rarely need to call act() manually

// Manual act() — when triggering updates outside RTL APIs
import { act } from '@testing-library/react';

test('timer updates count', async () => {
  jest.useFakeTimers();
  render(<TimerCounter />);
  expect(screen.getByText('0')).toBeInTheDocument();

  act(() => {
    jest.advanceTimersByTime(1000); // trigger timer callback inside act
  });

  expect(screen.getByText('1')).toBeInTheDocument();
  jest.useRealTimers();
});

// Async act
await act(async () => {
  await someAsyncOperation();
});
```

---

## Q12. How do you test components that use React Context?
**Answer:**
```tsx
// Option 1: Render with Provider wrapper
function renderWithProviders(ui, { initialState = {} } = {}) {
  function Wrapper({ children }) {
    return (
      <ThemeProvider theme="light">
        <UserProvider initialUser={initialState.user}>
          {children}
        </UserProvider>
      </ThemeProvider>
    );
  }
  return render(ui, { wrapper: Wrapper });
}

test('UserMenu shows user name', () => {
  renderWithProviders(<UserMenu />, { initialState: { user: { name: 'Alice' } } });
  expect(screen.getByText('Alice')).toBeInTheDocument();
});

// Option 2: Mock the context hook
jest.mock('@/contexts/AuthContext', () => ({
  useAuth: () => ({ user: { name: 'Alice' }, isAuthenticated: true })
}));
```

---

## Q13. What is the difference between unit, integration, and e2e tests?
**Answer:**
| | Unit | Integration | End-to-End |
|---|---|---|---|
| **Scope** | Single function/component | Multiple components together | Full user flow |
| **Speed** | Fast (ms) | Medium (ms-s) | Slow (s-min) |
| **Tools** | Jest | Jest + RTL | Playwright, Cypress |
| **Isolation** | Mocked dependencies | Real dependencies | Real browser + server |
| **Confidence** | Low | Medium | High |
| **Maintenance** | Low | Medium | High |

**Testing trophy (Kent C. Dodds):**
```
    🏆 Integration tests (most value per cost)
   /    \
  /      \
Unit   E2E   (fewest — most expensive)
```

For React: write mostly integration tests (render component + dependencies + RTL).

---

## Q14. How do you set up Jest with Vite?
**Answer:**
```bash
npm install --save-dev vitest @testing-library/react @testing-library/user-event @testing-library/jest-dom jsdom
```

```typescript
// vite.config.ts
export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,           // no need to import describe, it, expect
    environment: 'jsdom',    // simulates browser DOM
    setupFiles: ['./src/test/setup.ts']
  }
});

// src/test/setup.ts
import '@testing-library/jest-dom'; // adds toBeInTheDocument, toHaveClass, etc.

// package.json
{ "scripts": { "test": "vitest", "test:coverage": "vitest --coverage" } }
```

---

## Q15. What are common React testing anti-patterns?
**Answer:**
```tsx
// ❌ Testing implementation details
expect(component.state).toEqual({ isOpen: true });
expect(wrapper.find(Button)).toHaveLength(1);

// ❌ Querying by class/id (fragile)
screen.getByClassName('submit-btn');  // breaks on CSS refactor
screen.getByTestId('button');         // last resort only

// ❌ Awaiting arbitrary timeouts
await new Promise(r => setTimeout(r, 100)); // flaky
// ✓ Use waitFor or findBy*

// ❌ Not cleaning up
render(<Component />); // without cleanup → memory leaks in test suite
// ✓ RTL auto-cleans after each test (with proper setup)

// ❌ Snapshot testing blindly
expect(container).toMatchSnapshot(); // massive snapshots nobody reviews
// ✓ Test specific behaviour: expect(screen.getByRole('heading')).toHaveTextContent('Title')

// ❌ Mocking everything
jest.mock('./UserService'); // mocking so much removes confidence
// ✓ Use MSW for HTTP — test closer to real behaviour
```
