/*
    P4 -- Selectivity and Statistics  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Compute selectivity (distinct/total) of app.Tasks.StatusId and app.Tasks.TaskId --
       which is more useful as a standalone index key?
    2. DBCC SHOW_STATISTICS against an index on a low-selectivity column -- find EQ_ROWS
       for the most common value.
    3. Index StatusId alone -- show via the plan whether the optimizer scans or seeks for
       a common vs rare value.
    4. Explain, referencing actual EQ_ROWS numbers, why the choice is cost-based, not a fixed rule.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
