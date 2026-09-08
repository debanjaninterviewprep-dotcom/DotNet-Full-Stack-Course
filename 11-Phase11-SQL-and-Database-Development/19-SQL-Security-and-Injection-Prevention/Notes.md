# Topic 19: SQL Security & Injection Prevention

> Every other topic in this phase assumed you were the one writing the SQL. Production TaskFlow accepts search terms, task titles, and filter values from thousands of users you'll never see — and every one of those values eventually reaches a query. This topic covers SQL injection as a concrete, OWASP Top 10 vulnerability class: how it actually happens, why parameterisation is the only real fix, and the layers of database-level security (principle of least privilege, roles, encryption, dynamic data masking, auditing) that TaskFlow needs regardless of how careful the application layer is.

---

## 1. SQL Injection: How It Actually Happens

SQL injection occurs when untrusted input is concatenated directly into a SQL string, letting an attacker's input change the **structure** of the query, not just supply a value.

```sql
-- Vulnerable pattern (never do this): the search term becomes part of the SQL text itself.
DECLARE @search NVARCHAR(200) = N'''; DROP TABLE app.Tasks; --';
DECLARE @sql NVARCHAR(MAX) = N'SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE ''%' + @search + N'%''';
EXEC (@sql);
```

The resulting string becomes:

```sql
SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE '%'; DROP TABLE app.Tasks; --%'
```

The attacker's `'` closes the intended string literal early, `;` starts a new statement, and `--` comments out the rest — three completely ordinary SQL Server behaviors, none of which are "bugs" on their own. The vulnerability is entirely in **how the string was built**, not in any single T-SQL feature misbehaving.

### Classic authentication-bypass example

```sql
-- Vulnerable: building a login check by concatenation.
DECLARE @email NVARCHAR(256) = N'''  OR ''1''=''1';
DECLARE @sql NVARCHAR(MAX) = N'SELECT UserId FROM app.Users WHERE Email = ''' + @email + N'''';
-- Becomes: ... WHERE Email = '' OR '1'='1'  -- always true, returns every user's UserId.
```

### Second-order injection

Injection doesn't require the payload to be used immediately — a value stored **unsanitised** now can become dangerous later, if it's ever read back and concatenated into a *different* dynamic query:

```sql
-- A task title stored safely via a parameterised INSERT today...
INSERT INTO app.Tasks (Title, ...) VALUES (@UntrustedTitle, ...);   -- safe: parameterised

-- ...but a LATER report script that reads it back and concatenates it is still vulnerable.
DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM app.ArchivedTasks WHERE Title = ''' +
    (SELECT Title FROM app.Tasks WHERE TaskId = 999) + N'''';   -- still vulnerable, right here
```

> **Rule of thumb:** "We validated/sanitised the input at the API boundary" is not sufficient on its own. Every place a value is concatenated into SQL text is a fresh injection point, no matter how many times that value has already passed through "safe" code elsewhere.

---

## 2. Parameterisation: The Only Real Fix

Parameters are sent to SQL Server **separately from the query text** — the database compiles the SQL structure once, then binds values into it as pure data, never as executable text. This is why parameterisation isn't "input sanitisation done well," it's a structurally different mechanism.

```sql
-- Safe: the value of @search is bound as DATA, never becomes part of the SQL text.
DECLARE @search NVARCHAR(200) = N'''; DROP TABLE app.Tasks; --';
DECLARE @sql NVARCHAR(MAX) = N'SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE @p_search';
EXEC sp_executesql @sql, N'@p_search NVARCHAR(200)', @p_search = N'%' + @search + N'%';
-- Searches for a Title literally containing the string "'; DROP TABLE app.Tasks; --" -- finds nothing, breaks nothing.
```

```csharp
// Application-layer equivalent (ADO.NET) -- Topic 21 covers this in depth.
using var cmd = new SqlCommand("SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE @search", conn);
cmd.Parameters.AddWithValue("@search", $"%{userInput}%");   // userInput is DATA, never SQL text
```

| Approach | Injection-safe | Why |
|---|---|---|
| String concatenation | **Never** | User input becomes part of the parsed SQL structure |
| `sp_executesql` with bound parameters | **Yes** | Value passed as data, structure fixed at parse time |
| ORM/parameterised query builder (EF Core, Dapper) | Yes, **when used correctly** | Same mechanism under the hood — but raw SQL fragments inside an ORM call re-introduce the risk |
| Stored procedure with typed parameters | **Yes** | Parameters are always bound, never concatenated, by definition |
| Escaping/encoding special characters manually | **No — do not rely on this** | Easy to miss an edge case (encoding differences, multi-byte sequences, second-order reuse); not a defensible primary defense |

> **Anti-pattern:** A "sanitisation" function that strips or escapes `'`, `;`, `--` from user input as the *primary* defense. It's a losing game of finding every dangerous sequence across every context (different quoting rules, `xp_cmdshell`-adjacent risks, Unicode look-alikes) — parameterisation removes the entire attack surface instead of trying to filter it.

