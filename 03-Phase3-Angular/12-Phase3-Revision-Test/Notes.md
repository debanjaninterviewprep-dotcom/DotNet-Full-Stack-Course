# Topic 12: Phase 3 Revision Test

## Instructions

This is a comprehensive revision test covering **all Angular topics** from Phase 3.
- **Time**: Attempt within 4-5 hours (untimed, but track yourself)
- **Open book**: You may refer to your notes
- **Grading**: Each section carries equal weight
- **Goal**: Build a working Angular application that demonstrates every concept

---

## Part A: Theory & Concepts (Short Answers)

Answer each question in 2-4 sentences.

### TypeScript
1. What is the difference between `interface` and `type` in TypeScript? When would you use each?
2. Explain generics with an example. Why are they useful?
3. What is `unknown` vs `any`? Why is `unknown` safer?
4. What are decorators in TypeScript? Name 3 Angular decorators.

### Angular Architecture
5. What are the 4 types of data binding in Angular? Give the syntax for each.
6. Explain the Angular component lifecycle. Which 3 hooks do you use most often and why?
7. What is the difference between `@Input()` and `@Output()`? Draw the data flow.
8. What is dependency injection? Why doesn't Angular use `new ServiceName()` directly?

### Routing & Navigation
9. What is lazy loading? How does it improve performance?
10. Explain the difference between `snapshot` and `paramMap` observable for reading route params.
11. What are the different types of route guards? Give a use case for each.

### Forms
12. Compare template-driven vs reactive forms (at least 4 differences).
13. What is a cross-field validator? Give an example.
14. How does `FormArray` work? When would you use it?

### HTTP & State
15. What is an HTTP interceptor? Give 3 real-world use cases.
16. What is the NgRx flow? Explain: Action → Reducer → Store → Selector → Component.
17. What is the `async` pipe? Why is it preferred over manual subscribe?

### Pipes & Auth
18. What is the difference between pure and impure pipes?
19. Explain the JWT authentication flow in an Angular app.
20. Why should you validate permissions on the server even if the UI hides elements?

---

## Part B: Code Challenges (Write Code)

### B1. TypeScript Challenge
Write a generic `Repository<T>` class:

```typescript
interface HasId { id: number; }

class Repository<T extends HasId> {
  // Implement: add, getById, getAll, update, delete, find(predicate)
}
```

Add a `PaginatedResult<T>` type and a `getPage(page: number, size: number): PaginatedResult<T>` method.

### B2. Component Challenge
Write a complete `StarRatingComponent`:
- `@Input() rating: number` (0-5)
- `@Input() maxStars: number = 5`
- `@Input() readonly: boolean = false`
- `@Output() ratingChanged: EventEmitter<number>`
- Displays filled/empty stars
- Clicking a star updates the rating (unless readonly)
- Hover preview of rating

Write the full `.ts`, `.html`, and `.css` files.

### B3. Reactive Form Challenge
Write a multi-step form with 3 steps:

**Step 1**: Personal (firstName, lastName, email — all required)
**Step 2**: Address (street, city, state, zip — zip must be 5 digits)
**Step 3**: Review & Submit (display all data, confirm checkbox required)

Requirements:
- Each step validates before proceeding
- Back button preserves data
- Custom validator: email must end with @company.com
- Show progress: "Step X of 3"

### B4. Service + HTTP Challenge
Write `ProductService` with:
```typescript
getAll(params?: { search?: string; category?: string; page?: number }): Observable<PaginatedResponse<Product>>
getById(id: number): Observable<Product>
create(product: CreateProductDto): Observable<Product>
update(id: number, changes: Partial<Product>): Observable<Product>
delete(id: number): Observable<void>
```
Include: error handling with `catchError`, retry logic, `finalize` for loading state.

### B5. Custom Pipe Challenge
Write these pipes and demonstrate usage:
1. `timeAgo` — relative time display
2. `truncate` — shorten text with ellipsis
3. `highlight` — wrap matching text in `<mark>` tags
4. `sortBy` — sort array by property

