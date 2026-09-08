/*=============================================================================
  Topic 06 — Joins & APPLY
  P2 — The Missing-Rows Report                                        (Easy)
  -----------------------------------------------------------------------------
  Tags: anti-join | not-exists | not-in-null-trap

  PROBLEM
  -------
  Produce four "nothing here" reports. Write EACH one three ways
  (NOT EXISTS, LEFT JOIN ... IS NULL, NOT IN) with a comment on whether that
  version is correct and why:

      1. Tasks with no assignee.
      2. Users with no task assignment.
      3. Labels never applied to any task.
      4. Individual contributors — users who are nobody's manager
         (app.Users.ManagerId).

  Report 4 is the trap. Capture the actual row count returned by its NOT IN
  version and explain it in terms of three-valued logic.

  Then write one CORRECT NOT IN version of report 4 by adding the guard the
  subquery needs.

  EXPECTED
  --------
  Report 1 = 8 rows | Report 2 = 6 rows | Report 3 = 1 row (good-first-issue)
  Report 4 = 13 rows via NOT EXISTS, but 0 ROWS via unguarded NOT IN.
  Guarded NOT IN = 13 rows.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Report 1: tasks with no assignee  (three versions)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Report 2: users with no task assignment  (three versions)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Report 3: labels never applied  (three versions)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Report 4: individual contributors  (three versions + the NULL trap)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Report 4 repaired: guarded NOT IN, plus the recommendation write-up
-------------------------------------------------------------------------------

-- TODO: your solution here