### ORMs are not automatically safe

```csharp
// Dapper -- SAFE: @search is a bound parameter.
var tasks = conn.Query<TaskDto>(
    "SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE @search",
    new { search = $"%{userInput}%" });

// Dapper -- VULNERABLE: string interpolation defeats the entire point of using Dapper.
var tasks = conn.Query<TaskDto>(
    $"SELECT TaskId, Title FROM app.Tasks WHERE Title LIKE '%{userInput}%'");
```

```csharp
// EF Core -- SAFE: LINQ translates to a parameterised query.
var tasks = db.Tasks.Where(t => t.Title.Contains(userInput)).ToList();

// EF Core -- VULNERABLE: FromSqlRaw with interpolated/concatenated input.
var tasks = db.Tasks.FromSqlRaw($"SELECT * FROM app.Tasks WHERE Title LIKE '%{userInput}%'").ToList();

// EF Core -- SAFE alternative when raw SQL is genuinely needed: FromSqlInterpolated
// parameterises the interpolated values automatically.
var tasks = db.Tasks.FromSqlInterpolated($"SELECT * FROM app.Tasks WHERE Title LIKE {"%" + userInput + "%"}").ToList();
```

---

## 3. Where Injection Hides Beyond `WHERE` Clauses

- **`ORDER BY` / dynamic column names**: parameters cannot represent identifiers (column/table names) — only values. A dynamic `ORDER BY @column` is **not valid T-SQL**; the column name must be concatenated. This is a legitimate need for dynamic SQL, but the identifier must be validated against an **allow-list**, never passed through unchecked.

```sql
-- WRONG: even "just a column name" concatenated from user input is an injection point.
SET @sql = N'SELECT * FROM app.Tasks ORDER BY ' + @sortColumn;

-- RIGHT: validate against a known-safe allow-list before concatenating.
DECLARE @safeColumn SYSNAME =
    CASE @sortColumn
        WHEN N'Title'      THEN N'Title'
        WHEN N'DueDate'    THEN N'DueDate'
        WHEN N'CreatedAtUtc' THEN N'CreatedAtUtc'
        ELSE N'TaskId'                                    -- safe default if input doesn't match
    END;
SET @sql = N'SELECT * FROM app.Tasks ORDER BY ' + QUOTENAME(@safeColumn);
```

- **`LIKE` wildcard injection**: a user-supplied search term containing `%` or `_` changes the *meaning* of the pattern, even through a fully parameterised query — not a security hole, but a correctness one, fixed with `ESCAPE`.

```sql
SELECT * FROM app.Tasks WHERE Title LIKE @search ESCAPE '\';
-- @search built as: '%' + REPLACE(REPLACE(@userInput, '\', '\\'), '%', '\%') + '%'
```

