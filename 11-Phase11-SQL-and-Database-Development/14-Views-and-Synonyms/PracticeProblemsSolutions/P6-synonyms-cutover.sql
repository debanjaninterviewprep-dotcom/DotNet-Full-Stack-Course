/*
    P6 -- Synonyms for Location Abstraction and Cutover  (Hard)
    See ../Practice-Problems.md for full requirements.
    Ensure the database ends in its ORIGINAL state -- no leftover synonym or scratch table.

    1. app.CurrentTasks synonym FOR app.Tasks -- confirm identical results to direct query.
    2. app.Tasks_v2: structurally identical copy (SELECT INTO + PRIMARY KEY) with one extra row.
    3. Cutover: DROP SYNONYM / CREATE SYNONYM app.CurrentTasks FOR app.Tasks_v2 -- confirm the
       SAME query now returns the extra row.
    4. Cut back to app.Tasks; drop app.Tasks_v2 and the synonym.
    5. Comment table: synonyms vs views vs linked servers (>= 4 dimensions) -- which for
       "connection string always points at app.ReportingSource, physical table changes 2x/year"?
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
