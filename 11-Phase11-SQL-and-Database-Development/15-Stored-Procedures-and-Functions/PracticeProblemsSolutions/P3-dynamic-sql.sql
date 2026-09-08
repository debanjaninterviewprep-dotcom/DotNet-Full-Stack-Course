/*
    P3 -- Safe Dynamic SQL with sp_executesql  (Medium)
    See ../Practice-Problems.md for full requirements.
    The vulnerable procedure must be dropped before this script ends.

    1. app.usp_SearchTasks (@ProjectId, @StatusId, @TitleLike, all default NULL) using
       sp_executesql with BOUND parameters to build the WHERE clause dynamically.
    2. Call with zero, one, and all three filters -- confirm correct results each time.
    3. Deliberately vulnerable version: concatenate @TitleLike directly into the SQL string.
       Demonstrate a classic injection payload (e.g. ' OR '1'='1) altering its behaviour.
    4. Explain why the sp_executesql-parameterised version is immune to the same payload.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
