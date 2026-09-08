/*
    P1 -- Reading Seek vs Scan vs Key Lookup  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. SET STATISTICS IO ON; query app.Tasks WHERE TaskId = 5 -- record operator + logical reads.
    2. Query app.Tasks WHERE EstimatedHours > 30 (no index yet) -- record operator.
    3. CREATE INDEX IX_Tasks_ProjectId ON app.Tasks (ProjectId); query TaskId, Title,
       Description WHERE ProjectId = 1 -- identify + explain the Key Lookup.
    4. Drop the index at the end.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
