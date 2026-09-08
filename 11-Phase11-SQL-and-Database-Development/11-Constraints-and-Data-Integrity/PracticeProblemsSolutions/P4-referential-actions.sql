/*
    P4 -- Referential Actions and Cascade Paths  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Create app.TaskWatchers three times (NO ACTION / CASCADE / SET NULL) -- delete the
       parent task each time and record what happens. State SET NULL's column requirement.
    2. Explain why ON DELETE SET DEFAULT is nearly unusable, using app.Tasks.ProjectId.
    3. (Rolled back) Delete task 35 -- prove exactly 4 child rows cascade. Explain @@ROWCOUNT = 1.
    4. (Rolled back) Attempt to delete task 1 -- capture the error; identify the blocking constraint.
    5. Reproduce error 1785 twice: self-referencing cascade, and two cascade paths to app.Tasks.
    6. List 4 ways to resolve the two-path case; argue for one.
    7. Classify all 20 FKs as composition/association; check ON DELETE matches; flag mismatches.
    8. Drop everything created.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
