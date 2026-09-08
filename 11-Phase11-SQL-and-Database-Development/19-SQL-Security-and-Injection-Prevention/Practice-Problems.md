# Topic 19: SQL Security & Injection Prevention — Practice Problems

> Six exercises that force you to actually cause an injection, actually fix it, and then build the least-privilege/encryption/masking/audit layers around it. All against the seeded `TaskFlowDb`.

**Concept tags:** `sql-injection` `sp_executesql` `parameterisation` `least-privilege` `roles` `dynamic-data-masking` `sql-audit` `owasp`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Cause and Fix a Real Injection  *(Easy)*

**Tags:** `sql-injection` `dynamic-sql` `parameterisation`

### Requirements

1. Create a **deliberately vulnerable** procedure `app.usp_SearchTasksVulnerable (@TitleSearch NVARCHAR(200))` that builds and `EXEC`s a dynamic SQL string via string concatenation.
2. Call it with an ordinary search term and confirm it works as intended.
3. Call it with a payload that comments out the rest of the intended `WHERE` clause and returns **every** row regardless of the search term (an authentication/authorization-bypass-style payload, e.g. `' OR '1'='1' --`). Capture the resulting SQL text (`PRINT @sql` inside the procedure, temporarily, for observation) and the unintended result set.
4. Rewrite it as `app.usp_SearchTasksSafe` using `sp_executesql` with a bound parameter, and confirm the same payload is now treated as a literal, harmless search string that matches nothing.
5. Drop `app.usp_SearchTasksVulnerable` — do not leave it in the database.

### Deliverable

`P1-cause-and-fix-injection.sql`.

### Hints

- `'; DROP TABLE app.Labels; --'` is a stronger (and more dangerous) payload to *reason about* than to actually run — demonstrate the concept with a read-only payload (`' OR '1'='1`) so nothing is actually destroyed, and explain in a comment why the destructive version would have worked identically.

### Look-fors (rubric)

- [ ] The vulnerable procedure's unintended full-table-return behavior is demonstrated with the actual resulting SQL text shown.
- [ ] The safe version correctly treats the same payload as inert literal text.
- [ ] The vulnerable procedure is dropped before the script ends.

---

## P2 — Second-Order Injection  *(Medium)*

**Tags:** `second-order-injection` `stored-data`

### Requirements

