# Topic 17: Transactions, Concurrency & Locking — Practice Problems

> Seven exercises that require **two query windows/sessions** open simultaneously for most of them — concurrency bugs only show up when two things actually happen at once. All against the seeded `TaskFlowDb`.

**Concept tags:** `transactions` `locks` `isolation-levels` `dirty-read` `non-repeatable-read` `phantom-read` `snapshot-isolation` `rcsi` `blocking` `deadlocks` `sp_getapplock`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
-- Most problems below need TWO separate connections/query windows (Session A / Session B),
-- run in the interleaved order shown. Note your session_id (SELECT @@SPID;) in each.
```

---

## P1 — Atomicity: Proving a Rollback Undoes Everything  *(Easy)*

**Tags:** `transactions` `atomicity` `rollback`

### Requirements

1. In one transaction, update a task's `StatusId` and insert a matching `audit.TaskHistory` row.
2. Force an error partway through (e.g. a deliberately invalid third statement) and confirm, via `XACT_STATE()`/a follow-up `SELECT`, that **neither** the status change nor the audit insert persisted after `ROLLBACK`.
3. Repeat without the forced error, `COMMIT` instead, and confirm both changes now persist.
4. Roll back the successful version too, to leave the database in its seeded state, and explain in a comment why this is safe to do even after a `COMMIT` (hint: it isn't — explain what you'd actually need to do instead, and do that).

### Deliverable

`P1-atomicity-rollback.sql`.

### Hints

- Step 4 is a trick: you cannot "roll back" an already-committed transaction. Use a second transaction to reverse the change, or simply re-run the create script.

### Look-fors (rubric)

- [ ] The forced-error version correctly leaves both the status and the audit row unchanged.
- [ ] The committed version correctly persists both changes.
- [ ] Step 4 correctly identifies that a completed `COMMIT` cannot be undone by a `ROLLBACK`, and uses a compensating transaction (or a database reset) instead.

---

## P2 — Reproducing a Dirty Read  *(Medium — requires two sessions)*

**Tags:** `dirty-read` `read-uncommitted` `nolock`

### Requirements

1. **Session A:** `BEGIN TRANSACTION;` then update `app.Tasks.EstimatedHours` for `TaskId = 1` to `999.00` — do **not** commit yet.
2. **Session B:** `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` then `SELECT EstimatedHours FROM app.Tasks WHERE TaskId = 1;` — record what it sees.
3. **Session A:** `ROLLBACK TRANSACTION;`.
4. **Session B:** re-run the same `SELECT` and compare — explain what just happened to the value Session B "saw" in step 2.
5. Repeat steps 1–4 with Session B under the **default** (`READ COMMITTED`) isolation level instead, and confirm Session B now **blocks** during step 2 until Session A finishes, rather than reading a dirty value.

### Deliverable

`P2-dirty-read.sql` containing both sessions' statements clearly labelled (`-- SESSION A` / `-- SESSION B`) with instructions for interleaving them, plus your observations as comments.

### Hints

- You'll need two query windows/connections open against `TaskFlowDb` at the same time to actually interleave these statements.

### Look-fors (rubric)

- [ ] The `READ UNCOMMITTED` session is shown reading the uncommitted `999.00` value.
- [ ] The explanation correctly identifies this as a dirty read and explains why it's dangerous (the value never really existed).
- [ ] The `READ COMMITTED` repeat is shown blocking instead of reading dirty data.

---

## P3 — Non-Repeatable Read vs `REPEATABLE READ`  *(Medium — requires two sessions)*

**Tags:** `non-repeatable-read` `repeatable-read` `s-locks`

### Requirements

1. **Session A:** under default isolation, `BEGIN TRANSACTION;` then `SELECT EstimatedHours FROM app.Tasks WHERE TaskId = 1;` — record the value, do **not** commit or read again yet.
2. **Session B:** update and commit a change to that same row's `EstimatedHours`.
3. **Session A:** re-run the identical `SELECT` within the same still-open transaction and observe the value has changed — a non-repeatable read. Commit/rollback Session A.
4. Repeat the whole scenario with Session A instead using `SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;`, and confirm Session B now **blocks** on its update until Session A's transaction ends.
5. Explain, in a comment, the specific lock-duration difference between `READ COMMITTED` and `REPEATABLE READ` that causes this.

### Deliverable

`P3-non-repeatable-read.sql`, both sessions clearly labelled.

### Hints

- Remember to reset `TaskId = 1`'s `EstimatedHours` back to its seeded value (24.00) afterward.

### Look-fors (rubric)

- [ ] The default-isolation case correctly shows the value changing between the two reads within one transaction.
- [ ] The `REPEATABLE READ` case correctly shows Session B blocking instead.
- [ ] The lock-duration explanation is accurate (held until end of transaction vs released after the read).

---

## P4 — Snapshot Isolation and the Update Conflict  *(Hard — requires two sessions)*

**Tags:** `snapshot-isolation` `update-conflict` `msg-3960`

### Requirements

1. Enable snapshot isolation on `TaskFlowDb` (`ALTER DATABASE ... SET ALLOW_SNAPSHOT_ISOLATION ON;`).
2. **Session A:** `SET TRANSACTION ISOLATION LEVEL SNAPSHOT; BEGIN TRANSACTION;` then read `app.Tasks` for `TaskId = 6`.
3. **Session B:** under `READ COMMITTED`, update and commit a change to the **same row** (`TaskId = 6`).
4. **Session A:** attempt to update that same row within its still-open snapshot transaction, and capture the exact **Msg 3960** update-conflict error.
5. Explain, in a comment, why this conflict happens under `SNAPSHOT` but would **not** happen the same way under plain `READ COMMITTED` (where the second writer would simply block, then overwrite, with no error at all).
6. Reset `TaskId = 6` to its seeded values; disable snapshot isolation if you don't need it for later problems.

### Deliverable

`P4-snapshot-update-conflict.sql`, both sessions clearly labelled.

### Hints

- The conflict only fires on Session A's `COMMIT` (or the conflicting write attempt, depending on exact timing) — read the exact error text carefully.

### Look-fors (rubric)

- [ ] Msg 3960 is correctly reproduced and quoted verbatim.
- [ ] The explanation correctly contrasts "conflict + abort" (`SNAPSHOT`) against "silent last-writer-wins blocking" (`READ COMMITTED`).
- [ ] All data and database-level settings are reset at the end.

---

## P5 — Observing and Resolving Blocking  *(Medium — requires two sessions)*

**Tags:** `blocking` `sys-dm-exec-requests` `lock-timeout`

### Requirements

1. **Session A:** `BEGIN TRANSACTION;` then update a row in `app.Tasks` — do not commit.
2. **Session B:** attempt to update the **same row**, and confirm it blocks (hangs) rather than erroring immediately.
3. From a **third** session/window, query `sys.dm_exec_requests` joined to `sys.dm_exec_sessions` to identify the blocking/blocked session pair, and report the `wait_type` and `wait_resource`.
4. Commit or roll back Session A, and confirm Session B's statement then completes.
5. Repeat the scenario, but this time set `SET LOCK_TIMEOUT 2000;` in Session B beforehand, and confirm it now fails with error 1222 after ~2 seconds instead of waiting indefinitely.

### Deliverable

`P5-blocking.sql`, all sessions clearly labelled, plus the DMV query and its captured output as comments.

### Hints

- You'll genuinely need a third connection to run the diagnostic query while the other two are mid-block.

### Look-fors (rubric)

- [ ] The block is correctly reproduced and diagnosed via the DMV query with the correct session IDs identified.
- [ ] Committing/rolling back Session A is shown unblocking Session B.
- [ ] The `LOCK_TIMEOUT` version correctly fails with error 1222 instead of waiting.

---

## P6 — Reproducing and Handling a Deadlock  *(Hard — requires two sessions)*

**Tags:** `deadlocks` `msg-1205` `retry-logic` `access-order`

### Requirements

1. Reproduce the classic reverse-order deadlock from Notes.md §6: Session A updates a `Tasks` row then attempts a `Projects` row; Session B updates the same `Projects` row then attempts the same `Tasks` row, interleaved so each blocks on the other.
2. Confirm SQL Server picks one session as the deadlock victim with error **1205**, and that the other session's statement completes once the deadlock is detected.
3. Rewrite both sessions to access `Tasks` before `Projects` in **every** case (consistent ordering) and confirm the deadlock no longer occurs under the same interleaving.
4. Wrap the original (reverse-order) scenario's transaction logic in the retry pattern from Notes.md §6 (`TRY/CATCH` checking `ERROR_NUMBER() = 1205`) and demonstrate it successfully completes after a retry, without you needing to manually resolve anything.
5. Reset all data changes.

### Deliverable

`P6-deadlock.sql`, both sessions clearly labelled with the exact interleaving instructions (which statement to run in which session, in which order) needed to reliably reproduce the deadlock.

### Hints

- Reliable reproduction requires precise interleaving — document the exact step-by-step order a reader must follow across the two windows.

### Look-fors (rubric)

- [ ] The deadlock is genuinely reproduced with error 1205 captured.
- [ ] The consistent-ordering fix is shown to prevent the deadlock under the same interleaving attempt.
- [ ] The retry-logic version is shown succeeding after encountering and recovering from the deadlock.
- [ ] All data changes are reset.

---

## P7 — Application-Level Locking with `sp_getapplock`  *(Hard)*

**Tags:** `sp_getapplock` `application-locks` `serialization`

### Requirements

TaskFlow needs to ensure only one "close sprint" operation can run at a time for a given team, even though no single row directly represents "a sprint close is in progress."

1. Research `sp_getapplock`/`sp_releaseapplock` and explain, in a comment, what problem they solve that ordinary row/table locks cannot (locking a *concept*, not a *row*).
2. Write a stored procedure `app.usp_CloseSprintForTeam (@TeamId INT)` that acquires an exclusive application lock scoped to a resource string derived from `@TeamId` (e.g. `N'CloseSprint:' + CAST(@TeamId AS NVARCHAR(10))`) before doing its (placeholder) work, and releases it afterward.
3. From two sessions, call the procedure for the **same** `@TeamId` concurrently and demonstrate the second call waits for the first to release the lock.
4. Call it for two **different** `@TeamId` values concurrently and confirm neither blocks the other.
5. Drop the procedure at the end.

### Deliverable

`P7-application-locks.sql`.

### Hints

- `@LockMode = 'Exclusive'`, `@LockOwner = 'Transaction'` is the standard combination — the lock releases automatically at `COMMIT`/`ROLLBACK` if owned by the transaction.

### Look-fors (rubric)

- [ ] The explanation correctly identifies the "no row represents this concept" problem application locks solve.
- [ ] The same-`@TeamId` concurrent test correctly shows serialization (the second call waits).
- [ ] The different-`@TeamId` test correctly shows no blocking between them.
- [ ] The procedure is dropped at the end.

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven deliverables exist in `PracticeProblemsSolutions/` and clearly document which statements belong to which session and in what order.
- [ ] Every isolation-level/locking experiment resets its data changes and any database-level setting it changed.
- [ ] Every deliberately-triggered error (dirty read observation, Msg 3960, Msg 1205, Msg 1222) is captured and explained, not just reproduced.
- [ ] `README.md` in the solutions folder lists what each file is and reminds the reader that most files need two query windows.

---

## Stretch Goals

- Enable RCSI (`READ_COMMITTED_SNAPSHOT ON`) instead of plain snapshot isolation, and repeat P2/P3 to confirm dirty reads and non-repeatable reads behave differently under RCSI than under default `READ COMMITTED`.
- Capture an actual deadlock graph (via Extended Events' `system_health` session, which is on by default) from P6's reproduction, and annotate which XML element corresponds to which session's lock/wait.
- Investigate `sys.dm_db_index_operational_stats` for row-lock/page-lock wait counts on `app.Tasks` and correlate a spike with a specific workload you generate (e.g. many concurrent updates to the same few rows).
