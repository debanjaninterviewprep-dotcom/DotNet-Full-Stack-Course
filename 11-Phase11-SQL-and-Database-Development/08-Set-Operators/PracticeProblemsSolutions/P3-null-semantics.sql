/*
    P3 -- The Set-Operator NULL Rule  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Prove two NULLs are equal under INTERSECT (SELECT NULL INTERSECT SELECT NULL).
    2. Prove WHERE NULL = NULL returns 0 rows (ordinary equality never matches NULLs).
    3. Using app.Tasks.EstimatedHours, find two TaskIds with a NULL estimate; show INTERSECT
       matches them on that column while JOIN ON a.EstimatedHours = b.EstimatedHours does not.
    4. Summarise the rule in one sentence using "distinct from", not "equal to".
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
