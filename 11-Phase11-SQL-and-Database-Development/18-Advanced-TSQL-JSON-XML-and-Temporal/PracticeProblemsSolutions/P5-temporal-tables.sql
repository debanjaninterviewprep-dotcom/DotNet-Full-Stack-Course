/*
    P5 -- Retrofit a Table with System-Versioned Temporal History  (Hard)
    See ../Practice-Problems.md for full requirements.
    Disable system versioning before dropping either table; drop both at the end.

    1. SCRATCH table app.ProjectsTemporal (structural copy of app.Projects) with
       PERIOD FOR SYSTEM_TIME columns + SYSTEM_VERSIONING ON with a named history table.
    2. Insert rows; two rounds of UPDATEs on the same row(s) with real elapsed time between
       rounds (note the actual timestamps observed).
    3. FOR SYSTEM_TIME ALL -- confirm history captured automatically, no trigger/manual insert.
    4. FOR SYSTEM_TIME AS OF a timestamp between the two update rounds -- confirm mid-history state.
    5. Attempt to directly UPDATE ValidFrom/ValidTo -- capture the rejection error.
    6. Disable system versioning; drop both tables.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