1. Using a **parameterised** (safe) `INSERT`, store a task title containing a SQL metacharacter payload (e.g. `Fix bug'; SELECT * FROM app.Users; --`) — confirm it's stored correctly as literal text, proving the initial write was safe.
2. Write a **second**, separate script that reads that title back and concatenates it into a *new* dynamic SQL string (simulating a later report/export feature that wasn't as careful) — demonstrate the payload now executes as SQL, even though it was "safely" written originally.
3. Fix the second script using `sp_executesql`, and confirm the payload is now treated as inert data again.
4. Roll back the inserted row; drop any procedures created.

### Deliverable

`P2-second-order-injection.sql`. Wrap the data change in a transaction you roll back.

### Hints

- The point of this exercise is that "this data already went through a safe write path once" is not a guarantee against a later, careless read-and-concatenate.

### Look-fors (rubric)

- [ ] The initial parameterised `INSERT` correctly stores the payload as literal text.
- [ ] The vulnerable second script is shown actually executing the embedded payload.
- [ ] The fixed version correctly neutralises it.
- [ ] Data rolled back.

---

## P3 — Safe Dynamic `ORDER BY` with an Allow-List  *(Medium)*

**Tags:** `dynamic-order-by` `allow-list` `quotename`

### Requirements

1. Write `app.usp_GetTasksSorted (@SortColumn NVARCHAR(50))` that dynamically sorts by a caller-chosen column — but validates `@SortColumn` against an explicit `CASE`-based allow-list (Notes.md §3) before using it, falling back to a safe default for anything unrecognised.
2. Call it with each of the allow-listed values and confirm correct sorting for each.
3. Call it with an injection-shaped payload as the "column name" (e.g. `TaskId; DROP TABLE app.Labels; --`) and confirm it falls back to the safe default rather than erroring or executing anything unintended.
4. Explain, in a comment, why parameters alone cannot solve this specific problem (dynamic identifiers, not dynamic values).

### Deliverable

`P3-safe-dynamic-order-by.sql`. Drop the procedure at the end.

### Hints

- `QUOTENAME()` around the validated column name is good defensive practice even after the allow-list check.

### Look-fors (rubric)

- [ ] All allow-listed sort columns produce correctly ordered results.
- [ ] The injection-shaped payload is correctly neutralised via the fallback default, not merely "not crashing."
- [ ] The explanation correctly identifies the identifier-vs-value distinction.

---

## P4 — Least Privilege: Logins, Users, Roles  *(Medium)*

**Tags:** `least-privilege` `roles` `grant` `view-based-access`

### Requirements

1. Create a role `role_taskflow_reader` granted `SELECT` only on `app.vw_OpenTasks` and `app.vw_UserDirectory` (create these views if they don't already exist from Topic 14 — a plain, column-limited view is fine) — **no** permission on any base table.
2. Create a `role_taskflow_api` granted `EXECUTE` only on two or three procedures you designate (e.g. `app.usp_CreateTask`, `app.usp_AssignTask` from Topic 15/16 if present, or simple stand-ins you create for this exercise) — again, **no** direct table permissions.
3. Create a test login/user, add it to `role_taskflow_reader`, and demonstrate: it can query the views successfully, but a direct `SELECT * FROM app.Users` fails with a permissions error.
4. Explain, in a comment, specifically why granting on the view instead of the base table protects `HourlyRate` even though the role has "read access to user data."
5. Clean up: drop the test login/user, the roles, and any procedures created solely for this exercise.

### Deliverable

`P4-least-privilege.sql`.

### Hints

- `CREATE LOGIN ... WITH PASSWORD = ...` then `CREATE USER ... FOR LOGIN ...` then `ALTER ROLE ... ADD MEMBER ...`.
- Use `EXECUTE AS USER = '<name>'` / `REVERT` to test permissions from within the same session without a second connection.

### Look-fors (rubric)

- [ ] The reader role can query both views but is correctly denied direct table access.
- [ ] The API role can execute its granted procedures but has no direct table permissions.
- [ ] The `HourlyRate` protection explanation correctly ties back to Topic 14's view-based security pattern.
- [ ] All test logins/users/roles are dropped at the end.

---

## P5 — Dynamic Data Masking  *(Medium)*

**Tags:** `dynamic-data-masking` `unmask` `masking-functions`

### Requirements

1. Apply dynamic data masking to `app.Users.Email` (using the `email()` function) and `app.Users.HourlyRate` (using a `random()` range) — on a **scratch copy** of relevant columns if you're not comfortable altering the real seeded table, or on the real table if you plan to remove the masking afterward.
2. Query the table as the owner/admin (who has `UNMASK` implicitly) and confirm real values are visible.
3. Create a test user with only `SELECT` (no `UNMASK`), and demonstrate via `EXECUTE AS USER` that the same query now shows masked values.
4. Demonstrate the masking's known limitation: as the masked test user, run `SELECT COUNT(*) FROM app.Users WHERE HourlyRate > 100;` and show that filtering still works correctly against the **real**, unmasked underlying value — proving masking is a display-layer control only.
5. Remove the masking and any test user created; leave the real schema unchanged.

### Deliverable

`P5-dynamic-data-masking.sql`.

### Hints

- `GRANT UNMASK TO <user>;` reverses the masking for that specific principal.

### Look-fors (rubric)

- [ ] The masked columns correctly show real values to the admin/owner and masked values to the restricted test user.
- [ ] The filtering-still-works-on-real-values limitation is concretely demonstrated, not just asserted.
- [ ] Masking is removed and the test user dropped at the end; the real schema is unchanged.

---

## P6 — Defense in Depth: Design Review  *(Hard)*

**Tags:** `defense-in-depth` `design-review` `owasp`

### Requirements

TaskFlow is adding a public-facing "shared task board" feature: an unauthenticated link lets an external client view (read-only) a curated subset of one project's tasks. Write a defense-in-depth design review covering:

1. **Injection surface**: name every place user input reaches this feature (the shared link's token, any search/filter the public view might expose) and how each is neutralised.
2. **Least privilege**: design the specific database login/role this public-facing feature would use, and exactly what it can and cannot access — justify using view/procedure-based grants.
3. **Data exposure**: which columns of `app.Tasks`/`app.Projects`/`app.Users` must **never** be reachable from this feature (e.g. `HourlyRate`, internal comments, other projects' data), and which mechanism from this topic (view column restriction, masking, or simply not granting access at all) you'd use for each.
4. **Rate limiting / abuse**: this is generally an application/infrastructure concern, not a database one — explain briefly why, and name the one database-level safeguard that's still relevant (e.g. a query timeout, a dedicated low-privilege connection pool).
5. **Auditing**: would you enable SQL Server Audit for this feature's access path? Justify your answer given it's read-only and unauthenticated-by-design.

### Deliverable

`P6-defense-in-depth-review.md`.

### Hints

- The "token" for the shared link is itself a value that reaches a query (`WHERE ShareToken = @token`) — treat it with the same parameterisation discipline as any other input, even though it's not literally "user-typed text."

### Look-fors (rubric)

- [ ] Every named input surface has a specific, correct neutralisation mechanism (not a generic "sanitise inputs").
- [ ] The proposed role/login genuinely has no more access than the feature requires.
- [ ] The data-exposure answer correctly maps each sensitive field to a specific mechanism from this topic.
- [ ] The rate-limiting answer correctly identifies it as primarily non-database while still naming a relevant database-level safeguard.
- [ ] The auditing recommendation is justified, not just asserted either way.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All six deliverables exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] No deliberately vulnerable procedure persists beyond its own demonstration script.
- [ ] Every test login/user/role created for an experiment is dropped at the end of its own file.
- [ ] Every destructive statement against a real TaskFlow table is wrapped in `BEGIN TRANSACTION` / `ROLLBACK TRANSACTION`, and masking/permission changes to the real schema are reverted.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Research SQL Server's `EXECUTE AS` clause on a stored procedure itself (as opposed to session-level `EXECUTE AS USER`) and explain the difference between "definer's rights" and "invoker's rights" execution.
- Investigate Extended Events for capturing failed login attempts and permission-denied errors as an early-warning signal distinct from full SQL Server Audit.
- Read the OWASP Top 10's current entry for injection and write a paragraph mapping its general web-application guidance onto the specific T-SQL mechanisms covered in this topic.
