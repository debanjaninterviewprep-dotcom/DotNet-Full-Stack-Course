/*
    P7 -- Diagnose and Fix: A Slow Reporting Query  (Hard)
    See ../Practice-Problems.md for full requirements.

    TUNING REPORT (fill in after completing the exercise):
    -- Symptom:
    -- Diagnosis:
    -- Fix:
    -- Measured improvement:

    Using the ~200,000-row synthetic table from P6 (recreate if needed):
    1. Reporting query: join synthetic time entries to app.Tasks/app.Users, group by user
       and month, filter to the last 90 (synthetic) days, order by total hours descending.
    2. Capture the actual plan -- identify the single most expensive operator by cost %.
    3. Compare Estimated vs Actual Rows there. If they diverge, UPDATE STATISTICS and re-check.
    4. Design + create index(es) to remove the most expensive operator; report before/after
       logical reads and before/after most-expensive-operator.
    5. Find your query in sys.dm_exec_query_stats (joined to sys.dm_exec_sql_text) -- report
       total_logical_reads and execution_count.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
