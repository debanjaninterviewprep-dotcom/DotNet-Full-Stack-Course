# Topic 1: ASP.NET Core Fundamentals & Project Setup

## 📘 What is ASP.NET Core?

ASP.NET Core is a **cross-platform, high-performance, open-source framework** for building modern, cloud-enabled, internet-connected applications. It's the redesigned version of ASP.NET, built from scratch to run on Windows, macOS, and Linux.

### Key Characteristics

| Feature | Description |
|---------|------------|
| **Cross-Platform** | Runs on Windows, macOS, and Linux |
| **Open Source** | Maintained by Microsoft and the community on GitHub |
| **High Performance** | One of the fastest web frameworks available (Kestrel server) |
| **Modular** | Use only the packages you need via NuGet |
| **Cloud-Ready** | Built-in support for cloud deployment (Azure, AWS, Docker) |
| **Unified Framework** | Build Web APIs, MVC apps, Razor Pages, gRPC, SignalR all in one framework |

---

## 📘 .NET Core vs .NET Framework vs .NET 5/6/7/8/9/10

### Evolution Timeline

```
.NET Framework (2002) → Windows-only, full framework
       ↓
.NET Core 1.0 (2016) → Cross-platform, modular, open-source
       ↓
.NET Core 2.0 (2017) → More APIs, Razor Pages
       ↓
.NET Core 3.0 (2019) → WPF, WinForms, gRPC, Blazor
       ↓
.NET 5 (2020) → Unification (no more "Core" in name)
       ↓
.NET 6 (2021) → LTS, Minimal APIs, Hot Reload
       ↓
.NET 7 (2022) → Performance improvements, Rate Limiting
       ↓
.NET 8 (2023) → LTS, Native AOT for Web, Blazor United
       ↓
.NET 9 (2024) → Performance, OpenAPI improvements
       ↓
.NET 10 (2025) → LTS, latest version
```

### Comparison Table

| Feature | .NET Framework | .NET Core / .NET 5+ |
|---------|---------------|-------------------|
| Platform | Windows only | Cross-platform |
| Deployment | Machine-wide | Side-by-side, self-contained |
| Performance | Good | Excellent (Kestrel) |
| Open Source | Partially | Fully |
| Future | Maintenance mode | Active development |
| Package Manager | NuGet | NuGet |

---

## 📘 ASP.NET Core Project Types

| Project Type | Description | Use Case |
|-------------|-------------|----------|
| **Web API** | RESTful API with controllers | Backend for SPA, mobile apps |
| **MVC** | Model-View-Controller with Razor views | Server-rendered web apps |
| **Razor Pages** | Page-based model | Simple web apps, CRUD |
| **Blazor Server** | C# in browser via SignalR | Real-time interactive UI |
| **Blazor WebAssembly** | C# compiled to WebAssembly | Client-side SPA |
| **gRPC** | High-performance RPC | Microservices communication |
| **Minimal API** | Lightweight API without controllers | Simple APIs, microservices |
| **Worker Service** | Background processing | Scheduled tasks, queues |

---

## 📘 Creating Your First ASP.NET Core Web API

### Using the CLI

```bash
# Create a new Web API project
dotnet new webapi -n MyFirstApi

# Navigate into the project
cd MyFirstApi

# Run the project
dotnet run
```

### Using Visual Studio
1. File → New → Project
2. Select "ASP.NET Core Web API"
3. Choose your .NET version
4. Configure authentication (None for now)
5. Check "Use controllers" (uncheck for Minimal API)
6. Click Create

### Project Structure After Creation

```
MyFirstApi/
├── Controllers/
│   └── WeatherForecastController.cs   ← API Controller
├── Properties/
│   └── launchSettings.json            ← Dev server settings (ports, URLs)
├── appsettings.json                   ← Configuration (connection strings, etc.)
├── appsettings.Development.json       ← Dev-specific config overrides
├── Program.cs                         ← Application entry point & setup
├── MyFirstApi.csproj                  ← Project file (dependencies, target framework)
└── WeatherForecast.cs                 ← Model class
```

---

## 📘 Understanding Program.cs — The Entry Point

In .NET 6+, the `Startup.cs` class was removed. Everything is in `Program.cs` using **top-level statements** and the **minimal hosting model**.

### The Complete Program.cs Breakdown

```csharp
// 1. Create a WebApplication builder
var builder = WebApplication.CreateBuilder(args);

// 2. Register services to the DI container (ConfigureServices)
builder.Services.AddControllers();                    // Add controller support
builder.Services.AddEndpointsApiExplorer();           // Enable endpoint discovery
builder.Services.AddSwaggerGen();                     // Add Swagger/OpenAPI

// 3. Build the application
var app = builder.Build();

// 4. Configure the HTTP request pipeline (middleware)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();                                 // Enable Swagger JSON
    app.UseSwaggerUI();                               // Enable Swagger UI
}

app.UseHttpsRedirection();                            // Redirect HTTP to HTTPS
app.UseAuthorization();                               // Enable authorization middleware
app.MapControllers();                                 // Map controller routes

// 5. Run the application
app.Run();
```

