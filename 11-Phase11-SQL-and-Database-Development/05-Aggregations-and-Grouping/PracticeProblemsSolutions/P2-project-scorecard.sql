/*=============================================================================
  Topic 05 — Aggregations & Grouping
  P2 — Project Scorecard                                              (Easy)
  -----------------------------------------------------------------------------
  Tags: group-by | sum | avg | integer-truncation | isnull

  PROBLEM
  -------
  One row per project (use app.Projects.ProjectCode), with:

    1. TaskCount            number of tasks
    2. EstimatedHours       total estimate; 0 rather than NULL when unknown
    3. AvgEstimateHours     average estimate, 2 decimals, over tasks that
                            actually have an estimate
    4. AvgStoryPoints       average story points to 4 decimal places
    5. AvgStoryPointsNaive  AVG() applied straight to the TINYINT column, so
                            the truncation is visible next to column 4
    6. MaxStoryPoints, MinStoryPoints

  Order by TaskCount DESC, then ProjectCode.

  Then add a comment stating the numeric difference between columns 4 and 5
  for at least one project and explaining the cause in one sentence.

  RULES
  -----
  - Cast the COLUMN inside AVG, not the result of AVG.
  - Use ISNULL/COALESCE only where a NULL is genuinely possible.
  - ORDER BY should use the aliases, not repeated expressions.

  EXPECTED
  --------
  TF-CORE: TaskCount 9, EstimatedHours 140.00
  AvgStoryPointsNaive is visibly lower than AvgStoryPoints on at least one row.
=============================================================================*/

USE TaskFlowDb;
GO

-- TODO: your solution here
