/*
    P1 -- A Parameterised Procedure with Defaults and Output  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. app.usp_GetTasksByProject (@ProjectId INT, @IncludeClosed BIT = 0) -- TaskId, Title,
       StatusId, PriorityId, DueDate.
    2. Call with only @ProjectId, then with @IncludeClosed = 1 -- confirm row counts differ.
    3. app.usp_CreateTask with @NewTaskId INT OUTPUT via SCOPE_IDENTITY().
    4. Call it, capture the output into a variable, prove the row exists via a follow-up SELECT.
    5. Clean up the inserted row; drop both procedures.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
