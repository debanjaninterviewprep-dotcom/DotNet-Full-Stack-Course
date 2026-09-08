/*
    P4 -- EXCEPT as an Anti-Join, and Direction Sensitivity  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Users never assigned a task, via EXCEPT (app.Users.UserId vs app.TaskAssignments.UserId).
       Expect 6 rows.
    2. Same question via NOT EXISTS -- confirm identical UserIds, add FullName/Email columns.
    3. Run EXCEPT in BOTH directions between TaskAssignments.UserId and Users.UserId -- explain
       why one direction is guaranteed empty (name the constraint).
    4. Comment table: when to choose EXCEPT over NOT EXISTS and vice versa.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
