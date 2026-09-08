/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P1 — Aggregate Vital Signs                                          (Easy)
  -----------------------------------------------------------------------------
  Tags: count | null-handling | distinct

  PROBLEM
  -------
  1. Produce a SINGLE-ROW "vital signs" result over app.Tasks with these
     columns, in this order:

       TotalTasks            every row
       TasksWithDueDate      rows where DueDate is populated
       TasksWithEstimate     rows where EstimatedHours is populated
       TasksWithDescription  rows where Description is populated
       DistinctProjects      distinct ProjectId values
       DistinctStatuses      distinct StatusId values
       DistinctPriorities    distinct PriorityId values
       EarliestCreated       oldest CreatedAtUtc
       LatestCreated         newest CreatedAtUtc

  2. Write a SECOND statement of the same shape restricted to
     WHERE ProjectId = 999, and add a comment explaining in one line each
     why TotalTasks is 0 but SUM(EstimatedHours) is NULL.

  RULES
  -----
  - Exactly one column should use COUNT(*).
  - Schema-qualify every table (app.Tasks). Alias every table.
  - No SELECT *.

  EXPECTED
  --------
  TotalTasks 35 | TasksWithDueDate 27 | TasksWithEstimate 31
  TasksWithDescription 0 | DistinctProjects 8 | DistinctStatuses 7
  DistinctPriorities 5
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Part 1: vital signs over all tasks
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Part 2: the same shape over an empty set (ProjectId = 999)
--         plus the explanatory comment
-------------------------------------------------------------------------------

-- TODO: your solution here
