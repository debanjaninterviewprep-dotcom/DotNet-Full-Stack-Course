# Topic 10: Testing Full Stack — Interview Questions

---

## Q1. What is `WebApplicationFactory` and how is it used for integration testing?
**Answer:**
`WebApplicationFactory<T>` creates a real in-memory test server — tests run against the actual app with real middleware, routing, and DI:

```csharp
// Custom factory with test-specific configuration
public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(services => {
            // Replace production DB with in-memory
            var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
            if (descriptor is not null) services.Remove(descriptor);
            services.AddDbContext<AppDbContext>(opts => opts.UseInMemoryDatabase("TestDb"));

            // Seed test data
            using var sp = services.BuildServiceProvider();
            using var scope = sp.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Database.EnsureCreated();
            SeedTestData(db);
        });
    }
}

// Test class
public class UsersControllerTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public UsersControllerTests(TestWebApplicationFactory factory)
        => _client = factory.CreateClient();

    [Fact]
    public async Task GetUsers_ReturnsPagedResult()
    {
        var response = await _client.GetAsync("/api/users?page=1&pageSize=10");
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<PagedResult<UserDto>>();
        Assert.NotNull(result);
        Assert.True(result.Data.Any());
    }
}
```

---

## Q2. How do you use TestContainers for database integration tests?
**Answer:**
TestContainers spin up a real SQL Server instance in Docker for tests:

```csharp
// Install: Testcontainers.MsSql
public class DatabaseIntegrationTests : IAsyncLifetime
{
    private readonly MsSqlContainer _db = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
        .WithPassword("Test@1234!")
        .Build();

    public async Task InitializeAsync() => await _db.StartAsync();
    public async Task DisposeAsync() => await _db.StopAsync();

    [Fact]
    public async Task CreateUser_PersistsToDatabase()
    {
        var opts = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlServer(_db.GetConnectionString())
            .Options;

        await using var db = new AppDbContext(opts);
        await db.Database.MigrateAsync(); // run migrations on test DB

        var repo = new UserRepository(db);
        var user = new User { Name = "Test", Email = "test@example.com" };
        await repo.AddAsync(user);
        await db.SaveChangesAsync();

        var found = await repo.GetByIdAsync(user.Id);
        Assert.NotNull(found);
        Assert.Equal("Test", found.Name);
    }
}
```

---

## Q3. How do you test ASP.NET Core API endpoints with authentication?
**Answer:**
```csharp
// Custom auth scheme for tests
public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var claims = new List<Claim> {
            new(ClaimTypes.NameIdentifier, "1"),
            new(ClaimTypes.Email, "test@test.com"),
            new(ClaimTypes.Role, "Admin")
        };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, "Test"));
        return Task.FromResult(AuthenticateResult.Success(
            new AuthenticationTicket(principal, "Test")));
    }
}

// Factory with test auth
public class AuthenticatedTestFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(services => {
            services.AddAuthentication("Test")
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", _ => {});
        });
    }
}

// Test
[Fact]
public async Task DeleteUser_AsAdmin_Returns204()
{
    var response = await _client.DeleteAsync("/api/users/1");
    Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
}

[Fact]
public async Task ProtectedEndpoint_WithoutAuth_Returns401()
{
    var unauthClient = _factory.CreateClient(); // no test auth
    var response = await unauthClient.GetAsync("/api/admin/users");
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
}
```

---

## Q4. What is the testing pyramid for a full-stack application?
**Answer:**
```
         ▲
        / \
       / E2E\         ← Playwright/Cypress — few, slow, expensive
      /-------\
     /Integration\    ← WebApplicationFactory, TestContainers — moderate number
    /-------------\
   / Unit Tests    \  ← Jest/xUnit — many, fast, cheap
  /-----------------\

Full-stack testing strategy:
- Unit tests: Services, domain logic, validators, Angular/React components
- Integration tests: API endpoints, DB queries, SignalR hubs
- E2E tests: Critical user journeys (login, checkout, create order)
```

