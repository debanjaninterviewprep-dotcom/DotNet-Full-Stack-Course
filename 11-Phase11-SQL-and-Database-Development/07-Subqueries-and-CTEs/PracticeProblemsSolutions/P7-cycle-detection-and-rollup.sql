/*
    P7 — Cycle Detection and a Rolled-Up Task Tree  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Recursive CTE over app.Tasks.ParentTaskId: for EVERY root task, the root's TaskId, Title,
       node count, and SUM(EstimatedHours) across the whole subtree (root + descendants).
       Expect task 1 -> 3 nodes / 40.00 hours; task 10 -> 3 nodes / 62.00 hours.
    2. (verification of the above)
    3. Build a synthetic edge list with VALUES containing a genuine cycle (three nodes each
       pointing to the next, looping back). Write a recursive CTE with a visited-path column
       that detects and stops on the cycle WITHOUT relying on MAXRECURSION to bail you out.
    4. List, as a comment table, the four debugging steps for a hung recursive CTE in production.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
