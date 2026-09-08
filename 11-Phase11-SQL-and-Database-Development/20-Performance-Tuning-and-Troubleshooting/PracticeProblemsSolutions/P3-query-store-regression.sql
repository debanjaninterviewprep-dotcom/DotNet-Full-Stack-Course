/*
    P3 -- Query Store: Detecting a Plan Regression  (Medium)
    See ../Practice-Problems.md for full requirements.
    Unforce the plan and disable Query Store at the end if not needed further.

    1. Enable Query Store on TaskFlowDb.
    2. Run a parameterised query (as a procedure) several times with a parameter value
       chosen to compile a particular plan.
    3. Force a statistics update or artificial data change to make a DIFFERENT plan
       preferable -- run again -- confirm a second plan_id for the same query_id.
    4. sys.query_store_runtime_stats: compare the two plans' avg duration/logical reads.
    5. If the newer plan is worse, sp_query_store_force_plan the better one -- confirm
       subsequent executions use it.
    6. Unforce; disable Query Store if not needed further.
*/
USE TaskFlowDb;
GO

-- TODO: your solution here
