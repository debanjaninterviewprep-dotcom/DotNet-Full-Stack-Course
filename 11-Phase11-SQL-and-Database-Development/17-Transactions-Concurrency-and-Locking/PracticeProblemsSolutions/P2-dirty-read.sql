/*
    P2 -- Reproducing a Dirty Read  (Medium -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.
    Open TWO query windows against TaskFlowDb. Follow the SESSION A / SESSION B labels
    and run them in the interleaved order shown.

    1. SESSION A: BEGIN TRANSACTION; UPDATE app.Tasks SET EstimatedHours = 999.00
       WHERE TaskId = 1; -- do NOT commit yet.
    2. SESSION B: SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT EstimatedHours
       FROM app.Tasks WHERE TaskId = 1; -- record what it sees.
    3. SESSION A: ROLLBACK TRANSACTION;
    4. SESSION B: re-run the SELECT -- compare, explain what happened to the earlier value.
    5. Repeat 1-4 with SESSION B under READ COMMITTED (default) instead -- confirm it now
       BLOCKS during step 2 instead of reading dirty data.
*/
USE TaskFlowDb;
GO

-- ============================================================
-- SESSION A -- run these statements in the FIRST query window
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B -- run these statements in the SECOND query window
-- ============================================================
-- TODO: your solution here
