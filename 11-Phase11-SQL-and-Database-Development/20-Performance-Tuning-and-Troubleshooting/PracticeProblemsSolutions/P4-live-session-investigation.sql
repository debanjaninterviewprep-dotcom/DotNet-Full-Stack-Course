/*
    P4 -- Live Session Investigation  (Medium -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.

    1. SESSION A: start a deliberately slow query (large unindexed scan, or an open
       transaction holding a lock) -- leave it running/open.
    2. SESSION B (or third window): sys.dm_exec_requests JOIN sys.dm_exec_sessions JOIN
       sys.dm_exec_sql_text -- session_id, status, wait_type, blocking_session_id,
       cpu_time, current statement text for every active request.
    3. Confirm you can identify Session A's query and wait state from this output alone.
    4. Let Session A finish/roll back -- confirm it disappears from live results.
*/
USE TaskFlowDb;
GO

-- ============================================================
-- SESSION A
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B (diagnostic)
-- ============================================================
-- TODO: your solution here
