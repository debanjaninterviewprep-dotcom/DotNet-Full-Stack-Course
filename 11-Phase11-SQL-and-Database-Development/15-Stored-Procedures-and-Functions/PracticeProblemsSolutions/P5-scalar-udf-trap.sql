/*
    P5 -- The Scalar UDF Performance Trap  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. app.ufn_TaskOpenDays (@TaskId INT) RETURNS INT -- queries app.Tasks internally.
    2. SELECT t.TaskId, app.ufn_TaskOpenDays(t.TaskId) FROM app.Tasks AS t; capture
       SET STATISTICS TIME ON output.
    3. Rewrite as inline TVF app.ufn_TaskOpenDaysTable (@TaskId INT) RETURNS TABLE; call via
       CROSS APPLY; capture the same statistics.
    4. Check OBJECTPROPERTY(..., 'IsDeterministic') for both; check whether the scalar version
       qualifies for SQL Server 2019+ scalar UDF inlining.
    5. Explain why the scalar version's cost does not scale the way the inline TVF's does.
    6. Drop both functions.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
