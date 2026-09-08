/*
    P3 -- Composite Index Column Order  (Medium)
    See ../Practice-Problems.md for full requirements.

    Query: WHERE ProjectId = 1 AND StatusId = 3 ORDER BY CreatedAtUtc DESC

    1. Create the CORRECT-order composite index (equality cols first, then sort col) + covering INCLUDE.
    2. Create a WRONG-ordered index (sort column before an equality column) -- compare plans.
    3. Explain, referencing "only one range column can seek," why the wrong order is less efficient.
    4. Drop both indexes at the end.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
