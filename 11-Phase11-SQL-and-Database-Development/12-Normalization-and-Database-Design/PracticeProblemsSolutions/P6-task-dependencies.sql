/*
    P6 -- Design a Hierarchy: Task Dependencies  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Explain why ParentTaskId (adjacency list, single parent) cannot model
       "a task can depend on multiple other tasks" -- design app.TaskDependencies.
    2. Complete DDL including a self-dependency guard (named per TaskFlow convention).
    3. Explain why a CHECK cannot prevent an INDIRECT cycle (A->B->C->A); design (in prose,
       referencing Topic 07's cycle-detection technique) how you'd detect one.
    4. Compare adjacency-list-style vs closure-table for this use case (dependency chains are
       short, rarely > 3-4 deep) -- justify which you'd ship.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
