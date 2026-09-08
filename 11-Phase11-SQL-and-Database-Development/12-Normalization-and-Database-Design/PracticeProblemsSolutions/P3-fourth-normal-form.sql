/*
    P3 -- 4NF: Splitting an Independent Multi-Valued Table  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. #TaskFactsBad (TaskId, UserId, LabelId) -- cross-join task 4's assignees with its labels.
    2. Count rows -- confirm it matches assignee-count x label-count for task 4.
    3. Explain why "who's assigned" and "what's labelled" are independent facts; contrast a
       "is Ken Thompson assigned to task 4" query against #TaskFactsBad vs app.TaskAssignments.
    4. Show the correct 4NF decomposition using real app.TaskAssignments/app.TaskLabels --
       confirm no combinatorial explosion.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
