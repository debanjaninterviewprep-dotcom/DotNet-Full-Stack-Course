/*
    P4 -- Snapshot Isolation and the Update Conflict  (Hard -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.
    Open TWO query windows. Follow the SESSION A / SESSION B labels in order.

    1. ALTER DATABASE TaskFlowDb SET ALLOW_SNAPSHOT_ISOLATION ON;
    2. SESSION A: SET TRANSACTION ISOLATION LEVEL SNAPSHOT; BEGIN TRANSACTION; read TaskId = 6.
    3. SESSION B (READ COMMITTED): UPDATE + COMMIT a change to the SAME row (TaskId = 6).
    4. SESSION A: attempt to UPDATE that same row within its still-open snapshot transaction --
       capture the exact Msg 3960 verbatim.
    5. Explain why this happens under SNAPSHOT but not under plain READ COMMITTED (silent
       last-writer-wins blocking instead).
    6. Reset TaskId = 6; consider disabling snapshot isolation if not needed later.
*/
USE TaskFlowDb;
GO

-- ============================================================
-- SETUP (run once)
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION A
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B
-- ============================================================
-- TODO: your solution here
