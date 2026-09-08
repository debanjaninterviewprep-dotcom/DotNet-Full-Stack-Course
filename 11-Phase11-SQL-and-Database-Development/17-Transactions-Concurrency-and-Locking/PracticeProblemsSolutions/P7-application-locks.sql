/*
    P7 -- Application-Level Locking with sp_getapplock  (Hard -- requires TWO sessions)
    See ../Practice-Problems.md for full requirements.
    Drop the procedure at the end.

    1. Explain what problem sp_getapplock/sp_releaseapplock solve that ordinary row/table
       locks cannot (locking a CONCEPT, not a row).
    2. app.usp_CloseSprintForTeam (@TeamId INT): acquire an exclusive app lock scoped to
       N'CloseSprint:' + CAST(@TeamId AS NVARCHAR(10)) before placeholder work; release after.
    3. Two sessions call it for the SAME @TeamId concurrently -- demonstrate the second waits.
    4. Two sessions call it for DIFFERENT @TeamId values concurrently -- confirm neither blocks.
    5. Drop the procedure.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here (procedure definition)

-- ============================================================
-- SESSION A
-- ============================================================
-- TODO: your solution here

-- ============================================================
-- SESSION B
-- ============================================================
-- TODO: your solution here
