# Topic 09: Window Functions — Practice Problems

> Seven exercises moving from ranking ties through frames to the classic recipes — gaps-and-islands, sessionisation, running balances. All against the seeded `TaskFlowDb`.

**Concept tags:** `row_number` `rank` `dense_rank` `ntile` `frames` `lag-lead` `first-value-last-value` `top-n-per-group` `gaps-and-islands` `poc-index`

**Setup:**
```sql
-- One-time: create the shared sample database
--   sqlcmd -S localhost -U sa -P "<pwd>" -i ../../01-Relational-Databases-and-SQL-Fundamentals/PracticeProblemsSolutions/00-create-taskflow-db.sql
USE TaskFlowDb;
GO
```

---

## P1 — Ranking Functions Side by Side  *(Easy)*

**Tags:** `row_number` `rank` `dense_rank` `ntile` `ties`

### Requirements

1. For project 1's tasks, compute `ROW_NUMBER`, `RANK`, `DENSE_RANK` and `NTILE(3)`, all ordered by `EstimatedHours DESC`.
2. Identify the tied pair (tasks 34 and 6, both 8.00 hours) and explain in a comment how each of the four functions treats the tie differently.
3. Re-run `ROW_NUMBER` twice and confirm (or refute) that the tied pair's order is stable across runs. Add a tie-breaker column (`, t.TaskId`) and explain why that makes the result deterministic.
4. State in a comment: which function would you use for "top 3 distinct estimate sizes" versus "top 3 tasks"?

### Deliverable

`P1-ranking-functions.sql`.

### Hints

- NULL `EstimatedHours` (task 8) sorts last on `DESC` — confirm where it lands in each ranking.

### Look-fors (rubric)

- [ ] All four functions are computed in one query, side by side.
- [ ] The tie explanation correctly distinguishes "skips" (`RANK`) from "no skip" (`DENSE_RANK`) from "arbitrary" (`ROW_NUMBER`) from "by count, not value" (`NTILE`).
- [ ] The deterministic tie-breaker version is included and justified.

---

## P2 — Percent of Total and the Integer-Division Trap  *(Easy)*

**Tags:** `aggregate-window` `percent-of-total` `integer-division`

### Requirements

1. For every task in project 4, compute its `EstimatedHours`, the project total via `SUM(...) OVER (PARTITION BY ProjectId)`, and its percentage of the project total.
2. Deliberately write the percentage calculation without the `100.0 *` trick and show the (wrong) result.
3. Fix it and confirm the four rows sum to 100.0%.
4. Using `COUNT(*) OVER (...)` and `COUNT(EstimatedHours) OVER (...)` side by side on the whole `Tasks` table (partitioned by `ProjectId`), find every project where the two counts differ, and explain what that difference means.

### Deliverable

`P2-percent-of-total.sql`.

### Hints

- `100.0 *` forces the multiplication to decimal before the division happens.

### Look-fors (rubric)

- [ ] The broken integer-division version is kept as a commented block showing the wrong output.
- [ ] The four percentages for project 4 sum to (very close to) 100.0.
- [ ] The `COUNT(*)` vs `COUNT(col)` difference is correctly attributed to NULL `EstimatedHours` rows.

---

## P3 — Running Totals and the Default-Frame Trap  *(Medium)*

**Tags:** `frames` `rows-vs-range` `running-total`

### Requirements

1. Compute a running total of `EstimatedHours` for project 1's tasks (ordered `DESC`) using **no explicit frame** (i.e., relying on the default).
2. Compute the same running total with an explicit `ROWS UNBOUNDED PRECEDING` frame.
3. Identify the row(s) where the two running totals diverge, and explain — referencing peers/ties — exactly why.
4. State the rule for when `RANGE`'s peer-inclusive behavior is actually desirable, versus when it is a bug waiting to happen.

### Deliverable

`P3-frames-and-running-totals.sql`.

### Hints

- The divergence appears exactly at the tied 8.00-hour pair (tasks 34 and 6).

### Look-fors (rubric)

- [ ] Both running-total columns are computed in the same query for direct comparison.
- [ ] The divergence is correctly attributed to `RANGE`'s peer-grouping behavior on tied `ORDER BY` values, not to a computation error.
- [ ] The "when RANGE is desirable" answer names a real scenario (e.g. percentile/cumulative-distribution reporting).

---

## P4 — `LAG`/`LEAD` and the `LAST_VALUE` Trap  *(Medium)*

**Tags:** `lag` `lead` `first-value` `last-value` `frame-aware`

### Requirements

1. For Ken Thompson's (`UserId` 7) time entries, compute `PrevHours` (`LAG`), `NextDate` (`LEAD`), and `DaysSincePrev` (`DATEDIFF` combined with `LAG`).
2. For project 2's tasks ordered by `CreatedAtUtc`, compute `FIRST_VALUE(TaskId)` and `LAST_VALUE(TaskId)` **without** an explicit frame, and observe that `LAST_VALUE` just echoes the current row's own `TaskId`.
3. Fix `LAST_VALUE` with `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` and confirm every row now shows the same, correct last task.
4. Explain in a comment why `FIRST_VALUE` "worked" in step 2 even without an explicit frame, while `LAST_VALUE` did not.

### Deliverable

`P4-lag-lead-first-last.sql`.

