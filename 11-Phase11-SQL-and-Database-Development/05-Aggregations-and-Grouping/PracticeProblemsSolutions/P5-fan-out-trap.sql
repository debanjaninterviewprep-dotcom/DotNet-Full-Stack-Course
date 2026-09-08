/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P5 — The Fan-Out Trap                                             (Medium)
  -----------------------------------------------------------------------------
  Tags: fan-out | double-counting | derived-tables | count-distinct

  PROBLEM
  -------
  1. Write the BROKEN query: join app.Tasks to BOTH app.TaskAssignments and
     app.TimeEntries, GROUP BY TaskId, and output
         COUNT(*), COUNT(DISTINCT ta.UserId),
         COUNT(DISTINCT te.TimeEntryId), SUM(te.Hours)
     restricted to tasks 1, 4, 6, 10, 19.

  2. Add a comment giving, for each of those five tasks, the TRUE logged
     hours, the INFLATED value your query produced, and the multiplication
     factor.

  3. Write the FIXED query using pre-aggregated derived tables or CTEs that
     returns, for ALL 35 tasks:
         TaskId, Title, AssigneeCount, LoggedHours, BillableHours,
         CommentCount, LabelCount
     with 0 (never NULL) for tasks that have no children.

  4. Prove the fix with a final statement asserting
         SUM(LoggedHours)   = 160.00
         SUM(BillableHours) = 149.00
     across the whole result.

  RULES
  -----
  - No SELECT DISTINCT anywhere.
  - Explain in a comment why COUNT(DISTINCT ...) survives the fan-out but
    SUM does not.

  EXPECTED
  --------
  Broken: task 4  -> 6 rows, 42.00 hours (true 21.00, factor 2)
          task 10 -> 6 rows, 43.00 hours (true 21.50, factor 2)
  Fixed:  exactly 35 rows; AssigneeCount = 0 on 8 tasks;
          LabelCount = 0 on 10 tasks.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Step 1: the broken query
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 2: true vs inflated table (comment)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 3: the fixed query — pre-aggregate every child to one row per TaskId
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 4: reconciliation assertion
-------------------------------------------------------------------------------

-- TODO: your solution here
