/*
    P5 -- Observing and Resolving Blocking  (Medium -- requires TWO or THREE sessions)
    See ../Practice-Problems.md for full requirements.

    1. SESSION A: BEGIN TRANSACTION; UPDATE a row in app.Tasks -- do not commit.
    2. SESSION B: attempt to UPDATE the SAME row -- confirm it blocks (hangs).
    3. SESSION C (third window): query sys.dm_exec_requests JOIN sys.dm_exec_sessions to
       identify the blocking/blocked pair -- report wait_type and wait_resource.
    4. Commit/rollback SESSION A -- confirm SESSION B then completes.
    5. Repeat with SESSION B setting SET LOCK_TIMEOUT 2000; beforehand -- confirm it now
       fails with error 1222 after ~2 seconds instead of waiting indefinitely.
*/
USE TaskFlowDb;
GO

-- ============================================================
-- SESSION A
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION C (diagnostic -- third window)
-- ============================================================
-- TODO: your solution here
