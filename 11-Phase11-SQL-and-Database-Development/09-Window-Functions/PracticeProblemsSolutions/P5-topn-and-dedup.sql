/*
    P5 -- Top-N Per Group and Deduplication  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. ROW_NUMBER: 2 most recently created tasks per project (16 rows across 8 projects).
    2. Load those 16 rows into a #temp table; duplicate 3 of them to simulate a bad import.
    3. ROW_NUMBER-based DELETE (via a CTE) removing duplicates, keeping one copy each.
       Verify the #temp table is back to 16 rows.
    4. Explain why you must SELECT the ROW_NUMBER result first and inspect it before DELETE.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