---

## Q5. How do you write unit tests for ASP.NET Core services?
**Answer:**
```csharp
// xUnit + Moq
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repoMock = new();
    private readonly Mock<IEmailService> _emailMock = new();
    private readonly Mock<IMapper> _mapperMock = new();
    private readonly UserService _sut;

    public UserServiceTests()
        => _sut = new UserService(_repoMock.Object, _emailMock.Object, _mapperMock.Object);

    [Fact]
    public async Task CreateAsync_WithExistingEmail_ThrowsConflictException()
    {
        _repoMock.Setup(r => r.ExistsAsync(It.IsAny<Expression<Func<User, bool>>>()))
                 .ReturnsAsync(true);

        await Assert.ThrowsAsync<ConflictException>(
            () => _sut.CreateAsync(new CreateUserDto { Email = "existing@test.com" }));
    }

    [Fact]
    public async Task CreateAsync_WithNewEmail_CreatesAndSendsWelcomeEmail()
    {
        var dto = new CreateUserDto { Name = "Alice", Email = "alice@test.com" };
        _repoMock.Setup(r => r.ExistsAsync(It.IsAny<Expression<Func<User, bool>>>()))
                 .ReturnsAsync(false);
        _repoMock.Setup(r => r.AddAsync(It.IsAny<User>())).Returns(Task.CompletedTask);
        _mapperMock.Setup(m => m.Map<User>(dto)).Returns(new User { Name = dto.Name, Email = dto.Email });
        _mapperMock.Setup(m => m.Map<UserDto>(It.IsAny<User>())).Returns(new UserDto { Id = 1, Name = "Alice" });

        var result = await _sut.CreateAsync(dto);

        Assert.NotNull(result);
        _emailMock.Verify(e => e.SendWelcomeAsync(dto.Email, dto.Name), Times.Once);
    }
}
```

---

## Q6. What is Playwright for E2E testing?
**Answer:**
Playwright is a browser automation library for end-to-end testing across Chromium, Firefox, and WebKit:

```typescript
// tests/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication flow', () => {
  test('user can register and login', async ({ page }) => {
    // Navigate to app
    await page.goto('http://localhost:4200');

    // Register
    await page.click('a[href="/register"]');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'Test@1234!');
    await page.click('button[type="submit"]');

    // Should redirect to dashboard
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Welcome');

    // Logout and login again
    await page.click('[data-testid="logout-btn"]');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'Test@1234!');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
  });

  test('invalid credentials show error message', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[name="email"]', 'wrong@example.com');
    await page.fill('[name="password"]', 'wrongpass');
    await page.click('button[type="submit"]');
    await expect(page.locator('[data-testid="error-msg"]')).toBeVisible();
    await expect(page.locator('[data-testid="error-msg"]')).toContainText('Invalid credentials');
  });
});
```

---

## Q7. How do you mock external services in integration tests?
**Answer:**
```csharp
// Using WireMock.NET for HTTP service mocking
public class PaymentServiceTests : IDisposable
{
    private readonly WireMockServer _mockServer;
    private readonly HttpClient _client;

    public PaymentServiceTests()
    {
        _mockServer = WireMockServer.Start();

        // Setup mock Stripe response
        _mockServer.Given(Request.Create().WithPath("/v1/charges").UsingPost())
            .RespondWith(Response.Create().WithStatusCode(200)
                .WithBodyAsJson(new { id = "ch_test", status = "succeeded", amount = 9999 }));

        _client = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
                builder.UseSetting("Stripe:BaseUrl", _mockServer.Url))
            .CreateClient();
    }

    [Fact]
    public async Task ProcessPayment_WithValidCard_Succeeds()
    {
        var response = await _client.PostAsJsonAsync("/api/payments",
            new { Amount = 99.99m, CardToken = "tok_visa" });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    public void Dispose() => _mockServer.Stop();
}
```

---

