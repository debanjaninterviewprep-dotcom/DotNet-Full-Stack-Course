/*
    P5 -- Statistics Staleness and Its Consequences  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. sys.dm_db_stats_properties for app.Tasks -- last_updated, rows, modification_counter.
    2. Insert/update/delete a meaningful number of rows (scratch or Topic 13's synthetic
       table) -- re-check modification_counter.
    3. Capture estimated row count for a query filtering the changed data BEFORE updating
       statistics, and AFTER UPDATE STATISTICS ... WITH FULLSCAN -- compare vs actual.
    4. Explain the relationship between modification_counter, the auto-update threshold,
       and why a large bulk load can outpace automatic statistics maintenance.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
