# P5 — Surrogate vs Natural Key Decision Table

See [Practice-Problems.md](../Practice-Problems.md) P5 for the full requirement list.
DDL companion: [P5-surrogate-vs-natural.sql](./P5-surrogate-vs-natural.sql).

## TODO: your decision table here (at least 5 rows)

| Scenario | Recommended key | Why | Why not the alternatives |
|---|---|---|---|
| High-write-volume child table (e.g. `app.TimeEntries`) | | | |
| Distributed/merge scenario (data generated offline, merged later) | | | |
| Small, closed reference list (e.g. `ref.TaskStatuses`) | | | |
| Security-sensitive external identifier (e.g. an API key) | | | |
| General OLTP table, single database, high read volume | | | |