### B6. Auth Interceptor Challenge
Write a complete `authInterceptor` that:
- Adds Bearer token from AuthService
- Skips public URLs (`/auth/login`, `/auth/register`)
- Handles 401 by logging out
- Handles 403 by showing notification

---

## Part C: Build Project — Task Management App

### Build a complete Angular application with the following features:

### C1. Core Setup
- Angular 17+ standalone components
- Proper project structure (core, shared, features, models)
- Environment configuration (apiUrl, appName)
- Lazy-loaded feature modules

### C2. Authentication
- Login / Register pages
- AuthService with JWT token management
- Auth guard on protected routes
- Role guard on admin routes
- Auth interceptor for HTTP requests
- Navigation changes based on auth state

```
Guest:  [Home] [Login] [Register]
User:   [Home] [Tasks] [Profile] [Logout]
Admin:  [Home] [Tasks] [Admin] [Profile] [Logout]
```

### C3. Task Management (CRUD)
- Task list with filtering (status, priority, search)
- Create task form (reactive, with validation)
- Edit task form (with unsaved changes guard)
- Delete task (with confirmation)
- Task detail page (route params)

**Task Model:**
```typescript
interface Task {
  id: number;
  title: string;
  description: string;
  status: 'todo' | 'in-progress' | 'done';
  priority: 'low' | 'medium' | 'high';
  assignee: string;
  dueDate: Date;
  createdAt: Date;
  tags: string[];
}
```

### C4. Custom Pipes
Use at least 4 custom pipes:
- `timeAgo` for dates
- `truncate` for descriptions
- Priority badge pipe
- `pluralize` for counts

### C5. HTTP Integration
- Service layer with HttpClient
- Loading states for all API calls
- Error handling with user-friendly messages
- At least 2 interceptors (auth + loading)
- Search with debounce

### C6. Routing
```
/                    → Home
/login               → Login (no-auth guard)
/register            → Register (no-auth guard)
/tasks               → Task List (auth guard)
/tasks/new           → Create Task (auth guard + unsaved changes)
/tasks/:id           → Task Detail (auth guard + resolver)
/tasks/:id/edit      → Edit Task (auth guard + unsaved changes)
/admin               → Admin Dashboard (admin guard, lazy loaded)
/profile             → User Profile (auth guard)
/unauthorized        → 403 page
/**                  → 404 page
```

### C7. State Management (Bonus)
Use NgRx OR BehaviorSubject services for:
- Task list state
- Auth state
- UI state (loading, notifications)

---

## Grading Rubric

| Section | Points |
|---|---|
| Part A: Theory (20 questions × 2) | 40 |
| Part B: Code Challenges (6 × 5) | 30 |
| Part C: Build Project | 30 |
| **Total** | **100** |

### Part C Breakdown:
| Feature | Points |
|---|---|
| Project structure & setup | 3 |
| Authentication (login, guards, interceptors) | 6 |
| Task CRUD (list, create, edit, delete) | 6 |
| Routing (params, lazy loading, guards) | 4 |
| Forms (reactive, validation, multi-step) | 4 |
| HTTP integration (service, interceptors) | 3 |
| Custom pipes (at least 4) | 2 |
| NgRx/State management (bonus) | 2 |

---

## Evaluation Criteria

| Criteria | What I'll Check |
|---|---|
| **Correctness** | Does it work? No runtime errors? |
| **TypeScript** | Proper types? No `any`? |
| **Architecture** | Clean separation? Feature folders? |
| **Reusability** | Shared components and pipes? |
| **Error handling** | Loading states? Error messages? |
| **Security** | Guards enforce access? Interceptors add tokens? |
| **Code quality** | Clean, readable, follows Angular conventions? |
| **Completeness** | All requirements implemented? |

---

### Submission
- Complete all parts (A, B, C)
- Ensure `ng serve` runs without errors
- The app should be navigable and functional
- Push to GitHub
- Tell me "check" when you're ready for review!

---

**Good luck, Debanjan! This test covers everything from TypeScript to NgRx. Take your time and build quality code! 🎯**
