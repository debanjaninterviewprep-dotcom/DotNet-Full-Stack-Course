/*
    P2 -- Shredding JSON with OPENJSON  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. OPENJSON ... WITH: project every task's epic/risk fields (where present) into typed
       columns across all of app.Tasks.
    2. OPENJSON(..., '$.reviewers') + CROSS APPLY: shred task 1's reviewers into one row each.
    3. Extend to shred EVERY task's reviewers array (most have none) -- use OUTER APPLY so
       reviewer-less tasks still appear with NULL.
    4. Explain why CROSS APPLY was correct for step 2 but OUTER APPLY is required for step 3.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
