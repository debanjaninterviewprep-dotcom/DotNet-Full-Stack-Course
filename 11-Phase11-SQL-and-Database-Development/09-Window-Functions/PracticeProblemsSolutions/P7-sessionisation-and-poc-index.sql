/*
    P7 -- Sessionisation and a POC Index  (Hard)
    See ../Practice-Problems.md for full requirements.

    1. LAG + 60-minute gap rule: flag each comment as starting a new session or continuing one.
    2. Turn the flag into a running SessionNo per task using a windowed SUM.
    3. Confirm task 1 (22 min apart) = 1 session; task 20 (90 min apart) = 2 sessions.
    4. Design + create a POC index (Partition, Order, Covering) for:
       ROW_NUMBER() OVER (PARTITION BY ProjectId ORDER BY CreatedAtUtc DESC) selecting TaskId, Title.
       Compare the actual plan before/after -- note which operator disappears.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
