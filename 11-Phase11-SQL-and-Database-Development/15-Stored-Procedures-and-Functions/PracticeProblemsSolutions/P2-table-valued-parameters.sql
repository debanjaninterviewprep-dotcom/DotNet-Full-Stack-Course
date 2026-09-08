/*
    P2 -- Table-Valued Parameters for Bulk Operations  (Easy)
    See ../Practice-Problems.md for full requirements.
    Roll back the data change; drop the procedure and the type.

    1. User-defined table type app.TaskIdList (TaskId INT PRIMARY KEY).
    2. app.usp_BulkCloseTasks (@TaskIds app.TaskIdList READONLY) -- StatusId = 6 + CompletedAtUtc.
    3. Call with 3 task IDs in ONE round trip (no loop) -- confirm all 3 rows updated.
    4. Roll back; drop the procedure and the type.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
