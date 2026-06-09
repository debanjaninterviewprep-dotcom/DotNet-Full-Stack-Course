# Topic 8: HTTP Client & API Integration — Practice Problems

## Problem 1: Basic HTTP Operations (Easy)
**Concept**: GET, POST, PUT, DELETE with HttpClient

### 1a. Setup a Mock API
Option A: Use [JSONPlaceholder](https://jsonplaceholder.typicode.com):
```
GET    /users      — List users
GET    /users/1    — Get user by ID
POST   /users      — Create user
PUT    /users/1    — Update user
DELETE /users/1    — Delete user
GET    /posts      — List posts
```

Option B: Use `json-server` locally:
```bash
npm install -g json-server
# Create db.json with mock data
json-server --watch db.json --port 3000
```

### 1b. User Service
Create `UserService` with typed methods:
```typescript
getUsers(): Observable<User[]>
getUserById(id: number): Observable<User>
createUser(user: CreateUserDto): Observable<User>
updateUser(id: number, user: User): Observable<User>
deleteUser(id: number): Observable<void>
```

### 1c. User List Component
- Display all users from API
- Loading spinner while fetching
- Error message if request fails
- "Refresh" button to reload data

### 1d. CRUD Operations
- List page with all users
- "Add User" button → form → POST
- "Edit" button → pre-filled form → PUT
- "Delete" button → confirmation → DELETE
- Refresh list after each operation

---

## Problem 2: Async Pipe & Observables (Easy-Medium)
**Concept**: async pipe, Observable chaining, error handling

### 2a. Async Pipe Usage
Refactor UserListComponent to use async pipe:
```html
@if (users$ | async; as users) {
  @for (user of users; track user.id) {
    <div>{{ user.name }}</div>
  }
} @else {
  <p>Loading...</p>
}
```
No manual subscribe, no manual unsubscribe!

### 2b. Loading & Error States
Create a reusable pattern for data states:
```typescript
interface DataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}
```
Implement `loadUsers()`, `loadPosts()` using this pattern.
Display appropriate UI for each state.

### 2c. Chained Requests
When user selects a user from the list:
1. Fetch user details (`GET /users/:id`)
2. Fetch user's posts (`GET /users/:id/posts`)
3. Display user info + their posts

Use `switchMap` to chain the requests.

### 2d. Parallel Requests
Build a dashboard that loads data from multiple endpoints simultaneously:
```typescript
dashboard$ = forkJoin({
  users: this.http.get<User[]>('/api/users'),
  posts: this.http.get<Post[]>('/api/posts'),
  comments: this.http.get<Comment[]>('/api/comments')
}).pipe(
  map(({ users, posts, comments }) => ({
    totalUsers: users.length,
    totalPosts: posts.length,
    totalComments: comments.length,
    recentPosts: posts.slice(-5)
  }))
);
```

---

## Problem 3: Search & Filtering (Medium)
**Concept**: debounceTime, distinctUntilChanged, switchMap

### 3a. Live Search
Implement a search feature:
- Input field with real-time search
- Debounce 300ms after typing stops
- Cancel previous request when new one starts (switchMap)
- Min 2 characters to search
- Display "No results" when empty response
- Show loading spinner during search

### 3b. Filtered Table
Build a data table with server-side filtering:
- Search input (debounced)
- Category dropdown
- Sort by column (clicking header)
- Pagination (page, limit)
- All filters update the HTTP request:
  `GET /products?q=angular&category=books&sort=price&order=asc&page=1&limit=10`

### 3c. Autocomplete
Build an autocomplete dropdown:
- Type → debounce → search API
- Display dropdown with suggestions
- Click suggestion → fill input
- Close dropdown on blur
- Keyboard navigation (up/down arrows, enter to select)

### 3d. Infinite Scroll
Load more data as user scrolls:
- Initial load: 20 items
- When scroll reaches bottom: load next 20
- "Loading more..." indicator
- "No more items" when all loaded

---

## Problem 4: Interceptors (Medium-Hard)
**Concept**: Request/response modification, auth, error handling

### 4a. Auth Interceptor
Create an interceptor that:
- Reads JWT token from a service or localStorage
- Adds `Authorization: Bearer <token>` header to every request
- Skips token for login/register endpoints
- If 401 response → redirect to login page

### 4b. Logging Interceptor
Create an interceptor that logs:
```
→ GET /api/users
← GET /api/users → 200 OK (245ms)
→ POST /api/users
← POST /api/users → 201 Created (512ms)
→ GET /api/admin
← GET /api/admin → 403 Forbidden (89ms) ⚠️
```

### 4c. Error Handling Interceptor
Global error handler that:
- 400 → Show validation errors
- 401 → Redirect to login
- 403 → Show "Access denied" notification
- 404 → Show "Not found" notification
- 500 → Show "Server error, try again" notification
- Network error → Show "No connection" notification

### 4d. Loading Interceptor
Create an interceptor + service that:
- Tracks active HTTP requests count
- Shows global loading bar when requests > 0
- Hides when all complete
- Works as: `LoadingService.isLoading$` → async pipe in AppComponent

```typescript
export const loadingInterceptor: HttpInterceptorFn = (req, next) => {
  const loadingService = inject(LoadingService);
  loadingService.show();
  return next(req).pipe(
    finalize(() => loadingService.hide())
  );
};
```

---

## Problem 5: Complete API Integration (Hard)
**Concept**: Full CRUD app with API, interceptors, and state management

### Build a Blog Application

Use JSONPlaceholder or json-server as your backend.

**Services:**
```typescript
// PostService — CRUD for posts
// CommentService — CRUD for comments on posts
// UserService — Get user info (authors)
// AuthService — Mock login/logout (generates fake JWT)
```

**Features:**

### 5a. Post List Page
- Load all posts with pagination (10 per page)
- Each post shows: title, excerpt, author name, comment count
- Search by title (debounced)
- Filter by author
- Sort by date/title
- Loading skeleton while fetching

### 5b. Post Detail Page
- Load post + comments in parallel (`forkJoin`)
- Display post content
- Display author info (loaded via `switchMap`)
- Comment list with author names
- "Add Comment" form (POST request)

### 5c. Create/Edit Post
- Form for creating new post
- Edit existing post (pre-fill form via route resolver)
- Unsaved changes guard
- Submit → POST/PUT → navigate to post detail
- Show success/error notification

### 5d. Full Interceptor Stack
Register all interceptors:
```typescript
provideHttpClient(
  withInterceptors([
    authInterceptor,    // Add auth token
    loadingInterceptor, // Track loading state
    loggingInterceptor, // Log requests
    errorInterceptor,   // Handle errors globally
    cacheInterceptor    // Cache GET requests
  ])
)
```

### 5e. Caching
Implement response caching:
- Cache GET requests for 5 minutes
- Invalidate cache on POST/PUT/DELETE
- "Force refresh" button to bypass cache

**Expected Output:**
```
═══ Blog Application ═══
[Loading bar ████████░░░░]

── All Posts ──
Search: [angular________] | Author: [All ▼] | Sort: [Newest ▼]

┌────────────────────────────────────────┐
│ Understanding Angular Signals          │
│ by Debanjan · 5 comments · 2 days ago  │
│ Angular signals provide a reactive...  │
│ [Read More]                            │
├────────────────────────────────────────┤
│ TypeScript 5.5 Features                │
│ by Alice · 12 comments · 1 week ago    │
│ The latest TypeScript release...       │
│ [Read More]                            │
└────────────────────────────────────────┘

[← Previous] Page 1 of 10 [Next →]

── POST /api/posts (auth interceptor added token) ──
→ POST /api/posts
← POST /api/posts → 201 Created (312ms)
✅ Post created successfully!
```

---

### Submission
- Set up api service(s) pointing to JSONPlaceholder or json-server
- Implement all HTTP operations with proper typing
- Use async pipe where possible
- Implement at least 2 interceptors
- Handle loading and error states
- Tell me "check" when you're ready for review!
