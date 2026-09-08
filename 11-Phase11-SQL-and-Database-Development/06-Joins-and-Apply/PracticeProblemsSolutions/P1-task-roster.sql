/*=============================================================================
  Topic 06 — Joins & APPLY
  P1 — Task Roster                                                    (Easy)
  -----------------------------------------------------------------------------
  Tags: inner-join | left-join | row-counts

  PROBLEM
  -------
  Query A (inner)
      One row per task/assignee pair with TaskId, Title, ProjectCode,
      StatusName, PriorityName, AssigneeName. Join app.Tasks, app.Projects,
      ref.TaskStatuses, ref.Priorities, app.TaskAssignments, app.Users.
      State the expected row count BEFORE running, then verify.

  Query B (outer)
      The same query with the assignee side made outer, so unassigned tasks
      still appear with '(unassigned)' instead of NULL. State and verify the
      row count.

  Query C (difference)
      TaskId and Title of every task that appears in B but not in A.

  Write-up
      A comment stating which of the six joins are many-to-one
      (grain-preserving) and which is one-to-many (grain-changing), and how
      you can tell from the schema alone.

  EXPECTED
  --------
  A = 31 rows | B = 39 rows | C = 8 rows (tasks 8, 18, 22, 26, 27, 29, 30, 33)
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Query A: inner join roster
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Query B: outer join roster, '(unassigned)' placeholder
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Query C: tasks present in B but not in A
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Write-up: which joins change the grain, and how you know
-------------------------------------------------------------------------------

-- TODO: your solution here
