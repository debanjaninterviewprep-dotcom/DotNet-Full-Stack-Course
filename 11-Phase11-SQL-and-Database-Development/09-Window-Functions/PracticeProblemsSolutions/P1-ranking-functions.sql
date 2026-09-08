/*
    P1 -- Ranking Functions Side by Side  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Project 1's tasks: ROW_NUMBER, RANK, DENSE_RANK, NTILE(3), all ordered by EstimatedHours DESC.
    2. Identify the tied pair (tasks 34 and 6, both 8.00 hrs) -- explain how each function treats it.
    3. Re-run ROW_NUMBER twice; is the tied pair's order stable? Add a tie-breaker (, t.TaskId) and explain.
    4. Comment: which function for "top 3 distinct estimate sizes" vs "top 3 tasks"?
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
