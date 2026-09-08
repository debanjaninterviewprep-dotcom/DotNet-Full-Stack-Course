/*
    P1 -- Atomicity: Proving a Rollback Undoes Everything  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. One transaction: update a task's StatusId + insert a matching audit.TaskHistory row.
    2. Force an error partway through -- confirm (XACT_STATE()/follow-up SELECT) that NEITHER
       change persisted after ROLLBACK.
    3. Repeat without the forced error, COMMIT instead -- confirm both persist.
    4. TRICK: you cannot ROLLBACK an already-committed transaction. Explain and use a
       compensating transaction (or re-run the create script) to reset state instead.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
