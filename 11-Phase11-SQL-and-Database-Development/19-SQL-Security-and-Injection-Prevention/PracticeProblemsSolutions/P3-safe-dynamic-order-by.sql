/*
    P3 -- Safe Dynamic ORDER BY with an Allow-List  (Medium)
    See ../Practice-Problems.md for full requirements.
    Drop the procedure at the end.

    1. app.usp_GetTasksSorted (@SortColumn NVARCHAR(50)) -- CASE-based allow-list validation
       before use; safe default fallback for anything unrecognised.
    2. Call with each allow-listed value -- confirm correct sorting for each.
    3. Call with an injection-shaped "column name" (e.g. TaskId; DROP TABLE app.Labels; --)
       -- confirm it falls back to the safe default, no error, nothing executed.
    4. Explain why parameters alone cannot solve this (dynamic IDENTIFIERS, not values).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
