# Topic 2 — Practice Problems

> Mix of **design** (ERD) and **EF Core code** for the TaskFlow database. Solutions go in `PracticeProblemsSolutions/` (.NET console project).

**Concept tags:** `erd` `ef-core` `migrations` `indexes` `interceptors` `soft-delete` `concurrency` `keyset-pagination`

**Setup:**

```powershell
cd 06-Phase6-Full-Stack-Integration\02-Database-Design-EF-Core-Migrations\PracticeProblemsSolutions
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet run
```

You can use SQLite for local runs by swapping `UseSqlServer` → `UseSqlite("Data Source=taskflow.db")`.

---

## P1 — TaskFlow ERD  *(Easy)*

**Tags:** `erd` `mermaid`

### Requirements

Author a complete `mermaid erDiagram` covering all 12 entities:
`User`, `RefreshToken`, `Project`, `ProjectMember`, `TaskItem`, `TaskAssignee`, `Comment`, `Attachment`, `Tag`, `TaskTag`, `ActivityLog`, `Notification`.

For each entity show at least the PK, key FKs, 3-5 important columns, and audit columns. Show every relationship's cardinality.

### Deliverable

`Solutions/P1-erd.md`

### Look-fors

- [ ] All 12 entities present with correct PK/FK lines.
- [ ] M:N relationships explicit through join entities.
- [ ] Audit columns (`CreatedAt`, `UpdatedAt`, `IsDeleted`) on every domain entity.

---

## P2 — User & RefreshToken Entities + DbContext  *(Easy)*

**Tags:** `ef-core` `dbcontext` `iconfiguration`

### Requirements

In `Program.cs` (or split files) implement:

- `User` entity (`Id Guid PK`, `Email`, `PasswordHash`, `DisplayName`, audit, `IsDeleted`).
- `RefreshToken` entity (`Id Guid`, `UserId FK`, `TokenHash`, `ExpiresAt`, `RevokedAt?`).
- `IEntityTypeConfiguration<>` for both with: max lengths, unique index on `User.Email`, unique index on `RefreshToken.TokenHash`, FK with `OnDelete(Cascade)`.
- `TaskFlowDbContext` that calls `ApplyConfigurationsFromAssembly`.
- A small `Main` that creates the DB and inserts a sample user + refresh token.

### Look-fors

- [ ] `User.Email` uniqueness enforced at DB level (not just LINQ check).
- [ ] Both configurations inherit `IEntityTypeConfiguration<T>`.
- [ ] No magic strings in queries (no `.FromSql("SELECT ...")` for these queries).

---

## P3 — Project ↔ User Many-to-Many with `ProjectMember`  *(Medium)*

**Tags:** `many-to-many` `join-entity` `roles`

### Requirements

- Add `Project` entity (with `OwnerId FK`, `RowVersion`).
- Add `ProjectMember` join entity carrying `Role (Owner|Admin|Member|Viewer)` and `JoinedAt`.
- Composite key `(ProjectId, UserId)`.
- Configure navigations on both sides; expose `Project.Members` and `User.Memberships`.
- Demonstrate adding a member, changing a role, and listing all projects a user belongs to.

### Hints

- `enum ProjectRole` mapped via `HasConversion<int>()`.
- Use `WithMany().UsingEntity<ProjectMember>(...)` if you want skip navigations to coexist with the join entity.

### Look-fors

- [ ] PK is composite — no surrogate `Id` on `ProjectMember`.
- [ ] Role stored as `int` in DB but exposed as enum in C#.
- [ ] Listing query uses `AsNoTracking()` + projection.

---

## P4 — Audit Interceptor + Soft-Delete Filter  *(Medium)*

**Tags:** `savechanges-interceptor` `soft-delete` `query-filters`

### Requirements

- Create `IAuditable` interface (`CreatedAt`, `UpdatedAt`, `CreatedBy`, `UpdatedBy`) and `ISoftDelete` (`IsDeleted`, `DeletedAt`).
- Implement them on `Project`, `TaskItem`, `User`.
- Build `AuditInterceptor : SaveChangesInterceptor` that stamps audit fields using a stub `ICurrentUser` returning a fixed Guid.
- Override `Remove()` (or use a `SaveChangesInterceptor`) to convert deletes into soft deletes for `ISoftDelete` entities.
- Add `HasQueryFilter(x => !x.IsDeleted)` to all soft-deletable entities.
- In `Main`: insert, soft-delete, then prove the row is **not** returned by default but **is** returned with `.IgnoreQueryFilters()`.

### Look-fors

- [ ] Audit columns set on Add and Modified — not on Unchanged.
- [ ] Soft delete works on cascading children (or explicitly excluded — your call, document it).
- [ ] Query filter test passes both directions.

---

## P5 — Migrations: Initial + Rename Without Data Loss  *(Hard)*

**Tags:** `migrations` `expand-contract` `idempotent`

### Requirements

1. Create the initial migration covering the entities from P1-P4.
2. Generate an **idempotent SQL script** for it.
3. Add a follow-up migration that **renames** `Project.Description` → `Project.Summary` using the **expand → migrate → contract** pattern across two migrations (so a rolling deploy never sees missing columns).
4. Provide a 3-step deploy plan in `Solutions/P5-deploy-plan.md`.

### Hints

- EF Core's auto-generated rename can produce drop+create. Use `migrationBuilder.Sql("EXEC sp_rename ...")` if you want a true rename.
- Step 1 migration: add `Summary` (nullable), copy data via `Sql("UPDATE ... SET Summary = Description")`.
- Step 2 migration: drop `Description` after the new code is fully deployed.

### Look-fors

- [ ] Idempotent script runs cleanly twice.
- [ ] No window where reads or writes lose data.
- [ ] Deploy plan names which app version is compatible with each migration step.

---

## P6 — N+1-Free Project Listing With Indexing Plan  *(Hard)*

**Tags:** `query-perf` `n+1` `projection` `keyset-pagination` `indexing`

### Requirements

- Implement an endpoint-style method `Task<List<ProjectListItemDto>> ListProjectsAsync(...)` that returns each project with:
  - `Id`, `Name`, `OwnerName`, `MemberCount`, `OpenTaskCount`, `OverdueTaskCount`, `LastActivityAt`.
- Use **a single SQL query** (no N+1) — verify by enabling `LogTo(Console.WriteLine)` and counting the SELECTs.
- Add **keyset pagination** by `LastActivityAt DESC, Id DESC` (cursor: last seen `(LastActivityAt, Id)`).
- Document the index strategy in `Solutions/P6-indexes.md`:
  - Which indexes are needed?
  - What columns should be `INCLUDE`d?
  - Estimated read cost for page 1 and page 100.

### Hints

- Start from `db.Projects.AsNoTracking().Select(p => new ProjectListItemDto { ... })` and use sub-queries (`p.Tasks.Count(t => !t.IsDone)`).
- For the cursor: `WHERE (LastActivityAt < @c1) OR (LastActivityAt = @c1 AND Id < @c2)`.

### Look-fors

- [ ] Single SQL statement (verified in log).
- [ ] Cursor is correctly tie-broken with PK.
- [ ] Index plan covers the listing query.

---

## Self-Review Checklist

- [ ] You can explain TPH vs TPT in one sentence each.
- [ ] You know when `AsSplitQuery()` is needed and what problem it solves.
- [ ] You wrote at least one `IEntityTypeConfiguration<T>` from memory.
- [ ] You produced an idempotent migration script.
- [ ] You proved your listing query is N+1-free with a SQL log screenshot.
