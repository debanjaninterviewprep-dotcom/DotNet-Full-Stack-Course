/*
    P5 -- Regression-Testing a Query Rewrite with EXCEPT  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. "Old" query: TaskId, ProjectId, Title for tasks with PriorityId IN (1, 2), subquery-based filter.
    2. "New" query: same three columns via JOIN to ref.Priorities filtered on
       PriorityName IN (N'Critical', N'High').
    3. EXCEPT both directions between old and new -- fix until both return zero rows.
    4. Comment: one limitation of this technique (what kind of bug would it miss).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
