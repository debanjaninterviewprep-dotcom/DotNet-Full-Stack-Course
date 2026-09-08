/*
    P1 -- Cause and Fix a Real Injection  (Easy)
    See ../Practice-Problems.md for full requirements.
    Drop the vulnerable procedure before this script ends.

    1. app.usp_SearchTasksVulnerable (@TitleSearch NVARCHAR(200)) -- builds + EXECs dynamic
       SQL via string concatenation.
    2. Call with an ordinary search term -- confirm it works as intended.
    3. Call with a payload that comments out the rest of the WHERE clause (e.g. ' OR '1'='1' --)
       -- PRINT @sql to observe the resulting text; show the unintended full result set.
    4. app.usp_SearchTasksSafe using sp_executesql with a bound parameter -- confirm the
       SAME payload is now treated as a literal, harmless string.
    5. Drop app.usp_SearchTasksVulnerable.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