### What Each Section Does

| Section | Purpose | Old Equivalent (Startup.cs) |
|---------|---------|---------------------------|
| `WebApplication.CreateBuilder(args)` | Creates host with default config | `CreateHostBuilder` |
| `builder.Services.Add...` | Register DI services | `ConfigureServices()` |
| `app.Use...` / `app.Map...` | Configure middleware pipeline | `Configure()` |
| `app.Run()` | Start listening for requests | `host.Run()` |

---

## 📘 The Old Way: Startup.cs (Pre-.NET 6)

Understanding the old pattern helps when reading legacy code:

```csharp
// Program.cs (old way)
public class Program
{
    public static void Main(string[] args)
    {
        CreateHostBuilder(args).Build().Run();
    }

    public static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder.UseStartup<Startup>();
            });
}

// Startup.cs (old way)
public class Startup
{
    public IConfiguration Configuration { get; }

    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    // Register services
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();
        services.AddSwaggerGen();
    }

    // Configure middleware pipeline
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.UseHttpsRedirection();
        app.UseRouting();
        app.UseAuthorization();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}
```

---

## 📘 Dependency Injection (DI) in ASP.NET Core

ASP.NET Core has **built-in Dependency Injection**. You register services in the DI container, and they get injected automatically.

### Service Lifetimes

| Lifetime | Method | Behavior |
|----------|--------|----------|
| **Transient** | `AddTransient<T>()` | New instance every time it's requested |
| **Scoped** | `AddScoped<T>()` | One instance per HTTP request |
| **Singleton** | `AddSingleton<T>()` | One instance for the entire app lifetime |

### Registration Examples

```csharp
var builder = WebApplication.CreateBuilder(args);

// Interface → Implementation mapping
builder.Services.AddTransient<IEmailService, EmailService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddSingleton<ICacheService, MemoryCacheService>();

// Register concrete type directly
builder.Services.AddScoped<OrderService>();
```

### Constructor Injection

```csharp
public class UserController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly IEmailService _emailService;

    // DI container automatically provides these
    public UserController(IUserRepository userRepository, IEmailService emailService)
    {
        _userRepository = userRepository;
        _emailService = emailService;
    }
}
```

### When to Use Each Lifetime

| Scenario | Lifetime | Why |
|----------|----------|-----|
| Stateless utility services | Transient | No shared state needed |
| Database context (DbContext) | Scoped | One DB connection per request |
| Configuration, caching | Singleton | Shared state across all requests |
| HttpClient factory | Singleton | Reuse connections |
| Logging | Singleton | Thread-safe, shared |

> ⚠️ **Warning**: Never inject a Scoped service into a Singleton — it will become a Singleton too (captive dependency)!

---

## 📘 Configuration System

ASP.NET Core uses a layered configuration system that reads from multiple sources.

### Configuration Sources (Priority: Last Wins)

```
1. appsettings.json                  ← Base config
2. appsettings.{Environment}.json    ← Environment-specific overrides
3. User Secrets (dev only)           ← Secret values not in source control
4. Environment Variables             ← Deployment-specific values
5. Command-line arguments            ← Highest priority overrides
```

### appsettings.json Example

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyDb;Trusted_Connection=true;"
  },
  "AppSettings": {
    "ApiKey": "your-api-key",
    "MaxRetries": 3,
    "BaseUrl": "https://api.example.com"
  }
}
```

### Reading Configuration

```csharp
// Method 1: Direct injection of IConfiguration
public class MyService
{
    private readonly string _connectionString;

    public MyService(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection");
    }
}

// Method 2: Options Pattern (Recommended)
public class AppSettings
{
    public string ApiKey { get; set; }
    public int MaxRetries { get; set; }
    public string BaseUrl { get; set; }
}

// In Program.cs
builder.Services.Configure<AppSettings>(
    builder.Configuration.GetSection("AppSettings"));

// In a service
public class ApiService
{
    private readonly AppSettings _settings;

    public ApiService(IOptions<AppSettings> options)
    {
        _settings = options.Value;
    }
}
```

### User Secrets (Development Only)

```bash
# Initialize user secrets for a project
dotnet user-secrets init

# Set a secret
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=secret-server;..."

# List all secrets
dotnet user-secrets list

