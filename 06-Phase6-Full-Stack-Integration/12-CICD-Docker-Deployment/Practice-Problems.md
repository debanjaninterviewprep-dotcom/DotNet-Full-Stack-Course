# Topic 12 — Practice Problems

> Project: `PracticeProblemsSolutions/` — infra-only. Contains Dockerfiles, docker-compose, GitHub Actions workflows, nginx config, and an EF migrations bundle script. No `.csproj`.

---

## P1 — Multi-stage Dockerfile for the API

**Goal:** Build a small, non-root, distroless API image with layer caching.

**Tasks**
1. `Dockerfile.api` with **four stages**: `restore`, `build`, `publish`, `final` (chiseled runtime).
2. Copy only `*.csproj` + `Directory.*.props` in the restore stage so dependency restore is cached.
3. Final image runs as `$APP_UID`, exposes 8080, sets `ASPNETCORE_URLS=http://+:8080`.
4. Add a `HEALTHCHECK` against `/health/live`.
5. Build & verify size: `docker build -f Dockerfile.api -t taskflow-api . && docker images taskflow-api` — should be < 200 MB.

**Acceptance**
- `docker run -p 8080:8080 taskflow-api` boots and `curl localhost:8080/health/live` returns 200.
- Image runs as non-root (`docker exec ... id -u` is not 0).
- Editing a single `.cs` file rebuilds without invalidating the restore layer.

---

## P2 — Multi-stage Dockerfile + nginx for the Web app

**Goal:** Static SPA served by nginx with SPA fallback and aggressive caching of hashed assets.

**Tasks**
1. `Dockerfile.web`: `deps` (npm ci with cache mount), `build` (`npm run build`), `final` (nginx alpine).
2. Accept `VITE_API_BASE_URL` as a build arg and bake it.
3. `nginx.conf`: SPA fallback (`try_files $uri /index.html`), 1-year cache for hashed assets, no-store for `index.html`, security headers.
4. Listen on 8080 (so it can run as non-root in App Service).
5. Add a `HEALTHCHECK` against `/`.

**Acceptance**
- `docker build --build-arg VITE_API_BASE_URL=http://localhost:8080/api/v1 -t taskflow-web ./web` succeeds.
- Hashed assets respond with `Cache-Control: public, immutable`; `index.html` with `no-store`.
- Deep link `/projects/abc123` returns the SPA shell, not a 404.

---

## P3 — docker-compose for the full stack

**Goal:** One command brings up SQL Server + Redis + Mailpit + API + Web.

**Tasks**
1. `docker-compose.yml` with all five services on a shared network.
2. API depends on `sqlserver` and `redis`; environment vars use service-name DNS (`Server=sqlserver`, `Redis=redis:6379`).
3. Persistent volume for SQL data.
4. Healthchecks for sqlserver and redis (use `depends_on.condition: service_healthy`).
5. `docker compose up -d` followed by `docker compose ps` shows all services Healthy within ~60 s.

**Acceptance**
- `curl http://localhost:8080/health/ready` returns 200 (DB + Redis reachable).
- The web container at `http://localhost:5173` calls `http://localhost:8080/api/v1` (or via reverse-proxied path).
- `docker compose down -v` cleans state; next `up` produces an identical environment.

---

## P4 — GitHub Actions CI workflow

**Goal:** A single CI workflow that runs API build/test, web build/test, and E2E in parallel — with caching and concurrency cancellation.

**Tasks**
1. `.github/workflows/ci.yml` with three jobs: `api`, `web`, `e2e`.
2. `concurrency: group: ci-${{ github.ref }}, cancel-in-progress: true`.
3. API job: `dotnet restore/build/test` with TRX logger + Cobertura coverage; upload coverage to Codecov.
4. Web job: `npm ci`, `lint`, `typecheck`, `test --coverage`, `build`, `npx size-limit`.
5. E2E job: depends on `api` and `web`, uses `services.sqlserver`, runs `dotnet ef database update`, starts the API, runs Playwright; uploads trace on failure.

**Acceptance**
- A PR shows all three jobs running in parallel; merging requires all green.
- A failing test fails the relevant job and uploads the trace artifact.
- Pushing a second commit cancels the first run.

---

## P5 — Build & push images on tag

**Goal:** Tagged push (`v1.0.0`) builds and pushes both images to GitHub Container Registry with cache + provenance.

**Tasks**
1. `.github/workflows/release.yml` triggered on `push.tags: ['v*.*.*']`.
2. `docker/setup-buildx-action` + `docker/login-action` against `ghcr.io`.
3. `docker/build-push-action@v6` for API and Web with:
   - `tags`: both the version tag and `latest`.
   - `cache-from/cache-to: type=gha`.
   - `provenance: true`, `sbom: true`.
4. Permissions: `packages: write`, `id-token: write`.
5. Verify by tag-pushing `v0.0.1` and pulling the resulting image.

**Acceptance**
- `ghcr.io/<owner>/taskflow-api:v0.0.1` and `:latest` both exist.
- The image has SBOM and provenance attestations (`docker buildx imagetools inspect ...`).
- A second tag push reuses cache and completes in <50% of the cold time.

---

## P6 — Deploy with EF migrations bundle + slot swap

**Goal:** Deploy job runs migrations against prod DB, deploys to the staging slot, smoke-tests it, then swaps to production. Fail-safe: never swap on a failed smoke test.

**Tasks**
1. `dotnet ef migrations bundle --self-contained -r linux-x64 -o ./artifacts/efbundle` — produced as a CI artifact.
2. `.github/workflows/deploy.yml` triggered on `workflow_run` of `Release`.
3. Login with OIDC federation (`azure/login@v2`, no client secret).
4. Run the bundle against `${{ secrets.SQL_CONN }}` (or read from Key Vault reference).
5. `azure/webapps-deploy@v3` to the **staging** slot with the tagged image.
6. Smoke loop: poll `https://<app>-staging.azurewebsites.net/health/ready` for up to 2 min; non-200 → fail.
7. `az webapp deployment slot swap` to production. Document the rollback command.

**Acceptance**
- A successful deploy lands the new version in production with zero downtime.
- A deliberately broken image stays on the staging slot — production is untouched.
- The runbook includes the exact rollback command and the smoke-test URL.
