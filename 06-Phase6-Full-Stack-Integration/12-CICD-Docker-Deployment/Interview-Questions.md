# Topic 12: CI/CD, Docker & Deployment — Interview Questions

---

## Q1. What is Docker and why is it used?
**Answer:**
Docker packages an application and all its dependencies into a **container** — a lightweight, isolated environment that runs consistently anywhere:

```
Problem without Docker:
  "It works on my machine!" — different OS, runtimes, library versions
  Dev: Windows + .NET 9 + SQL Server 2022
  Prod: Ubuntu + .NET 8 + SQL Server 2019
  → Different behaviour

With Docker:
  The exact same container image runs on every machine
  Dev, staging, and production use identical environments
```

**Key concepts:**
- **Image** — read-only template with app + dependencies (built from Dockerfile).
- **Container** — running instance of an image.
- **Registry** — stores and distributes images (Docker Hub, Azure Container Registry, ECR).
- **Volume** — persistent storage mounted into container.
- **Network** — virtual network connecting containers.

---

## Q2. What is a Dockerfile and how do you write one for .NET?
**Answer:**
```dockerfile
# Multi-stage Dockerfile for ASP.NET Core
# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore (separate layer for caching)
COPY ["MyApp.WebApi/MyApp.WebApi.csproj", "MyApp.WebApi/"]
COPY ["MyApp.Application/MyApp.Application.csproj", "MyApp.Application/"]
RUN dotnet restore "MyApp.WebApi/MyApp.WebApi.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/MyApp.WebApi"
RUN dotnet build -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish -c Release -o /app/publish --no-restore

# Stage 3: Runtime (small image)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080

# Security: run as non-root
USER app

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.WebApi.dll"]
```

**Multi-stage benefits:**
- Final image contains only the runtime (~200MB), not the SDK (~700MB).
- Intermediate build artifacts don't bloat the image.
- Build secrets don't leak into final image.

---

## Q3. What is Docker Compose and when is it used?
**Answer:**
Docker Compose defines multi-container applications with a single YAML file:

```yaml
# docker-compose.yml
version: '3.9'

services:
  api:
    build:
      context: .
      dockerfile: MyApp.WebApi/Dockerfile
    ports:
      - "5000:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__Default=Server=db;Database=MyApp;User=sa;Password=Test@1234!
      - Redis__ConnectionString=redis:6379
    depends_on:
      db:    { condition: service_healthy }
      redis: { condition: service_started }

  db:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Test@1234!
    volumes:
      - sqldata:/var/opt/mssql
    healthcheck:
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "Test@1234!", "-Q", "SELECT 1"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  frontend:
    build: ./frontend
    ports: ["4200:80"]

volumes:
  sqldata:
```

```bash
docker-compose up -d    # start all services in background
docker-compose logs -f  # follow logs
docker-compose down -v  # stop and remove volumes
```

---

## Q4. What is CI/CD and what does a pipeline look like?
**Answer:**
```
CI (Continuous Integration):
  On every push → build → test → report
  Goal: catch bugs before they reach main branch

CD (Continuous Deployment):
  On merge to main → build → test → deploy to staging → (manual or auto) → deploy to prod
  Goal: deploy frequently, reliably

Example GitHub Actions pipeline:
name: CI/CD

on:
  push:    { branches: [main] }
  pull_request: { branches: [main] }

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '9.0.x' }
      - run: dotnet restore
      - run: dotnet build --no-restore
      - run: dotnet test --no-build --verbosity normal

  build-and-push:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with: { registry: myacr.azurecr.io, username: ${{ secrets.ACR_USERNAME }}, password: ${{ secrets.ACR_PASSWORD }} }
      - run: docker build -t myacr.azurecr.io/myapp:${{ github.sha }} .
      - run: docker push myacr.azurecr.io/myapp:${{ github.sha }}

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - uses: azure/webapps-deploy@v3
        with:
          app-name: myapp-prod
          images: myacr.azurecr.io/myapp:${{ github.sha }}
```

---

## Q5. What is the difference between horizontal and vertical scaling?
**Answer:**
```
Vertical scaling (scale up): add more resources to ONE server
  Server: 2 CPU → 8 CPU, 8GB RAM → 32GB RAM
  Simple, no code changes, limited by hardware maximum
  ✓ Good for: monoliths, databases

Horizontal scaling (scale out): add MORE servers
  1 server → 5 servers behind a load balancer
  Requires: stateless app, shared database, shared cache, distributed sessions
  ✓ Good for: APIs, web servers

Full-stack implications:
- Make the API stateless: no in-memory session, no local file storage
- Shared Redis cache (not IMemoryCache)
- Shared SignalR backplane (Redis/Azure SignalR)
- Upload files to blob storage, not local disk
- Distributed locking if needed (Redis SETNX)
```

