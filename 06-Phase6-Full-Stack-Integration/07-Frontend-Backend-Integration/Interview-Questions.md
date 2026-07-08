# Topic 07: Frontend-Backend Integration — Interview Questions

---

## Q1. What are common patterns for consuming a REST API from Angular/React?
**Answer:**
```typescript
// Angular service pattern
@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly api = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/users`;

  getAll(params?: UserQueryParams): Observable<PagedResult<UserDto>> {
    return this.api.get<PagedResult<UserDto>>(this.baseUrl, { params: params as any });
  }

  getById(id: number): Observable<UserDto> {
    return this.api.get<UserDto>(`${this.baseUrl}/${id}`);
  }

  create(dto: CreateUserDto): Observable<UserDto> {
    return this.api.post<UserDto>(this.baseUrl, dto);
  }

  update(id: number, dto: UpdateUserDto): Observable<void> {
    return this.api.put<void>(`${this.baseUrl}/${id}`, dto);
  }

  delete(id: number): Observable<void> {
    return this.api.delete<void>(`${this.baseUrl}/${id}`);
  }
}
```

---

## Q2. How do you handle API loading states and errors in the UI?
**Answer:**
```typescript
// Angular component with loading/error states
@Component({
  template: `
    @if (loading()) { <app-spinner /> }
    @if (error()) { <app-error-message [message]="error()" /> }
    @if (users()) {
      @for (user of users(); track user.id) { <app-user-card [user]="user" /> }
    }
  `
})
export class UserListComponent {
  private svc = inject(UserService);

  users   = signal<UserDto[]>([]);
  loading = signal(true);
  error   = signal<string | null>(null);

  ngOnInit() {
    this.svc.getAll().pipe(
      finalize(() => this.loading.set(false))
    ).subscribe({
      next:  users => this.users.set(users),
      error: err => this.error.set(err.error?.title ?? 'Failed to load users')
    });
  }
}

// React with TanStack Query
function UserList() {
  const { data: users, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => userService.getAll()
  });

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage message={error.message} />;
  return <>{users?.map(u => <UserCard key={u.id} user={u} />)}</>;
}
```

---

## Q3. What is the optimistic UI pattern and how do you implement it?
**Answer:**
Update the UI immediately before the server confirms — roll back if the request fails:

```typescript
// Angular with optimistic update
deleteUser(id: number) {
  const backup = [...this.users()]; // save state for rollback

  // 1. Optimistically remove from UI
  this.users.update(users => users.filter(u => u.id !== id));

  // 2. Make API call
  this.userService.delete(id).subscribe({
    error: () => {
      // 3. Rollback on failure
      this.users.set(backup);
      this.notify.showError('Failed to delete user');
    }
  });
}

// React with TanStack Query
const deleteUser = useMutation({
  mutationFn: (id: number) => userService.delete(id),
  onMutate: async (id) => {
    await queryClient.cancelQueries({ queryKey: ['users'] });
    const previous = queryClient.getQueryData(['users']); // snapshot
    queryClient.setQueryData(['users'], (old: UserDto[]) => old.filter(u => u.id !== id));
    return { previous }; // context for rollback
  },
  onError: (_err, _id, context) => {
    queryClient.setQueryData(['users'], context?.previous); // rollback
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['users'] })
});
```

---

## Q4. How do you implement global notification/toast system?
**Answer:**
```typescript
// Angular notification service
@Injectable({ providedIn: 'root' })
export class NotificationService {
  private notifications = signal<Notification[]>([]);

  show(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'info', duration = 3000) {
    const id = crypto.randomUUID();
    this.notifications.update(list => [...list, { id, message, type }]);
    setTimeout(() => this.dismiss(id), duration);
  }

  showSuccess(message: string) { this.show(message, 'success'); }
  showError(message: string)   { this.show(message, 'error', 5000); }
  dismiss(id: string)          { this.notifications.update(list => list.filter(n => n.id !== id)); }

  readonly list = this.notifications.asReadonly();
}

// Toast container (placed in AppComponent)
@Component({
  template: `
    <div class="toast-container">
      @for (n of notifSvc.list(); track n.id) {
        <div [class]="'toast toast-' + n.type" (click)="notifSvc.dismiss(n.id)">
          {{ n.message }}
        </div>
      }
    </div>
  `
})
export class ToastContainerComponent {
  notifSvc = inject(NotificationService);
}
```

---

## Q5. What is the Angular reactive forms + API pattern for edit forms?
**Answer:**
```typescript
@Component({ template: `...` })
export class UserEditComponent implements OnInit {
  private route  = inject(ActivatedRoute);
  private svc    = inject(UserService);
  private notify = inject(NotificationService);
  private router = inject(Router);

  form = inject(FormBuilder).group({
    name:  ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    role:  ['User']
  });

  userId!: number;
  loading = signal(false);

  ngOnInit() {
    this.userId = +this.route.snapshot.params['id'];
    this.svc.getById(this.userId).subscribe(user => this.form.patchValue(user));
  }