- **Stored procedure parameters used to build further dynamic SQL inside the procedure** — parameterising the *call* to the procedure doesn't help if the procedure body itself concatenates that parameter into another string (§1's second-order pattern, one level removed).

- **`OPENQUERY`/linked servers**: string-built queries passed to a remote server carry the same risk, compounded by potentially different quoting/escaping rules on the far side.

---

## 4. Principle of Least Privilege

Database-level security is the layer that holds even if the application layer has a bug — defense in depth, not a replacement for parameterisation.

```sql
-- Application login: only what the API actually needs, nothing more.
CREATE LOGIN TaskFlowApiLogin WITH PASSWORD = N'<strong, rotated, vaulted secret>';
CREATE USER TaskFlowApiUser FOR LOGIN TaskFlowApiLogin;

-- Grant EXECUTE on the specific procedures the API calls -- not blanket table access.
GRANT EXECUTE ON app.usp_GetTasksByProject TO TaskFlowApiUser;
GRANT EXECUTE ON app.usp_CreateTask         TO TaskFlowApiUser;
-- No direct SELECT/INSERT/UPDATE/DELETE on app.Tasks granted to this user at all.
```

| Anti-pattern | Risk |
|---|---|
| Application connects as `sa`/`db_owner` | A single injected `DROP TABLE` or `xp_cmdshell` call has zero remaining barriers |
| One shared login for every environment (dev/staging/prod) | A dev-environment credential leak becomes a production breach |
| `GRANT ALL` "to make the error messages stop" | Removes the entire point of having permissions at all |
| Ad hoc scripts run as an admin account "just this once" | Normalises exactly the habit that turns a routine mistake into an incident |

**Roles** group permissions logically instead of granting them user-by-user:

```sql
CREATE ROLE role_taskflow_reader;
GRANT SELECT ON app.vw_OpenTasks TO role_taskflow_reader;      -- view, not the base table (Topic 14)
GRANT SELECT ON app.vw_UserDirectory TO role_taskflow_reader;  -- HourlyRate structurally excluded

ALTER ROLE role_taskflow_reader ADD MEMBER TaskFlowReportingUser;
```

> **Rule of thumb:** Grant permissions on **views and stored procedures**, not base tables, wherever the caller doesn't genuinely need arbitrary ad hoc query access. This is the same view-based security pattern from Topic 14, applied as a deliberate application-account design, not an afterthought.

---

## 5. Encryption

| Mechanism | Protects against | Protects data | Performance cost |
|---|---|---|---|
| **TDE** (Transparent Data Encryption) | Physical theft of backup/data files | At rest, on disk | Low — encryption happens at the I/O layer, transparent to queries |
| **Always Encrypted** | A compromised **database engine/DBA** seeing plaintext | In use, at rest, and in transit — the engine itself only ever sees ciphertext | Higher — limits what operations SQL Server can perform on the column server-side |
| **Column-level encryption** (`ENCRYPTBYKEY`) | Selective column protection, older/manual mechanism | At rest and in transit for that column | Requires explicit encrypt/decrypt calls in every query touching the column |
| **TLS/SSL (encrypted connections)** | Network eavesdropping between app and database | In transit only | Low |

```sql
-- Always Encrypted (illustrative -- actual setup requires client driver support and
-- key provisioning outside T-SQL itself, typically via SSMS wizard or PowerShell).
CREATE COLUMN MASTER KEY CMK_TaskFlow
WITH (KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
      KEY_PATH = N'CurrentUser/My/<thumbprint>');

-- A column protected this way is encrypted client-side before ever reaching the network --
-- SQL Server, its DBAs, and anyone with raw file/backup access see only ciphertext.
```

> **Rule of thumb:** TDE is close to a "turn it on, forget about it" baseline for any production database (protects stolen backups/disks). Always Encrypted is for specific columns where even a DBA or a compromised server process must never see plaintext — genuinely sensitive fields like SSNs or payment data, not blanket-applied to everything.