---

## Q6. What is Kubernetes and how does it relate to Docker?
**Answer:**
Kubernetes (K8s) is a container orchestration system — it manages Docker containers at scale:

```yaml
# Kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-api
spec:
  replicas: 3                    # 3 instances
  selector:
    matchLabels: { app: myapp-api }
  template:
    metadata:
      labels: { app: myapp-api }
    spec:
      containers:
      - name: myapp-api
        image: myacr.azurecr.io/myapp:v1.2.3
        ports: [{ containerPort: 8080 }]
        env:
        - name: ConnectionStrings__Default
          valueFrom:
            secretKeyRef: { name: db-secret, key: connection-string }
        resources:
          requests: { cpu: "250m", memory: "256Mi" }
          limits:   { cpu: "500m", memory: "512Mi" }
        livenessProbe:  { httpGet: { path: /health/live, port: 8080 }, periodSeconds: 30 }
        readinessProbe: { httpGet: { path: /health/ready, port: 8080 }, periodSeconds: 10 }
```

**Kubernetes provides:**
- Self-healing (restarts failed containers).
- Auto-scaling (HPA based on CPU/memory).
- Rolling deployments (zero-downtime updates).
- Service discovery (DNS between containers).
- Load balancing.

---

## Q7. What is Azure App Service and how do you deploy to it?
**Answer:**
Azure App Service is a managed PaaS hosting for web apps:

```bash
# Deploy with Azure CLI
az webapp create \
  --name myapp \
  --resource-group myRG \
  --plan myPlan \
  --runtime "DOTNETCORE:9.0"

# Deploy container
az webapp config container set \
  --name myapp \
  --docker-custom-image-name myacr.azurecr.io/myapp:latest \
  --docker-registry-server-url https://myacr.azurecr.io

# Deploy with GitHub Actions
- uses: azure/webapps-deploy@v3
  with:
    app-name: 'myapp'
    slot-name: 'staging'
    publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
    images: 'myacr.azurecr.io/myapp:${{ github.sha }}'
```

**App Service features:**
- Deployment slots (staging, production — zero-downtime swap).
- Auto-scaling.
- Custom domains + SSL.
- Built-in monitoring.
- App settings = environment variables (no secrets in code).

---

## Q8. What is blue-green deployment and canary deployment?
**Answer:**
```
Blue-Green Deployment:
  Blue: Current production version (live traffic)
  Green: New version (deployed and tested)
  
  Switch: Route 100% traffic from blue to green
  Rollback: Route traffic back to blue (instant)
  
  Advantage: Zero downtime, instant rollback
  Cost: Double infrastructure (both running simultaneously)

Canary Deployment:
  Route 5% of traffic to new version
  Monitor: errors, latency, user feedback
  Gradually increase: 5% → 20% → 50% → 100%
  Rollback: Route 0% to canary if issues detected
  
  Advantage: Gradual rollout reduces blast radius
  Cost: More complex traffic routing

// Azure App Service: deployment slots (blue-green)
az webapp deployment slot swap \
  --name myapp \
  --resource-group myRG \
  --slot staging  // staging → production swap
```

---

## Q9. What are Docker container best practices?
**Answer:**
```dockerfile
# 1. Use specific version tags (not :latest)
FROM mcr.microsoft.com/dotnet/aspnet:9.0.1

# 2. Layer caching — copy slow-to-change files first
COPY *.csproj .
RUN dotnet restore        # cached if no .csproj changes

COPY . .                  # invalidates cache on any code change
RUN dotnet publish ...

# 3. .dockerignore — exclude unnecessary files
# .dockerignore:
**/bin/
**/obj/
**/.git/
*.md
tests/

# 4. Non-root user (security)
RUN adduser -u 5678 --disabled-password --gecos "" appuser
USER appuser

# 5. Health checks
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health/live || exit 1

# 6. Read-only filesystem
docker run --read-only --tmpfs /tmp myimage

# 7. Minimize image size
# .NET: use Alpine or Chiseled images
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine    # ~100MB vs ~200MB
FROM mcr.microsoft.com/dotnet/aspnet:9.0-chiseled  # ~70MB, ultra-minimal
```

---

