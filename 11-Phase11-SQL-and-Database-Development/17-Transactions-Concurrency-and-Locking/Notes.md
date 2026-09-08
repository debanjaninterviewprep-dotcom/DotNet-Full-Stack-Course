# Topic 17: Transactions, Concurrency & Locking

> TaskFlow in production has hundreds of engineers hitting the same tables at once — two people updating the same task, a report running while a bulk import writes, a background job archiving old projects while someone reopens one. None of the SQL from Topics 1–16 said anything about what happens when two of these collide. This topic covers what a transaction actually guarantees, how SQL Server enforces isolation with locks (and what each isolation level trades away), the specific anomalies each level allows, and how to read, cause, and resolve blocking and deadlocks.

---

## 1. ACID, Concretely

| Property | Guarantee | TaskFlow example |
|---|---|---|
| **Atomicity** | All statements in a transaction succeed, or none do | Assigning a task and writing its audit row either both happen or neither does |
| **Consistency** | Every transaction leaves the database satisfying its constraints | A transaction can never commit a task referencing a deleted project |
| **Isolation** | Concurrent transactions don't see each other's uncommitted work (to a degree — see §3) | Two managers reassigning the same task don't corrupt each other's read |
| **Durability** | Once committed, the change survives a crash | A confirmed task creation is never silently lost after a server restart |

Every single statement is its **own implicit transaction** unless wrapped in an explicit one — this is why a bare `UPDATE` that hits a constraint violation rolls back completely (Topic 10 §7) without you writing `BEGIN TRANSACTION` at all.

```sql
USE TaskFlowDb;
GO

BEGIN TRANSACTION;
    UPDATE app.Tasks SET StatusId = 6 WHERE TaskId = 5;
    INSERT INTO audit.TaskHistory (TaskId, ColumnName, OldValue, NewValue)
    VALUES (5, N'StatusId', N'3', N'6');
COMMIT TRANSACTION;
-- Both statements committed together, or (on any error with XACT_ABORT ON) neither did.
```

---

## 2. Locks: What SQL Server Actually Takes

SQL Server enforces isolation primarily through **locks** — not through copying the whole database. Every lock has a **mode** and a **granularity**.

| Mode | Blocks | Typical cause |
|---|---|---|
| **S** (Shared) | Other `X` locks, not other `S` locks | An ordinary read under `READ COMMITTED`/`REPEATABLE READ` |
| **X** (Exclusive) | Everything else on the same resource | `INSERT`/`UPDATE`/`DELETE` |
| **U** (Update) | Other `U` and `X` locks, not `S` | The "about to update" phase — prevents two readers both upgrading to `X` and deadlocking each other |
| **IS/IX** (Intent Shared/Exclusive) | Nothing directly — signals "a lock exists at a finer granularity below this level" | Row/page-level locks propagate an intent lock up to the table |

| Granularity | Scope | Trade-off |
|---|---|---|
| Row (RID/key) | One row | Maximum concurrency, most memory/overhead per lock |
| Page | One 8 KB page | Middle ground |
| Table | Whole table | Minimum overhead, minimum concurrency |

```sql
SELECT
    tl.request_session_id AS SessionId,
    OBJECT_NAME(p.object_id) AS TableName,
    tl.resource_type, tl.request_mode, tl.request_status
FROM sys.dm_tran_locks AS tl
LEFT JOIN sys.partitions AS p ON p.hobt_id = tl.resource_associated_entity_id
WHERE tl.resource_database_id = DB_ID();
```

### Lock escalation

SQL Server automatically escalates row/page locks to a single table lock once a statement holds roughly **5,000** locks on one object — trading concurrency for memory efficiency. This is exactly why Topic 10 recommends batching large DML: a 500,000-row `UPDATE` in one statement will escalate to a table lock and block every other session on that table until it commits, while the same update run in 1,000-row batches never crosses the threshold.

---

## 3. Isolation Levels and the Anomalies They Allow

