/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P6 — Subtotals That Tell the Truth                                  (Hard)
  -----------------------------------------------------------------------------
  Tags: rollup | cube | grouping-sets | grouping | grouping-id

  PROBLEM
  -------
  1. Project x status matrix with project subtotals and a grand total using
     ROLLUP. Report the exact row count and reconcile it with
     (real combinations) + (projects) + 1.

  2. Repeat with CUBE. Report the row count and reconcile it the same way.

  3. Express the ROLLUP result exactly using GROUPING SETS and prove the two
     are equivalent: identical row counts and identical Tasks values.

  4. Headcount over app.Users grouped by ROLLUP (JobTitle) that correctly
     distinguishes the one user with a NULL JobTitle from the grand-total
     row. Use GROUPING(), not ISNULL().

  5. Add GROUPING_ID() to the CUBE query and write a legend comment mapping
     0 / 1 / 2 / 3 to their meanings.

  RULES
  -----
  - Use GROUP BY ROLLUP (a, b), not the deprecated GROUP BY a, b WITH ROLLUP.
  - ORDER BY GROUPING(a), a, GROUPING(b), b so subtotals follow their detail.

  EXPECTED
  --------
  Plain GROUP BY -> 25 rows
  ROLLUP         -> 34 rows   (25 + 8 + 1)
  CUBE           -> 41 rows   (25 + 8 + 7 + 1)
  Headcount      -> "(no title on record)" = 1 AND "ALL TITLES" = 20,
                    as two distinct rows.
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Step 1: ROLLUP matrix + row-count reconciliation
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 2: CUBE matrix + row-count reconciliation
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 3: GROUPING SETS rewrite of the ROLLUP, plus the equivalence proof
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 4: headcount by JobTitle — real NULL vs subtotal NULL
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Step 5: GROUPING_ID() on the CUBE + legend comment
-------------------------------------------------------------------------------

-- TODO: your solution here
