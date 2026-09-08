/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P2 — The Overdue Filter                                             (Easy)
  -----------------------------------------------------------------------------
  Tags: where, comparison-operators, precedence, bit, parentheses

  PROBLEM
  Product wants an "Attention Required" list: tasks that are NOT FINISHED and
  are EITHER overdue OR critical.

  REQUIREMENTS
    1. Define "not finished" using ref.TaskStatuses.IsTerminal — not a
       hard-coded list of status IDs.
    2. Define "overdue" as DueDate strictly before today
       (CAST(SYSUTCDATETIME() AS DATE)).
    3. Define "critical" as PriorityId = 1.
    4. Write the predicate WRONG first:
           IsTerminal = 0 AND DueDate < @today OR PriorityId = 1
       Run it, record the row count in a comment, and explain what it actually
       means.
    5. Write the corrected, parenthesised version. Record its row count.
    6. Explain why tasks with a NULL DueDate do not appear in the "overdue"
       half, and show a variant that treats undated tasks as also needing
       attention.

  HINTS
    - AND binds tighter than OR. The wrong version returns every critical task
      in the database, including completed ones.
    - t.DueDate < @today is UNKNOWN when DueDate IS NULL, and UNKNOWN is not TRUE.
    - IsTerminal is a BIT. Compare it to 0, not to FALSE.
=============================================================================*/

USE TaskFlowDb;
GO

DECLARE @Today DATE = CAST(SYSUTCDATETIME() AS DATE);

-----------------------------------------------------------------------------
-- 1. The WRONG predicate (unparenthesised). Record the row count.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. What does the wrong predicate actually mean?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 3. The CORRECT, parenthesised predicate. Record the row count.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4. Why are NULL DueDate rows excluded from the "overdue" half?
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 5. Variant: undated tasks also require attention
-----------------------------------------------------------------------------

-- TODO: your solution here
GO
