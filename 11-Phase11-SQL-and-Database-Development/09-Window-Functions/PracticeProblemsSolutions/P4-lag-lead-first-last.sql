/*
    P4 -- LAG/LEAD and the LAST_VALUE Trap  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. Ken Thompson's (UserId 7) time entries: PrevHours (LAG), NextDate (LEAD),
       DaysSincePrev (DATEDIFF + LAG).
    2. Project 2 tasks ordered by CreatedAtUtc: FIRST_VALUE(TaskId) and LAST_VALUE(TaskId)
       WITHOUT an explicit frame -- observe LAST_VALUE echoing the current row.
    3. Fix LAST_VALUE with ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.
    4. Explain why FIRST_VALUE "worked" without an explicit frame but LAST_VALUE did not.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
