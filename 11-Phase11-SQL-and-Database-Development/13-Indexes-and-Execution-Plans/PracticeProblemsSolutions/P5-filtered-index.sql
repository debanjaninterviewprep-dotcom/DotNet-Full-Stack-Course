/*
    P5 -- Filtered Index for a Hot Subset  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. CREATE INDEX ... ON app.Tasks (ProjectId, DueDate) WHERE StatusId NOT IN (6, 7).
    2. Query matching the filter predicate + a ProjectId filter -- confirm the filtered index is used.
    3. Query that does NOT match the filter shape (e.g. WHERE StatusId = 3 alone) -- observe and
       explain whether the optimizer still uses it.
    4. Compare row/page counts between this filtered index and a hypothetical unfiltered
       equivalent -- state the storage saving (22 vs 35 rows).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
