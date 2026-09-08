/*=============================================================================
  Topic 04 — Built-In Functions & Expressions
  P2 — Numbers That Do Not Lie                                        (Easy)
  -----------------------------------------------------------------------------
  Tags: numeric-functions, rounding, integer-division, modulo, nullif, rand

  REQUIREMENTS
    1. For each task with a non-NULL EstimatedHours, show ROUND to 0 decimals,
       ROUND with the truncate flag, CEILING, FLOOR and ABS. Explain the
       difference between ROUND(x, 0) and ROUND(x, 0, 1).
    2. Show that ROUND does NOT change the scale, and give the expression that
       returns a true INT.
    3. State how SQL Server's ROUND(2.5, 0) differs from .NET's Math.Round(2.5),
       and why that matters for a report that must reconcile with C#.
    4. Compute "percent of tasks complete" per project using
       ref.TaskStatuses.IsTerminal. Write it WRONG first (integer division) and
       record the result, then write it correctly. Explain why 100.0 * a / b
       works and a / b * 100.0 does not.
    5. Use % to bucket EstimatedHours into whole working days plus a remainder.
    6. Compute EstimatedHours / StoryPoints safely so a zero or NULL StoryPoints
       returns NULL rather than raising Msg 8134.
    7. Show that RAND() returns the same value for every row, then produce a
       genuinely random sample of 5 tasks. Explain the mechanism behind your fix.

  HINTS
    - app.Tasks.EstimatedHours is DECIMAL(6,2); StoryPoints is TINYINT, nullable.
    - NULLIF(x, 0) is the divide-by-zero guard.
    - RAND() is folded to a single runtime constant; NEWID() is evaluated per row.
=============================================================================*/

USE TaskFlowDb;
GO

-----------------------------------------------------------------------------
-- 1. ROUND / ROUND-truncate / CEILING / FLOOR / ABS on EstimatedHours
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 2. ROUND does not change the scale. How do you actually get an INT?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 3. T-SQL ROUND(2.5, 0) vs .NET Math.Round(2.5) — and why it matters
-----------------------------------------------------------------------------

-- TODO: your answer here (comment block)


-----------------------------------------------------------------------------
-- 4a. Percent complete per project — the WRONG (integer division) version
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 4b. Percent complete per project — the CORRECT version.
--     Why does 100.0 * a / b work while a / b * 100.0 does not?
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 5. Modulo: whole working days + remainder hours
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 6. Safe division: EstimatedHours / StoryPoints without Msg 8134
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7a. RAND() is a per-QUERY constant, not per-row. Prove it.
-----------------------------------------------------------------------------

-- TODO: your solution here


-----------------------------------------------------------------------------
-- 7b. A genuinely random sample of 5 tasks. Explain the mechanism.
-----------------------------------------------------------------------------

-- TODO: your solution here
GO
