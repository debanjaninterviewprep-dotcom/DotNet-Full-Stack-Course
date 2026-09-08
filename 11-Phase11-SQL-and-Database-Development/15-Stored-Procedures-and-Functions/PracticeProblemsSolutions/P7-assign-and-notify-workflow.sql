/*
    P7 -- Design and Build: A Complete "Assign and Notify" Workflow  (Hard)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes; drop the procedure.

    app.usp_AssignTaskWithHistory:
    1. Validate task exists and is not terminal (StatusId 6/7) -- THROW a clear custom error otherwise.
    2. Insert the new assignment (skip silently, no error, if the pair already exists).
    3. Use OUTPUT (Topic 10) to write a row into audit.TaskHistory in the SAME statement as the insert.
    4. Wrap in one transaction, XACT_ABORT ON, proper TRY/CATCH.
    5. Final SELECT: the task's full current assignee list after the change.
    6. Test calls: valid new assignment; already-terminal task (expect custom error);
       duplicate assignment (expect silent skip).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