### Hints

- The default frame ends at `CURRENT ROW` — that is the entire bug.

### Look-fors (rubric)

- [ ] `LAG`/`LEAD` results are correct and match the Notes.md worked example shape.
- [ ] The broken `LAST_VALUE` output is shown and is visibly wrong (echoing the current row).
- [ ] The fixed version returns the same final-task value on every row of the partition.

---

## P5 — Top-N Per Group and Deduplication  *(Medium)*

**Tags:** `row_number` `top-n-per-group` `deduplication` `cte`

### Requirements

1. Using `ROW_NUMBER`, return the 2 most recently created tasks per project (16 rows total across 8 projects).
2. Load the same 16 rows into a `#temp` table, then deliberately duplicate 3 of the rows (re-insert them) to simulate a bad import.
3. Write a `ROW_NUMBER`-based `DELETE` (via a CTE) that removes the duplicates, keeping exactly one copy of each. Verify the `#temp` table is back to 16 rows.
4. Explain, in a comment, why you must `SELECT` the `ROW_NUMBER` result first and inspect it before running the `DELETE`.

### Deliverable

`P5-topn-and-dedup.sql`.

### Hints

- `PARTITION BY` should list every column that defines "the same row" for dedup purposes.
- You can `DELETE FROM <cte-name> WHERE rn > 1` directly.

### Look-fors (rubric)

- [ ] Top-N query correctly returns exactly 2 rows per project (16 total).
- [ ] The dedup `DELETE` removes exactly the 3 injected duplicates, no more, no less.
- [ ] The "verify before delete" reasoning is explicit, not just asserted.

---

## P6 — Gaps and Islands: Consecutive Work-Day Streaks  *(Hard)*

**Tags:** `gaps-and-islands` `row_number` `date-arithmetic`

### Requirements

1. For every user, find every consecutive run ("island") of calendar days on which they logged time in `app.TimeEntries`, using the `value − ROW_NUMBER()` trick.
2. Confirm Dennis Ritchie (`UserId` 8) produces three separate islands.
3. Extend the query to report `StreakStart`, `StreakEnd`, and `COUNT(*) AS Days_` for every user's islands, ordered by streak length descending.
4. Explain, in a comment, why the initial `DISTINCT` over `(UserId, WorkDate)` is necessary before the arithmetic trick works.

### Deliverable

`P6-gaps-and-islands.sql`.

### Hints

- `DATEADD(DAY, -ROW_NUMBER() OVER (...), WorkDate)` is constant within a consecutive run.

### Look-fors (rubric)

- [ ] Dennis Ritchie's three islands are correctly identified with matching start/end dates.
- [ ] The general query works for every user, not just one hard-coded case.
- [ ] The `DISTINCT` requirement is correctly explained (duplicate same-day entries would break the row-number arithmetic).

---

## P7 — Sessionisation and a POC Index  *(Hard)*

**Tags:** `sessionisation` `lag` `poc-index` `execution-plan`

### Requirements

1. Using `LAG` and a 60-minute gap rule, flag each comment on a task as starting a new "session" or continuing the previous one.
2. Turn the flag into a running `SessionNo` per task using a windowed `SUM`.
3. Confirm task 1's two comments form one session (22 minutes apart) and task 20's two comments form two sessions (90 minutes apart).
4. Design and create a POC (Partition, Order, Covering) index to support a `ROW_NUMBER() OVER (PARTITION BY ProjectId ORDER BY CreatedAtUtc DESC)` query selecting `TaskId` and `Title`. Compare the actual execution plan before and after the index exists, and note which operator disappears.

### Deliverable

`P7-sessionisation-and-poc-index.sql`.

### Hints

- The first row of every partition has a NULL `LAG` result — confirm your `CASE` expression still opens a session correctly on that row (three-valued logic strikes again).
- `INCLUDE` the columns the query selects but does not filter/order by.

### Look-fors (rubric)

- [ ] Sessionisation correctly reproduces the 1-session/2-session split described above.
- [ ] The first-row NULL-`LAG` edge case is explicitly addressed, not accidentally correct.
- [ ] The POC index is defined with correct column order (partition, then order, then `INCLUDE`).
- [ ] Before/after plan comparison names the specific operator removed (the `Sort`).

---

## Submission Checklist

Before marking this topic complete, ensure:

- [ ] All seven `.sql` files exist in `PracticeProblemsSolutions/` and run end-to-end against a freshly created `TaskFlowDb`.
- [ ] Every "broken" version kept for comparison (P2, P3, P4) is clearly labelled as such in a comment.
- [ ] No window function appears in a `WHERE`/`HAVING` clause anywhere in your solutions — always wrapped in a CTE/derived table.
- [ ] `README.md` in the solutions folder lists what each file is.

---

## Stretch Goals

- Rewrite P6's gaps-and-islands query to also report the **longest gap** (in days) between any user's streaks, not just the streaks themselves.
- Investigate the `WINDOW` clause (SQL Server 2022+) and rewrite P7 to share one named window across `LAG`, the session flag, and the running `SUM`.
- Use `SET STATISTICS TIME ON` to measure P7's query before and after the POC index on a larger synthetic dataset (generate ~100,000 rows via a cross-joined `VALUES` number series from Topic 07) and record the actual wall-clock difference.