## Q10. How do you manage secrets in CI/CD and production?
**Answer:**
```
NEVER:
❌ Commit secrets to git
❌ Hardcode in Dockerfile or code
❌ Pass as build args (visible in image history)

Instead:
✓ GitHub Actions Secrets → Injected as environment variables in pipeline
✓ Azure Key Vault → Secrets stored securely, accessed via managed identity
✓ Kubernetes Secrets → Base64-encoded, mounted as env vars or volumes
✓ Docker Secrets (Swarm) → Encrypted, mounted as files
✓ User Secrets (local dev only)

// Azure Key Vault in .NET
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential()); // uses Managed Identity — no credentials needed!

// GitHub Actions secrets usage
env:
  DB_CONNECTION: ${{ secrets.DB_CONNECTION_STRING }}
  JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

---

## Q11. What is an nginx reverse proxy and why is it used with .NET apps?
**Answer:**
```nginx
# nginx.conf
server {
    listen 80;
    server_name myapp.com;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name myapp.com;

    ssl_certificate     /etc/ssl/cert.pem;
    ssl_certificate_key /etc/ssl/key.pem;

    # Proxy to Kestrel
    location /api/ {
        proxy_pass         http://api:8080;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    # Serve Angular app
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html; # SPA routing
    }

    # WebSocket for SignalR
    location /hubs/ {
        proxy_pass         http://api:8080;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection "Upgrade";
    }
}
```

---

## Q12. What is environment promotion in CI/CD?
**Answer:**
```
Code pushed → Dev deploy (automatic) → QA tests (automatic) → Staging (manual approval) → Production

Environments:
  dev:       Always deployed on PR
             Automated tests run
             Ephemeral (destroyed when PR closed)

  staging:   Always deployed on merge to main
             Full integration tests
             Performance tests
             Security scans
             Mirrors production configuration

  production: Manual approval gate
              Canary or blue-green deployment
              Monitoring alerts configured

// GitHub Actions environment protection
deploy-prod:
  environment:
    name: production
    url: https://myapp.com
  # Requires approval from: @senior-dev, @devops-team
```

---

## Q13. What is the Twelve-Factor App methodology?
**Answer:**
12 principles for building scalable, maintainable cloud-native apps:

| Factor | Description |
|---|---|
| 1. Codebase | One codebase, many deploys |
| 2. Dependencies | Explicitly declare (NuGet, npm) |
| 3. Config | Store in environment variables |
| 4. Backing services | Treat as attached resources |
| 5. Build/release/run | Strict separation of stages |
| 6. Processes | Stateless processes |
| 7. Port binding | Self-contained, export via port |
| 8. Concurrency | Scale via process model |
| 9. Disposability | Fast startup, graceful shutdown |
| 10. Dev/prod parity | Keep environments similar |
| 11. Logs | Treat as event streams |
| 12. Admin processes | Run one-off tasks in the environment |

```csharp
// Factor 3: Config in environment
var connStr = builder.Configuration.GetConnectionString("Default");
// Set via: ConnectionStrings__Default env var

// Factor 9: Graceful shutdown
builder.Services.AddHostedService<GracefulShutdownService>();
app.Lifetime.ApplicationStopping.Register(() => {
    // Drain in-flight requests, commit pending transactions
    _processingComplete.Wait(TimeSpan.FromSeconds(30));
});
```

---

## Q14. What is Infrastructure as Code (IaC)?
**Answer:**
IaC manages infrastructure through code rather than manual configuration:

```bicep
// Azure Bicep (Microsoft IaC for Azure)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'myapp-plan'
  location: resourceGroup().location
  sku: { name: 'P1v3', tier: 'PremiumV3' }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'myapp-api'
  location: resourceGroup().location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|9.0'
      appSettings: [
        { name: 'ASPNETCORE_ENVIRONMENT', value: 'Production' }
      ]
    }
  }
}
```

```hcl
# Terraform (multi-cloud IaC)
resource "azurerm_linux_web_app" "main" {
  name                = "myapp-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    application_stack { dotnet_version = "9.0" }
  }
}
```

---

## Q15. What is a container registry and how do you use it in CI/CD?
**Answer:**
A container registry stores and distributes Docker images:

```bash
# Azure Container Registry (ACR)
# 1. Build and push in CI/CD
docker build -t myacr.azurecr.io/myapp:$GITHUB_SHA .
docker push myacr.azurecr.io/myapp:$GITHUB_SHA

# 2. Tag releases
docker tag myacr.azurecr.io/myapp:$GITHUB_SHA myacr.azurecr.io/myapp:v1.2.3
docker tag myacr.azurecr.io/myapp:$GITHUB_SHA myacr.azurecr.io/myapp:latest

# 3. ACR Geo-replication — replicate images to multiple regions
# 4. Vulnerability scanning — auto-scan images for CVEs
# 5. Content trust — sign and verify images

# Image tagging strategy
myapp:latest               # always the latest build
myapp:main                 # latest from main branch
myapp:1.2.3                # semantic version (immutable)
myapp:abc1234              # Git commit SHA (immutable)
myapp:20260708-abc1234     # date + SHA (sortable + traceable)

# Rollback: deploy previous image tag
az webapp config container set --name myapp --docker-custom-image-name myacr.azurecr.io/myapp:1.2.2
```
