# P8 — Integrity Design Review: TaskFlow Sprints

See [Practice-Problems.md](../Practice-Problems.md) P8 for the full requirement list (14 business
rules for `app.Sprints` / `app.SprintTasks`) and the rubric.

Companion file: [P8-sprints-ddl.sql](./P8-sprints-ddl.sql) — the runnable DDL, triggers, smoke
tests and rollback script referenced below.

## TODO: your review here

For each of the 14 rules, complete a row:

| # | Rule | Mechanism | Reason | Failure mode if wrong |
|---|------|-----------|--------|------------------------|
| 1 | A sprint always belongs to exactly one team. | | | |
| 2 | `SprintName` unique within a team; archived teams may reuse names. | | | |
| 3 | `EndDate` >= `StartDate`. | | | |
| 4 | Sprint length between 7 and 28 days. | | | |
| 5 | `IsClosed` defaults to false. | | | |
| 6 | Two open sprints for the same team must not overlap. | | | |
| 7 | A task may be in at most one OPEN sprint, but many closed ones. | | | |
| 8 | A task can only join a sprint belonging to its own project's team. | | | |
| 9 | `CommittedPoints`, when supplied, must be a Fibonacci number. | | | |
| 10 | Deleting a task removes it from all sprints. | | | |
| 11 | Deleting a team must not be possible while it has sprints. | | | |
| 12 | Closing a sprint is irreversible. | | | |
| 13 | Only a team lead may close a sprint. | | | |
| 14 | `Goal` is optional free text, max 500 characters. | | | |

## Portability Notes

- TODO: which choices would not survive a port to PostgreSQL / MySQL / Oracle, and what you'd use instead (e.g. `EXCLUDE` constraints for rule 6).

## Sign-off

- [ ] All 14 rules assigned a mechanism with reason and failure mode.
- [ ] Rules 13 and 14 correctly NOT implemented as constraints, with reasoning given.
- [ ] Portability section completed.
