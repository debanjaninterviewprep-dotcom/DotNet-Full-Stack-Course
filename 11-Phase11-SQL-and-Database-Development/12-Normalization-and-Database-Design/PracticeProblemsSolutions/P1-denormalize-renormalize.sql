/*
    P1 -- Denormalize, Then Renormalize  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Flat join of Tasks/Projects/TaskAssignments/Users/TaskLabels+Labels into
       #TaskReportDenormalized, shaped like the TaskReport example in Notes.md Sec 2.
    2. For task 4 (2 assignees x 2 labels): how many rows does it occupy? Why?
    3. Comment: one concrete insert anomaly, one update anomaly, one delete anomaly --
       using real TaskFlow values.
    4. Map each anomaly to its normal form (1NF/2NF/3NF) and the real table that fixes it.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