  onSubmit() {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.loading.set(true);

    this.svc.update(this.userId, this.form.value as UpdateUserDto).pipe(
      finalize(() => this.loading.set(false))
    ).subscribe({
      next: () => {
        this.notify.showSuccess('User updated successfully');
        this.router.navigate(['/users']);
      },
      error: err => {
        if (err.status === 422) {
          Object.entries(err.error.errors).forEach(([field, errors]) =>
            this.form.get(field.toLowerCase())?.setErrors({ server: errors }));
        } else {
          this.notify.showError(err.error?.title ?? 'Update failed');
        }
      }
    });
  }
}
```

---

## Q6. How do you handle API pagination in the frontend?
**Answer:**
```typescript
// Angular paginated list
@Component({
  template: `
    <app-user-table [users]="users()"></app-user-table>
    <app-pagination
      [total]="total()" [page]="page()" [pageSize]="pageSize"
      (pageChange)="onPageChange($event)">
    </app-pagination>
  `
})
export class UserListComponent {
  private svc = inject(UserService);
  users    = signal<UserDto[]>([]);
  total    = signal(0);
  page     = signal(1);
  pageSize = 20;

  ngOnInit() { this.loadUsers(); }

  loadUsers() {
    this.svc.getAll({ page: this.page(), pageSize: this.pageSize }).subscribe(result => {
      this.users.set(result.data);
      this.total.set(result.total);
    });
  }

  onPageChange(newPage: number) {
    this.page.set(newPage);
    this.loadUsers();
  }
}
```

---

## Q7. What is the difference between synchronous and asynchronous data loading strategies?
**Answer:**
```typescript
// Strategy 1: Eager loading — fetch on component init
ngOnInit() { this.loadData(); }

// Strategy 2: Lazy loading — fetch on user action
<button (click)="loadComments()">Show Comments</button>
loadComments() { if (!this.comments) this.svc.getComments(this.postId).subscribe(...); }

// Strategy 3: Route resolver — data ready before component renders
// No loading spinner, component always has data
{ path: 'user/:id', component: UserDetailComponent, resolve: { user: userResolver } }

// Strategy 4: Prefetching — fetch on hover/intent
(mouseenter)="prefetchData()"
prefetchData() { this.queryClient.prefetchQuery({ queryKey: ['user', id], queryFn: ... }); }

// Strategy 5: Background refresh — poll for updates
refreshData$ = interval(30000).pipe(
  switchMap(() => this.svc.getLatestData()),
  takeUntilDestroyed()
).subscribe(data => this.data.set(data));
```

---

## Q8. What is the `async` pipe best practice in Angular?
**Answer:**
```typescript
// Anti-pattern: multiple subscriptions to the same observable
@Component({
  template: `
    {{ (user$ | async)?.name }}
    {{ (user$ | async)?.email }}  <!-- 2nd HTTP call! -->
  `
})

// Best practice: single subscription with 'as' alias
@Component({
  template: `
    @if (user$ | async; as user) {
      {{ user.name }}
      {{ user.email }}  <!-- same subscription -->
    }
  `
})

// Or with shareReplay
user$ = this.svc.getUser(id).pipe(shareReplay(1)); // cached

// Combined multiple observables
vm$ = combineLatest({
  user:    this.userSvc.getUser(id),
  orders:  this.orderSvc.getByUserId(id),
  loading: this.loadingSvc.isLoading$
});
// Template: @if (vm$ | async; as vm) { ... vm.user.name ... }
```

---

## Q9. What is request deduplication and how do you implement it?
**Answer:**
Prevent the same API request from being made multiple times simultaneously:

```typescript
// Angular: shareReplay for shared data
@Injectable({ providedIn: 'root' })
export class ConfigService {
  // All subscribers share one HTTP call
  config$ = this.http.get<Config>('/api/config').pipe(
    shareReplay({ bufferSize: 1, refCount: true })
  );
}

// React Query handles deduplication automatically
// Multiple components calling the same query key → one HTTP request
const { data } = useQuery({ queryKey: ['config'], queryFn: fetchConfig });
// 10 components mounting simultaneously → 1 HTTP call

// Angular signals with lazy initialization
config = signal<Config | null>(null);
private loading = false;

loadConfig() {
  if (this.loading || this.config()) return; // already loading or loaded
  this.loading = true;
  this.http.get<Config>('/api/config').subscribe(c => {
    this.config.set(c);
    this.loading = false;
  });
}
```

---

## Q10. How do you implement infinite scrolling?
**Answer:**
```typescript
// Angular with Intersection Observer
@Component({ template: `
  @for (item of items(); track item.id) { <app-item [item]="item" /> }
  <div #loadMore class="load-trigger"></div>
  @if (loading()) { <app-spinner /> }
` })
export class InfiniteListComponent implements AfterViewInit, OnDestroy {
  @ViewChild('loadMore') loadMoreEl!: ElementRef;

  items   = signal<ItemDto[]>([]);
  loading = signal(false);
  hasMore = signal(true);
  page    = 1;

  private observer!: IntersectionObserver;

