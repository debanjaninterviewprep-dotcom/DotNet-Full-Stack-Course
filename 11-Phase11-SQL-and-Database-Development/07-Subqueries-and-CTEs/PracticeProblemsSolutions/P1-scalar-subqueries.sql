/*
    P1 — Scalar Subqueries & the "More Than One Value" Trap  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. TaskId, Title, EstimatedHours, global-average EstimatedHours (scalar subquery), Delta.
    2. (included above)
    3. Deliberately trigger Msg 512 with a scalar subquery that returns >1 row, capture the message.
    4. Fix it two ways: aggregate the subquery, and TOP (1) ... ORDER BY with a justified tiebreaker.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
