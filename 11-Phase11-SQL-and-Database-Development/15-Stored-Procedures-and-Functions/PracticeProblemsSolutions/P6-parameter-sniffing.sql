/*
    P6 -- Observing Parameter Sniffing  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. app.usp_TasksByStatus (@StatusId TINYINT).
    2. Call with a high-selectivity status, then a low-selectivity status -- inspect
       (sys.dm_exec_query_stats / actual plan) whether the same cached plan served both.
    3. Add OPTION (RECOMPILE) -- demonstrate each call gets its own fresh plan.
    4. Add OPTIMIZE FOR (@StatusId UNKNOWN) instead -- explain the estimate used regardless
       of the actual value passed.
    5. Comment table: when to choose default caching / RECOMPILE / OPTIMIZE FOR.
    6. Drop the procedure(s).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
