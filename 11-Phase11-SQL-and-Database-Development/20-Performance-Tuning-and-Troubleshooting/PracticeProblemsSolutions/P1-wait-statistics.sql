/*
    P1 -- Reading Wait Statistics  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. sys.dm_os_wait_stats, excluding benign/idle wait types -- top 10 by total wait time.
    2. Snapshot into #WaitsBefore.
    3. Generate artificial load (large CROSS JOIN, or Topic 13's synthetic table) --
       re-snapshot into #WaitsAfter.
    4. Diff the two snapshots by wait type -- explain why snapshot-and-diff is necessary
       instead of reading the lifetime cumulative view directly.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
