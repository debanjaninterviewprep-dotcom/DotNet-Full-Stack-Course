/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P4 — Status Pivot Without PIVOT                                   (Medium)
  -----------------------------------------------------------------------------
  Tags: conditional-aggregation | pivot | percentages

  PROBLEM
  -------
  Build the board summary the TaskFlow web client renders: one row per
  project, one column per status, plus totals.

  Columns:
      ProjectCode, Backlog, ToDo, InProgress, InReview, Blocked, Done,
      Cancelled, TotalTasks, PctComplete

  RULES
  -----
  - Conditional aggregation ONLY. No PIVOT operator, no per-column subquery.
  - Reference statuses by joining ref.TaskStatuses and testing StatusCode.
    No StatusId integer literal may appear in a CASE expression.
  - PctComplete = percentage of tasks whose status has IsTerminal = 1,
    typed as DECIMAL(5,2).
  - Include every project even if it has no tasks: drive from app.Projects
    with LEFT JOIN and use COUNT(t.TaskId), not COUNT(*).
  - Add a grand-total row with UNION ALL, OR state in a comment why ROLLUP
    would be the better choice here.

  EXPECTED
  --------
  Column totals across the whole result:
      Backlog 6 | ToDo 5 | InProgress 8 | InReview 1 | Blocked 2
      Done 11 | Cancelled 2   (sum = 35)
  TF-MOB: Cancelled = 2, PctComplete = 100.00
  The seven status columns must add up to TotalTasks on every row.
=============================================================================*/

USE TaskFlowDb;
GO

-- TODO: your solution here
