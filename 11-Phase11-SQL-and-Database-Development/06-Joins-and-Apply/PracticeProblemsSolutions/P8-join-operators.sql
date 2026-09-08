/*=============================================================================
  Topic 06 — Joins & APPLY
  P8 — Physical Join Operators and Plan Reading                       (Hard)
  -----------------------------------------------------------------------------
  Tags: execution-plans | nested-loops | merge-join | hash-match |
        join-hints | indexes

  PROBLEM
  -------
  1. Enable the actual execution plan and SET STATISTICS IO, TIME ON.

  2. Run app.Tasks JOIN app.TaskAssignments JOIN app.Users and record which
     physical operator each join used.

  3. Force each operator in turn with INNER LOOP JOIN, INNER MERGE JOIN and
     INNER HASH JOIN. Record logical reads and any warnings for each.

  4. Show that a HASH JOIN cannot serve a NON-EQUI join: attempt
     OPTION (HASH JOIN) on the SLA range join from P6 and capture the error
     verbatim.

  5. Create IX_TaskAssignments_UserId on
         app.TaskAssignments (UserId) INCLUDE (TaskId)
     and re-run step 2. Record any change in operator choice.

  6. Run the P2 report-1 anti-join three ways (NOT EXISTS,
     LEFT JOIN ... IS NULL, NOT IN) and compare the plans. Which two are
     identical, and why is the third different?

  7. Add OPTION (FORCE ORDER) to a four-table join and explain, in a comment,
     why a join hint written in the FROM clause has the same effect on the
     whole query.

  8. Drop the index.

  DELIVERABLE
  -----------
  The statements plus a comment results table:
      scenario | operator | logical reads | warnings

  RULES
  -----
  - 35 rows is far too small for cost to matter. Compare PLAN SHAPE and
    LOGICAL READS, never elapsed time.
  - Compare estimated vs actual rows on at least one operator.
  - List what you would try BEFORE a hint: statistics, indexes, sargability,
    RECOMPILE, Query Store plan forcing.
=============================================================================*/

USE TaskFlowDb;
GO

SET STATISTICS IO, TIME ON;
GO

-------------------------------------------------------------------------------
-- 2. Baseline three-table join — which operators?
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 3. Force LOOP, then MERGE, then HASH
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 4. HASH JOIN on a non-equi predicate — capture the error verbatim
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 5. Add the index and re-run the baseline
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 6. Anti-join three ways — compare the plans
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 7. OPTION (FORCE ORDER) and the implicit-force-order gotcha
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Results table (comment)
--   scenario | operator | logical reads | warnings
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 8. Cleanup — leave the database as you found it
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS IX_TaskAssignments_UserId ON app.TaskAssignments;
GO

SET STATISTICS IO, TIME OFF;
GO
