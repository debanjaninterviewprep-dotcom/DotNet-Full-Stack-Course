/*
    P4 — Correlated Subqueries vs APPLY  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Correlated subquery: tasks whose EstimatedHours exceeds their OWN project's average.
    2. Use SET STATISTICS IO ON (or the actual plan) to check whether SQL Server decorrelated
       the query -- paste the relevant plan operator name as a comment.
    3. Three measures from app.TimeEntries per task (count, total hours, most recent work date):
       first as three correlated scalar subqueries, then as a single OUTER APPLY. Confirm they match.
    4. State, in a comment, the rule for when to escalate from a correlated subquery to APPLY.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
