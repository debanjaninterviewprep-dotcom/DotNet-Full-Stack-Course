# Topic 17 — Practice Solutions

This folder is your scratchpad for the seven exercises in [Practice-Problems.md](../Practice-Problems.md).

**Most files here need TWO (or three) query windows/connections open against `TaskFlowDb`
simultaneously** — concurrency bugs only show up when two things actually happen at once.
Each script clearly labels `-- SESSION A` / `-- SESSION B` blocks with interleaving instructions.

| File | Problem | Type |
|---|---|---|
| `P1-atomicity-rollback.sql` | P1 — Atomicity: proving a rollback undoes everything | T-SQL script |
| `P2-dirty-read.sql` | P2 — Reproducing a dirty read | T-SQL script (2 sessions) |
| `P3-non-repeatable-read.sql` | P3 — Non-repeatable read vs `REPEATABLE READ` | T-SQL script (2 sessions) |
| `P4-snapshot-update-conflict.sql` | P4 — Snapshot isolation and the update conflict | T-SQL script (2 sessions) |
| `P5-blocking.sql` | P5 — Observing and resolving blocking | T-SQL script (2-3 sessions) |
| `P6-deadlock.sql` | P6 — Reproducing and handling a deadlock | T-SQL script (2 sessions) |
| `P7-application-locks.sql` | P7 — Application-level locking with `sp_getapplock` | T-SQL script (2 sessions) |

## Conventions

- Every script starts with `USE TaskFlowDb; GO`.
- Every isolation-level or locking experiment resets its data changes and any database-level setting it changed (`ALLOW_SNAPSHOT_ISOLATION`, `READ_COMMITTED_SNAPSHOT`, etc.).
- Every deliberately-triggered error (dirty read observation, Msg 3960, Msg 1205, Msg 1222) is captured and explained as a comment, not just reproduced.

## Reset

```sql
-- Re-run any time to reset the sample data to its seeded state.
:r ..\..\01-Relational-Databases-and-SQL-Fundamentals\PracticeProblemsSolutions\00-create-taskflow-db.sql
```

When done, say **"check"** and I'll review against the rubric in [Practice-Problems.md](../Practice-Problems.md).
