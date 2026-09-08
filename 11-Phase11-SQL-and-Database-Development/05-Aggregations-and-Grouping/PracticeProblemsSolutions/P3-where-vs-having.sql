/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P3 — WHERE vs HAVING, Proven                                      (Medium)
  -----------------------------------------------------------------------------
  Tags: having | where | logical-processing-order | left-join

  PROBLEM
  -------
  Answer the same business question three different ways:
      "How many non-terminal (open) tasks does each project have,
       and which projects have 4 or more?"

  Query A  Filter with WHERE s.IsTerminal = 0, GROUP BY project,
           HAVING COUNT(*) >= 4. Record the row count.

  Query B  Move the IsTerminal test into conditional aggregation so projects
           with ZERO open tasks still appear with 0. Drive the query from
           app.Projects with LEFT JOINs. No app.Tasks or ref.TaskStatuses
           predicate may appear in WHERE.

  Query C  Deliberately write WHERE COUNT(*) >= 4 and capture the exact error
           number and message verbatim as a comment.

  Finally, add a comment table listing which projects appear in A but not B
  (and vice versa) with the reason, naming the logical processing step
  (WHERE = step 4, HAVING = step 6) that causes the difference.

  EXPECTED
  --------
  Query A -> 2 rows: TF-CORE (5), TF-WEB (4)
  Query B -> 8 rows, with TF-MOB = 0
  Query C -> Msg 147
=============================================================================*/

USE TaskFlowDb;
GO

-------------------------------------------------------------------------------
-- Query A: WHERE row filter + HAVING group filter
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Query B: conditional aggregation from app.Projects, zero-preserving
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Query C: the deliberate error. Paste the verbatim message below it.
-------------------------------------------------------------------------------

-- TODO: your solution here


-------------------------------------------------------------------------------
-- Write-up: A vs B differences and why
-------------------------------------------------------------------------------

-- TODO: your solution here
