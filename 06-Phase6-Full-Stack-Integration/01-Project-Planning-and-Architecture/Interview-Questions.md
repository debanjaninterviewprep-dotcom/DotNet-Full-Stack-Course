# Topic 01: Project Planning & Architecture — Interview Questions

---

## Q1. How do you approach planning a full-stack web application?
**Answer:**
1. **Requirements gathering** — functional (what it does) and non-functional (performance, scalability, security).
2. **Technology selection** — frontend framework, backend framework, database, cloud provider.
3. **Architecture decision** — monolith vs microservices, deployment model.
4. **Data modeling** — entity relationships, database schema.
5. **API contract design** — OpenAPI spec, DTOs, versioning strategy.
6. **Security model** — authentication scheme (JWT/OAuth2), authorization model (RBAC/ABAC).
7. **Folder/project structure** — Vertical Slice, Clean Architecture, feature-based.
8. **CI/CD pipeline design** — build, test, deploy stages.

---

## Q2. What is API-first design?
**Answer:**
API-first means designing the API contract (OpenAPI spec) **before** writing code. Backend and frontend teams can work in parallel using mocks:

```yaml
# openapi.yaml — design first
paths:
  /api/users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: integer }
      responses:
        200:
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserDto' }
        404:
          description: User not found
```

**Benefits:**
- Frontend can generate a typed client from the spec immediately.
- Enables contract testing between teams.
- Forces clear communication about API shape before implementation.
- Tools: Swagger/OpenAPI, NSwag, Kiota, OpenAPI Generator.

---

## Q3. What is the difference between monolith and microservices?
**Answer:**
| | Monolith | Microservices |
|---|---|---|
| **Deployment** | Single deployable unit | Many independently deployable services |
| **Development** | Simple (one codebase) | Complex (distributed system) |
| **Scaling** | Scale entire app | Scale individual services |
| **Technology** | One tech stack | Each service can use different stack |
| **Communication** | In-process method calls | HTTP/gRPC/messaging |
| **Failure** | One failure may crash all | Failures isolated per service |
| **Team size** | Small teams | Large, independent teams |

**For most new projects:** Start with a **modular monolith** — well-structured with clear bounded contexts that can be extracted to microservices later if needed.

---

## Q4. How do you design a REST API URL structure?
**Answer:**
```
# Resource naming — nouns, plural, lowercase, hyphens
GET    /api/users              → get all users
GET    /api/users/{id}         → get user by ID
POST   /api/users              → create user
PUT    /api/users/{id}         → full update
PATCH  /api/users/{id}         → partial update
DELETE /api/users/{id}         → delete user

# Nested resources (sub-resources)
GET    /api/users/{id}/orders        → orders for a user
POST   /api/users/{id}/orders        → create order for user
GET    /api/users/{id}/orders/{oid}  → specific order

# Filtering/sorting/pagination — query parameters
GET /api/products?category=electronics&minPrice=100&sort=price&order=asc&page=2&limit=20

# Actions that don't fit CRUD — use verbs as exception
POST /api/orders/{id}/cancel     → cancel an order
POST /api/users/{id}/activate    → activate account
POST /api/auth/login             → authentication action
```

---

## Q5. What is Swagger/OpenAPI and how do you implement it in ASP.NET Core?
**Answer:**
OpenAPI is a standard for describing REST API contracts. Swagger is the toolset around OpenAPI:

```csharp
// Install: Swashbuckle.AspNetCore
builder.Services.AddSwaggerGen(options => {
    options.SwaggerDoc("v1", new OpenApiInfo {
        Title = "TaskFlow API", Version = "v1",
        Description = "RESTful API for TaskFlow application"
    });

    // JWT auth in Swagger UI
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement {
        [new OpenApiSecurityScheme { Reference = new OpenApiReference {
            Type = ReferenceType.SecurityScheme, Id = "Bearer"
        }}] = []
    });

    // Include XML comments
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    options.IncludeXmlComments(Path.Combine(AppContext.BaseDirectory, xmlFile));
});

if (app.Environment.IsDevelopment()) {
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1"));
}
```

