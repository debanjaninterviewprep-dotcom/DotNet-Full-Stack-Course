/*
    P1 -- Disciplined INSERT and Identity Capture  (Easy)
    See ../Practice-Problems.md for full requirements.

    1. Insert 3 new rows into app.Labels via one multi-row VALUES statement, explicit column list.
    2. Capture all 3 generated LabelIds via OUTPUT ... INTO a table variable.
    3. Show (as a comment) why a positional insert into (ColorHex, LabelName) against the real
       (LabelName, ColorHex) column order would silently write wrong data.
    4. Clean up the 3 rows you inserted.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
