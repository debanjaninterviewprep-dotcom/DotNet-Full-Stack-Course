/*=============================================================================
  Topic 03 — SELECT, Filtering & Sorting
  P5 — Deterministic Sorting and Top-N                              (Medium)
  -----------------------------------------------------------------------------
  Tags: order-by, null-ordering, collation, top, with-ties, percent, distinct,
        determinism

  PROBLEM / REQUIREMENTS
    1. Return TaskId, Title, DueDate from app.Tasks ordered by DueDate ASC.
       Record where the NULL due dates land.
    2. Rewrite so undated tasks sort LAST while dated tasks stay ascending.
       Do NOT use ISNULL with a sentinel date — explain why a sentinel is bad.
    3. Sort app.Users by LastName twice: database default collation, then
       Latin1_General_BIN2. Identify by UserId the row that moves, and explain why.
    4. Return the top 2 tasks by EstimatedHours DESC, then the same query with
       WITH TIES. Record both row counts and explain the difference.
    5. Return TOP (10) PERCENT of tasks by CreatedAtUtc DESC. State the exact
       row count returned and the rounding rule.
    6. Write a SELECT TOP (5) with NO ORDER BY, and explain why the result is
       not a bug but is also not usable.
    7. Produce the distinct list of (ProjectId, StatusId) pairs in app.Tasks.
       Then attempt  SELECT DISTINCT t.ProjectId ... ORDER BY t.CreatedAtUtc,
       capture the error number and message, and explain it.
    8. Add a CASE-based ORDER BY that puts BLOCKED tasks first, then IN_PROGRESS,
       then everything else by ref.TaskStatuses.SortOrder. Argue why SortOrder
       is a better long-term design than the CASE.

  HINTS
    - SQL Server sorts NULL first in ASC and has no NULLS LAST clause —
      emulate with a leading CASE WHEN ... IS NULL THEN 1 ELSE 0 END.
    - The user who moves under a binary collation has a lowercase surname prefix.
    - 10 percent of 35 rows is not 3.
    - The DISTINCT + ORDER BY failure is Msg 145.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. ORDER BY DueDate ASC — where do the NULLs land?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. NULLS LAST emulation. Why is a sentinel date a bad idea?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3a. Sort app.Users by LastName — database default collation
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3b. Sort app.Users by LastName — Latin1_General_BIN2.
--     Which UserId moves, and why? (Answer at code-point level.)
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4a. TOP (2) by EstimatedHours DESC — record the row count
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4b. TOP (2) WITH TIES — record the row count and name the tied values
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. TOP (10) PERCENT by CreatedAtUtc DESC — exact row count + rounding rule
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. TOP (5) with no ORDER BY — why is this unusable?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7a. Distinct (ProjectId, StatusId) pairs
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7b. SELECT DISTINCT ... ORDER BY a non-projected column.
--     Capture the error number + message verbatim, then explain it.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 8. CASE-based business ordering (BLOCKED, IN_PROGRESS, then SortOrder).
--    Why is ref.TaskStatuses.SortOrder the better long-term design?
-----------------------------------------------------------------------------

-- TODO: your solution here
GO
