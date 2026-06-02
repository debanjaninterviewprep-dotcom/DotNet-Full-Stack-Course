# Topic 5 — Practice Problems

> Build TaskFlow's identity layer end-to-end. Solutions go in `PracticeProblemsSolutions/` (an ASP.NET Core 9 webapi project).

**Concept tags:** `jwt` `bcrypt` `refresh-token-rotation` `policy-auth` `resource-auth` `cors` `rate-limit`

**Setup**

```powershell
cd Phase6-Full-Stack-Integration\05-Authentication-Authorization-End-to-End\PracticeProblemsSolutions
dotnet user-secrets set "Jwt:SigningKey" "<base64-of-32-random-bytes>"
dotnet run
```

---

## P1 — Sign-up + Login with BCrypt + JWT  *(Easy)*

**Tags:** `register` `bcrypt` `jwt-issuer`

### Requirements

- `User` entity with `Email`, `PasswordHash`, `DisplayName`, `EmailConfirmed`.
- `IPasswordHasher` (BCrypt cost 12).
- `IJwtTokenService` issuing HS256 access tokens (15 min) with `sub`, `unique_name`, `jti`, `role` claims.
- Endpoints:
  - `POST /auth/register` — creates user, returns access + refresh tokens.
  - `POST /auth/login` — returns access + refresh tokens.
- Email uniqueness enforced at DB level.
- Generic error message on bad credentials (no enumeration).

### Look-fors

- [ ] Password never appears in any log.
- [ ] BCrypt cost is configurable via `JwtOptions` or a separate `SecurityOptions`.
- [ ] `[Authorize]` endpoint accepts the issued token (verify in Swagger Authorize button).

---

## P2 — Refresh Token Rotation  *(Medium)*

**Tags:** `refresh` `rotation` `httponly-cookie` `revocation`

### Requirements

- `RefreshToken` entity (`UserId`, `TokenHash`, `ExpiresAt`, `RevokedAt`, `ReplacedById`, `CreatedByIp`, `UserAgent`).
- `POST /auth/refresh` reads the cookie, looks up by hashed value, rotates it, returns new tokens.
- Detection of **token reuse**: if a token is presented after `RevokedAt` is set, treat it as a breach — revoke all sibling tokens for that user and return 401.
- Cookie attributes: HttpOnly, Secure, SameSite=Strict, Path=/auth, Expires=7d.
- `POST /auth/logout` revokes the current refresh token + clears the cookie.

### Look-fors

- [ ] Refresh token plaintext is never stored — only the hash.
- [ ] Reuse path is unit-tested (return code + sibling revocation).
- [ ] Cookie path scoped so the refresh cookie isn't sent on every API call.

---

## P3 — `[Authorize]` Policies + ICurrentUser  *(Medium)*

**Tags:** `policy-auth` `claims` `icurrentuser`

### Requirements

- Define policies:
  - `AdminOnly` — requires role `Admin`.
  - `EmailConfirmed` — requires claim `email_verified=true`.
  - `Member` — authenticated only.
- Implement `ICurrentUser` reading from `HttpContext.User` (id, email, IsInRole).
- Decorate sample endpoints with each policy. Verify with valid + missing-claim tokens.
- Add a custom `[Authorize(Policy="AdminOnly")]` endpoint that returns the requesting user's claims for debugging.

### Look-fors

- [ ] Missing token → 401, not 403.
- [ ] Authenticated but failing policy → 403.
- [ ] `MapInboundClaims = false` so `sub` stays `sub`.

---

## P4 — Resource-Based Authorization for Projects  *(Medium)*

**Tags:** `iauthorizationhandler` `row-level` `project-member`

### Requirements

- Policy `CanEditProject` enforced via `AuthorizationHandler<CanEditProject, Project>`.
- Handler queries `ProjectMember` for `(projectId, userId)`. Owner / Admin succeed; Member / Viewer fail.
- `PUT /api/v1/projects/{id}` calls `IAuthorizationService.AuthorizeAsync(User, project, new CanEditProject())` and returns Forbid on failure.
- Unit test the handler with an in-memory `DbContext` and a stub `ICurrentUser`.

### Look-fors

- [ ] Handler is `Scoped` (uses DbContext).
- [ ] Auth check happens **after** the resource is loaded — you need the project to authorize.
- [ ] No N+1 query on the membership lookup.

---

## P5 — Login Rate Limiting + Account Lockout  *(Hard)*

**Tags:** `rate-limit` `lockout` `cache`

### Requirements

- Use `Microsoft.AspNetCore.RateLimiting` to add a fixed-window limiter `login`: 5 requests per IP per minute.
- Track failed login attempts per `(emailHash, ip)` in `IDistributedCache` (in-memory in dev). After 5 failures within 15 min → temporary lockout response (`429 Retry-After: 900`). Reset counter on success.
- Wire `[EnableRateLimiting("login")]` on the login endpoint.
- Cover with integration tests using `WebApplicationFactory` + `HttpClient` looping 6 times.

### Look-fors

- [ ] Limiter configuration loaded from `appsettings.json` (no magic numbers in code).
- [ ] Lockout response includes `Retry-After` header in seconds.
- [ ] Successful login clears the failure counter.

---

## P6 — Password Reset + Logout-All  *(Hard)*

**Tags:** `reset` `single-use-token` `revoke-all`

### Requirements

- `POST /auth/forgot-password { email }` — always 200 (no enumeration). If user exists, generate a single-use 64-byte token, store `(userId, hash, expiresAt 1h)`, send link via `IEmailSender` (console sender in dev).
- `POST /auth/reset-password { token, newPassword }` — validate, hash, update password, **revoke all refresh tokens** for the user.
- `POST /auth/logout-all` — for the current authenticated user, revoke all refresh tokens.

### Look-fors

- [ ] Reset token table records `UsedAt` to enforce single-use.
- [ ] Password change forces re-login on every device (verified in test).
- [ ] Email content does not include the user's password or any sensitive value.

---

## Self-Review Checklist

- [ ] You can describe the refresh-rotation breach detection in one paragraph.
- [ ] You can list 3 reasons not to put a refresh token in localStorage.
- [ ] You authored at least one resource-based authorization handler.
- [ ] You produced a 429 with Retry-After from a real test.
- [ ] You implemented a single-use token (reset) with TTL.
- [ ] You confirmed `[Authorize]` is unaware of HTTP cookies in the API project (uses Bearer only).