---

## Q6. What are bounded contexts in DDD?
**Answer:**
A bounded context is a logical boundary within which a particular domain model applies. The same concept can mean different things in different contexts:

```
"Customer" in different bounded contexts:
- Sales context: Customer { Id, Name, CreditLimit, SalesRep }
- Shipping context: Customer { Id, ShippingAddress, ContactName }
- Support context: Customer { Id, TicketHistory, PreferredChannel }

Each context has its own model — they communicate via integration events or APIs
```

In code:
```
src/
├── Sales/
│   ├── Domain/      ← Sales.Customer, Sales.Order
│   ├── Application/
│   └── Infrastructure/
├── Shipping/
│   ├── Domain/      ← Shipping.Customer, Shipping.Package
│   └── ...
└── Support/
    ├── Domain/      ← Support.Customer, Support.Ticket
    └── ...
```

---

## Q7. What are the non-functional requirements (NFRs) and why do they matter?
**Answer:**
NFRs define **how** the system works rather than what it does:

| NFR | Examples |
|---|---|
| **Performance** | Response time < 200ms at P95, 1000 RPS throughput |
| **Scalability** | Handle 10x traffic growth without code changes |
| **Availability** | 99.9% uptime (8.7 hours downtime/year) |
| **Security** | OWASP Top 10 compliance, data encryption at rest/transit |
| **Reliability** | Zero data loss, graceful degradation |
| **Maintainability** | <2 hours to onboard new developer |
| **Observability** | Full distributed traces, structured logs, metrics |
| **Compliance** | GDPR, PCI-DSS, HIPAA as applicable |

NFRs drive architectural decisions (caching for performance, read replicas for scale, circuit breakers for reliability).

---

## Q8. What is the C4 model for architecture documentation?
**Answer:**
The C4 model uses four levels of abstraction to document software architecture:

```
Level 1 — System Context
  Shows how your system interacts with users and external systems
  (Users → TaskFlow App → Email Service, Payment Gateway, Database)

Level 2 — Container
  Shows the high-level technology choices and their interactions
  (React SPA → ASP.NET Core API → SQL Server DB, Redis Cache)

Level 3 — Component
  Shows the key components inside a container
  (ASP.NET Core: Controllers, Services, Repositories, Middleware)

Level 4 — Code
  Class diagrams for critical/complex components
  (Used sparingly — usually too detailed to maintain)
```

---

## Q9. What are the principles of RESTful API design?
**Answer:**
Roy Fielding's REST constraints:

1. **Client-Server** — separation of UI and data storage concerns.
2. **Stateless** — each request contains all information needed. No server-side session state.
3. **Cacheable** — responses must be cacheable or non-cacheable. Cache-Control headers.
4. **Uniform Interface:**
   - Resource identification via URIs.
   - Resource manipulation via representations (JSON).
   - Self-descriptive messages (Content-Type, Status codes).
   - HATEOAS (links in responses).
5. **Layered System** — client can't tell if connected directly to server or proxy.
6. **Code on Demand** (optional) — server can send executable code to client.

---

## Q10. What is HATEOAS and is it used in practice?
**Answer:**
HATEOAS (Hypermedia As The Engine Of Application State) means API responses include links to related actions:

```json
{
  "id": 42,
  "status": "pending",
  "total": 99.99,
  "_links": {
    "self":   { "href": "/api/orders/42", "method": "GET" },
    "cancel": { "href": "/api/orders/42/cancel", "method": "POST" },
    "pay":    { "href": "/api/orders/42/pay", "method": "POST" },
    "items":  { "href": "/api/orders/42/items", "method": "GET" }
  }
}
```

