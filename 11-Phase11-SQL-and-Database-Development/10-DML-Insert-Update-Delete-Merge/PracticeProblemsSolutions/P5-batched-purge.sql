/*
    P5 -- Batched Purge Loop  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Generate ~10,000 synthetic rows into a #temp table (cross-joined VALUES/ROW_NUMBER series).
    2. WHILE loop: DELETE TOP (1000) per iteration, checking @@ROWCOUNT to terminate.
    3. PRINT (or RAISERROR ... WITH NOWAIT) progress after each batch.
    4. Explain the two production risks (log growth, lock escalation) this batching avoids.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
