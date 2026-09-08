/*
    P3 -- Cross-Row Enforcement: the Hours Cap Trigger  (Medium)
    See ../Practice-Problems.md for full requirements.
    Roll back all data changes; drop the trigger.

    1. app.trg_TimeEntries_HoursCap (Notes.md Sec 4): total logged hours <= 2x estimate.
    2. Task 1 (est 24.00, logged 18.75): insert an entry pushing past 48.00 -- confirm the
       WHOLE INSERT rolls back with the custom error.
    3. Insert a smaller entry staying under the cap -- confirm it succeeds.
    4. Multi-row INSERT where ONE row violates the cap and others wouldn't -- confirm the
       ENTIRE statement rolls back, not just the offending row.
    5. Roll back; drop the trigger.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
