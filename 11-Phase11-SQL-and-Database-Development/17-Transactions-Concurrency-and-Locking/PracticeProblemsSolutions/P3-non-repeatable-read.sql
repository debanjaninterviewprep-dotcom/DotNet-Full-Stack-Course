/*
    P3 -- Non-Repeatable Read vs REPEATABLE READ  (Medium -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.
    Open TWO query windows. Follow the SESSION A / SESSION B labels in order.

    1. SESSION A (default isolation): BEGIN TRANSACTION; SELECT EstimatedHours WHERE TaskId = 1;
       record the value -- do not commit/read again yet.
    2. SESSION B: UPDATE + COMMIT a change to that same row's EstimatedHours.
    3. SESSION A: re-run the IDENTICAL SELECT within the same open transaction -- observe the
       changed value (non-repeatable read). Commit/rollback Session A.
    4. Repeat with SESSION A using SET TRANSACTION ISOLATION LEVEL REPEATABLE READ -- confirm
       SESSION B now BLOCKS on its update until Session A's transaction ends.
    5. Explain the lock-duration difference between READ COMMITTED and REPEATABLE READ.
    Remember to reset TaskId = 1's EstimatedHours back to 24.00 afterward.
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
