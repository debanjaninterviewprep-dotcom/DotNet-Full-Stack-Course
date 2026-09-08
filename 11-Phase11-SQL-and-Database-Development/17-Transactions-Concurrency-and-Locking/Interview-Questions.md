# Topic 17: Transactions, Concurrency & Locking — Interview Questions

---

## Q1. What do the four ACID properties guarantee, in plain terms?
**Answer:**
**Atomicity** — every statement in a transaction commits, or none do. **Consistency** — a transaction can never leave the database violating its own constraints. **Isolation** — concurrent transactions don't see each other's uncommitted changes (to a degree defined by the isolation level). **Durability** — once committed, a change survives a crash. Every individual statement is its own implicit transaction unless wrapped in an explicit `BEGIN TRANSACTION`, which is why a single `UPDATE` that violates a constraint rolls back completely on its own.

---

## Q2. Name the three classic concurrency anomalies and define each.
**Answer:**
**Dirty read** — reading another transaction's uncommitted change, which might later roll back. **Non-repeatable read** — re-reading the same row within one transaction and getting a different value because another transaction committed a change in between. **Phantom read** — re-running the same range query within one transaction and getting different rows because another transaction inserted/deleted matching rows in between.

---

## Q3. What is SQL Server's default isolation level, and which anomalies does it prevent versus allow?
**Answer:**
`READ COMMITTED` is the default. It prevents **dirty reads** (a shared lock is required to read a row, so you can never see another transaction's uncommitted `X`-locked change) but allows both **non-repeatable reads** and **phantom reads**, because the shared lock is released immediately after each individual read rather than held until the transaction ends.

---

## Q4. What's the difference between `REPEATABLE READ` and `SERIALIZABLE`?
**Answer:**
Both hold shared locks until the end of the transaction, preventing non-repeatable reads. `SERIALIZABLE` additionally takes **range locks**, which also block a second transaction from **inserting new rows** that would match the first transaction's earlier range query — preventing phantom reads too. `REPEATABLE READ` alone does not protect against phantoms, since it only locks the rows it already read, not the "gaps" a new matching row could appear in.

---

## Q5. What is Read Committed Snapshot Isolation (RCSI), and how does it differ from ordinary `READ COMMITTED`?
**Answer:**
RCSI is a database-level option (`ALTER DATABASE ... SET READ_COMMITTED_SNAPSHOT ON`) that changes what `READ COMMITTED` **means** for that database: instead of taking a shared lock for each read (which can block on a concurrent writer), readers see a **versioned** snapshot of the row as of the start of their statement, maintained via row versions in tempdb. The practical effect: readers no longer block writers, and writers no longer block readers — at the cost of tempdb version-store space.

---

## Q6. What is `SNAPSHOT` isolation, and what happens on a write-write conflict?
**Answer:**
An opt-in isolation level (`SET TRANSACTION ISOLATION LEVEL SNAPSHOT`) where the **entire transaction** sees a consistent view of the database as of its first statement's start, using row versioning rather than locks for reads. If a second `SNAPSHOT` transaction tries to commit a change to a row that another transaction has already modified and committed since the first transaction's snapshot began, the second one fails with:

```
Msg 3960: Snapshot isolation transaction aborted due to update conflict.
```

Unlike ordinary blocking (where the second writer simply waits, then silently overwrites), `SNAPSHOT` surfaces the conflict as an explicit, retryable error — application code using `SNAPSHOT` must be prepared to catch and retry this.

---

## Q7. Is blocking a bug?
**Answer:**
No — blocking is a lock working exactly as designed, made visible only because it's taking a noticeable amount of time. It becomes an operational problem when it's excessively long, cascades across many sessions, or reveals an underlying design issue (a long-running transaction holding locks unnecessarily, a missing index forcing an overly broad scan-and-lock, or an unbatched DML statement triggering lock escalation).

---

## Q8. What is lock escalation, and why does it matter for large DML operations?
**Answer:**
SQL Server automatically converts many row/page locks on one object into a single table lock once a statement holds roughly 5,000 locks, trading concurrency for memory efficiency. A large, unbatched `UPDATE`/`DELETE` will escalate to a table lock, blocking every other session against that table until the statement commits — which is exactly why large operations should be run in smaller batches (Topic 10), keeping each batch's lock count under the escalation threshold.

---

## Q9. What is a deadlock, and how does SQL Server resolve one?
**Answer:**
Two or more sessions each hold a lock the other needs, forming a cycle with no possible resolution by waiting. SQL Server's deadlock monitor detects the cycle automatically and picks one session as the **deadlock victim**, rolling back its entire transaction with error **1205**, allowing the other session(s) to proceed. Unlike ordinary blocking, a deadlock will never resolve on its own without this intervention.

---

## Q10. What are three concrete ways to prevent deadlocks?
**Answer:**
**Consistent access order** — if every transaction always touches table A before table B (never the reverse), the circular wait pattern that causes a deadlock cannot form. **Short transactions** — less time holding locks means less chance of colliding with another transaction's lock acquisition. **Lower isolation where safe** — RCSI removes read locks from the picture entirely, eliminating an entire category of reader/writer deadlocks. Application-level retry logic (treating error 1205 as retryable) is also essential, since even with these mitigations, a deadlock can still occasionally occur under real concurrent load.

---

## Q11. Why do "nested transactions" not behave the way the name implies?
**Answer:**
`@@TRANCOUNT` is a **counter**, not a stack of independent transactions. An inner `COMMIT TRANSACTION` merely decrements the counter — nothing is durably committed until the count reaches zero (the outermost `COMMIT`). But an inner `ROLLBACK TRANSACTION` rolls back **everything**, all the way to the outermost `BEGIN TRANSACTION`, regardless of nesting depth. For a genuine partial-rollback point within a single transaction, use `SAVE TRANSACTION <name>` and `ROLLBACK TRANSACTION <name>` instead.

---

## Q12. What does the `UPDLOCK, HOLDLOCK` hint combination do, and when would you use it?
**Answer:**
`UPDLOCK` takes an update lock at read time, preventing two sessions from both reading the same row and later attempting to upgrade to an exclusive lock simultaneously (which would otherwise deadlock or race). `HOLDLOCK` is equivalent to `SERIALIZABLE` for that specific table reference, holding the lock until the end of the transaction and covering the *absence* of a row as well as its presence. Together, they are the standard pattern for a race-safe "check if a row exists, then insert if not" upsert (Topic 10):

```sql
IF NOT EXISTS (SELECT 1 FROM app.Labels WITH (UPDLOCK, HOLDLOCK) WHERE LabelName = N'x')
    INSERT INTO app.Labels (LabelName) VALUES (N'x');
```

---

## Q13. Why is `WITH (NOLOCK)` risky, and when (if ever) is it acceptable?
**Answer:**
`NOLOCK` (equivalent to reading under `READ UNCOMMITTED`) takes no shared locks at all, allowing dirty reads — you might read a value another transaction is about to roll back, or in some cases even encounter more subtle issues like reading a row twice or missing it entirely during a page split. It is defensible only for a genuinely approximate, non-critical read (e.g. a rough dashboard tolerant of momentarily-inconsistent numbers) — never for anything that drives a financial calculation, a business decision, or a subsequent write. In most cases where `NOLOCK` is reached for as a performance fix, RCSI is the better solution, since it removes the same blocking without sacrificing read consistency.

---

## Q14. What is `sp_getapplock` used for, and how is it different from an ordinary row or table lock?
**Answer:**
It creates a named, application-defined lock on an arbitrary string resource — not tied to any specific row or table — used to serialize access to a *concept* that has no direct row representation. For example, ensuring only one "close this sprint for this team" operation runs at a time, even though no single row in the schema represents "a sprint-close is currently in progress" for locking purposes:

```sql
EXEC sp_getapplock @Resource = N'CloseSprint:5', @LockMode = 'Exclusive', @LockOwner = 'Transaction';
```

The lock is released automatically at `COMMIT`/`ROLLBACK` when `@LockOwner = 'Transaction'`.

---

## Q15. Design question: a background job processes a queue table by selecting unprocessed rows, and you need to support multiple worker instances running concurrently without two workers picking up the same row. How would you design this using concepts from this topic?
**Answer:**
The core pattern combines `UPDLOCK` with `READPAST`:

```sql
UPDATE TOP (10) q
SET q.Status = N'Processing', q.ClaimedBy = @WorkerId
OUTPUT INSERTED.QueueId
FROM app.Queue AS q WITH (UPDLOCK, READPAST)
WHERE q.Status = N'Pending';
```

`UPDLOCK` claims each row as it's read so a second concurrent worker can't select the same row before the first worker's `UPDATE` commits. `READPAST` tells a second worker running the identical query to **skip** any row currently locked by another worker instead of blocking and waiting for it — so multiple workers each grab a distinct batch of rows and proceed in parallel, rather than serializing behind each other. This is a standard high-throughput queue-processing pattern and a legitimate, narrow use case for `READPAST`, distinct from the general "avoid locking hints" guidance elsewhere in this topic.