| Anomaly | Definition |
|---|---|
| **Dirty read** | Reading another transaction's **uncommitted** change, which might later roll back |
| **Non-repeatable read** | Re-reading the same row within one transaction and getting a **different value**, because another transaction committed a change in between |
| **Phantom read** | Re-running the same range query within one transaction and getting **different rows**, because another transaction inserted/deleted matching rows in between |

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Mechanism |
|---|---|---|---|---|
| **READ UNCOMMITTED** | Possible | Possible | Possible | No `S` locks taken on read; reads whatever is on the page, even uncommitted |
| **READ COMMITTED** *(default)* | Prevented | Possible | Possible | `S` lock held only for the instant of reading, then released |
| **REPEATABLE READ** | Prevented | Prevented | Possible | `S` locks held until end of transaction |
| **SERIALIZABLE** | Prevented | Prevented | Prevented | `S` locks (as range locks) held until end of transaction, blocking inserts into the read range too |
| **SNAPSHOT** | Prevented | Prevented | Prevented | No locks for reads at all — versioning instead (§4) |
| **READ COMMITTED SNAPSHOT (RCSI)** | Prevented | Possible | Possible | Statement-level versioning; a `READ COMMITTED`-shaped variant that adds no read locks |

```sql
-- Session A
BEGIN TRANSACTION;
UPDATE app.Tasks SET EstimatedHours = 99.00 WHERE TaskId = 1;   -- uncommitted, X lock held
-- (no COMMIT yet)

-- Session B, under READ UNCOMMITTED
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT EstimatedHours FROM app.Tasks WHERE TaskId = 1;   -- reads 99.00 -- a DIRTY READ
-- If Session A rolls back, Session B already acted on a value that never really existed.
```

> **Rule of thumb:** `READ UNCOMMITTED` (or the `WITH (NOLOCK)` hint) is not a free performance win — it's a correctness trade you must consciously accept. It is defensible for an approximate dashboard tolerant of momentarily-wrong numbers; it is never defensible for anything that drives a financial calculation, a business decision, or a write based on what was read.

---

## 4. Optimistic Concurrency: Snapshot Isolation and RCSI

Both use **row versioning** in tempdb instead of blocking readers against writers.

```sql
ALTER DATABASE TaskFlowDb SET READ_COMMITTED_SNAPSHOT ON;   -- changes the MEANING of the existing default
-- vs.
ALTER DATABASE TaskFlowDb SET ALLOW_SNAPSHOT_ISOLATION ON;  -- enables an OPT-IN isolation level
```

| | RCSI | SNAPSHOT |
|---|---|---|
| How enabled | Database option — changes what `READ COMMITTED` **means** database-wide | Database option to allow it, then each session opts in with `SET TRANSACTION ISOLATION LEVEL SNAPSHOT` |
| Consistency point | Each **statement** sees data as of that statement's start | The **whole transaction** sees data as of its first statement's start |
| Readers block writers | No | No |
| Writers block writers | Yes (still) | Yes, but see below |
| Write-write conflict handling | Last writer simply wins the row lock (ordinary blocking) | **Update conflict error** — the second transaction to try to commit a change to a row already changed by the first since its snapshot began is aborted |

```sql
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    -- ... reads a consistent view as of transaction start ...
    UPDATE app.Tasks SET PriorityId = 1 WHERE TaskId = 5;
COMMIT TRANSACTION;
-- If another SNAPSHOT transaction already committed a change to TaskId 5 since this one
-- began, this COMMIT fails with:
-- Msg 3960: Snapshot isolation transaction aborted due to update conflict.
```

> **Rule of thumb:** RCSI is close to a "free" upgrade for most OLTP workloads — readers no longer block writers or get blocked by them, at the cost of tempdb version-store space and slightly heavier row headers. `SNAPSHOT` is a stronger, opt-in guarantee for transactions that need a fully consistent multi-statement view, at the cost of needing to handle update-conflict retries in application code.

---

## 5. Blocking

Blocking is not a bug — it's a lock working correctly, just visible because it's taking a while. It becomes a problem when it's long, cascading, or masking a design issue.

