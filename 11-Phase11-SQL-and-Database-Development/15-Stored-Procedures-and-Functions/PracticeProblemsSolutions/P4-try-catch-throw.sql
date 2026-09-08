/*
    P4 -- TRY/CATCH, THROW, and Transaction State  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. app.usp_AssignTask (@TaskId INT, @UserId INT): XACT_ABORT ON, TRY/CATCH, explicit
       transaction, THROW 50001 for a non-existent TaskId.
    2. Call with valid TaskId/UserId -- confirm success; roll back afterward.
    3. Call with invalid TaskId (9999) -- confirm the custom error fires.
    4. Extend to catch duplicate-assignment (PK_TaskAssignments, error 2627) via ERROR_NUMBER()
       and re-THROW with a friendlier message.
    5. Demonstrate all three paths (success, not-found, duplicate); drop the procedure.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