---

## 6. Dynamic Data Masking

Masks column values in query **results** for non-privileged users, without changing the stored data — a display-layer control, explicitly **not** a substitute for real access control or encryption.

```sql
ALTER TABLE app.Users ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE app.Users ALTER COLUMN HourlyRate ADD MASKED WITH (FUNCTION = 'random(50, 200)');

-- A user WITHOUT UNMASK permission sees:
SELECT Email, HourlyRate FROM app.Users;
-- eXXX@XXXX.com   |  137.42   (masked, randomised -- not the real value)

-- A user WITH UNMASK permission (or db_owner) sees the real values.
GRANT UNMASK TO role_taskflow_admin;
```

> **Anti-pattern:** Treating dynamic data masking as a security boundary on its own. A user with `SELECT` permission and enough T-SQL access can often infer or extract masked values through indirect queries (e.g. filtering `WHERE HourlyRate > 100` still works against the real underlying value even though the displayed value is masked) — it reduces **casual, accidental** over-exposure (a support engineer glancing at a query result), not a determined attacker who already has query access.

---

## 7. SQL Server Audit

```sql
CREATE SERVER AUDIT TaskFlow_Audit
TO FILE (FILEPATH = N'C:\SqlAudit\');
ALTER SERVER AUDIT TaskFlow_Audit WITH (STATE = ON);

CREATE DATABASE AUDIT SPECIFICATION TaskFlow_AuditSpec
FOR SERVER AUDIT TaskFlow_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON app.Users BY public)   -- audit every access to Users
WITH (STATE = ON);
```

Audits provide a tamper-evident record of who did what, independent of application-level logging — essential for compliance requirements (who viewed a specific user's `HourlyRate`, not just who changed it) that go beyond what `audit.TaskHistory`-style application tables typically capture.

---

## 8. Defense in Depth — The Layers Together

| Layer | Defends against | Topic |
|---|---|---|
| Parameterised queries / `sp_executesql` | SQL injection | This topic, Topic 15 |
| Least-privilege logins, roles, view/procedure-based grants | A compromised application account doing more damage than necessary | This topic, Topic 14, Topic 15 |
| `CHECK`/`FOREIGN KEY` constraints | Structurally invalid data, regardless of how it got written | Topic 11 |
| TDE / Always Encrypted / TLS | Data exposure at rest, in transit, or to a compromised engine process | This topic |
| Dynamic data masking | Casual over-exposure in query results | This topic |
| SQL Server Audit | Undetected unauthorized access, forensic reconstruction | This topic |

> **Rule of thumb:** No single layer here is sufficient alone. Parameterisation stops injection; it does nothing if the application's own login has `db_owner` and a genuinely different vulnerability (e.g. a business-logic flaw) lets an attacker run arbitrary approved-shaped queries anyway. Least privilege limits blast radius; it does nothing against a query that's perfectly well-formed but requests data the legitimate user shouldn't see, which is what masking and row-level security (Topic 14) are for.

---

## Mental Model

> SQL injection is not a database bug — it is what happens when untrusted data is allowed to become part of the SQL **language** instead of staying data, and the single, complete fix is parameterisation, because it is a different mechanism entirely, not better string-cleaning. Every place a value reaches a query is a fresh injection point, including values that were "already validated" upstream, values stored safely once and read back into a new dynamic string later, and identifiers like column names that parameters cannot represent at all and must instead be checked against an allow-list. Getting injection right buys you nothing if the application's own database login can do anything an attacker who compromises it might want — least privilege, roles scoped to views and procedures rather than base tables, is the layer that limits blast radius even after some other layer fails. And encryption, masking, and auditing each solve a narrower, specific problem — data at rest, casual over-exposure in results, and forensic accountability, respectively — none of them a substitute for the other, all of them assuming the injection layer underneath them is already solid.

Move to [Practice Problems](./Practice-Problems.md).