```sql
-- Find who's blocking whom right now.
SELECT
    blocking.session_id AS BlockingSessionId,
    blocked.session_id  AS BlockedSessionId,
    blocked.wait_type, blocked.wait_time, blocked.wait_resource
FROM sys.dm_exec_requests AS blocked
JOIN sys.dm_exec_sessions AS blocking ON blocking.session_id = blocked.blocking_session_id
WHERE blocked.blocking_session_id <> 0;
```

Common causes and fixes:

| Cause | Fix |
|---|---|
| A long-running transaction holding locks (a report inside `BEGIN TRAN` that was never committed) | Keep transactions **short** — never wrap user-interactive waiting time inside an open transaction |
| A missing index forcing a scan that takes locks across far more rows/pages than necessary | Add the covering/seek-supporting index (Topic 13) |
| Lock escalation from a large unbatched DML statement | Batch it (Topic 10 §9) |
| An open transaction left uncommitted by a client that crashed mid-session | `KILL <session_id>` as an operational last resort, then fix the client-side bug |

`SET LOCK_TIMEOUT` bounds how long a session will wait for a lock before giving up with error 1222, rather than waiting indefinitely:

```sql
SET LOCK_TIMEOUT 5000;   -- milliseconds; give up after 5 seconds instead of waiting forever
```

---

## 6. Deadlocks

A deadlock is two (or more) sessions each holding a lock the other needs — a cycle with no possible resolution except aborting one of them. SQL Server detects this automatically (a background "deadlock monitor") and kills one session as the **deadlock victim**, rolling back its transaction with error 1205, so the other can proceed.

```sql
-- Session A                              -- Session B
BEGIN TRANSACTION;                        BEGIN TRANSACTION;
UPDATE app.Tasks SET ... WHERE TaskId=1;  UPDATE app.Projects SET ... WHERE ProjectId=1;
-- (holds X lock on Tasks row 1)          -- (holds X lock on Projects row 1)
UPDATE app.Projects SET ... WHERE ProjectId=1;  -- blocks, waiting on B
                                           UPDATE app.Tasks SET ... WHERE TaskId=1;  -- blocks, waiting on A
-- Neither can proceed. SQL Server picks one, rolls it back with Msg 1205,
-- and lets the other continue.
```

| Prevention technique | How it helps |
|---|---|
| **Consistent access order** | If every transaction always touches `Tasks` before `Projects` (never the reverse), the circular wait above cannot form |
| **Keep transactions short** | Less time holding locks means less opportunity to collide with another transaction's lock acquisition |
| **Lower isolation where safe** | RCSI removes read locks from the equation entirely, eliminating a whole category of reader/writer deadlocks |
| **Retry logic in application code** | A deadlock victim's transaction is fully rolled back and safe to simply retry — treat error 1205 as retryable, not fatal |
| **Enable trace flag / Extended Events for deadlock graphs** | `system_health` Extended Events session (on by default) captures deadlock graphs for post-incident analysis without any special setup |

```sql
-- Retryable pattern in application-adjacent T-SQL (or the equivalent in app code).
DECLARE @Retries INT = 0;
WHILE @Retries < 3
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- ... work ...
        COMMIT TRANSACTION;
        BREAK;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() = 1205
        BEGIN
            SET @Retries += 1;
            CONTINUE;                          -- retry the loop
        END;
        THROW;                                  -- any other error: propagate immediately
    END CATCH;
END;
```

---

## 7. Transaction Scope: Explicit, Implicit, Autocommit

| Mode | Behavior |
|---|---|
| **Autocommit** (default) | Every individual statement commits automatically unless wrapped in an explicit transaction |
| **Explicit** | `BEGIN TRANSACTION ... COMMIT/ROLLBACK` — you control the boundary |
| **Implicit** (`SET IMPLICIT_TRANSACTIONS ON`) | Any DML statement silently starts a transaction that must be explicitly committed — a legacy ODBC-era setting, easy to leave a transaction open by accident |

