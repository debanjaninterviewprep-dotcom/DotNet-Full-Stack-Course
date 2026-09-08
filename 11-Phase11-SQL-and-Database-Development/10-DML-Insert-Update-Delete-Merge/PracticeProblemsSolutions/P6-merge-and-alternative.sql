/*
    P6 -- MERGE Upsert, $action, and Its Concurrency Caveat  (Hard)
    See ../Practice-Problems.md for full requirements.
    Roll back all changes at the end.

    1. MERGE against app.Labels from a VALUES source (2 existing, 2 new labels): update ColorHex
       where different, insert missing ones. OUTPUT $action to report what happened per row.
    2. Add a guarded WHEN NOT MATCHED BY SOURCE branch that only ever considers one specific
       test label -- explain why the guard matters.
    3. Rewrite as two explicit statements (UPDATE then INSERT ... WHERE NOT EXISTS) in one
       transaction -- confirm same end state as the MERGE version.
    4. Explain the specific concurrency race an unguarded upsert is vulnerable to, and the fix.
*/
USE TaskFlowDb;
GO

BEGIN TRANSACTION;

-- TODO: your solution here

ROLLBACK TRANSACTION;
