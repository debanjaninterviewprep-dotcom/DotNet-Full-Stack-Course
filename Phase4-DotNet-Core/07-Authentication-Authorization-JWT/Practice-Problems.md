# Practice Problems: Authentication & Authorization (JWT)

---

## Problem 1: JWT Token Generator & Validator ⭐ Easy

**Objective**: Build a console app that creates and validates JWT tokens manually (without ASP.NET libraries).

### Requirements:
1. Implement Base64URL encoding/decoding
2. Build a JWT with header, payload (claims), and HMACSHA256 signature
3. Create tokens for different users with different roles
4. Validate tokens: check signature, expiry, claims
5. Show what happens with tampered tokens and expired tokens

### Expected Output:
```
=== JWT Token Generator ===

--- Create Token for Admin ---
Header:  { "alg": "HS256", "typ": "JWT" }
Payload: { "sub": "1", "name": "admin", "role": "Admin", "exp": 1745600000 }
Token:   eyJhbGci....[truncated]
Parts:   Header.Payload.Signature

--- Validate Token ---
✓ Signature valid
✓ Not expired (expires in 59 minutes)
✓ Claims: sub=1, name=admin, role=Admin

--- Tampered Token ---
✗ INVALID SIGNATURE! Token has been modified.

--- Expired Token ---
✗ TOKEN EXPIRED at 2026-04-25 09:00:00 (15 minutes ago)
```

---

## Problem 2: Password Hashing & Authentication System ⭐⭐ Easy-Medium

**Objective**: Build a console app that implements secure password hashing and a complete login/registration flow.

### Requirements:
1. Implement password hashing with salt (simulate BCrypt behavior)
2. Registration: validate input, check duplicates, hash password, store user
3. Login: find user, verify password hash, generate token
4. Show that same password produces different hashes (due to salt)
5. Demonstrate brute-force resistance (timing comparison)

---

## Problem 3: Role-Based Access Control (RBAC) System ⭐⭐ Medium

**Objective**: Build a console app that implements a complete RBAC authorization system with roles, permissions, and policy-based access.

### Requirements:
1. Define roles: Admin, Manager, User, Guest
2. Define permissions per role: Read, Write, Delete, ManageUsers
3. Implement `[Authorize]` simulation: check if user's role has required permission
4. Implement policies: "AdminOnly", "CanWrite", "DepartmentManager"
5. Simulate 10+ API requests with different users and access levels

---

## Problem 4: Complete Auth Flow with Refresh Tokens ⭐⭐ Medium-Hard

**Objective**: Build a console app that implements the complete authentication lifecycle: register → login → access → token refresh → logout.

### Requirements:
1. User registration with validation and password hashing
2. Login returning access token (short-lived) and refresh token (long-lived)
3. Protected endpoint access with token validation
4. Token refresh flow when access token expires
5. Logout that invalidates refresh token
6. Simulate the full lifecycle for 2 users

---

## Problem 5: Enterprise Auth System with Claims & Policies ⭐⭐⭐ Hard

**Objective**: Build a console app simulating an enterprise-grade auth system with custom claims, hierarchical roles, resource-level authorization, and audit logging.

### Requirements:
1. **Hierarchical Roles**: Admin > Manager > TeamLead > Developer > User (inherits lower permissions)
2. **Custom Claims**: department, team, clearance_level
3. **Resource-Level Auth**: Users can only edit their own resources, managers can edit team's
4. **Policy Engine**: Combine role + claims + resource ownership for access decisions
5. **Audit Log**: Record every access attempt (who, what, when, allowed/denied)
6. Process 15+ requests showing different authorization scenarios

### Expected Output:
```
=== Enterprise Auth System ===

[Register] Users: admin(Admin), john(Manager/Engineering), jane(Developer/Engineering), bob(Developer/Marketing)

━━━ Request 1: GET /api/products (jane, Developer) ━━━
[Auth] Token valid, User: jane, Role: Developer
[Policy] "CanRead" → Developer has Read permission ✓
[Audit] jane | GET /api/products | ALLOWED | 2026-04-25 10:00:01
◀ 200 OK

━━━ Request 2: DELETE /api/products/1 (jane, Developer) ━━━
[Auth] Token valid, User: jane, Role: Developer
[Policy] "CanDelete" → Developer does NOT have Delete permission ✗
[Audit] jane | DELETE /api/products/1 | DENIED | 2026-04-25 10:00:02
◀ 403 Forbidden

━━━ Request 3: PUT /api/users/jane/profile (jane) ━━━
[Auth] Token valid, User: jane
[Policy] "ResourceOwner" → jane owns resource /users/jane ✓
[Audit] jane | PUT /users/jane/profile | ALLOWED
◀ 200 OK

━━━ Request 4: PUT /api/users/jane/profile (john, Manager/Engineering) ━━━
[Auth] Token valid, User: john, Role: Manager, Dept: Engineering
[Policy] "ResourceOwner" → john does NOT own /users/jane
[Policy] "DepartmentManager" → john is Manager of Engineering, jane is in Engineering ✓
[Audit] john | PUT /users/jane/profile | ALLOWED (department manager override)
◀ 200 OK

━━━ Audit Report ━━━
Total Requests: 15
Allowed: 10 (67%)
Denied: 5 (33%)
Most Active: jane (6 requests)
Most Denied: bob (3 denied — tried admin actions)
```