`@@TRANCOUNT` tracks nesting depth. **Nested transactions do not behave the way the name suggests** — an inner `COMMIT` does not actually commit anything until the outermost `COMMIT` runs (it only decrements `@@TRANCOUNT`), but an inner `ROLLBACK` rolls back **everything**, all the way to the outermost `BEGIN TRANSACTION`, regardless of nesting depth.

```sql
BEGIN TRANSACTION;              -- @@TRANCOUNT = 1
    BEGIN TRANSACTION;           -- @@TRANCOUNT = 2 (not a genuinely independent transaction)
        UPDATE app.Tasks SET PriorityId = 1 WHERE TaskId = 1;
    COMMIT TRANSACTION;          -- @@TRANCOUNT = 1 -- nothing durably committed yet
    ROLLBACK TRANSACTION;        -- rolls back the PriorityId change too, despite the inner COMMIT
```

> **Rule of thumb:** Treat "nested transactions" as a counter, not real nesting. Use **`SAVE TRANSACTION <name>`** and `ROLLBACK TRANSACTION <name>` for genuine partial-rollback points within one transaction — that is the actual mechanism for "undo just this part."

---

## 8. Locking Hints — Use Sparingly, Understand Fully

```sql
SELECT * FROM app.Tasks WITH (NOLOCK) WHERE ProjectId = 1;         -- allows dirty reads
SELECT * FROM app.Tasks WITH (READCOMMITTEDLOCK) WHERE TaskId = 1;  -- forces locking even under RCSI
SELECT * FROM app.Tasks WITH (ROWLOCK) WHERE TaskId = 1;            -- request row-level, resist escalation
SELECT * FROM app.Tasks WITH (UPDLOCK, HOLDLOCK) WHERE TaskId = 1;  -- the upsert-safe pattern (Topic 10)
```

| Hint | Effect | When it's legitimate |
|---|---|---|
| `NOLOCK` | No shared locks; allows dirty/inconsistent reads | Rarely — an approximate, non-critical dashboard, and even then RCSI is usually the better fix |
| `UPDLOCK` | Takes an update lock on read, preventing two readers from both later upgrading to `X` and colliding | The check-then-insert/update race guard (Topic 10) |
| `HOLDLOCK` | Equivalent to `SERIALIZABLE` for this table reference — locks persist to end of transaction, including the *absence* of rows | Paired with `UPDLOCK` for a race-safe existence check |
| `ROWLOCK` | Requests row-granularity, resisting escalation | Rare; usually the engine's default choice is already correct |
| `READPAST` | Skips locked rows instead of waiting — reads only what's immediately available | Queue-processing patterns where "skip what's currently taken" is the desired semantic |

> **Rule of thumb:** Every locking hint is a promise to the optimizer that you understand a specific trade-off better than its default choice. Reach for one only to solve a diagnosed, specific problem (Topic 10's upsert race, a queue-processing pattern) — never as a reflexive "make it faster" incantation.

---

## Mental Model

> A transaction's job is to make several statements behave as one atomic unit, and isolation is the promise about what a *concurrent* transaction is allowed to see while that unit is still in flight — SQL Server keeps that promise with locks by default, escalating from row to table once a statement holds enough of them, and the isolation level you choose is literally a choice about which of three well-named anomalies (dirty, non-repeatable, phantom) you're willing to tolerate in exchange for less blocking. `READ COMMITTED` is the default because it's a reasonable middle ground; `RCSI` and `SNAPSHOT` sidestep the whole reader-vs-writer trade-off using row versioning instead of locks, at the cost of tempdb space and, for `SNAPSHOT`, an update-conflict error you must be prepared to retry. Blocking is locks working as designed, visible only because it's slow — the fixes are the same three things every time: shorter transactions, better indexes, and batched DML. A deadlock is the one scenario locks cannot resolve on their own, so the engine breaks the cycle by force, and the only real defenses are consistent access ordering, short transactions, and application code that treats error 1205 as retryable rather than fatal. Locking hints exist for the moments the default isn't right — but every one of them is a deliberate override of the engine's own reasoning, and should be used exactly as sparingly as that implies.

Move to [Practice Problems](./Practice-Problems.md).