# Remove a secret
dotnet user-secrets remove "ConnectionStrings:DefaultConnection"
```

> User secrets are stored outside the project directory, so they're never committed to source control.

---

## 📘 Environments

ASP.NET Core supports multiple environments out of the box.

### Built-in Environments

| Environment | Purpose |
|------------|---------|
| `Development` | Local development, detailed errors, Swagger |
| `Staging` | Pre-production testing |
| `Production` | Live deployment, minimal errors shown |

### Setting the Environment

```bash
# Windows (PowerShell)
$env:ASPNETCORE_ENVIRONMENT = "Development"

# Windows (cmd)
set ASPNETCORE_ENVIRONMENT=Development

# Linux/macOS
export ASPNETCORE_ENVIRONMENT=Development
```

### Checking Environment in Code

```csharp
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseDeveloperExceptionPage();  // Detailed error pages
}
else if (app.Environment.IsStaging())
{
    app.UseExceptionHandler("/Error");
}
else // Production
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();                    // HTTP Strict Transport Security
}
```

---

## 📘 launchSettings.json

Controls how the app is launched during development.

```json
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "swagger",
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "swagger",
      "applicationUrl": "https://localhost:7001;http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

> ⚠️ **Note**: `launchSettings.json` is **only for development**. It is NOT deployed to production.

---

## 📘 The Kestrel Web Server

Kestrel is the **default, cross-platform web server** for ASP.NET Core.

### Kestrel Architecture

```
Internet → Reverse Proxy (IIS/Nginx/Apache) → Kestrel → ASP.NET Core App
                    OR
Internet → Kestrel → ASP.NET Core App (edge server)
```

### Kestrel vs IIS

| Feature | Kestrel | IIS |
|---------|---------|-----|
| Platform | Cross-platform | Windows only |
| Performance | Very high | Good |
| Features | Basic HTTP server | Full-featured (caching, compression) |
| Recommended Use | Behind a reverse proxy | As reverse proxy for Kestrel |

### Configuring Kestrel

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenLocalhost(5000);                    // HTTP
    options.ListenLocalhost(5001, listenOptions =>
    {
        listenOptions.UseHttps();                     // HTTPS
    });
    options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10 MB
});
```

---

## 📘 Middleware Pipeline

Middleware are components that handle HTTP requests and responses in a pipeline.

### How the Pipeline Works

```
Request  →  Middleware 1  →  Middleware 2  →  Middleware 3  →  Endpoint
Response ←  Middleware 1  ←  Middleware 2  ←  Middleware 3  ←  Endpoint
```

Each middleware can:
- **Process the request** before passing it to the next middleware
- **Short-circuit** the pipeline (stop processing and return a response)
- **Process the response** after the next middleware returns

### Common Built-in Middleware (Order Matters!)

```csharp
var app = builder.Build();

// 1. Exception handling (first, catches everything)
app.UseExceptionHandler("/error");

// 2. HSTS (HTTP Strict Transport Security)
app.UseHsts();

// 3. HTTPS redirection
app.UseHttpsRedirection();

// 4. Static files (CSS, JS, images)
app.UseStaticFiles();

// 5. Routing (determines which endpoint matches)
app.UseRouting();

// 6. CORS (Cross-Origin Resource Sharing)
app.UseCors();

// 7. Authentication (who are you?)
app.UseAuthentication();

// 8. Authorization (are you allowed?)
app.UseAuthorization();

// 9. Map endpoints (controllers, Razor Pages, etc.)
app.MapControllers();
```

> ⚠️ **Critical**: Middleware order matters! `UseAuthentication()` must come before `UseAuthorization()`.

### Custom Middleware

```csharp
// Inline middleware
app.Use(async (context, next) =>
{
    Console.WriteLine($"Request: {context.Request.Method} {context.Request.Path}");
    await next();  // Call the next middleware
    Console.WriteLine($"Response: {context.Response.StatusCode}");
});

// Class-based middleware
public class RequestTimingMiddleware
{
    private readonly RequestDelegate _next;

    public RequestTimingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        await _next(context);
        stopwatch.Stop();
        Console.WriteLine($"Request took {stopwatch.ElapsedMilliseconds}ms");
    }
}

// Register in pipeline
app.UseMiddleware<RequestTimingMiddleware>();
```

---

## 📘 Minimal APIs vs Controller-Based APIs

### Minimal API (Simple, Lightweight)

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello World!");

app.MapGet("/users/{id}", (int id) => $"User {id}");

app.MapPost("/users", (User user) => 
{
    // Save user...
    return Results.Created($"/users/{user.Id}", user);
});

app.Run();
```

