/*
    P1 -- A Basic Encapsulating View  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. CREATE VIEW app.vw_OpenTasks (TaskId, Title, ProjectId, StatusId, PriorityId, DueDate)
       WHERE StatusId NOT IN (6, 7).
    2. Query filtered by ProjectId -- confirm matches a hand-written equivalent.
    3. #ScratchTasks with a SELECT * view -- add a column to the scratch table, show the
       view does NOT pick it up.
    4. sp_refreshview -- confirm the new column now appears.
    Drop all scratch objects at the end.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
