/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P8 — Grouping Performance Lab                                       (Hard)
  -----------------------------------------------------------------------------
  Tags: execution-plans | stream-aggregate | hash-match | indexes | statistics-io

  PROBLEM
  -------
  1. SET STATISTICS IO, TIME ON and enable the actual execution plan.

  2. Baseline:
         SELECT ProjectId, StatusId, COUNT(*), SUM(EstimatedHours)
         FROM app.Tasks GROUP BY ProjectId, StatusId;
     Record: aggregate operator used, logical reads, whether a Sort appears.

  3. Create IX_Tasks_Project_Status_Incl on
         app.Tasks (ProjectId, StatusId) INCLUDE (EstimatedHours, StoryPoints)
     Re-run. Record what changed.

  4. Reverse the GROUP BY to (StatusId, ProjectId) and re-run. Explain whether
     the index still avoids the Sort, and why.

  5. Run a COUNT(DISTINCT CreatedByUserId) variant and describe the extra
     operator it introduces.

  6. Run the same with APPROX_COUNT_DISTINCT and compare plan shape. 35 rows
     is far too small to change the RESULT, so comment on what would change
     at scale.

  7. Drop the index so the database returns to its seeded state.

  DELIVERABLE
  -----------
  The statements plus a results table in comments with one row per
  experiment:  scenario | aggregate operator | sort present | logical reads

  RULES
  -----
  - Read the plan; do not guess. OPTION (ORDER GROUP) and OPTION (HASH GROUP)
    can force the comparison for diagnosis.
  - Compare logical reads, not elapsed milliseconds, on a 35-row table.
  - Only clear the plan cache on a local dev instance, never shared.
=============================================================================*/

USE TaskFlowDb;
GO

SET STATISTICS IO, TIME ON;
GO

-------------------------------------------------------------------------------
-- Step 2: baseline
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 3: create the covering index and re-run
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 4: reversed GROUP BY column order
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 5: COUNT(DISTINCT CreatedByUserId)
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 6: APPROX_COUNT_DISTINCT comparison
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Results table (comment)
--   scenario | aggregate operator | sort present | logical reads
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 7: cleanup — leave the database as you found it
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS IX_Tasks_Project_Status_Incl ON app.Tasks;
GO

SET STATISTICS IO, TIME OFF;
GO
