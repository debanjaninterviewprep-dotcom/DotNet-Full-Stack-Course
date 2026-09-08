/*
    P4 -- Building and Measuring an Indexed View  (Medium)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes; drop the view/index at the end.

    1. app.vw_ProjectTaskCounts (TaskCount via COUNT_BIG(*), SUM(EstimatedHours) per project),
       WITH SCHEMABINDING.
    2. UNIQUE CLUSTERED INDEX on ProjectId to materialise it.
    3. Insert a new task into project 1 -- query the indexed view immediately, confirm it
       updated with NO manual refresh.
    4. Attempt to break the schemabound view's assumptions (e.g. drop a referenced column) --
       capture the blocking error.
    5. Drop the indexed view and any test data changes.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
