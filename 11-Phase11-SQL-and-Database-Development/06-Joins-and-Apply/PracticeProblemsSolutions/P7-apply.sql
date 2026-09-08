/*=============================================================================
  Topic 06 — Joins & APPLY
  P7 — CROSS APPLY and OUTER APPLY                                    (Hard)
  -----------------------------------------------------------------------------
  Tags: cross-apply | outer-apply | top-n-per-group | tvf | openjson

  PROBLEM
  -------
  1. Top-N per group      The 2 most recently created tasks per project.
                          State the row count.

  2. Latest child row     The most recent time entry per task, with a
                          deterministic tie-breaker. Write it with CROSS APPLY
                          and then with OUTER APPLY; state both row counts.

  3. Several measures     For every task return AssigneeCount, LoggedHours,
                          BillableHours, CommentCount using one OUTER APPLY
                          per child. Compare against the four-LEFT-JOIN
                          derived-table version from Topic 05 P5 and say
                          which you prefer and why.

  4. Table-valued         Create an INLINE TVF app.fn_TaskEffort(@TaskId)
     function             returning logged hours, billable hours and entry
                          count. Call it with CROSS APPLY. Explain why it
                          returns a row even for tasks with no time entries,
                          and what changes if you add a GROUP BY inside it.
                          Say why RETURNS TABLE beats RETURNS @t TABLE.

  5. JSON expansion       List the reviewers on task 1 from MetadataJson, and
                          separately list every task's 'epic' value while
                          keeping tasks that have no epic.

  6. Expression reuse     Use CROSS APPLY (VALUES (...)) to compute a derived
                          value once and reference it in SELECT, WHERE and
                          ORDER BY.

  7. Cleanup              Drop the TVF.

  EXPECTED
  --------
  1. 16 rows (every project has at least 2 tasks).
  2. CROSS APPLY = 16 rows | OUTER APPLY = 35 rows.
  3. 35 rows, zeroes not NULLs for childless tasks.
  5. 2 reviewers on task 1; all 35 tasks retained in the epic listing.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- 1. Two most recently created tasks per project
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 2. Latest time entry per task — CROSS APPLY then OUTER APPLY
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 3. Four child measures, one row per task, via OUTER APPLY
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 4. Inline TVF app.fn_TaskEffort + CROSS APPLY, with the write-up
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 5. JSON: reviewers on task 1, and every task's epic
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 6. CROSS APPLY (VALUES (...)) for expression reuse
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 7. Cleanup
-------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS app.fn_TaskEffort;
GO
