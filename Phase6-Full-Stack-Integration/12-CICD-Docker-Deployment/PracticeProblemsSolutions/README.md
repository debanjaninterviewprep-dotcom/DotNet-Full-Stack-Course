# Topic 12 — Practice Problems Solutions (infra-only)

This folder contains the deployment artifacts referenced by P1–P6. There is no `.csproj` here — this is configuration and pipeline scaffolding meant to be copied into the real solution roots when you ship.

## Layout

```
PracticeProblemsSolutions/
├── Dockerfile.api               # P1
├── Dockerfile.web               # P2
├── nginx.conf                   # P2
├── docker-compose.yml           # P3
├── .dockerignore
├── .github/
│   └── workflows/
│       ├── ci.yml               # P4
│       ├── release.yml          # P5
│       └── deploy.yml           # P6
└── README.md
```

## Smoke checklist

| Step | Command |
|---|---|
| Build API image | `docker build -f Dockerfile.api -t taskflow-api ../../..` |
| Build Web image | `docker build -f Dockerfile.web -t taskflow-web --build-arg VITE_API_BASE_URL=http://localhost:8080/api/v1 ../../web` |
| Bring up stack  | `docker compose up -d` |
| Verify ready    | `curl http://localhost:8080/health/ready` |
| Tear down       | `docker compose down -v` |

## CI/CD secrets to configure

In **Settings → Secrets and variables → Actions**:

- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — for OIDC login.
- `SQL_CONN` — production SQL connection string (or Key Vault reference).
- `CODECOV_TOKEN` — coverage upload.

GitHub Environments:

- `production` — required reviewers, environment-scoped secrets, branch protection to `main`.

## Branch protection (P-checklist for `main`)

- Require PR + 1 approval (2 for `CODEOWNERS`-protected paths).
- Require status checks: `api`, `web`, `e2e`, `size-limit`.
- Require linear history; require signed commits; block force-push.

## Rollback runbook

Fastest rollback is a slot swap back:

```bash
az webapp deployment slot swap \
  -n taskflow-api -g taskflow-rg \
  --slot production --target-slot staging
```

If the broken release was promoted past staging, redeploy the previous tag:

```bash
az webapp config container set -n taskflow-api -g taskflow-rg \
  --container-image-name ghcr.io/<owner>/taskflow-api:v1.3.9
```
