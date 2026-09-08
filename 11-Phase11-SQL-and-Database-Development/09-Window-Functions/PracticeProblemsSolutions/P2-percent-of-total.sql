/*
    P2 -- Percent of Total and the Integer-Division Trap  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Project 4 tasks: EstimatedHours, project total via SUM(...) OVER (PARTITION BY ProjectId),
       and percentage of project total.
    2. Deliberately omit the 100.0 * trick -- show the (wrong) result.
    3. Fix it -- confirm the four rows sum to 100.0%.
    4. COUNT(*) OVER (...) vs COUNT(EstimatedHours) OVER (...) across all projects -- find where
       they differ and explain what the difference means.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
