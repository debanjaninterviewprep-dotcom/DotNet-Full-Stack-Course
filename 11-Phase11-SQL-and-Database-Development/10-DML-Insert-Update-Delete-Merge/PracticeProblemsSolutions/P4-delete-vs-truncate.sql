/*
    P4 -- DELETE vs TRUNCATE TABLE: Side-by-Side Behaviour  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Copy ref.Priorities into #PrioritiesCopy (SELECT INTO) with its own IDENTITY(1,1) IntId column.
    2. DELETE all rows, insert one row back, observe the new identity value.
    3. Reset, TRUNCATE instead, insert one row back, observe the new identity value. Compare.
    4. Attempt TRUNCATE TABLE app.Tasks (has incoming FKs) -- capture the exact error.
       Explain how DELETE FROM app.Tasks would behave differently.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
