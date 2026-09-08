/*
    P3 -- OUTPUT for an Audit Trail  (Medium)
    See ../Practice-Problems.md for full requirements.
    Roll back the app.Tasks/app.Comments changes at the end.

    1. UPDATE a task's StatusId/CompletedAtUtc; OUTPUT the change into audit.TaskHistory
       (column name, old value, new value) in the SAME statement.
    2. Confirm audit.TaskHistory has no FK to app.Tasks (check sys.foreign_keys) -- explain why.
    3. DELETE a task's comments; OUTPUT the deleted rows into a #DeletedCommentsArchive temp
       table in the SAME statement -- no separate SELECT beforehand.
    4. Verify the archived rows match what was deleted.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
