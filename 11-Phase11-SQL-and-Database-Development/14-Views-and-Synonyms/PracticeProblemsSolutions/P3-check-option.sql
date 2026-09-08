/*
    P3 -- WITH CHECK OPTION  (Medium)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes.

    1. View over app.Tasks: PriorityId IN (1,2) AND StatusId NOT IN (6,7), WITH CHECK OPTION.
    2. UPDATE a row to PriorityId = 4 (would vanish from the view) -- capture the rejection.
    3. Recreate WITHOUT CHECK OPTION -- show the same update succeeds, row then missing
       from a subsequent SELECT against the view.
    4. Explain which behaviour is safer for "write through this view, read it back" callers.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
