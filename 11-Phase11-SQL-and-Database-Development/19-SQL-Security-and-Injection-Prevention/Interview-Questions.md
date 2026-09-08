# Topic 19: SQL Security & Injection Prevention — Interview Questions

---

## Q1. What is SQL injection, in precise terms?
**Answer:**
A vulnerability where untrusted input is concatenated directly into SQL text, allowing that input to change the **structure** of the executed query rather than just supplying a value. The attacker's input can close a string literal early, add new clauses, or start entirely new statements — none of which are bugs in SQL Server itself; the vulnerability is entirely in how the application built the query string.

```sql
DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM app.Tasks WHERE Title = ''' + @userInput + N'''';
-- If @userInput = ''' OR ''1''=''1', the query becomes: ... WHERE Title = '' OR '1'='1'
```

---

## Q2. Why is parameterisation the correct fix, rather than escaping/sanitising special characters?
**Answer:**
Parameters are sent to SQL Server **separately from the query text** — the structure is compiled once, and values are bound afterward as pure data that can never be interpreted as SQL syntax, regardless of what characters they contain. Escaping/sanitising, by contrast, tries to enumerate and neutralise every dangerous character sequence across every context (quoting rules, encodings, second-order reuse) — it's a losing, incomplete strategy compared to a mechanism that removes the entire attack surface structurally.

---

## Q3. Are ORMs like Entity Framework Core or Dapper automatically safe from SQL injection?
**Answer:**
Only when used as intended — their standard query-building APIs (LINQ in EF Core, parameterised `Query<T>` calls in Dapper) parameterise automatically. But both also offer raw-SQL escape hatches (`FromSqlRaw` in EF Core, string-interpolated SQL in Dapper) that reintroduce the exact same vulnerability if user input is concatenated or interpolated directly into the raw SQL string:

```csharp
// SAFE (EF Core): LINQ translates to a parameterised query.
db.Tasks.Where(t => t.Title.Contains(userInput));

// VULNERABLE: raw SQL with string interpolation defeats the ORM's protection entirely.
db.Tasks.FromSqlRaw($"SELECT * FROM app.Tasks WHERE Title LIKE '%{userInput}%'");
```

---

## Q4. What is second-order SQL injection?
**Answer:**
Injection where the malicious payload is stored safely (via a properly parameterised write) but becomes dangerous **later**, if it's ever read back and concatenated into a *different*, less careful dynamic SQL statement — e.g. a report or export feature built after the original safe write path, that doesn't apply the same parameterisation discipline when reading the previously-stored value back out.

---

## Q5. Why can't you parameterise a dynamic `ORDER BY` column name the same way you parameterise a filter value?
**Answer:**
SQL parameters can only represent **values** (literals) — they cannot represent **identifiers** like table or column names; `ORDER BY @column` is not valid T-SQL syntax with `@column` bound as a parameter value. Because the column name genuinely must be concatenated into the SQL text, it must instead be validated against an explicit **allow-list** before concatenation, so that only known-safe, hard-coded identifier strings ever reach the query text:

```sql
DECLARE @safeColumn SYSNAME = CASE @sortColumn
    WHEN N'Title' THEN N'Title' WHEN N'DueDate' THEN N'DueDate' ELSE N'TaskId' END;
SET @sql = N'SELECT * FROM app.Tasks ORDER BY ' + QUOTENAME(@safeColumn);
```

---

## Q6. What does the principle of least privilege mean for a database login used by an application?
**Answer:**
The application's database account should have **exactly** the permissions its actual functionality requires — typically `EXECUTE` on specific stored procedures, or `SELECT` on specific views — and nothing more. It should never connect as `sa`, `db_owner`, or any account with blanket table access, because the entire point is limiting the blast radius if some other vulnerability (injection or otherwise) is ever exploited: an attacker who compromises a least-privilege connection can only do what that connection was ever allowed to do.

---

## Q7. Why is granting permissions on views/procedures preferable to granting them on base tables?
**Answer:**
It lets you restrict exactly which columns/rows are reachable, structurally, at the permission layer — not just by convention. Granting `SELECT` on a view that excludes `HourlyRate` means a caller with that permission genuinely cannot see `HourlyRate`, even by accident, because the column isn't part of what they have access to at all (Topic 14's security-view pattern). Granting `SELECT` on the base table instead relies entirely on every query the caller ever writes remembering to exclude that column — a much weaker guarantee.

