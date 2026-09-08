/*
    P2 -- The Updatable View Boundary  (Easy)
    See ../Practice-Problems.md for full requirements.
    WRAP EVERYTHING IN BEGIN TRANSACTION / ROLLBACK TRANSACTION.

    1. CREATE VIEW app.vw_TaskWithProject joining app.Tasks and app.Projects.
    2. UPDATE a Tasks-only column through the view -- succeeds.
    3. UPDATE a Projects-only column through the view -- succeeds.
    4. UPDATE one column from EACH table in a single statement -- capture Msg 4405 verbatim.
    5. Roll back.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
