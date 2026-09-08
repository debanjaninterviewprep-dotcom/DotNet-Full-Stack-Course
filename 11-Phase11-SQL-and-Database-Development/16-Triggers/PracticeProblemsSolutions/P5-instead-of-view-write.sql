/*
    P5 -- INSTEAD OF Trigger: Making a Multi-Table View Writable  (Hard)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes; drop the trigger and the view.

    1. app.vw_TaskWithProjectName joining app.Tasks and app.Projects.
    2. Attempt a two-table UPDATE through it directly (no trigger yet) -- confirm Msg 4405.
    3. app.trg_vw_TaskWithProjectName_Update: INSTEAD OF UPDATE, writes Title/StatusId back
       to app.Tasks only, deliberately NOT propagating ProjectName to app.Projects.
    4. Same two-table UPDATE now "succeeds" -- prove with a follow-up SELECT that
       app.Projects.ProjectName was NOT actually changed.
    5. Explain why this silent-partial-write is a documented design decision, not a bug --
       sketch how you'd change it to REJECT the whole statement instead if it touches ProjectName.
    6. Roll back; drop the trigger and the view.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