---

## Q8. What's the difference between TDE and Always Encrypted?
**Answer:**
**TDE** (Transparent Data Encryption) encrypts data files/backups at rest, protecting against physical theft of storage media — it's transparent to queries and the database engine itself can freely read plaintext once the database is online. **Always Encrypted** goes further: data is encrypted **client-side** before ever reaching the network, so the database engine, its DBAs, and anyone with raw access to the running server process only ever see ciphertext — protecting against a compromised database engine or a malicious/compromised DBA, a threat model TDE does not address at all.

---

## Q9. What is dynamic data masking, and what is its key limitation?
**Answer:**
It masks column values in query **results** for users without `UNMASK` permission, without altering the stored data — useful for reducing casual over-exposure (e.g. a support engineer glancing at a query result seeing `eXXX@XXXX.com` instead of a real email). The key limitation: it is a **display-layer** control only. A user with ordinary `SELECT` access can still filter/compare against the real underlying value even though the displayed value is masked:

```sql
-- As a masked user: HourlyRate is shown masked in results, but this filter still works
-- correctly against the REAL value -- proving masking doesn't hide the value from logic, only from display.
SELECT COUNT(*) FROM app.Users WHERE HourlyRate > 100;
```

It is not a substitute for real access control or encryption.

---

## Q10. What does SQL Server Audit provide that application-level logging (like a trigger-based `audit.TaskHistory` table) does not?
**Answer:**
A tamper-evident, engine-level record of activity that isn't dependent on application code remembering to log it — including **read** access (`SELECT`), which application audit tables typically don't capture at all (they log changes, not views). This matters for compliance requirements like "who viewed this user's salary field," not just "who changed it," which is a fundamentally different question than what a change-tracking trigger answers.

---

## Q11. A colleague says "we use stored procedures for everything, so we're safe from SQL injection." Is this correct?
**Answer:**
Not automatically. Stored procedures protect against injection **only when their own parameters are used as bound values**, not concatenated into further dynamic SQL inside the procedure body:

```sql
-- Still vulnerable, despite being "a stored procedure": the parameter is concatenated internally.
CREATE PROCEDURE app.usp_Search @Term NVARCHAR(200) AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM app.Tasks WHERE Title LIKE ''%' + @Term + N'%''';
    EXEC (@sql);
END;
```

The procedure boundary itself provides no protection — what matters is whether the procedure's *internal* SQL construction uses parameter binding (`sp_executesql`) or string concatenation.

---

## Q12. Design question: you're building a public-facing "shared read-only link" feature exposing a curated subset of task data to unauthenticated external users. Walk through the layered defenses you'd apply.
**Answer:**
1. **Parameterise every input reaching a query** — including the share-link token itself (`WHERE ShareToken = @token`), even though it's not "user-typed" text in the traditional sense; any value from an external request is untrusted input.
2. **Dedicated least-privilege login** for this feature specifically — separate from the main authenticated-API login — granted `SELECT` only on a purpose-built view exposing exactly the curated columns/rows the feature needs, with no direct table access at all.
3. **Column exclusion via the view**, not masking, for genuinely sensitive fields (`HourlyRate`, internal comments) that this feature should never expose — masking is the wrong tool here since it still lets a sufficiently crafted query infer values through filtering; simply not granting access at all is stronger.
4. **Row-level restriction** in the view's `WHERE` clause (or Row-Level Security) so the token only ever surfaces the one associated project's tasks, never any other project's data.
5. **Database-level safeguards for abuse** are secondary to application/infrastructure rate-limiting, but a query timeout (`SET LOCK_TIMEOUT`, command timeout at the connection level) and a connection pool sized specifically for this low-privilege, high-volume, unauthenticated path (isolated from the authenticated API's connection pool) are reasonable database-adjacent mitigations.
6. **Consider SQL Server Audit** on this specific access path if the shared data is sensitive enough that "who accessed which shared link, when" needs to be forensically reconstructable later — weighed against the audit log volume a public, unauthenticated, potentially high-traffic feature could generate.
