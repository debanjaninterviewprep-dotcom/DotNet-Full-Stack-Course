/*
    P2 -- Finding the Culprit Query via the Plan Cache  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Run 3-4 different queries against app.Tasks/app.Projects with deliberately
       different costs (simple seek, full scan, one with a sort).
    2. sys.dm_exec_query_stats JOIN sys.dm_exec_sql_text -- correctly use statement
       offset columns to extract just the relevant statement text.
    3. Sort by total_logical_reads -- confirm the most expensive query is at the top.
    4. Re-sort by execution_count after looping your cheapest query many times --
       confirm the ranking changes to reflect volume.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
