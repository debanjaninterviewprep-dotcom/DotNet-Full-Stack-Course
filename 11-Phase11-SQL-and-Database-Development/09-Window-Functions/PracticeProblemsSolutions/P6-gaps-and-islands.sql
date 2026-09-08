/*
    P6 -- Gaps and Islands: Consecutive Work-Day Streaks  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. Every user's consecutive-day "islands" of logged time, using value - ROW_NUMBER().
    2. Confirm Dennis Ritchie (UserId 8) produces three separate islands.
    3. Report StreakStart, StreakEnd, COUNT(*) AS Days_ per island, ordered by length descending.
    4. Explain why the initial DISTINCT over (UserId, WorkDate) is necessary first.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
