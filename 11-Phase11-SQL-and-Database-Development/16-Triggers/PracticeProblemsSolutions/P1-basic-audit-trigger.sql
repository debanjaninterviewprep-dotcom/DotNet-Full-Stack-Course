/*
    P1 -- A Basic Audit Trigger  (Easy)
    See ../Practice-Problems.md for full requirements.
    Wrap data changes in a transaction you roll back; drop the trigger at the end.

    1. audit.trg_Tasks_StatusChange ON app.Tasks AFTER UPDATE -- write to audit.TaskHistory
       only when StatusId's VALUE actually changes (not just when targeted).
    2. Update a task's StatusId to a genuinely different value -- confirm one audit row.
    3. Update a task's StatusId to its EXISTING value (no-op) -- confirm ZERO audit rows.
       Explain why UPDATE(StatusId) alone would have been insufficient.
    4. Roll back; drop the trigger.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
