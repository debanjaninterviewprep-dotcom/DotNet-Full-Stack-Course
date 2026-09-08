/*
    P7 -- Cursor (RBAR) vs Set-Based Rewrite  (Hard)
    See ../Practice-Problems.md for full requirements.
    Roll back all changes at the end.

    1. Cursor-based loop: raise every PriorityId = 3 task on project 2 to PriorityId = 2,
       one row at a time.
    2. Roll back; write the set-based single-statement equivalent.
    3. SET STATISTICS TIME ON -- compare elapsed time of both approaches.
    4. Explain why the cursor version's cost does not scale the way you'd want in production --
       name specific per-row overheads.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
