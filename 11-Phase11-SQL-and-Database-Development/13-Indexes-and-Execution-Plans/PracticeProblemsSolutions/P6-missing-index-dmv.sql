/*
    P6 -- Missing Index DMVs on a Larger Synthetic Table  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Build dbo.BigTimeEntriesPermanent (~200,000 rows) shaped like app.TimeEntries, using a
       cross-joined VALUES/ROW_NUMBER number series (Topic 07) for synthetic TaskId/UserId/
       WorkDate/Hours.
    2. Query it filtering an unindexed column -- check sys.dm_db_missing_index_details.
    3. Create the suggested index; re-run; confirm improved logical reads (SET STATISTICS IO ON).
    4. Query sys.dm_db_index_usage_stats for the new index -- confirm user_seeks incremented.
    5. Explain why the missing-index DMV is a "suggestion engine, not a mandate."
    Drop all scratch objects at the end.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
