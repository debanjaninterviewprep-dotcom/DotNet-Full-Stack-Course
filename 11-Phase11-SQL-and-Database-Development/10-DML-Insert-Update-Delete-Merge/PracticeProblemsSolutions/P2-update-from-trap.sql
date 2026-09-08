/*
    P2 -- The UPDATE ... FROM Multi-Match Trap  (Medium)
    See ../Practice-Problems.md for full requirements.
    WRAP EVERYTHING IN BEGIN TRANSACTION / ROLLBACK TRANSACTION -- never commit this file.

    1. Temporarily insert a second IsPrimary = 1 row into app.TaskAssignments for a task
       that already has one, creating a genuine multi-match condition.
    2. UPDATE ... FROM joining Tasks to TaskAssignments (IsPrimary = 1) -- note it does not error.
    3. Rewrite as a correlated subquery UPDATE -- show it raises Msg 512 under the same data.
    4. ROLLBACK. Explain why the correlated-subquery version is the safer default.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
