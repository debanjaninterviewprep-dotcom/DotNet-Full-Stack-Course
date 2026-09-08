/*
    P4 -- INSTEAD OF Trigger: Soft Delete  (Medium)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes; drop the trigger.

    1. app.trg_Projects_SoftDelete: INSTEAD OF DELETE ON app.Projects -- sets IsArchived = 1
       instead of physically deleting.
    2. DELETE FROM app.Projects WHERE ProjectId = 8 -- confirm the row STILL EXISTS, now archived.
    3. Confirm @@ROWCOUNT after the DELETE -- explain what it's actually counting.
    4. Attempt the same DELETE against project 1 (has open child tasks) -- explain whether
       your trigger's UPDATE succeeds or fails given existing FKs, and why that differs
       from what a real DELETE would have done.
    5. Roll back; drop the trigger.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