### Controller-Based API (Structured, Feature-Rich)

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll() => Ok(new[] { "User1", "User2" });

    [HttpGet("{id}")]
    public IActionResult GetById(int id) => Ok($"User {id}");

    [HttpPost]
    public IActionResult Create(User user) => CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
}
```

### When to Use Which?

| Scenario | Use |
|----------|-----|
| Simple microservices, 5-10 endpoints | Minimal API |
| Large projects, many endpoints | Controllers |
| Need filters, model binding, conventions | Controllers |
| Quick prototyping | Minimal API |
| Enterprise applications | Controllers |

---

## 📘 Swagger / OpenAPI Integration

Swagger provides automatic API documentation and a testing UI.

### Setup (Already included in Web API template)

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "My API",
        Version = "v1",
        Description = "A sample ASP.NET Core Web API",
        Contact = new OpenApiContact
        {
            Name = "Your Name",
            Email = "your@email.com"
        }
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "My API v1");
    });
}
```

### Accessing Swagger
- **Swagger JSON**: `https://localhost:7001/swagger/v1/swagger.json`
- **Swagger UI**: `https://localhost:7001/swagger`

---

## 📘 HTTP Methods & REST Conventions

| HTTP Method | CRUD Operation | Example Route | Description |
|------------|---------------|---------------|-------------|
| `GET` | Read | `GET /api/users` | Get all users |
| `GET` | Read | `GET /api/users/1` | Get user by ID |
| `POST` | Create | `POST /api/users` | Create new user |
| `PUT` | Update (full) | `PUT /api/users/1` | Replace entire user |
| `PATCH` | Update (partial) | `PATCH /api/users/1` | Update specific fields |
| `DELETE` | Delete | `DELETE /api/users/1` | Delete a user |

### HTTP Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| `200 OK` | Success | GET, PUT, PATCH success |
| `201 Created` | Resource created | POST success |
| `204 No Content` | Success, no body | DELETE success |
| `400 Bad Request` | Invalid input | Validation errors |
| `401 Unauthorized` | Not authenticated | Missing/invalid token |
| `403 Forbidden` | Not authorized | Valid token, no permission |
| `404 Not Found` | Resource doesn't exist | Invalid ID |
| `409 Conflict` | Duplicate resource | Unique constraint violation |
| `500 Internal Server Error` | Server error | Unhandled exceptions |

---

## 📘 NuGet Package Management

NuGet is the package manager for .NET. You'll install many packages throughout this phase.

### Common Commands

```bash
# Add a package
dotnet add package Microsoft.EntityFrameworkCore

# Add a specific version
dotnet add package Newtonsoft.Json --version 13.0.3

# List installed packages
dotnet list package

# Remove a package
dotnet remove package Newtonsoft.Json

# Restore packages (after cloning/pulling)
dotnet restore
```

### Essential Packages for Web API Development

| Package | Purpose |
|---------|---------|
| `Microsoft.EntityFrameworkCore` | ORM for database access |
| `Microsoft.EntityFrameworkCore.SqlServer` | SQL Server provider |
| `Microsoft.EntityFrameworkCore.Tools` | EF migrations CLI |
| `AutoMapper.Extensions.Microsoft.DependencyInjection` | Object-to-object mapping |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | JWT authentication |
| `Swashbuckle.AspNetCore` | Swagger/OpenAPI (included by default) |
| `FluentValidation.AspNetCore` | Input validation |
| `Serilog.AspNetCore` | Structured logging |

---

## 📘 Putting It All Together — TaskFlow API Setup

Let's see how all these concepts come together in a real project:

```csharp
// Program.cs for TaskFlow API
var builder = WebApplication.CreateBuilder(args);

// === SERVICES (DI Container) ===
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Custom services
builder.Services.AddScoped<ITaskRepository, TaskRepository>();
builder.Services.AddScoped<ITaskService, TaskService>();
builder.Services.AddSingleton<ICacheService, MemoryCacheService>();

// Database
builder.Services.AddDbContext<TaskFlowDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Configuration
builder.Services.Configure<AppSettings>(
    builder.Configuration.GetSection("AppSettings"));

var app = builder.Build();

// === MIDDLEWARE PIPELINE ===
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

---

## 📝 Summary Notes

| Concept | Key Takeaway |
|---------|-------------|
| ASP.NET Core | Cross-platform, high-performance web framework |
| Program.cs | Single entry point: builder → services → app → middleware → run |
| DI Container | Built-in: Transient, Scoped, Singleton lifetimes |
| Configuration | Layered: appsettings → secrets → env vars → CLI args |
| Environments | Development, Staging, Production |
| Kestrel | Default cross-platform web server |
| Middleware | Pipeline of request/response handlers (order matters!) |
| Swagger | Auto-generated API documentation & testing UI |
| REST | HTTP methods map to CRUD: GET, POST, PUT, PATCH, DELETE |

> **Next Topic**: Controllers & Routing — Deep dive into building API endpoints.
