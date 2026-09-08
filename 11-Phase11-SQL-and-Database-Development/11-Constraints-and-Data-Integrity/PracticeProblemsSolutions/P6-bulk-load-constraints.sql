/*
    P6 -- Bulk Load with Constraints Disabled  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Create app.TimeEntriesStaging -- same shape as app.TimeEntries, NO constraints.
    2. Populate 40 rows: 35 valid (derived from app.TimeEntries) + 5 deliberately bad
       (bad TaskId, bad UserId, Hours = 0, Hours = 30, NULL WorkDate).
    3. Create app.TimeEntriesBulk as a full clone INCLUDING PK, both FKs, CK_TimeEntriesBulk_Hours.
    4. Disable all FKs/CHECKs on app.TimeEntriesBulk, load staging rows, confirm bad rows landed.
    5. Attempt ALTER TABLE ... WITH CHECK CHECK CONSTRAINT ALL -- capture the error; note
       which constraint fired first.
    6. Write one validation query PER constraint that finds offending rows before re-enabling.
    7. Quarantine bad rows into app.TimeEntriesRejects, delete from target, re-enable successfully.
       Prove every constraint is_disabled = 0 AND is_not_trusted = 0.
    8. Compare against doing it the RIGHT way (validate-then-insert-clean, never disable) --
       rows loaded, statements run, crash-halfway behaviour.
    9. Explain why NOCHECK can't apply to a PK, what ALTER INDEX ... DISABLE would do instead,
       and why disabling a CLUSTERED index is catastrophic.
    10. Drop all three scratch tables.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