**In practice:** Pure HATEOAS adds complexity and is rarely used in modern APIs. Most teams use a "REST-like" approach with documented API contracts (OpenAPI) instead. HATEOAS is more relevant in hypermedia-driven APIs (GitHub API, Stripe API use partial HATEOAS).

---

## Q11. How do you version a REST API?
**Answer:**
```
URL versioning (most common):
GET /api/v1/users
GET /api/v2/users

Header versioning:
GET /api/users
X-API-Version: 2

Query parameter versioning:
GET /api/users?api-version=2

Media type versioning (content negotiation):
Accept: application/vnd.myapp.v2+json
```

**ASP.NET Core versioning:**
```csharp
builder.Services.AddApiVersioning(opt => {
    opt.DefaultApiVersion = new ApiVersion(1, 0);
    opt.AssumeDefaultVersionWhenUnspecified = true;
    opt.ReportApiVersions = true;
});

[ApiVersion("1.0"), ApiVersion("2.0")]
[Route("api/v{version:apiVersion}/users")]
public class UsersController : ControllerBase { }
```

---

## Q12. What is the strangler fig pattern for API evolution?
**Answer:**
The strangler fig pattern gradually replaces an old system/API by routing traffic to the new system incrementally:

```
Phase 1: Add v2 endpoints alongside v1
  - v1: GET /api/v1/users → old implementation
  - v2: GET /api/v2/users → new implementation (new response shape)

Phase 2: Migrate clients to v2
  - Document v1 as deprecated
  - Give clients deadline to migrate

Phase 3: Remove v1
  - After all clients migrated (or sunset date passed)
  - Return 410 Gone from v1 endpoints
```

This avoids a "big bang" migration and reduces risk.

---

## Q13. What is the difference between synchronous and asynchronous communication in a full-stack app?
**Answer:**
```
Synchronous (request-response):
Client → API → Response (waits)
  Use for: CRUD, queries, user interactions
  Tools: HTTP REST, gRPC

Asynchronous (fire and forget / event-driven):
Client → API → Queue → Worker processes in background
  Use for: emails, notifications, reports, file processing
  Tools: Azure Service Bus, RabbitMQ, Hangfire, SignalR

Full-stack example:
  User uploads CSV → API returns 202 Accepted with job ID
  Worker processes CSV in background
  SignalR pushes progress to frontend
  User polls /api/jobs/{id}/status OR receives WebSocket notification
```

---

## Q14. What is API gateway pattern?
**Answer:**
An API Gateway is a single entry point that routes requests to backend services, handles cross-cutting concerns:

```
Client → API Gateway → Service A (Users)
                     → Service B (Orders)
                     → Service C (Products)

API Gateway handles:
- Authentication/Authorization (centralized)
- Rate limiting
- Request/response transformation
- Load balancing
- SSL termination
- Logging and monitoring
- Caching
- Circuit breaking

Tools: YARP (Reverse Proxy for .NET), Azure API Management, Kong, Nginx, Ocelot (.NET)
```

---

## Q15. What are the OWASP Top 10 and how do they affect API design?
**Answer:**
| # | Vulnerability | API Mitigation |
|---|---|---|
| 1 | Broken Object Level Authorization | Check ownership on every resource access |
| 2 | Broken Authentication | Use JWT + HTTPS + short expiry + refresh tokens |
| 3 | Broken Object Property Level Auth | Use DTOs — never expose entity directly |
| 4 | Unrestricted Resource Consumption | Rate limiting, request size limits |
| 5 | Broken Function Level Authorization | Explicit `[Authorize]` on every endpoint |
| 6 | Unrestricted Access to Sensitive Business Flows | Bot detection, CAPTCHA, rate limit auth endpoints |
| 7 | Server Side Request Forgery | Validate URLs, allowlist destinations |
| 8 | Security Misconfiguration | HTTPS, CORS, remove default credentials, hide error details in prod |
| 9 | Improper Inventory Management | API versioning, remove unused endpoints |
| 10 | Unsafe Consumption of APIs | Validate all third-party responses |
