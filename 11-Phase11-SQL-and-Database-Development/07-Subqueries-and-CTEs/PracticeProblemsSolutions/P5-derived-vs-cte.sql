/*
    P5 — Derived Tables vs CTE Chains  (Medium)
    See ../Practice-Problems.md for full requirements.

    1. A single, three-levels-deep nested subquery: per project with >= 3 open tasks
       (StatusId NOT IN (6, 7)), the project code and open task count.
    2. The identical query rewritten as a three-step, named CTE chain.
    3. Compare the actual execution plans of both -- state whether they differ.
    4. Explain (comment) why the CTE chain is preferable even if the plan is identical.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
