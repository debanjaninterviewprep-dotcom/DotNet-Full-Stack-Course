/*
    P3 — The NOT IN NULL Trap  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. NOT IN query for users who are not a manager (against app.Users.ManagerId). Record the row count.
    2. Explain in a comment, using three-valued logic, why that row count is wrong.
    3. Fix three ways: NOT EXISTS, LEFT JOIN ... IS NULL, NOT IN with an explicit IS NOT NULL guard.
       Confirm all three return the same 13 rows.
    4. Summarise all four attempts in a comment table (Approach | NULL-safe | Rows).
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