## Q8. What is test isolation and why is it important?
**Answer:**
Each test must run independently — shared state causes intermittent failures:

```csharp
// Problem: tests share database state
[Fact]
public async Task CreateUser_Should_Increment_Count()
{
    await _client.PostAsJsonAsync("/api/users", new { Name = "Alice" });
    var response = await _client.GetAsync("/api/users");
    var result = await response.Content.ReadFromJsonAsync<PagedResult<UserDto>>();
    Assert.Equal(1, result.Total); // FAILS if other test ran first!
}

// Solution 1: Unique test database per test class
public class UserTests : IAsyncLifetime
{
    private readonly string _dbName = $"TestDb_{Guid.NewGuid()}";
    // Use _dbName for this test class only
    public Task InitializeAsync() => Task.CompletedTask;
    public Task DisposeAsync() { DeleteTestDb(_dbName); return Task.CompletedTask; }
}

// Solution 2: Transaction rollback (fastest)
public class UserTests
{
    private readonly IDbConnection _db;
    private IDbTransaction _transaction;

    public void Setup() => _transaction = _db.BeginTransaction();
    public void TearDown() => _transaction.Rollback(); // undo all changes after each test
}

// Solution 3: Respawn (reset DB to known state)
var respawner = await Respawner.CreateAsync(connectionString);
await respawner.ResetAsync(connectionString); // run in SetUp to clean DB
```

---

## Q9. How do you test Angular components that consume APIs?
**Answer:**
```typescript
// Angular component test with HTTP mock
describe('UserListComponent', () => {
  let component: UserListComponent;
  let fixture: ComponentFixture<UserListComponent>;
  let httpMock: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserListComponent, HttpClientTestingModule]
    }).compileComponents();

    fixture = TestBed.createComponent(UserListComponent);
    component = fixture.componentInstance;
    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should display users after loading', fakeAsync(() => {
    fixture.detectChanges(); // triggers ngOnInit → HTTP call

    const req = httpMock.expectOne('/api/users?page=1&pageSize=20');
    req.flush({
      data: [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }],
      total: 2, page: 1, pageSize: 20
    });

    tick(); // process async operations
    fixture.detectChanges(); // update template

    const userCards = fixture.nativeElement.querySelectorAll('app-user-card');
    expect(userCards.length).toBe(2);
  }));

  it('should show error on API failure', fakeAsync(() => {
    fixture.detectChanges();
    httpMock.expectOne('/api/users?page=1&pageSize=20').error(new ErrorEvent('Network error'));
    tick();
    fixture.detectChanges();
    const error = fixture.nativeElement.querySelector('[data-testid="error"]');
    expect(error).toBeTruthy();
  }));

  afterEach(() => httpMock.verify());
});
```

---

## Q10. What are the best practices for test naming and organization?
**Answer:**
```csharp
// Test naming pattern: MethodName_Scenario_ExpectedBehavior
[Fact]
public async Task GetById_WhenUserExists_ReturnsUser() { }

[Fact]
public async Task GetById_WhenUserNotFound_ThrowsNotFoundException() { }

[Fact]
public async Task Create_WithDuplicateEmail_ThrowsConflictException() { }

[Fact]
public async Task Create_WithValidData_SendsWelcomeEmail() { }

// Given-When-Then structure
[Fact]
public async Task PlaceOrder_WithSufficientStock_DeductsStock()
{
    // Given
    var product = new Product { Id = 1, Stock = 10, Price = 9.99m };
    _productRepo.Setup(r => r.GetByIdAsync(1)).ReturnsAsync(product);

    // When
    await _sut.PlaceOrderAsync(new PlaceOrderDto { ProductId = 1, Quantity = 3 });

    // Then
    Assert.Equal(7, product.Stock);
}

// Test data builders (readable test setup)
var user = UserBuilder.Create()
    .WithEmail("test@test.com")
    .WithRole("Admin")
    .IsActive()
    .Build();
```
