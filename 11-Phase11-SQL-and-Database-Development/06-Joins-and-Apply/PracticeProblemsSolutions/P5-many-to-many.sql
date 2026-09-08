/*=============================================================================
  Topic 06 — Joins & APPLY
  P5 — Many-to-Many and Row Multiplication                          (Medium)
  -----------------------------------------------------------------------------
  Tags: many-to-many | junction-table | fan-out | string-agg | outer-apply

  PROBLEM
  -------
  1. Count the rows produced by app.Tasks JOIN app.TaskLabels. Explain the
     number in terms of tasks-with-labels and tasks-with-two-labels.

  2. The NAIVE report: task, project, label name, estimated hours — then
     SUM(EstimatedHours) grouped by project. Show the total is inflated and
     quantify the inflation for at least one project.

  3. The CORRECT report: exactly one row per task with a comma-separated,
     alphabetical label list and '(unlabelled)' where there are none.
     Use OUTER APPLY + STRING_AGG.

  4. The same on the people side: one row per team with a comma-separated
     member list, INCLUDING the team that has no members.

  5. Every user in MORE THAN ONE team, and every task carrying MORE THAN ONE
     label.

  6. Tasks carrying BOTH the 'security' AND the 'tech-debt' label — without
     using DISTINCT. Implement one approach (two EXISTS clauses, or
     GROUP BY ... HAVING COUNT(DISTINCT ...) = 2) and mention the other.

  EXPECTED
  --------
  1. 28 rows = 25 labelled tasks + 3 tasks with a second label.
  3. exactly 35 rows.
  4. exactly 7 rows, with 'Design System' present.
  5. Ken Thompson (Platform + Security); tasks 4, 6, 20.
  6. task 20.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- 1. Row count through the junction table, explained
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 2. The naive, inflated report
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 3. One row per task with an aggregated label list
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 4. One row per team with an aggregated member list
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 5. Multi-team users and multi-label tasks
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- 6. Tasks with BOTH 'security' and 'tech-debt', no DISTINCT
-------------------------------------------------------------------------------

-- TODO: your solution here