  ngAfterViewInit() {
    this.observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && !this.loading() && this.hasMore())
        this.loadMore();
    });
    this.observer.observe(this.loadMoreEl.nativeElement);
    this.loadMore(); // initial load
  }

  loadMore() {
    this.loading.set(true);
    this.svc.getPage(this.page++, 20).pipe(finalize(() => this.loading.set(false)))
      .subscribe(result => {
        this.items.update(list => [...list, ...result.data]);
        this.hasMore.set(result.hasNextPage);
      });
  }

  ngOnDestroy() { this.observer.disconnect(); }
}
```

---

## Q11. What is the API contract testing pattern?
**Answer:**
Consumer-Driven Contract Testing ensures the backend API matches what the frontend expects:

```typescript
// Angular consumer defines what it expects from the API
// Using Pact (pact.io)
describe('Users API contract', () => {
  it('should return a list of users', async () => {
    await pact.addInteraction({
      state: 'users exist',
      uponReceiving: 'a GET request to /api/users',
      withRequest: { method: 'GET', path: '/api/users', query: { page: '1', pageSize: '20' } },
      willRespondWith: {
        status: 200,
        body: {
          data: eachLike({ id: like(1), name: like('Alice'), email: like('alice@test.com') }),
          total: like(1), page: like(1), pageSize: like(20)
        }
      }
    });

    const result = await userService.getAll({ page: 1, pageSize: 20 }).toPromise();
    expect(result.data).toBeDefined();
  });
});

// The contract is shared with the backend to validate they honor it
// dotnet test --filter "ApiContract" — backend verifies against pact file
```

---

## Q12. How do you handle form submission with file uploads?
**Answer:**
```typescript
// Angular file upload with progress
uploadFile(file: File): Observable<number> {
  const formData = new FormData();
  formData.append('file', file, file.name);
  formData.append('title', this.title);

  return this.http.post('/api/files', formData, {
    reportProgress: true,
    observe: 'events'
  }).pipe(
    map(event => {
      switch (event.type) {
        case HttpEventType.UploadProgress:
          return Math.round(100 * event.loaded / (event.total ?? 1));
        case HttpEventType.Response:
          return 100;
        default:
          return 0;
      }
    })
  );
}

// Component
onFileSelected(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (!file) return;

  this.uploadFile(file).subscribe({
    next: progress => this.progress.set(progress),
    error: err => this.error.set(err.error?.detail),
    complete: () => this.notify.showSuccess('File uploaded!')
  });
}
```

---

## Q13. What is a loading skeleton and why is it better than a spinner?
**Answer:**
Skeletons show the shape of content while loading — reduce perceived wait time:

```html
<!-- Spinner — user just sees "loading"... -->
<div *ngIf="loading">
  <app-spinner />
</div>

<!-- Skeleton — user sees the layout instantly -->
@if (loading()) {
  <div class="user-card-skeleton">
    <div class="skeleton-avatar"></div>
    <div class="skeleton-line w-3/4"></div>
    <div class="skeleton-line w-1/2"></div>
  </div>
} @else {
  <app-user-card [user]="user()" />
}
```

```css
.skeleton-line {
  height: 1rem;
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
  margin-bottom: 8px;
}
@keyframes shimmer { 0% { background-position: 200% 0 } 100% { background-position: -200% 0 } }
```

---

## Q14. How do you manage API base URL configuration between environments?
**Answer:**
```typescript
// Angular environment files
// environment.ts (dev)
export const environment = { apiUrl: 'http://localhost:5000/api' };
// environment.production.ts
export const environment = { apiUrl: 'https://api.myapp.com/api' };

// Use in service
@Injectable({ providedIn: 'root' })
export class ApiBaseService {
  protected readonly base = inject<string>(API_URL_TOKEN);
}
// Provide:
{ provide: API_URL_TOKEN, useValue: environment.apiUrl }

// Or configure HttpClient base URL globally
// Install: @angular/common/http
export function apiInterceptor(env = inject(ENVIRONMENT)): HttpInterceptorFn {
  return (req, next) => next(req.clone({ url: `${env.apiUrl}/${req.url}` }));
}
```

---

## Q15. How do you implement the frontend side of pagination with URL state?
**Answer:**
```typescript
// Preserve pagination state in URL (back button works, bookmarkable)
@Component({})
export class UserListComponent {
  private router = inject(Router);
  private route  = inject(ActivatedRoute);

  ngOnInit() {
    // Restore state from URL
    this.route.queryParams.subscribe(params => {
      this.page.set(+(params['page'] ?? 1));
      this.pageSize.set(+(params['pageSize'] ?? 20));
      this.search.set(params['search'] ?? '');
      this.loadUsers();
    });
  }

  onPageChange(newPage: number) {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { page: newPage },
      queryParamsHandling: 'merge' // keep other params
    });
  }

  onSearch(term: string) {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { search: term, page: 1 }, // reset page on search
      queryParamsHandling: 'merge'
    });
  }
}
// URL: /users?page=3&pageSize=20&search=alice
```
